package = 'live-share-server'
version = 'dev-1'
source = {
    url = '*** please add URL for source tarball, zip or repository here ***'
}
description = {
    summary = 'Words go here.',
    detailed = 'More words go here.',
    homepage = 'https://github.com/henry4k/live-share-server',
    license = 'MIT'
}
dependencies = {
    'lua >= 5.1',
    'cqueues',
    'luaossl',
    'http',
    'argon2',
    'lua-cjson',
    'luadbi',
    'luadbi-sqlite3',
    'argparse',
    'mimetypes',
    --'luaposix',
    --'lpeg',
    --'lpeg_patterns',
    --'fifo',
    --'compat53',
    'ansicolors',
    'basexx',
    'lua-path',
    'middleclass',
    'fat_error',
    'xcq-subprocess'
}
supported_platforms = {
    '!windows'
}
external_dependencies = {
    VIPS = {
        header = 'vips/vips.h',
        library = 'vips'
    }
}
build = {
    type = 'make',
    build_variables = {
        CC = '$(CC)',
        CFLAGS = '$(CFLAGS)',
        LIBFLAG = '$(LIBFLAG)',
        LUALIB = '$(LUALIB)',
        LUA_INCDIR = '$(LUA_INCDIR)',
        LUA_LIBDIR = '$(LUA_LIBDIR)',
        VIPS_INCDIR = '$(VIPS_INCDIR)',
        VIPS_LIBDIR = '$(VIPS_LIBDIR)',
    },
    install_variables = {
        INSTALL_BINDIR="$(BINDIR)",
        INSTALL_LIBDIR="$(LIBDIR)",
        INSTALL_LUADIR="$(LUADIR)"
    },
    --variables
    --predefined make variables: CC, CFLAGS, LIBFLAGS
    --install = {
    --    lua = {
    --        ['live-share.EventStream'] = 'src/lua/live-share/EventStream.lua',
    --        ['live-share.Index'] = 'src/web/dist/index.html',
    --        ['live-share.Script'] = 'src/web/dist/script.js'
    --    },
    --    bin = {
    --        ['live-share-server'] = 'src/lua/live-share/cli.lua'
    --    }
    --},
    copy_directories = {
        'doc'
    }
}
