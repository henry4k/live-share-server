local dbi = require'DBI'
local here = require'live-share.utils'.here
local config = require'config'


local connection = assert(dbi.Connect('SQLite3', config.database))

local database = {}
setmetatable(database, database)

local statement_cache = {} -- maps sql to prepared statements

function database.close()
    for _, ps in pairs(statement_cache) do
        ps:close()
    end
    connection:close()
end

local function prepare(statement)
    --print(statement)
    return assert(connection:prepare(statement))
end

-- @param statement May be a string or an sqlrocks Statement instance
function database.exec(statement, use_cache, ...)
    local ps
    if use_cache then
        ps = statement_cache[statement]
    end

    if not ps then
        ps = prepare(statement)
        if use_cache then
            statement_cache[statement] = ps
        end
    end

    assert(ps:execute(...))

    return ps
end

function database:__call(statement, ...)
    return database.exec(statement, true, ...)
end

function database.exec_batch(sql)
    for statement in sql:gmatch('[^%s].-;') do
        database.exec(statement, false):close()
    end
end

function database.exec_file(file_name)
    local file = assert(io.open(file_name, 'r'))
    local sql = file:read('*a')
    file:close()
    return database.exec_batch(sql)
end

function database.last_id()
    return connection:last_id()
end

function database.quote(s)
    return connection:quote(s)
end

function database.commit()
    return connection:commit()
end

function database.rollback()
    return connection:rollback()
end

database.exec_file(here('schema.sql'))
database.commit()

return database
