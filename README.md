live-share-server
=================

[HTTP API Documentation](https://henry4k.github.io/live-share-server)

Words go here.


## Dependencies

Runtime dependencies:

- Lua 5.2
- LuaJIT (required by lua-vips)
- [libvips](https://jcupitt.github.io/libvips)
- [FFmpeg](https://ffmpeg.org)
- [Argon2](https://github.com/P-H-C/phc-winner-argon2)
- Implicit dependencies:
  - OpenSSL (required by [luaossl](https://github.com/wahern/luaossl))
  - [SQLite](https://sqlite.org)


Development dependencies:

- luarocks-5.2
- luarocks-5.1 (for LuaJIT)
- For building the static content:
  - nodejs
  - npm
  - (and everthing mentioned in `web/package.json`)


## Setup

1. Install the dependencies mentioned above.
2. Install further backend dependencies by running `./install-deps`.
3. Build the static web content by running `npm install` and `npm run build` in `web`.


## License and copyright

Copyright © Henry Kielmann

`live-share-server` is licensed under the MIT license, which can be found in the
`LICENSE` file.
