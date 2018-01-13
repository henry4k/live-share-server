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
    media.mime_type = mime_type
end

return {by_id = media_types,
        by_mime_type = media_types_by_mime_type}
