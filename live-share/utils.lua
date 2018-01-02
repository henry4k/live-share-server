local cjson = require'cjson'


local utils = {}

function utils.is_shady_file_name(file_name)
    return file_name:match'%.%.' or
           file_name:match'^/'   or
           file_name:match'^%./' or
           file_name:match'/$'   or
           file_name:match'\\'
end

function utils.respond_with_json(stream, response_headers, value)
    local json = assert(cjson.encode(value))
    response_headers:append('content-type', 'application/json')
    assert(stream:write_headers(response_headers, false))
    assert(stream:write_chunk(json, true))
end

-- See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control#Examples
utils.cache_control_dynamic = 'no-cache, no-store, must-revalidate'
utils.cache_control_static  = 'public, max-age=31536000'

return utils
