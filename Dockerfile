FROM alpine:3.8
LABEL maintainer="Henry Kielmann <henrykielmann@gmail.com>"
LABEL description="See https://github.com/henry4k/live-share-server"

ARG LUA_VERSION=5.2

RUN set -o xtrace; \
    apk add --no-cache \
        lua$LUA_VERSION \
        ffmpeg \
        argon2-libs \
        sqlite-libs \
        openssl \
        lua${LUA_VERSION}-cqueues \
        lua${LUA_VERSION}-ossl \
        curl && \
    apk add --no-cache \
        --repository 'http://nl.alpinelinux.org/alpine/edge/main' \
        --repository 'http://nl.alpinelinux.org/alpine/edge/testing' \
        vips \
        vips-dev && \
    apk add --no-cache --virtual build-dependencies \
        luarocks$LUA_VERSION \
        coreutils \
        gcc \
        make \
        pkgconf \
        musl-dev \
        lua${LUA_VERSION}-dev \
        argon2-dev \
        sqlite-dev \
        git \
        nodejs \
        npm

# Sometimes restrictive firewalls block git://
RUN git config --global 'url.https://.insteadOf' 'git://'

WORKDIR /live-share

COPY live-share ./live-share
COPY server config.lua .gitignore Makefile *.rockspec ./

RUN luarocks-$LUA_VERSION make
RUN apk del build-dependencies vips-dev

EXPOSE 80
#VOLUME /live-share/data

#ENTRYPOINT /live-share/server
#CMD run
#HEALTHCHECK --interval=5m --timeout=3s \
#            CMD curl -f http://localhost/ || exit 1
