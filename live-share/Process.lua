local unistd = require 'posix.unistd'
local signal = require 'posix.signal'
local wait = require 'posix.sys.wait'
local class = require 'middleclass'

assert(wait.WNOHANG, 'wait.WNOHANG not supported.')


local Process = class'live-share.Process'

function Process:initialize(t)
    print(table.concat(t,' ')) -- DEBUG
    local path = t.path or t[1]
    assert(path, 'No excutable path.')

    local pid = assert(unistd.fork())
    if pid == 0 then
        local args = {}
        for i, arg in ipairs(t) do
            args[i-1] = arg
        end

        ---- move to a own process group, so it can't be affected by stopping the
        ---- manager with ctrl-c:
        --assert(unistd.setpid('p', 0, 0))
        ---- see: https://stackoverflow.com/questions/6803395/child-process-receives-parents-sigint#6804155

        assert(unistd.execp(path, args))
    else
        self._pid = pid
    end
end

function Process:destroy()
    if self:is_alive() then
        self:signal('kill')
        self:wait() -- cleanup child TODO: what about local signal handlers?
    end
end

function Process:signal(signal_name)
    local signal_id = signal['SIG'..string.upper(signal_name)]
    assert(signal_id, 'No such signal.')
    assert(signal.kill(self._pid, signal_id))
end

function Process:wait(no_hang)
    local options
    if no_hang then
        options = wait.WNOHANG
    end

    assert(self._pid, 'Process ended already.')

    -- `wait` will free the PID after successfully waiting for a process
    local pid, end_type, end_status = assert(wait.wait(self._pid, options))
    if pid ~= 0 then
        assert(end_type ~= 'stopped') -- depends on WUNTRACED
        self._pid = nil
        self._end_type = end_type -- exited, killed or stopped
        self._end_status = end_status -- exit code (exited) or signal number (killed and stopped)
    end
end

function Process:is_alive()
    if self._pid then
        self:wait(true)
    end
    return self._pid ~= nil, self._end_type, self._end_status
end

function Process:exited_cleanly()
    if self._pid then
        self:wait(true)
    end
    return not self._pid and
           self._end_type == 'exited' and
           self._end_status == 0
end

local well_known_exit_codes = -- these are taken from sysexits.h
{
    [0]  = 'successful termination',
    [64] = 'command line usage error',
    [65] = 'data format error',
    [66] = 'cannot open input',
    [67] = 'addressee unknown',
    [68] = 'host name unknown',
    [69] = 'service unavailable',
    [70] = 'internal software error',
    [71] = 'system error (e.g., can\'t fork)',
    [72] = 'critical OS file missing',
    [73] = 'can\'t create (user) output file',
    [74] = 'input/output error',
    [75] = 'temp failure; user is invited to retry',
    [76] = 'remote error in protocol',
    [77] = 'permission denied',
    [78] = 'configuration error'
}

function Process:end_reason()
    if self._end_type == 'exited' then
        local code = self._end_status
        if code == 0 then
            return 'exited cleanly'
        else
            local postfix = ''
            local description = well_known_exit_codes[code]
            if description then
                postfix = ' ('..description..')'
            end
            return 'exited with '..tostring(code)..postfix
        end
    elseif self._end_type == 'killed' then
        local signal_id = self._end_status
        local postfix
        local signal_name
        for k, v in pairs(signal) do
            if v == signal_id and k:match('^SIG') then
                signal_name = k:match('^SIG(.*)$'):lower()
                break
            end
        end
        return 'killed by '..(signal_name or 'unknown')..' signal'
    else
        error('unknown end type')
    end
end


-- cqueues support:

local cqueues = require'cqueues'
local signal = require'cqueues.signal'
local Promise = require'cqueues.promise'.new

local function wait_for_signals(...)
    signal.block(...)
    local s = signal.listen(...)
    s:wait()
    signal.unblock(...)
end

local signal_watcher_runs = false
local watched_processes = {}

function Process.static:start_signal_watcher(cqueue)
    if signal_watcher_runs then
        return
    end

    cqueue:wrap(function()
        while true do
            wait_for_signals(signal.SIGCHLD)
            for process, promise in pairs(watched_processes) do
                if not process:is_alive() then
                    watched_processes[process] = nil
                    promise:set(true)
                end
            end
        end
    end)

    signal_watcher_runs = true
end

local function get_process_end_promise(process)
    local promise = watched_processes[process]
    if not promise then
        assert(signal_watcher_runs, 'Signal watcher does not run.')
        promise = Promise()
        watched_processes[process] = promise
    end
    return promise
end

function Process:_get_promise()
    local promise = self._promise
    if not promise then
        assert(self:is_alive())
        promise = get_process_end_promise(self)
        self._promise = promise
    end
    return promise
end

function Process:pollfd()
    return self:_get_promise():pollfd()
end

--[[
function Process:events()
    return self:_get_promise():events()
end

function Process:timeout()
    return self:_get_promise():timeout()
end
]]

return Process
