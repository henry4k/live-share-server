local datetime = {}

do
    local t1 = os.time()
    local d = os.date('!*t', t1)
    local t2 = os.time(d)
    datetime.utc_offset = t1 - t2
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
