local path = require'path'
local mimetypes = require'mimetypes'
local imf_date = require'http.util'.imf_date
local websocket = require'http.websocket'
local utils = require'live-share.utils'


local handlers = {}

function handlers.Constant(t)
    local content = t.content or t[1] or ''
    assert(type(content) == 'string', 'Content must be a string.')

    local headers = t.headers or {}

    headers[':status'] = t.status or '200'
    headers['cache-control'] = utils.cache_control_static
    headers['last-modified'] = imf_date(os.time())

    if #content > 0 then
        headers['content-type'] = t.content_type or 'application/octet-stream'
        headers['content-length'] = tostring(#content)

        return function(p)
            local response_headers = p.response_headers
            for name, value in pairs(headers) do
                response_headers:append(name, value)
            end
            assert(p.stream:write_headers(response_headers, false))
            assert(p.stream:write_body_from_string(content))
        end
    else
        return function(p)
            local response_headers = p.response_headers
            for name, value in pairs(headers) do
                response_headers:append(name, value)
            end
            assert(p.stream:write_headers(response_headers, true))
        end
    end
end

function handlers.Redirect(t)
    local location = assert(t.location or t.to)
    local status = t.status or '308' -- defaults to permanent redirect
    return handlers.Constant{status = status,
                             headers = {location = location}}
end

function handlers.Websocket(callback)
    return function(p)
        local connection_header = p.request_headers:get'connection':lower()
        local upgrade_header = p.request_headers:get'upgrade':lower()
        assert(connection_header:match('upgrade') and
               upgrade_header == 'websocket',
               'Not a WebSocket upgrade request.')
        local ws = assert(websocket.new_from_stream(p.stream, p.request_headers))
        ws:accept()
        p.websocket = ws
        return callback(p)
    end
end

local function collect_headers_from_file(headers, file_name, file)
    if not headers:has'content-type' then
        local mimetype = mimetypes.guess(file_name)
        if mimetype then
            headers:append('content-type', mimetype)
        end
    end

    local mtime = assert(path.mtime(file_name))
    headers:upsert('last-modified', imf_date(mtime))

    local file_size = file:seek'end'
    file:seek'set' -- rewind
    headers:upsert('content-length', tostring(file_size))
end

local function send_file(p, file_name)
    local response_headers = p.response_headers
    if not response_headers:has'cache-control' then
        response_headers:append('cache-control', utils.cache_control_static)
    end

    local file = io.open(file_name, 'r')
    if not file then
        -- TODO: 404
        response_headers:append(':status', '404')
        assert(p.stream:write_headers(response_headers, true))
    end

    response_headers:append(':status', '200')
    collect_headers_from_file(response_headers, file_name, file)

    local is_head_request = p.request_headers:get':method' == 'HEAD'

    assert(p.stream:write_headers(response_headers, is_head_request))

    if is_head_request then
        file:close()
        return
    else
        assert(p.stream:write_body_from_file(file))
        file:close()
    end
end
handlers.send_file = send_file

function handlers.StaticFile(file_name)
    assert(path.isfile(file_name), 'File does not exist.')
    return function(p)
        return send_file(p, file_name)
    end
end

function handlers.StaticDir(dir_name)
    assert(path.isdir(dir_name), 'Directory does not exist.')
    return function(p)
        local file_name = assert(p.file, 'Router passes no file parameter.')
        assert(not utils.is_shady_file_name(file_name), 'Shady file name.')
        local file_name = path.join(dir_name, file_name)
        return send_file(p, file_name)
    end
end

return handlers
