live-share-server
=================

[HTTP API Documentation](https://henry4k.github.io/live-share-server)

Words go here.


## Dependencies

Runtime dependencies:

- Lua 5.2
- [libvips](https://jcupitt.github.io/libvips)
- [FFmpeg](https://ffmpeg.org)
- [Argon2](https://github.com/P-H-C/phc-winner-argon2)
- Implicit dependencies:
  - OpenSSL (required by [luaossl](https://github.com/wahern/luaossl))
  - [SQLite](https://sqlite.org)


Development dependencies:

- luarocks-5.2
- make
- pkg-config
- For building the static content:
  - nodejs
  - npm


## Setup

1. Run `luarocks make` in the projects root directory.
2. Adapt `config.lua` to your needs.
3. Use `./server run` to start the server.


## License and copyright

Copyright © Henry Kielmann

`live-share-server` is licensed under the MIT license, which can be found in the
`LICENSE` file.
