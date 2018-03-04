local cjson = require'cjson'
local subprocess = require'xcq.subprocess'
local Promise = require'cqueues.promise'.new
local utils = require'live-share.utils'
local thumbnail_config = require'live-share.config'.thumbnail


assert(utils.program_is_available('ffmpeg'))

local thumbnail = {}

local function wait_for_process(process)
    local code, status = process:wait()
    if code ~= 0 then
        error('Process '..status)
    end
end

local function build_postprocessor_args(input, output)
    local c = thumbnail_config
    local args = {input_file = input,
                  output_file = output,
                  target_size = c.size,
                  format_options = c.vips_format_options}
    local arg_string = cjson.encode(args)
    return {'./postprocess-image', arg_string}
end

-- returns image metadata as table
local function analyze_and_generate_thumbnail(input, output)
    local args = build_postprocessor_args(input, output)
    args.stdout = subprocess.PIPE
    local process = assert(subprocess.spawn(args))

    local metadata_string = process.stdout:read('*a')
    local metadata = assert(cjson.decode(metadata_string))

    wait_for_process(process)
    return metadata
end

local function build_ffmpeg_args(input, output)
    local c = thumbnail_config
    local inspected_frames = c.ffmpeg_inspected_frames or 100
    local extra_args = c.ffmpeg_extra_args or {}

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

function thumbnail.generate(media_type, file, thumbnail_file)
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

return thumbnail
