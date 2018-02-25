FROM alpine:edge
# vips is currently only available in testing
RUN echo 'http://nl.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
# See https://pkgs.alpinelinux.org/packages
# Runtime dependencies:
RUN apk --no-cache add \
    lua5.2 \
    luajit \
    openssl \
    sqlite-libs \
    argon2-libs \
    vips \
    ffmpeg
# Build dependencies:
RUN apk --no-cache add --virtual build-dependencies \
    make \
    luarocks5.2 \
    luarocks5.1 \
    openssl-dev \
    sqlite-dev \
    argon2-dev \
    vips-dev \
    nodejs-npm
VOLUME /live-share-server
WORKDIR /live-share-server
#RUN ./configure && make build
#RUN apk del build-dependencies
EXPOSE 80
