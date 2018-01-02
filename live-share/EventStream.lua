local cjson = require'cjson'
local http_headers = require'http.headers'
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

return function(http_stream)
    local self = {_http_stream = http_stream}

    local res_headers = http_headers.new()
    res_headers:append(':status', '200')
    res_headers:append('content-type', 'text/event-stream')
    res_headers:append('cache-control', utils.cache_control_dynamic)
    assert(http_stream:write_headers(res_headers, false))

    return setmetatable(self, EventStream)
end
