local colors = require'ansicolors'


local err_file = io.stderr
local out_file = io.stdout

local log = {}


local request_properties =
{
    client_address = function (stream, request_headers)
        if request_headers:has'forwarded' then
            return request_headers:get'forwarded':match'for=([^%s]+)'
        else
            local _, address = stream.connection:peername()
            return address
        end
    end,

    user_id = function() return nil end, -- TODO

    time = function() return os.date'%d/%b/%Y:%H:%M:%S %z' end,

    method = function(_, request_headers) return request_headers:get':method' end,

    path = function(_, request_headers) return request_headers:get':path' end,

    protocol_version = function(stream) return tostring(stream.connection.version) end,

    response_status = function(_, __, response_headers)
        local status = response_headers:get':status'
        local status_color
        if not status then
            status = '...'
            status_color = 'dim white'
        elseif status:match'^2' then
            status_color = 'green'
        elseif status:match'^5' then
            status_color = 'red'
        else
            status_color = 'yellow'
        end
        return string.format('%%{%s}%s%%{reset}', status_color, status)
    end,

    response_length = function(_, __, response_headers)
        return response_headers:get'content-length' -- TODO
    end,

    referer = function(_, request_headers) return request_headers:get'referer' end,

    user_agent = function(_, request_headers) return request_headers:get'user-agent' end
}

-- NCSA combined log format (without cookie):
--local request_log_format = '%{client_address} - %{user_id} [%{time}] "%{method} %{path} HTTP/%{protocol_version}" %{response_status} %{response_length} "%{referer}" "%{user_agent}"'

-- Lapis log format:
local request_log_format = '[%{response_status}] %{bright}%{cyan}%{method} %{path}%{reset}'

local function create_request_log_line(stream, request_headers, response_headers)
    local message = request_log_format:gsub('%%{(.-)}', function(property)
        local getter = request_properties[property]
        if getter then
            return getter(stream, request_headers, response_headers) or '-'
        end
    end)
    return colors(message)
end

-- This is intended for long running requests.
function log.new_request(stream, ...)
    log.info(create_request_log_line(stream, ...))
end

function log.completed_request(stream, ...)
    log.info(create_request_log_line(stream, ...))
end

function log.info(...)
    out_file:write(...)
    out_file:write('\n')
end

function log.error(...)
    err_file:write(...)
    err_file:write('\n')
end

log.fat_error = require'fat_error.writers.FancyWriter'{destination = err_file,
                                                       show_variables = 'parameters'}

return log
