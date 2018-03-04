local function command_target_name(level)
    return string.format('_command_%d', level)
end

local function setup_command(parser, def, level)
    parser:command_target(command_target_name(level))

    if def.setup_parser then
        def.setup_parser(parser)
    end

    parser:require_command(not def.run)

    for subcmd_name, subcmd_def in pairs(def.subcommands or {}) do
        local subcmd_parser = parser:command(subcmd_name)
        setup_command(subcmd_parser, subcmd_def, level+1)
    end
end

local function run_command(arguments, def, level)
    if def.setup then
        def.setup(arguments)
    end

    local subcmd_name = arguments[command_target_name(level)]
    if subcmd_name then
        local subcmd_def = assert(def.subcommands[subcmd_name])
        return run_command(arguments, subcmd_def, level+1)
    else
        return def.run(arguments)
    end
end

local main_cmd_def =
{
    setup_parser = function(parser)
        parser:description'Serves screenshots and screencasts.'
              :epilog'For more info, see https://github.com/henry4k/live-share-server'

        parser:option'-c --config'
              :description'Configuration file'
              :args(1)
              :argname'<file>'
              :default'config.lua'
    end,

    setup = function(arguments)
        local config = require'live-share.config'
        config.load(arguments.config)
    end,

    run = function(arguments)
    end,

    subcommands =
    {
        run = require'live-share.cli.run',
        user = require'live-share.cli.user'
    }
}

-- - create nice stack traces on error
-- - setup config
local function call_main(fn, ...)
    local fat_error = require'fat_error'
    local log = require'live-share.log'

    local ok, result_or_err = fat_error.pcall(fn, ...)
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

local parser = require'argparse'()
setup_command(parser, main_cmd_def, 1)
local arguments = parser:parse()
call_in_cqueue(function()
    call_main(run_command, arguments, main_cmd_def, 1)
end)
