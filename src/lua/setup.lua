-- This does the following:
-- - set package search path
-- - provide a running cqueue
-- - create nice stack traces on error
-- - monkeypatch coroutine module with cqueues wrapper-functions

package.path = 'lua/?.lua;'..package.path

local cqueues = require'cqueues'
local auxlib = require'cqueues.auxlib'
local fat_error = require'fat_error'
local log = require'live-share.log'

coroutine.resume = auxlib.resume
coroutine.wrap = auxlib.wrap

local function wrap_main(main)
    local ok, result_or_err = fat_error.pcall(function()
        local cqueue = cqueues.new()
        cqueue:wrap(main)
        assert(cqueue:loop())
    end)
    if not ok then
        log.fat_error(result_or_err)
        os.exit(1)
    end
end

return wrap_main
