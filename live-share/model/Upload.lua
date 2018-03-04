local path = require'path'
local class = require'middleclass'
local log = require'live-share.log'
local MappedEntity = require'live-share.MappedEntity'
local User = require'live-share.model.User'
local Category = require'live-share.model.Category'
local media_types = require'live-share.media_types'
local datetime = require'live-share.datetime'
local config = require'live-share.config'


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
Upload:map_column'width'
Upload:map_column'height'

do
    local image_type = config.thumbnail.image_type
    local mime_type = 'image/'..image_type
    local media_type = media_types.by_mime_type[mime_type]
    assert(media_type, 'Unknown thumbnail media type.')
    Upload.thumbnail_media_type = media_type
end

function Upload:initialize()
    self:initialize_mapping()
end

local function try_remove(file)
    local ok, err = os.remove(file)
    if not ok then
        log.error(err)
    end
end

function Upload:delete()
    try_remove(self:get_file_name())
    try_remove(self:get_thumbnail_file_name())
    MappedEntity.delete(self)
end

function Upload:get_file_name()
    local base_name = tostring(self.id)..'.'..self.media_type.file_extension
    return path.join(config.upload_directory, base_name)
end

function Upload:get_thumbnail_file_name()
    local base_name = tostring(self.id)..'.'..self.thumbnail_media_type.file_extension
    return path.join(config.thumbnail.directory, base_name)
end

function Upload:get_resource_properties()
    return {id = self.id,
            time = datetime.compose_iso_date_time(self.time),
            user_name = self.user.name,
            category_name = self.category.name,
            media_type = self.media_type.type,
            width = self.width,
            height = self.height}
end

return Upload
