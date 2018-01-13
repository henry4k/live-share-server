local cqueues = require'cqueues'
local utils = require'live-share.utils'
local server = require'live-share.server'
local handlers = require'live-share.handlers'
local database = require'live-share.database'
local media_types = require'live-share.media_types'
local update_resource = require'live-share.resource.update'
local User = require'live-share.model.User'
local Category = require'live-share.model.Category'
local Upload = require'live-share.model.Upload'
local thumbnail = require'live-share.thumbnail'
local config = require'config'


server.router:post('/upload', function(p)
    local user = assert(User:get_from_request(p.request_headers))

    local category_name = assert(p.query.category, 'Category name missing.')
    local category = Category:get_or_create(category_name)

    local mime_type = assert(p.request_headers:get'content-type')
    local media_type = assert(media_types.by_mime_type[mime_type],
                              'Unknown/unsupported content type.')

    local upload = Upload()
    upload.time = os.time()
    upload.user = user
    upload.category = category
    upload.media_type = media_type
    upload:create_entity()

    local file_name = upload:get_file_name()

    local file = assert(io.open(file_name, 'w'))
    p.stream:save_body_to_file(file)
    file:close()

    database.commit()

    p.response_headers:append(':status', '200')
    p.response_headers:append('cache-control', utils.cache_control_dynamic)
    assert(p.stream:write_headers(p.response_headers, true))

    local process = thumbnail.generate(upload)
    assert(cqueues.poll(process))

    update_resource.notify_observers('new-upload',
                                     upload:get_resource_properties())
end)

local function handle_file_request(p)
    local id = assert(tonumber(p.id))
    local upload = assert(Upload:by_id(id))
    p.response_headers:append('content-type', upload.media_type.mime_type)
    return handlers.send_file(p, upload:get_file_name())
end
server.router:get('/upload/:id', handle_file_request)
server.router:head('/upload/:id', handle_file_request)

local function handle_thumbnail_request(p)
    local id = assert(tonumber(p.id))
    local upload = assert(Upload:by_id(id))
    p.response_headers:append('content-type', upload.thumbnail_media_type.mime_type)
    return handlers.send_file(p, upload:get_thumbnail_file_name())
end
server.router:get('/upload/:id/thumbnail', handle_thumbnail_request)
server.router:head('/upload/:id/thumbnail', handle_thumbnail_request)
