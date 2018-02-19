local server = require'live-share.server'
local handlers = require'live-share.handlers'
local config = require'config'

local static = config.static_content
server.router:get('/', handlers.Redirect{to='/index.html'})
server.router:get('/index.html', handlers.StaticFile(static..'/index.html'))
server.router:get('/style.css', handlers.StaticFile(static..'/style.css'))
server.router:get('/script.js', handlers.StaticFile(static..'/script.js'))
