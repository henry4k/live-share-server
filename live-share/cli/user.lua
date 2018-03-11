return
{
    setup_parser = function(parser)
        parser:description'See and manage users.'
    end,

    setup = function(arguments)
        print'setup: user'
    end,

    run = function(arguments)
        print'run: user'
    end,

    subcommands =
    {
        add =
        {
            setup_parser = function(parser)
                parser:description'Create new users.'

                parser:argument'name'
                    :description'Unique user name.'
                    :args(1)
                parser:flag'--admin'
                    :description'Grants admin privileges.'
                parser:option'-p --password'
                    :argname'<password>'
                    :args(1)
            end,

            run = function(args)
                local function read_process(cmd, what)
                    what = what or '*a'
                    local process = assert(io.popen(cmd, 'r'))
                    local content = process:read(what)
                    process:close()
                    return content
                end

                local function read_password()
                    local tty_state = read_process('stty --save', '*l')
                    os.execute('stty -echo')
                    local password = io.stdin:read('*l')
                    os.execute('stty '..tty_state)
                    return password
                end

                if not args.password then
                    args.password = read_password()
                end

                local database = require'live-share.database'
                local User = require'live-share.model.User'

                local user = User()
                user.name = args.name
                user.is_admin = args.admin
                user:set_password_hash(args.password)
                user:create_entity()
                database.commit()

                require'live-share.utils'.shutdown()
            end
        }
    }
}
