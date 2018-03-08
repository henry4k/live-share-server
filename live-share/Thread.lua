local cjson = require'cjson'
local class = require'middleclass'
local cqueues = require'cqueues'
local thread = require'cqueues.thread'
local strerror = require'cqueues.errno'.strerror
local cq_assert = require'cqueues.auxlib'.assert


local Thread = class'live-share.Thread'

function Thread.static._serialize(...)
    return cjson.encode{...}
end

function Thread.static._deserialize(data)
    return table.unpack(cjson.decode(data))
end


local Socket = class'live-share.Thread.Socket'
Thread.static.Socket = Socket

function Socket:initialize(handle)
    self._handle = handle
end

function Socket:send(...)
    self._handle:write(Thread._serialize(...), '\n')
end

function Socket:receive()
    return Thread._deserialize(self._handle:read('*l'))
end


function Thread:initialize(fn, ...)
    local serialized_fn = string.dump(fn)
    local serialized_args = Thread._serialize{...}
    local wrapped_fn = function(socket_handle,
                                package_path,
                                package_cpath,
                                serialized_fn,
                                serialized_args)
        package.path = package_path
        package.cpath = package_cpath
        local Thread = require'live-share.Thread'
        local socket = Thread.Socket(socket_handle)
        local fn = assert(load(serialized_fn))
        local args = Thread._deserialize(serialized_args)
        return fn(socket, table.unpack(args))
    end
    local cq_thread, cq_socket =
        cq_assert(thread.start(wrapped_fn,
                               package.path,
                               package.cpath,
                               serialized_fn,
                               serialized_args))
    self._handle = cq_thread
    self.socket = Socket(cq_socket)
end

function Thread:join()
    local _, err = self._handle:join()
    if err then
        if type(err) == 'number' then
            err = strerror(err)
        end
        error(err) -- TODO: Errors should be passed using fat_error someday.
    end
end

return Thread
