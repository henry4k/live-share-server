local cjson = require'cjson'
local utils = require'live-share.utils'


local EventStream = {}
EventStream.__index = EventStream

function EventStream:send_comment()
    assert(self._http_stream:write_chunk(':\n\n', false))
end

function EventStream:send_json(event_name, data)
    local json = assert(cjson.encode(data))
    return self:send_raw(event_name, json)
end

function EventStream:send_json(event_name, data)
    data = cjson.encode(data)
    return self:send_raw(event_name, data)
end

function EventStream:send_raw(event_name, data)
    local buffer = {}

    if event_name then
        table.insert(buffer, 'event: ')
        table.insert(buffer, event_name)
        table.insert(buffer, '\n')
    end

    table.insert(buffer, 'data: ')
    table.insert(buffer, data)
    table.insert(buffer, '\n')

    table.insert(buffer, '\n') -- terminate event message

    local chunk = table.concat(buffer)
    assert(self._http_stream:write_chunk(chunk, false))
end

function EventStream:close()
    assert(self._http_stream:write_chunk('', true))
end

return function(p)
    local self = {_http_stream = p.stream}

    local headers = p.response_headers
    headers:append(':status', '200')
    headers:append('content-type', 'text/event-stream')
    headers:append('cache-control', utils.cache_control_dynamic)
    assert(p.stream:write_headers(headers, false))
    assert(p.stream.connection:flush())

    return setmetatable(self, EventStream)
end
