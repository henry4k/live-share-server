local path = require'path'
local class = require'middleclass'
local MappedEntity = require'live-share.MappedEntity'
local User = require'live-share.model.User'
local Category = require'live-share.model.Category'
local media_types = require'live-share.media_types'
local config = require'config'


local Upload = class'live-share.model.Upload'
Upload:include(MappedEntity)

Upload:set_table_name'upload'
Upload:map_primary_key'id'
Upload:map_column'time'
Upload:map_column{'user_id', lua_name='user', type=User}
Upload:map_column{'category_id', lua_name='category', type=Category}
Upload:map_column{'media_type',
                  import = function(type_id)
                      type_id = tonumber(type_id)
                      return assert(media_types.by_id[type_id],
                                    'Unknown media type ID.')
                  end,
                  export = function(type)
                      return type.id
                  end}

function Upload:initialize()
    self:initialize_mapping()
end

function Upload:get_file_name()
    --local base_name = tostring(self.id)..'.'..self.media_type.file_extension
    return path.join(config.upload_directory, tostring(self.id))
end

function Upload:get_resource_properties()
    return {id = self.id,
            time = self.time,
            user_name = self.user.name,
            category_name = self.category.name,
            media_type = self.media_type.type}
end

return Upload
