-- - create nice stack traces on error
-- - setup config
local function call_main(fn, arguments)
    local fat_error = require'fat_error'
    local log = require'live-share.log'
    local config = require'live-share.config'

    config.load(arguments.config)

    local ok, result_or_err = fat_error.pcall(fn, arguments)
    if not ok then
        log.fat_error(result_or_err)
        os.exit(1)
    end
end

-- - provide a running cqueue
-- - monkeypatch coroutine module with cqueues wrapper-functions
-- - setup shutdown listener
local function call_in_cqueue(fn)
    local cqueues = require'cqueues'
    local auxlib = require'cqueues.auxlib'
    local utils = require'live-share.utils'

    -- luacheck: ignore global coroutine
    coroutine.resume = auxlib.resume
    coroutine.wrap = auxlib.wrap

    local cqueue = cqueues.new()
    utils.install_shutdown_listener(cqueue)
    cqueue:wrap(fn)
    assert(cqueue:loop())
end

local function run(commands)
    local parser = require'argparse'()
        :description'Serves screenshots and screencasts.'
        :epilog'For more info, see https://github.com/henry4k/live-share-server'
        :require_command(true)
        :command_target'command'

    parser:option'-c --config'
        :description'Configuration file'
        :args(1)
        :argname'<file>'
        :default'config.lua'

    for command_name, command in pairs(commands) do
        local subparser = parser:command(command_name, command.description)
        if command.setup_parser then
            command.setup_parser(subparser)
        end
    end

    local arguments = parser:parse()
    local execute = commands[arguments.command].execute
    if type(execute) == 'string' then
        execute = require(execute)
    end

    call_in_cqueue(function()
        call_main(execute, arguments)
    end)
end

run{
    run =
    {
        description = 'Runs the web server.',
        --setup_parser = function(parser)
        --end,
        execute = function(arguments)
            return require'live-share.cli.run'(arguments)
        end
    }
}
