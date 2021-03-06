local path = require 'path'
local types = require'tableshape'.types
local media_types = require'live-share.media.types'

local function directory_type()
    return types.custom(function(value, self)
        if type(value) ~= 'string' then
            return nil, 'expected string'
        end

        if not path.isdir(value) then
            return nil, 'not a directory'
        end

        return true
    end)
end

local function image_type()
    return types.custom(function(value)
        if type(value) ~= 'string' then
            return nil, 'expected string'
        end

        if not media_types.by_mime_type['image/'..value] then
            return nil, 'invalid/unknown image type'
        end

        return true
    end)
end

local function defaults_to(value)
    return types.any/value
end

local store
local config_mt = {}
local config = setmetatable({}, config_mt)

function config_mt.__index()
    error('Nothing to see here! Config has not been loaded yet.')
end

function config.load(file_name)
    assert(not store, 'Reloading is not supported.')

    local env = {}
    setmetatable(env, {__index = _ENV})
    assert(loadfile(file_name, nil, env))()

    local config_shape = types.shape{
        host = types.string + defaults_to'0.0.0.0',
        port = types.integer,
        static_content = directory_type():is_optional(),
        upload_directory = directory_type(),
        database = types.string,
        thumbnail = types.shape{
            directory = directory_type(),
            size = types.integer + defaults_to(160),
            image_type = image_type() + defaults_to'jpeg',
            vips = types.shape{
                load_options = types.any,
                save_options = types.any
            } + defaults_to{},
            ffmpeg_inspected_frames = types.integer + defaults_to(100),
            ffmpeg_extra_args = types.array_of(types.string) + defaults_to{}
        } + defaults_to{},
        password = types.shape{
            salt_length = types.integer + defaults_to(16),
            argon2_options = types.shape{
                t_cost = types.integer:is_optional(),
                m_cost = types.integer:is_optional(),
                parallelism = types.integer:is_optional(),
                hash_len = types.integer:is_optional(),
                variant = types.one_of{'argon2_i',
                                       'argon2_d',
                                       'argon2_id'}:is_optional()
            } + defaults_to{}
        } -- NOTE: tableshape can't apply defaults recursivly
    }

    env.password = env.password or {} -- see above

    env = assert(config_shape:transform(env)) -- check and insert default values

    store = env
    config_mt.__index = store
end

return config
