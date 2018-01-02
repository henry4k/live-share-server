local http_server = require'http.server'
local http_headers = require'http.headers'
local utils = require'live-share.utils'
local fat_error = require'fat_error'
local write_error = require'fat_error.writers.FancyWriter'{}

local server = {_routes = {}}

local function resolve(method, url_path)
    for _, route in ipairs(server._routes) do
        if route.method == method then
            local captures = {string.match(url_path, route.pattern)}
            if #captures > 0 then
                return route.callback, {pattern_captures = captures}
            end
        end
    end
end

local function stream_handler(_server, stream) -- luacheck: ignore 212
    -- Read in headers
    local req_headers = assert(stream:get_headers())
    local method = req_headers:get':method'
    local url_path = req_headers:get':path'

    io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"\n',
        os.date'%d/%b/%Y:%H:%M:%S %z',
        method,
        url_path,
        stream.connection.version,
        req_headers:get'referer' or '-',
        req_headers:get'user-agent' or '-'
    ))

    local callback, params = resolve(method, url_path)
    if not callback then
        error(string.format('Could not resolve %s %s', method, url_path))
    end

    params.stream = stream
    params.headers = req_headers

    local ok, err = fat_error.pcall(callback, params)
    if not ok then
        write_error(err)
    end
end

local function error_handler(_server, context, op, err, errno) -- luacheck: ignore 212
    local msg = op .. ' on ' .. tostring(context) .. ' failed'
    if err then
        msg = msg .. ': ' .. tostring(err)
    end
    io.stderr:write(msg, '\n')
end

function server.match(method, url_pattern, callback)
    local route = {method = method,
                   pattern = url_pattern,
                   callback = callback}
    table.insert(server._routes, route)
end

function server.websocket(url_path, callback)
    local websocket = require'http.websocket'
    server.match('GET', url_path, function(p)
        local connection_header = p.headers:get'connection':lower()
        local upgrade_header = p.headers:get'upgrade':lower()
        assert(connection_header:match('upgrade') and
               upgrade_header == 'websocket',
               'Not a WebSocket upgrade request.')
        local ws = assert(websocket.new_from_stream(p.stream, p.headers))
        ws:accept()
        p.websocket = ws
        callback(p)
    end)
end

function server.static(url_path, fs_path)
    local path = require'path'
    local mimetypes = require'mimetypes'
    local imf_date = require'http.util'.imf_date
    assert(path.isdir(fs_path), 'Directory does not exist.')
    server.match('GET', '^'..url_path..'/(.*)$', function(p)
        local file_name = p.pattern_captures[1]
        assert(not utils.is_shady_file_name(file_name), 'Shady file name.')
        local file_path = path.join(fs_path, file_name)
        local file = assert(io.open(file_path, 'r'))

        local response_headers = http_headers.new()
        response_headers:append(':status', '200')
        response_headers:append('cache-control', utils.cache_control_static)

        local mimetype = mimetypes.guess(file_name)
        if mimetype then
            response_headers:append('content-type', mimetype)
        end

        local file_size = file:seek'end'
        file:seek'set' -- rewind
        response_headers:append('content-length', tostring(file_size))

        local mtime = assert(path.mtime(file_path))
        response_headers:append('last-modified', imf_date(mtime))

        assert(p.stream:write_headers(response_headers, false))
        assert(p.stream:write_body_from_file(file))

        file:close()
    end)
end

function server.run(t)
    t = t or {}
    t.port = t.port or 0
    t.host = t.host or 'localhost'
    t.onstream = stream_handler
    t.onerror = error_handler

    local instance = assert(http_server.listen(t))

    -- Manually call :listen() so that we are bound before calling :localname()
    assert(instance:listen())
    do
        local bound_port = select(3, instance:localname())
        io.stderr:write(string.format('Now listening on port %d\n', bound_port))
    end
    -- Start the main server loop
    assert(instance:loop())
end

return server
