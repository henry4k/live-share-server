local server = require'live-share.server'
local handlers = require'live-share.handlers'
local path = require'path'
local here = require'live-share.utils'.here
local config = require'live-share.config'

local static = config.static_content or here('static')
assert(path.isdir(static), 'Can\'t locate static content directory.')

server.router:get('/', handlers.Redirect{to='/index.html'})
for _, file in ipairs{'/index.html',
                      '/style.css',
                      '/style.css.map',
                      '/script.js',
                      '/script.js.map',
                      '/vendor.js',
                      '/vendor.js.map'} do
    server.router:get(file, handlers.StaticFile(static..file))
end
