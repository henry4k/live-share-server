local message_by_code =
{
    [200] = 'OK',
    [201] = 'Created',
    [202] = 'Accepted',

    [300] = 'Multiple Choices',
    [301] = 'Moved Permanently',
    [303] = 'See Other',
    [307] = 'Temporary Redirect',
    [308] = 'Permanent Redirect',

    [400] = 'Bad Request',
    [401] = 'Unauthorized',
    [403] = 'Forbidden',
    [404] = 'Not Found',
    [405] = 'Method Not Allowed',
    [406] = 'Not Acceptable',
    [408] = 'Request Timeout',
    [409] = 'Conflict',
    [410] = 'Gone',
    [413] = 'Payload Too Large',
    [415] = 'Unsupported Media Type',
    [426] = 'Upgrade Required', -- also set upgrade header
    [429] = 'Too Many Requests',

    [500] = 'Internal Server Error',
    [501] = 'Not Implemented',
    [503] = 'Service Unavailable'
}

local http_status = {}

function http_status.get_message_by_code(code)
    code = assert(tonumber(code))
    local message = message_by_code[code]
    if not message then
        -- Try standard class:
        code = math.floor(code / 100) * 100
        message = message_by_code[code] or 'Unknown'
    end
    return message
end

return http_status
