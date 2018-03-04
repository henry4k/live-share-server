local config = require'live-share.config'
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
local datetime = require'live-share.datetime'
local HttpError = require'live-share.HttpError'

local assert_parameter = HttpError.assert.parameter
local assert_authorized = HttpError.assert.authorized
local assert_found = HttpError.assert.found
local assert_media_type = HttpError.assert.media_type


--[[
@api {post} /upload Upload a file
@apiName UploadFile
@apiGroup Upload
@apiPermission user

@apiParam {String} category Name of the category. (query parameter)
--]]
server.router:post('/upload', function(p)
    local user = assert_authorized(User:get_from_request(p.request_headers))

    local category_name = assert_parameter(p.query.category, 'Category name missing.')
    local category = Category:get_or_create(category_name)

    local mime_type = assert_parameter(p.request_headers:get'content-type')
    local media_type = assert_media_type(media_types.by_mime_type[mime_type],
                                         'Unknown/unsupported content type.')

    local upload = Upload()
    upload.time = os.time()
    upload.user = user
    upload.category = category
    upload.media_type = media_type

    local temp_upload_file_name =
        utils.get_temporary_file_name{
            dir = config.upload_directory,
            prefix = 'tmp',
            postfix = '.'..upload.media_type.file_extension}

    local temp_thumbnail_file_name =
        utils.get_temporary_file_name{
            dir = config.thumbnail.directory,
            prefix = 'tmp',
            postfix = '.'..upload.thumbnail_media_type.file_extension}

    -- TODO: Files need to be removed when something goes wrong!

    local temp_upload_file = assert(io.open(temp_upload_file_name, 'w'))
    p.stream:save_body_to_file(temp_upload_file)
    temp_upload_file:close()

    local metadata = thumbnail.generate(upload.media_type,
                                        temp_upload_file_name,
                                        temp_thumbnail_file_name):get()
    upload.width  = assert(metadata.width)
    upload.height = assert(metadata.height)

    upload:create_entity()
    -- Now the upload entity is complete and can be used:
    assert(os.rename(temp_upload_file_name,
                     upload:get_file_name()))
    assert(os.rename(temp_thumbnail_file_name,
                     upload:get_thumbnail_file_name()))

    database.commit()

    p.response_headers:append(':status', '200')
    p.response_headers:append('cache-control', utils.cache_control_dynamic)
    assert(p.stream:write_headers(p.response_headers, true))

    update_resource.notify_observers('new-upload',
                                     upload:get_resource_properties())
end)


--[[
@api {get} /upload/query Search for uploads
@apiName QueryUpload
@apiGroup Upload

@apiParam {DateTime} [before] Select uploads created before given timestamp. (query parameter)
@apiParam {String} [order_asc] ... (query parameter)
@apiParam {String} [order_desc] ... (query parameter)
@apiParam {Number} [limit=100] ... (query parameter)

@apiSuccess {Number} id
@apiSuccess {DateTime} time ISO date time format
@apiSuccess {String} user_name
@apiSuccess {String} category_name
@apiSuccess {String="image","video"} media_type
@apiSuccessExample {json}
    HTTP/1.1 200 OK
    [
        {
            "id": 42,
            "time": "2007-04-05T12:30-02:00Z",
            "user_name": "Mario",
            "category_name": "Portal",
            "media_type": "image"
        },
        {
            "id": 45,
            "time": "2007-05-12T7:33-06:03Z",
            "user_name": "Luigi",
            "category_name": "Witcher",
            "media_type": "video"
        }
    ]
--]]
local max_query_limit = 100
server.router:get('/upload/query', function(p)
    local s = Upload:select()

    if p.query.before then
        local time = assert_parameter(datetime.parse_iso_date_time(p.query.before),
                                      "Malformatted date time in 'before' field.")
        s:raw'WHERE time < ':var(time)
    end

    if p.query.order_asc then
        s:raw' ORDER BY ':id(p.query.order_asc):raw' ASC'
    end

    if p.query.order_desc then
        s:raw' ORDER BY ':id(p.query.order_desc):raw' DESC'
    end

    local limit = math.min(p.query.limit or max_query_limit, max_query_limit)
    s:raw' LIMIT ':var(limit)

    local results = {}
    for upload in s:execute():each() do
        table.insert(results, upload:get_resource_properties())
    end

    p.response_headers:append(':status', '200')
    p.response_headers:append('cache-control', utils.cache_control_dynamic)
    utils.respond_with_json(p, results)
end)

--[[
@api {get} /upload/:id Retrieve a file
@apiName GetUpload
@apiGroup Upload

@apiParam {Number} id
--]]
local function handle_file_request(p)
    local id = assert_parameter(tonumber(p.id), 'Upload ID must be a number.')
    local upload = assert_found(Upload:by_id(id))
    p.response_headers:append('content-type', upload.media_type.mime_type)
    return handlers.send_file(p, upload:get_file_name())
end
server.router:get('/upload/:id', handle_file_request)
server.router:head('/upload/:id', handle_file_request)

--[[
@api {get} /upload/:id/thumbnail Retrieve a thumbnail
@apiName GetUploadThumbnail
@apiGroup Upload

@apiParam {Number} id
--]]
local function handle_thumbnail_request(p)
    local id = assert_parameter(tonumber(p.id), 'Upload ID must be a number.')
    local upload = assert_found(Upload:by_id(id))
    p.response_headers:append('content-type', upload.thumbnail_media_type.mime_type)
    return handlers.send_file(p, upload:get_thumbnail_file_name())
end
server.router:get('/upload/:id/thumbnail', handle_thumbnail_request)
server.router:head('/upload/:id/thumbnail', handle_thumbnail_request)
