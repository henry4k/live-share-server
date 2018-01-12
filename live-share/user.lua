local basexx = require'basexx'
local db = require'live-share.database'
local server = require'live-share.server'


local user = {}

function user.create(name)
    db('INSERT INTO user (name) VALUES (?)', name)
    return db.last_id()
end

function user.get_by_name(name)
    local row = db('SELECT id FROM user WHERE name = ?', name):fetch()
    if row then return row[1] end
end

function user.get_name(id)
    local row = db('SELECT name FROM user WHERE id = ?', id):fetch()
    if row then return row[1] end
end

function user.get_user_from_request(request_headers)
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
    print('name: "'..name..'"')
    print('password: "'..password..'"')

    local user_id = user.get_by_name(name)
    if not user_id then
        return nil, 'Unknown user.'
    end

    -- TODO: password

    return user_id
end

return user
