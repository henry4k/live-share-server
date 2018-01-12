local path = require'path'
local db = require'live-share.database'
local utils = require'live-share.utils'
local user = require'live-share.user'
local category = require'live-share.category'
local database = require'live-share.database'
local server = require'live-share.server'
local update = require'live-share.update'
local handlers = require'live-share.handlers'
local config = require'config'


local media_types = {{type = 'image',
                      subtype = 'png',
                      file_extension = 'png'},
                     {type = 'image',
                      subtype = 'jpg',
                      file_extension = 'jpg'},
                     {type = 'image',
                      subtype = 'webp',
                      file_extension = 'webp'},
                     {type = 'video',
                      subtype = 'webm',
                      file_extension = 'webm'},
                     {type = 'video',
                      subtype = 'mp4',
                      extension = 'mp4'}}

local media_types_by_mime_type = {}

for id, media in ipairs(media_types) do
    local mime_type = media.type..'/'..media.subtype
    media_types_by_mime_type[mime_type] = media
    media.id = id
end


local upload = {}

function upload.create(user_id, category_id, media_type)
    assert(media_type.id)
    db("INSERT INTO upload (time, user_id, category_id, media_type) VALUES (strftime('%s','now'), ?, ?, ?)",
       user_id, category_id, media_type.id)
    return db.last_id()
end

local function get_file_name(upload_id, media_type)
    return path.join(config.upload_directory, tostring(upload_id)) --..'.'..media_type.file_extension)
end

server.router:post('/upload', function(p)
    local user_id = assert(user.get_user_from_request(p.request_headers))

    local category_name = assert(p.query.category, 'Category name missing.')
    local category_id = category.get_or_create(category_name)

    local mime_type = assert(p.request_headers:get'content-type')
    local media_type = assert(media_types_by_mime_type[mime_type],
                              'Unknown/unsupported content type.')

    local upload_id = upload.create(user_id, category_id, media_type)

    local file_name = get_file_name(upload_id, media_type)

    local file = assert(io.open(file_name, 'w'))
    p.stream:save_body_to_file(file)
    file:close()

    database.commit()

    p.response_headers:append(':status', '200')
    p.response_headers:append('cache-control', utils.cache_control_dynamic)
    assert(p.stream:write_headers(p.response_headers, true))

    update.notify_observers('new-upload', {id = upload_id,
                                           type = media_type.type,
                                           user = user.get_name(user_id),
                                           category = category_name})
end)

server.router:get('/upload/:file', handlers.StaticDir(config.upload_directory))
--server.router:get('/thumbnails/:file', handlers.StaticFile())

return upload
