local class = require'middleclass'
local database = require'live-share.database'
local SqlStatement = require'live-share.SqlStatement'


local MappedEntity = {static = {}}

function MappedEntity:included(klass)
    klass.static._mapping =
    {
        table_name = nil,
        primary_key_property = nil,
        property_list = {},
        property_by_column_name = {},
        property_by_lua_name = {},
        entities = setmetatable({}, {__mode = 'v'})
    }
end

function MappedEntity.static:set_table_name(name)
    local mapping = self.static._mapping
    assert(not mapping.table_name, 'Table name has already been set.')
    mapping.table_name = name
end

local function IsMappedEntityClass(c)
    return type(c) == 'table' and c._mapping
end

local function compare_properties(a, b)
    return a.index < b.index
end

local function pass_through(v) return v end

-- @tparam [1] column name
-- @tparam as lua name (defaults to column name)
-- @tparam type
function MappedEntity.static:map_column(t)
    if type(t) ~= 'table' then
        t = {t}
    end

    local column_name = assert(t[1], 'Column name missing.')
    local lua_name = t.lua_name or column_name

    local import
    local export

    if IsMappedEntityClass(t.type) then
        local klass = t.type
        local pk = assert(klass._mapping.primary_key_property)
        local pk_import = pk.import
        local pk_export = pk.export
        import = function(s) return klass:by_id(pk_import(s)) end
        export = function(v) return pk_export(v:get_id()) end
    else
        import = t.import or pass_through
        export = t.export or pass_through
    end

    local property = {column_name = column_name,
                      lua_name = lua_name,
                      index = 0, -- see below
                      import = import,
                      export = export}

    local mapping = self._mapping
    table.insert(mapping.property_list, property)
    mapping.property_by_column_name[column_name] = property
    mapping.property_by_lua_name[lua_name] = property

    property.index = #mapping.property_list

    return property
end

function MappedEntity.static:map_primary_key(t) -- TODO: Or 'id column'?
    local mapping = self._mapping
    assert(not mapping.primary_key_property,
           'Primary key has already been mapped.')
    mapping.primary_key_property = self:map_column(t)
end

function MappedEntity.static:by_id(id)
    local mapping = self._mapping
    local entity = mapping.entities[id]
    if not entity then
        entity = self:new()
        entity:set_id(id)
        entity:read_all_properties()
    end
    return entity
end

-- TODO: This should go into fat_error!
--local fat_error = require'fat_error'
--local coro_create = fat_error.create_coroutine_with_error_handler
--local coro_resume = fat_error.resume_coroutine_and_propagate_error
--local function coro_wrap(fn)
--    local coro = coro_create(fn)
--    return function(...)
--        return coro_resume(coro, ...)
--    end
--end

local EntityQueryResults = {}
EntityQueryResults.__index = EntityQueryResults

function EntityQueryResults:__call(raw_results)
    self.raw_results = raw_results
    return self
end

function EntityQueryResults:next()
    local row = self.raw_results:fetch()
    if row then
        assert(#row == 1)
        local id = self.import_id(row[1])
        return self.klass:by_id(id)
    end
end

EntityQueryResults.first = EntityQueryResults.next

function EntityQueryResults:each()
    return self.next, self
end

function EntityQueryResults:collect()
    local r = {}
    for v in self:each() do
        r[#r+1] = v
    end
    return r
end

function MappedEntity.static:select()
    local mapping = self._mapping
    local primary_key_property = mapping.primary_key_property

    local queryResults = {klass = self,
                          import_id = primary_key_property.import}
    setmetatable(queryResults, EntityQueryResults)
    local statement = SqlStatement(queryResults)
    statement:raw'SELECT ':id(primary_key_property.column_name)
    statement:raw' FROM ':id(mapping.table_name):raw' '
    return statement
end

function MappedEntity:initialize_mapping()
    self._property_state =
    {
        values = {}, -- maps property index to its current value
        dirty_set = {} -- set of properties
    }
end

function MappedEntity:close()
    local mapping = self.class._mapping
    local id = self:get_id()
    assert(mapping.entities[id])
    mapping.entities[id] = nil
end

--- Shorthand for the primary key value.
function MappedEntity:get_id()
    local primary_key_property = self.class._mapping.primary_key_property
    assert(primary_key_property, 'No primary key has been mapped.')
    local id = self._property_state.values[primary_key_property.index]
    assert(id, 'ID has not been set.')
    return id
end

--- Shorthand for the primary key value.
function MappedEntity:set_id(id)
    local mapping = self.class._mapping
    local primary_key_property = mapping.primary_key_property
    assert(primary_key_property, 'No primary key has been mapped.')

    local index = primary_key_property.index
    local values = self._property_state.values
    assert(not values[index], 'ID has already been set.')
    values[index] = id

    assert(not mapping.entities[id],
           'There is already an entity with this ID loaded.')
    mapping.entities[id] = self
end

function MappedEntity:get_property_value(lua_name)
    local mapping = self.class._mapping
    local property = assert(mapping.property_by_lua_name[lua_name],
                            'There is no property with this lua name.')
    return self._property_state.values[property.index]
end

function MappedEntity:set_property_value(lua_name, value)
    local mapping = self.class._mapping
    local property = assert(mapping.property_by_lua_name[lua_name],
                            'There is no property with this lua name.')
    local property_state = self._property_state
    property_state.values[property.index] = value
    property_state.dirty_set[property] = true
end

function MappedEntity:__index(key)
    local property = self.class._mapping.property_by_lua_name[key]
    if property then
        return self:get_property_value(key)
    end
end

function MappedEntity:__newindex(key, value)
    local property = self.class._mapping.property_by_lua_name[key]
    if property then
        return self:set_property_value(key, value)
    else
        rawset(self, key, value)
    end
end

function MappedEntity:create_entity()
    local mapping = self.class._mapping
    local primary_key_property = mapping.primary_key_property
    local values = self._property_state.values

    assert(not values[primary_key_property.index],
           'Entity has already an ID - so it can\'t be created again.')

    local column_names = {}
    local parameter_placeholders = {}
    local statement_parameters = {}
    for _, property in ipairs(mapping.property_list) do
        if property ~= primary_key_property then
            local value = values[property.index]
            if value ~= nil then -- 'false' is alowed
                local exported_value = property.export(value)
                assert(exported_value)
                table.insert(column_names, property.column_name)
                table.insert(parameter_placeholders, '?')
                table.insert(statement_parameters, exported_value)
            end
        end
    end

    local sql = string.format('INSERT INTO %s (%s) VALUES (%s)',
                              mapping.table_name,
                              table.concat(column_names, ', '),
                              table.concat(parameter_placeholders, ', '))

    local statement = database(sql, table.unpack(statement_parameters))
    assert(statement:affected() == 1) -- should insert exactly one row

    local id = database.last_id()
    self:set_id(primary_key_property.import(id))

    self._property_state.dirty_set = {} -- clear
end

function MappedEntity:read_all_properties()
    local mapping = self.class._mapping
    local primary_key_property = mapping.primary_key_property
    local values = self._property_state.values

    local column_names = {}
    for i, property in ipairs(mapping.property_list) do
        if property ~= primary_key_property then
            table.insert(column_names, property.column_name)
        end
    end

    -- TODO: There is no need to include the primary key in the column list.

    local sql = string.format('SELECT %s FROM %s WHERE %s = ?',
                              table.concat(column_names, ', '),
                              mapping.table_name,
                              primary_key_property.column_name)

    local id = values[primary_key_property.index]
    id = primary_key_property.export(id)
    assert(id)

    local statement = database(sql, id)

    local row = statement:fetch()
    assert(row, 'There is no entity with this ID in the database.')
    assert(#row == #column_names)
    assert(statement:fetch() == nil) -- there must be no further rows

    for i, value in ipairs(row) do
        local property = mapping.property_by_column_name[column_names[i]]
        assert(property)
        values[property.index] = property.import(value)
    end

    self._property_state.dirty_set = {} -- clear
end

function MappedEntity:write_modified_properties()
    local mapping = self.class._mapping
    local primary_key_property = mapping.primary_key_property
    local values = self._property_state.values
    local dirty_set = self._property_state.dirty_set

    assert(next(dirty_set), 'No need to write as nothing was modified.')

    assert(not dirty_set[primary_key_property],
           'The entity ID musn\'t be modified.')

    local dirty_property_list = {}
    for property in pairs(dirty_set) do
        table.insert(dirty_property_list, property)
    end
    table.sort(dirty_property_list, compare_properties)
    -- ^- Assures that the list looks the same whenever the same properties are
    -- dirty.  This is needed because statements are cached by the database
    -- module.

    local column_assignments = {}
    local statement_parameters = {}
    for i, property in pairs(dirty_property_list) do
        column_assignments[i] = property.column_name..' = ?'
        local value = values[property.index]
        local exported_value = property.export(value)
        statement_parameters[i] = exported_value
    end

    local sql = string.format('UPDATE %s SET %s WHERE %s = ?',
                              mapping.table_name,
                              table.concat(column_assignments, ', '),
                              primary_key_property.column_name)

    local id = values[primary_key_property.index]
    id = primary_key_property.export(id)
    assert(id)

    table.insert(statement_parameters, id)

    local statement = database(sql, table.unpack(statement_parameters))
    assert(statement:affected() == 1) -- should update exactly one row

    self._property_state.dirty_set = {} -- clear
end

function MappedEntity:delete()
    local mapping = self.class._mapping
    local primary_key_property = mapping.primary_key_property
    local values = self._property_state.values

    local sql = string.format('DELETE FROM %s WHERE %s = ?',
                              mapping.table_name,
                              primary_key_property.column_name)

    local id = values[primary_key_property.index]
    id = primary_key_property.export(id)
    assert(id)

    local statement = database(sql, id)
    assert(statement:affected() == 1) -- should delete exactly one row

    self:close()
end

return MappedEntity
