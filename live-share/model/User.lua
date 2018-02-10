local basexx = require'basexx'
local class = require'middleclass'
local MappedEntity = require'live-share.MappedEntity'
local password = require'live-share.password'


local User = class'live-share.model.User'
User:include(MappedEntity)

User:set_table_name'user'
User:map_primary_key'id'
User:map_column'name'
User:map_column'password_hash'
User:map_column'is_admin'

function User.static:get_by_name(name)
    return self:select():raw'WHERE name = ':var(name):execute():first()
end

function User.static:get_from_request(request_headers)
    local auth_header = request_headers:get'authorization'
    if not auth_header then
        return nil, 'No authorization header is provided.'
    end

    local encoded_user_info = auth_header:match('^Basic (.+)$')
    if not encoded_user_info then
        return nil, 'Only basic authorization is supported.'
    end

    local user_info = basexx.from_base64(encoded_user_info)
    if not user_info then
        return nil, 'Malformatted authorization header.'
    end

    local name, pw = user_info:match('^(.-):(.*)$')
    if not name then
        return nil, 'Malformatted authorization header.'
    end

    local user = self:get_by_name(name)
    if not user then
        return nil, 'Unknown user.'
    end

    local ok, err = password.verify(pw, user.password_hash)
    if not ok then
        return nil, err
    end

    return user
end

function User:initialize()
    self:initialize_mapping()
end

function User:set_password_hash(pw)
    self:set_property_value('password_hash', password.hash(pw))
end

return User
