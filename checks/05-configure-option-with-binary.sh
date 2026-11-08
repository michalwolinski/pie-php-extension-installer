#!/usr/bin/env bash
# A package that ships prebuilt binaries, installed with a configure option: binary or compiled from source?
source "$(dirname "$0")/lib.sh"
img=$(image tools 1.5.5)
plain=$(docker run --rm "$img" sh -c 'pie install pie-extensions/redis:6.3.0 2>&1')
option=$(docker run --rm "$img" sh -c 'pie install pie-extensions/redis:6.3.0 --disable-redis-session 2>&1')
claim configure.plain.binary "$(grep -c 'Pre-packaged binary found' <<<"$plain")"
claim configure.option.binary "$(grep -c 'Pre-packaged binary found' <<<"$option")"
claim configure.option.built "$(grep -c 'Build complete' <<<"$option")"
