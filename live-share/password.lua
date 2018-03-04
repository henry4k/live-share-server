local argon2 = require'argon2'
local rand = require'openssl.rand'
local settings = require'live-share.settings'
local pw_config = require'live-share.config'.password

assert(rand.ready(), 'OpenSSL random source not ready.')

local salt_length = pw_config.salt_length
local argon2_options = pw_config.argon2_options
if argon2_options.variant then
    argon2_options.variant = assert(argon2.variants[argon2_options.variant],
                                    'Unknown Argon2 variant.')
end

if not settings.salt then
    settings.salt = rand.bytes(salt_length)
end

local password = {}

function password.hash(pw)
    return
        assert(argon2.hash_encoded(pw, settings.salt, argon2_options))
end

-- Returns success state and optional error message.
function password.verify(pw, hash)
    return argon2.verify(hash, pw)
end

return password
