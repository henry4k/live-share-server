-- - create nice stack traces on error
local function call_main(fn, ...)
    local fat_error = require'fat_error'
    local log = require'live-share.log'

    local ok, result_or_err = fat_error.pcall(fn, ...)
    if not ok then
        log.fat_error(result_or_err)
        os.exit(1)
    end
end

local function run(commands)
    local parser = require'argparse'()
    parser{name = 'live-share-server',
           description = 'Serves screenshots and screencasts.',
           epilog = 'For more info, see https://github.com/henry4k/live-share-server'}
    parser:option('-c --config', 'Configuration file') -- TODO
    parser:command_target'command'

    for command_name, command in pairs(commands) do
        local subparser = parser:command(command_name, command.description)
        if command.setup_parser then
            command.setup_parser(subparser)
        end
    end

    local arguments = parser:parse()
    call_main(commands[arguments.command].execute, arguments)
end

-- - provide a running cqueue
-- - monkeypatch coroutine module with cqueues wrapper-functions
local function call_with_cqueue(fn, ...)
    local cqueues = require'cqueues'
    local auxlib = require'cqueues.auxlib'

    coroutine.resume = auxlib.resume
    coroutine.wrap = auxlib.wrap

    local cqueue = cqueues.new()
    cqueue:wrap(fn, ...)
    assert(cqueue:loop())
end

run{
    run =
    {
        description = 'Runs the web server.',
        --setup_parser = function(parser)
        --end,
        execute = function(arguments)
            call_with_cqueue(require'live-share.cli.run', arguments)
        end
    }
}
