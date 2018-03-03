return function(arguments)
    local database = require'live-share.database'
    local server = require'live-share.server'
    local config = require'config'

    require'live-share.resource.upload'
    require'live-share.resource.update'
    require'live-share.resource.static'

    server.run{port = config.port,
            host = config.host}

    database.close()
end
