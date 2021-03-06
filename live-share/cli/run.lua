return
{
    setup_parser = function(parser)
        parser:description'Run the web server.'
    end,

    run = function(arguments)
        local database = require'live-share.database'
        local server = require'live-share.server'
        local config = require'live-share.config'

        require'live-share.resource.upload'
        require'live-share.resource.update'
        require'live-share.resource.static'

        server.run{port = config.port,
                   host = config.host}
    end
}
