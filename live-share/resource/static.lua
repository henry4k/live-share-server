local server = require'live-share.server'
local handlers = require'live-share.handlers'
local path = require'path'
local here = require'live-share.utils'.here
local config = require'live-share.config'

local static = config.static_content or here('static')
assert(path.isdir(static), 'Can\'t locate static content directory.')

server.router:get('/', handlers.Redirect{to='/index.html'})
server.router:get('/index.html', handlers.StaticFile(static..'/index.html'))
server.router:get('/style.css', handlers.StaticFile(static..'/style.css'))
server.router:get('/script.js', handlers.StaticFile(static..'/script.js'))
