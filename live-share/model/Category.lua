local class = require'middleclass'
local MappedEntity = require'live-share.MappedEntity'


local Category = class'live-share.model.Category'
Category:include(MappedEntity)

Category:set_table_name'category'
Category:map_primary_key'id'
Category:map_column'name'

function Category.static:get_by_name(name)
    return self:select():raw'WHERE name = ':var(name):execute():first()
end

function Category.static:get_or_create(name)
    local category = self:get_by_name(name)
    if not category then
        category = Category()
        category.name = name
        category:create_entity()
    end
    return category
end

function Category:initialize()
    self:initialize_mapping()
end

return Category
