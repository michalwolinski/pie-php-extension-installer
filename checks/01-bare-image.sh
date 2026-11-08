#!/usr/bin/env bash
# The official PHP image as it is: does PIE install redis, and how does it fail?
source "$(dirname "$0")/lib.sh"
img=$(image bare 1.5.5)
out=$(docker run --rm "$img" sh -c 'pie install phpredis/phpredis:6.3.0 2>&1; echo "rc=$?"')
claim bare.rc "$(grep -o 'rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim bare.missing-tools "$(grep -o 'The following build tools are missing: .*' <<<"$out" | sed 's/.*missing: //; s/ /_/g')"
claim bare.suggests-apt "$(grep -c 'apt-get install -y --no-install-recommends --no-install-suggests libtool unzip' <<<"$out")"
claim bare.redis-loaded "$(docker run --rm "$img" php -r 'echo (int) extension_loaded("redis");')"
# PIE also asks for libtool. Is it needed, or is unzip enough?
out=$(docker run --rm "$img" sh -c 'apt-get update -qq && apt-get install -y -qq --no-install-recommends unzip > /dev/null 2>&1;
    pie install phpredis/phpredis:6.3.0 > /tmp/o 2>&1; echo "rc=$?"; grep -c "missing: libtoolize" /tmp/o | sed "s/^/warned=/";
    php --ri redis > /dev/null 2>&1; echo "ri=$?"')
claim unzip-only.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim unzip-only.libtool-warning "$(grep -o '^warned=[0-9]*' <<<"$out" | cut -d= -f2)"
claim unzip-only.redis-loads "$([ "$(grep -o '^ri=[0-9]*' <<<"$out" | cut -d= -f2)" = 0 ] && echo yes || echo no)"
