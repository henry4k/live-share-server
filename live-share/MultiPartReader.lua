local http_headers = require'http.headers'

--[[ Example:
server.router:post('/upload', function(p)
    local reader = MultiPartReader(p.stream, p.request_headers:get'content-type')
    while reader:read_boundary() == 'next' do
        local headers = reader:read_headers()
        ...
        for chunk in reader:each_chunk() do
            ...
        end
    end
end
]]


local MultiPartReader = {}
MultiPartReader.__index = MultiPartReader

function MultiPartReader:_read_line()
    local stream = self._stream
    return assert(stream:get_body_until('\r\n', true))
end

function MultiPartReader:read_boundary()
    local line = self:_read_line()
    local boundary_start = self._boundary_start

    self._hit_boundary = false

    assert(line:sub(1, #boundary_start) == boundary_start,
           'Not a boundary.')

    if #line == #boundary_start then
        return 'next'
    else
        assert(line:sub(#boundary_start+1, -1) == '--',
               'Malformed end marker.')
        return 'end'
    end
end

function MultiPartReader:read_headers()
    local headers = http_headers.new()
    while true do
        local line = self:_read_line()
        if #line > 0 then
            local header, value = line:match('^(.-):%s*(.*)$')
            assert(header, 'Malformatted header.')
            headers:append(header, value)
        else
            break
        end
    end
    return headers
end

local function safe(s) return s:gsub('\r', '\\r') end

function MultiPartReader:get_next_chunk()
    if self._hit_boundary then
        return nil
    end

    local stream = self._stream

    local chunk, err = stream:get_next_chunk()
    if not chunk then
        return nil, err
    end

    local pos = chunk:find(self._crlf_boundary_start, 1, true) -- plain text search
    -- xxxxxxxRN--BOUNDARY...
    --        ^
    if pos then
        local rest = chunk:sub(pos+2, -1) -- drop crlf (\r\n)
        assert(stream:unget(rest))
        self._hit_boundary = true -- read_boundary resets this

        if pos > 1 then
            return chunk:sub(1, pos-1)
        else
            return nil
        end
    else
        return chunk
    end
end

function MultiPartReader:each_chunk()
    return self.get_next_chunk, self
end

return function(stream, content_type)
    local subtype, boundary =
        content_type:match('^multipart/(.-);%s*boundary=(.+)$')
    assert(subtype, 'Incorrect multipart content type.')

    local self = {_stream = stream,
                  _boundary_start = '--'..boundary,
                  _crlf_boundary_start = '\r\n--'..boundary,
                  _hit_boundary = false} -- used by the chunk reader
    return setmetatable(self, MultiPartReader)
end
