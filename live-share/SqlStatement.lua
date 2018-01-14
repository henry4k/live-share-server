local database = require'live-share.database'


local SqlStatement = {}
SqlStatement.__index = SqlStatement

function SqlStatement:raw(...)
    local buffer = self._buffer
    for _, s in ipairs{...} do
        buffer[#buffer+1] = s
    end
    return self
end

function SqlStatement:id(identifier)
    if identifier:match"['%s]" then
        identifier = identifier:gsub("'", "\\'")
        return self:raw("'", identifier, "'")
    else
        return self:raw(identifier)
    end
end

function SqlStatement:var(value)
    if value ~= nil then
        table.insert(self._variables, value)
        return self:raw'?'
    else
        return self:raw'NULL'
    end
end

function SqlStatement:__tostring()
    return table.concat(self._buffer)
end

function SqlStatement:execute()
    return self._result_handler(database(self:__tostring(), table.unpack(self._variables)))
end

local function pass_through(v) return v end

return function(result_handler)
    return setmetatable({_buffer = {},
                         _variables = {},
                         _result_handler = result_handler or pass_through},
                        SqlStatement)
end
