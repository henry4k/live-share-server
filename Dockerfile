ARG LUA_VERSION=5.2

FROM alpine:3.8 AS base
ARG LUA_VERSION

RUN set -o xtrace; \
    apk add --no-cache \
        lua$LUA_VERSION \
        luarocks$LUA_VERSION \
        ffmpeg \
        argon2-libs \
        sqlite-libs \
        openssl \
        lua${LUA_VERSION}-cjson \
        lua${LUA_VERSION}-cqueues \
        lua${LUA_VERSION}-ossl \
        curl && \
    apk add --no-cache \
        --repository 'http://nl.alpinelinux.org/alpine/edge/testing' \
        vips

WORKDIR /live-share


FROM base AS build
ARG LUA_VERSION

RUN set -o xtrace; \
    apk add --no-cache \
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
        npm && \
    apk add --no-cache \
        --repository 'http://nl.alpinelinux.org/alpine/edge/main' \
        --repository 'http://nl.alpinelinux.org/alpine/edge/testing' \
        vips-dev && \
    git config --global 'url.https://.insteadOf' 'git://'
    # Sometimes restrictive firewalls block git://

COPY live-share ./live-share
COPY server .gitignore Makefile *.rockspec ./

RUN luarocks-$LUA_VERSION make


FROM base
LABEL maintainer="Henry Kielmann <henrykielmann@gmail.com>"
LABEL description="See https://github.com/henry4k/live-share-server"

COPY --from=build /usr/local \
                  /usr/local
COPY config.lua ./
RUN mkdir uploads thumbnails

EXPOSE 80
VOLUME /live-share

ENTRYPOINT [ "live-share-server" ]
CMD [ "run" ]
HEALTHCHECK --interval=5m --timeout=3s \
            CMD curl -f http://localhost/ || exit 1
