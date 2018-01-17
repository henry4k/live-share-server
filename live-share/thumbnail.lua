local path = require'path'
local utils = require'live-share.utils'
local Process = require'live-share.Process'
local config = require'config'


assert(utils.program_is_available('vipsthumbnail'))
assert(utils.program_is_available('ffmpeg'))

local thumbnail = {}

local function build_vips_args(input, output)
    local c = config.thumbnail
    local size = c.size
    local extra_args = c.vipsthumbnail_extra_args or {}
    local format_options = c.vips_format_options or ''
    if #format_options > 0 then
        format_options = '['..format_options..']'
    end
    output = path.fullpath(output) -- vipsthumbnail misbehaves otherwise

    local args = {'vipsthumbnail',
                  '--size='..size}
    for _, arg in ipairs(extra_args) do
        table.insert(args, arg)
    end
    table.insert(args, '--output='..output..format_options)
    table.insert(args, input)
    return args
end

local function build_ffmpeg_args(input, output)
    local c = config.thumbnail
    local size = c.size
    local inspected_frames = c.ffmpeg_inspected_frames or 100
    local extra_args = c.ffmpeg_extra_args or {}

    local f = string.format
    local filter = {f('thumbnail=%d',
                      inspected_frames),
                    f('scale=w=%d:h=%d:force_original_aspect_ratio=increase',
                      size, size)}
                    --f('crop=w=%d:h=%d',
                    --  size, size)}

    local args = {'ffmpeg',
                  '-hide_banner',
                  '-loglevel', 'warning',
                  '-y', -- overwriting is allowed
                  '-i', input,
                  '-filter:v', table.concat(filter, ','),
                  '-frames:v', '1'}
    for _, arg in ipairs(extra_args) do
        table.insert(args, arg)
    end
    table.insert(args, output)
    return args
end

function thumbnail.generate(upload)
    local input_file_name = upload:get_file_name()
    local output_file_name = upload:get_thumbnail_file_name()

    if upload.media_type.type == 'image' then
        return Process(build_vips_args(input_file_name,
                                       output_file_name))
    else -- video
        return Process(build_ffmpeg_args(input_file_name,
                                         output_file_name))
    end
end

return thumbnail
