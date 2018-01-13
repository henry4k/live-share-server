local basexx = require'basexx'
local class = require'middleclass'
local MappedEntity = require'live-share.MappedEntity'


local User = class'live-share.model.User'
User:include(MappedEntity)

User:set_table_name'user'
User:map_primary_key'id'
User:map_column'name'
User:map_column'is_admin'

function User.static:get_by_name(name)
    return self:select_one{where = {name = name}}
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
    assert(user_info, 'Malformatted authorization header.')

    local name, password = user_info:match('^(.-):(.*)$')
    assert(name and password, 'Malformatted authorization header.')
    --print('name: "'..name..'"')
    --print('password: "'..password..'"')

    local user = self:get_by_name(name)
    if not user then
        return nil, 'Unknown user.'
    end

    -- TODO: password

    return user
end

function User:initialize()
    self:initialize_mapping()
end

return User
