local class = require 'middleclass'
local cjson = require'cjson'
local imf_date = require'http.util'.imf_date
local utils = require'live-share.utils'
local get_message_by_code = require'live-share.http_status'.get_message_by_code


local HttpError = class'live-share.HttpError'

function HttpError:initialize(http_status, message)
    self.http_status = http_status
    self._message = message or get_message_by_code(http_status)
end

function HttpError:__tostring()
    return self._message
end

local html_template = [[
<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <title>live-share</title>
        <link rel="stylesheet" type="text/css" href="/style.css"></link>
    </head>
    <body>
        <div id="error">
            <span class="status-code">%d</span>
            <span class="message">%s</span>
        </div>
    </body>
</html>]]

function HttpError:handle(p)
    local headers = p.response_headers
    headers:upsert(':status', tostring(self.http_status))
    headers:upsert('cache-control', utils.cache_control_static)
    headers:upsert('last-modified', imf_date(os.time()))

    local content

    local accept_header = p.request_headers:get'accept' or ''
    if accept_header:match'application/json' then
        headers:upsert('content-type', 'application/json')
        content = assert(cjson.encode{HttpError = self._message})
    elseif accept_header:match'text/html' then
        headers:upsert('content-type', 'text/html')
        content = string.format(html_template, self.http_status, self._message)
    else
        headers:upsert('content-type', 'text/plain')
        content = self._message
    end

    headers:upsert('content-length', tostring(#content))

    p.stream:write_headers(headers, false)
    p.stream:write_body_from_string(content)
end

local asserts = {}
HttpError.static.assert = asserts

local function make_assert(name, code)
    asserts[name] = function(value, ...)
        if value then
            return value, ...
        else
            error(HttpError(code, ...))
        end
    end
end

make_assert('parameter', 400)
make_assert('found', 404)
make_assert('media_type', 415)


return HttpError
