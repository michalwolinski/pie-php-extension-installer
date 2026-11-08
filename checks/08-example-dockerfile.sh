#!/usr/bin/env bash
# The Dockerfile the article recommends: does it build, and do the extensions load in the image it produces?
source "$(dirname "$0")/lib.sh"
docker build -q -t pie-article:example examples >/dev/null && claim example.builds 1 || claim example.builds 0
claim example.loaded "$(docker run --rm pie-article:example php -r 'echo (int) extension_loaded("redis"), (int) extension_loaded("pcov");')"
claim example.startup-warnings "$(docker run --rm pie-article:example php -m 2>&1 | grep -c 'Warning')"
claim example.unzip-removed "$(docker run --rm pie-article:example sh -c 'command -v unzip > /dev/null && echo no || echo yes')"
# Mutation: the same Dockerfile with redis.so deleted before the check. The check has to fail the build.
broken=$(mktemp -d)
sed 's|    php --ri redis > /dev/null; \\|    rm /usr/local/lib/php/extensions/*/redis.so; php --ri redis > /dev/null; \\|' examples/Dockerfile > "$broken/Dockerfile"
grep -q 'rm /usr/local/lib/php/extensions' "$broken/Dockerfile" || echo "mutation not applied" >&2
docker build -q "$broken" >/dev/null 2>&1 && claim example.mutation-build-fails 0 || claim example.mutation-build-fails 1
rm -rf "$broken"
# Without --no-cache, PIE leaves Composer's cache of the downloaded sources in /root/.composer.
claim example.composer-cache-left "$(docker run --rm pie-article:example sh -c '[ -d /root/.composer/cache/files ] && echo yes || echo no')"
# php --ri proves that an extension loads, not that it was built for this image. The redis.so built on Debian
# (glibc) loads on Alpine (musl), whose loader accepts libc.so.6 as itself.
so=$(mktemp -d)
docker run --rm -v "$so:/out" pie-article:example sh -c 'cp "$(php -r "echo ini_get(\"extension_dir\");")/redis.so" /out/'
claim example.debian-so-on-alpine.ri-rc "$(docker run --rm -v "$so:/so:ro" --entrypoint sh \
    'php:8.5.12-cli-alpine@sha256:d1fbbe78850d1eb9aa8f7da652ec5db61eb4c9377c8215cf5e23f3b528ed4f2b' -c \
    'cp /so/redis.so "$(php -r "echo ini_get(\"extension_dir\");")/" && echo extension=redis > "$PHP_INI_DIR/conf.d/redis.ini";
     php --ri redis > /dev/null 2>&1; echo $?')"
# Within one PHP minor version, the same .so loads across patch releases: built on 8.5.12, loaded on 8.5.11.
claim example.so-on-8.5.11.ri-rc "$(docker run --rm -v "$so:/so:ro" --entrypoint sh \
    'php:8.5.11-cli-bookworm@sha256:878bbda19358b8be328c9c037b8812ce256f75be0af6869c8414aa65231a20d4' -c \
    'cp /so/redis.so "$(php -r "echo ini_get(\"extension_dir\");")/" && echo extension=redis > "$PHP_INI_DIR/conf.d/redis.ini";
     php --ri redis > /dev/null 2>&1; echo $?')"
rm -rf "$so"
