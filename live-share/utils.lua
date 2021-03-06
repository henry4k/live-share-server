local path = require'path'
local cjson = require'cjson'
local cqueues = require'cqueues'
local promise = require'cqueues.promise'
local signal = require'cqueues.signal'


local utils = {}

function utils.program_is_available(name)
    for dir in os.getenv('PATH'):gmatch('[^:]+') do
        local file_name = path.join(dir, name)
        if path.exists(file_name) then
            return file_name
        end
    end
    return nil, string.format('Can\'t find %s in PATH.', name)
end

function utils.is_shady_file_name(file_name)
    return file_name:match'%.%.' or
           file_name:match'^/'   or
           file_name:match'^%./' or
           file_name:match'/$'   or
           file_name:match'\\'
end

function utils.respond_with_json(p, value, empty_type)
    local json
    if not next(value) and empty_type == 'array' then
        json = '[]'
    else
        json = assert(cjson.encode(value))
    end
    p.response_headers:append('content-type', 'application/json')
    assert(p.stream:write_headers(p.response_headers, false))
    assert(p.stream:write_body_from_string(json))
end

-- See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#Examples
utils.cache_control_dynamic = 'no-cache, no-store, must-revalidate'
--utils.cache_control_static  = 'public, max-age=600' -- 10 minutes
utils.cache_control_static  = 'public, max-age=31536000' -- "forever"

local function get_source_path(stack_index)
    local info = debug.getinfo(stack_index+1, 'S')
    if info and
       info.source and
       info.source:sub(1,1) == '@' then
        return info.source:sub(2)
    end
end

local source_dir_pattern = '^(.*)[/\\]'
local function get_source_dir(stack_index)
    local source_path = get_source_path(stack_index+1)
    if source_path then
        return source_path:match(source_dir_pattern)
    end
end

--- Gives the current directory or a subpath thereof.
function utils.here(sub_path)
    local source_dir = get_source_dir(2)
    if source_dir then
        if sub_path then
            return path.join(source_dir, sub_path)
        else
            return source_dir
        end
    end
end

function utils.is_instance(value, class)
    if type(value) == 'table' and value.isInstanceOf then
        return value:isInstanceOf(class)
    end
end

local tmp_file_process_id = math.random(0, 9999)
local tmp_file_counter = 0

---
-- @tparam[opt=''] postfix
-- @tparam[opt=''] prefix
-- @tparam[opt] dir Defaults to the systems temp directory.
function utils.get_temporary_file_name(t)
    local dir = t.dir or path.tmpdir()
    tmp_file_counter = tmp_file_counter+1
    local basename = string.format('%s%d-%04d%s',
                                   t.prefix or '',
                                   tmp_file_process_id,
                                   tmp_file_counter,
                                   t.postfix or '')
    local filename = path.join(dir, basename)
    --assert(not path.exists(filename))
    return filename
end

utils.shutdown_promise = promise.new()

function utils.shutdown()
    utils.shutdown_promise:set(true)
end

function utils.on_shutdown(callback)
    local cqueue = cqueues.running()
    cqueue:wrap(function()
        utils.shutdown_promise:wait()
        callback()
    end)
end

function utils.install_shutdown_listener(cqueue)
    local signal_set = {signal.SIGTERM, signal.SIGINT}
    local signal_listener = signal.listen(table.unpack(signal_set))
    signal.block(table.unpack(signal_set))
    cqueue:wrap(function()
        local ready = assert(cqueues.poll(signal_listener, utils.shutdown_promise))
        if ready == signal_listener then
            require'live-share.log'.info('Received shutdown signal')
            utils.shutdown()
        end
    end)
end

function utils.get_systemd_listen_fds()
    local count = os.getenv'LISTEN_FDS'
    if count then
        count = assert(tonumber(count))
        local fds = {}
        for i = 1, count do
            fds[i] = 2+i -- SD_LISTEN_FDS_START == 3
        end
        return table.unpack(fds)
    end
end

return utils
