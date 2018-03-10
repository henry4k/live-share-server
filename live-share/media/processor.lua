local subprocess = require'xcq.subprocess'
local Promise = require'cqueues.promise'.new
local utils = require'live-share.utils'
local image_processor = require'live-share.media.image_processor'
local thumbnail_config = require'live-share.config'.thumbnail


assert(image_processor.init(arg[0]))
assert(utils.program_is_available('ffmpeg'))

local function wait_for_process(process)
    local code, status = process:wait()
    if code ~= 0 then
        error('Process '..status)
    end
end

local function vips_options_from_table(options)
    if not options or not next(options) then
        return ''
    end
    local buffer = {}
    for name, value in pairs(options) do
        if type(value) == 'boolean' then
            if value then
                table.insert(buffer, name)
            end
        else
            table.insert(name..'='..tostring(value))
        end
    end
    return '['..table.concat(buffer,',')..']'
end
local load_options = vips_options_from_table(thumbnail_config.vips.load_options)
local save_options = vips_options_from_table(thumbnail_config.vips.save_options)

-- returns image metadata as table
local function analyze_and_generate_thumbnail(input, output)
    local size = thumbnail_config.size
    input = input..load_options
    output = output..save_options
    local metadata = assert(image_processor.process(input, output, size))
    -- TODO: Move into a thread or so.
    return metadata
end

local function build_ffmpeg_args(input, output)
    local c = thumbnail_config
    local inspected_frames = c.ffmpeg_inspected_frames
    local extra_args = c.ffmpeg_extra_args

    local f = string.format
    local filter = {f('thumbnail=%d',
                      inspected_frames)}

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

local function extract_image_from_video(input, output)
    local args = build_ffmpeg_args(input, output)
    local process = assert(subprocess.spawn(args))
    wait_for_process(process)
end

local media_processor = {}

function media_processor.process(media_type, file, thumbnail_file)
    if media_type.type == 'image' then
        return Promise(function()
            return analyze_and_generate_thumbnail(file,
                                                  thumbnail_file)
        end)
    else -- video
        return Promise(function()
            local temp_file =
                utils.get_temporary_file_name{postfix='.png'}

            extract_image_from_video(file, temp_file)
            local metadata = analyze_and_generate_thumbnail(temp_file,
                                                            thumbnail_file)

            assert(os.remove(temp_file))
            return metadata
        end)
    end
end

return media_processor
