local cqueues = require'cqueues'
local cqueues_socket = require'cqueues.socket'
local http_version = require'http.version'
local http_server = require'http.server'
local http_headers = require'http.headers'
local http_util = require'http.util'
local fat_error = require'fat_error'
local utils = require'live-share.utils'
local is_instance = utils.is_instance
local log = require'live-share.log'
local HttpError = require'live-share.HttpError'


local server_header = http_version.name..'/'..http_version.version
local router = require'live-share.third-party.router'.new()

local server = {router = router}

local function split_query_args(url_path)
    local pure_path, query_str = url_path:match('^(.+)?(.+)$')
    if pure_path then
        local query_args = {}
        for k, v in http_util.query_args(query_str) do
            query_args[k] = v
        end
        return pure_path, query_args
    else
        return url_path, {}
    end
end

local function default_handler(p)
    local url_path = p.request_headers:get':path'
    local message = string.format('File not found: %s', url_path)
    local err = HttpError(404, message)
    return err:handle(p)
end

local function onstream(_server, stream) -- luacheck: ignore 212
    -- Read in headers
    local request_headers = assert(stream:get_headers())
    local method = request_headers:get':method'
    local url_path = request_headers:get':path'
    local query_args

    url_path, query_args = split_query_args(url_path)

    local response_headers = http_headers.new()
    response_headers:append('server', server_header)

    local handler, params = router:resolve(method, url_path)
    if not handler then
        handler = default_handler
        params = {}
    end

    params.stream = stream
    params.request_headers = request_headers
    params.response_headers = response_headers
    params.query = query_args

    local ok, err = fat_error.pcall(handler, params)
    if not ok then
        log.fat_error(err)

        local desc = err.description
        if not is_instance(desc, HttpError) then
            desc = HttpError(500, desc)
        end

        if stream.state == 'idle' or
           stream.state == 'open' or
           stream.state == 'half closed (remote)' then -- not sent headers or body yet
            desc:handle(params)
        else
            response_headers:upsert(':status', tostring(desc.http_status)) -- for logging
        end
    end

    log.completed_request(stream, request_headers, response_headers)
end

local function onerror(_server, context, op, err, errno) -- luacheck: ignore 212
    local msg = op .. ' on ' .. tostring(context) .. ' failed'
    if err then
        msg = msg .. ': ' .. tostring(err)
    end
    log.error(msg)
end

local server_instance
function server.run(t)
    t = t or {}
    t.onstream = onstream
    t.onerror = onerror
    t.cq = assert(cqueues.running())

    local listen_fd = utils.get_systemd_listen_fds()
    if listen_fd then
        local socket = assert(cqueues_socket.fdopen(listen_fd))
        t.socket = socket

        server_instance = assert(http_server.new(t))
    else
        t.port = t.port or 0
        t.host = t.host or 'localhost'

        server_instance = assert(http_server.listen(t))

        -- Manually call :listen() so that we are bound before calling :localname()
        assert(server_instance:listen())

        if t.port == 0 then
            local bound_port = select(3, server_instance:localname())
            log.info('Now listening on port ', tostring(bound_port))
        end
    end

    utils.on_shutdown(server.stop)
end

function server.stop()
    server_instance:close()
    server_instance = nil
end

return server
