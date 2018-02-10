local database = require'live-share.database'

local function fetch_one(statement)
    local row = assert(statement:fetch())
    assert(#row <= 1) -- because result may be a NULL value
    return row[1]
end

local function column_exists()
    local value = fetch_one(database('SELECT COUNT(*) FROM settings'))
    return value == 1
end

local function create_column()
    database('INSERT INTO settings DEFAULT VALUES')
end

local function get_setting(name)
    return fetch_one(database('SELECT '..name..' FROM settings'))
end

local function set_setting(name, value)
    database('UPDATE settings SET '..name..' = ?', tostring(value))
    database.commit() -- TODO: Is this okay here?
end

if not column_exists() then
    create_column()
end

local function index(self, key)
    local value = get_setting(key)
    rawset(self, key, value)
    return value
end

local function newindex(self, key, value)
    set_setting(key, value)
    rawset(self, key, value)
end

local value_cache = {}

return setmetatable(value_cache,
                    {__index = index,
                     __newindex = newindex})
