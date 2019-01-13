local datetime = {}

do
    local now = os.time()
    local utc_date   = os.date('!*t', now)
    local local_date = os.date('*t', now)
    local_date.isdst = false -- this is the trick
    datetime.utc_offset = os.difftime(os.time(local_date), os.time(utc_date))
    -- See: http://lua-users.org/wiki/TimeZone
end

local iso_date_time_format = '%Y-%m-%dT%H:%M:%SZ'

function datetime.compose_iso_date_time( time )
    return os.date('!'..iso_date_time_format, time)
end

function datetime.parse_iso_date_time( str )
    local year, month, day, hour, minute, second =
        str:match('^(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)')
    if year then
        return os.time{year  = tonumber(year),
                       month = tonumber(month),
                       day   = tonumber(day),
                       hour  = tonumber(hour),
                       min   = tonumber(minute),
                       sec   = tonumber(second)} + datetime.utc_offset
    end
end

return datetime
