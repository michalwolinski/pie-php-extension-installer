#!/usr/bin/env bash
# PIE in the Alpine image, which ships no compiler, and install-php-extensions (mlocati) for comparison:
# how many make jobs it runs, inside --cpus=2 too, and whether it checks that the module loads.
source "$(dirname "$0")/lib.sh"
alpine=$(image alpine 1.5.5)
out=$(docker run --rm "$alpine" sh -c 'pie install phpredis/phpredis:6.3.0 2>&1; echo "rc=$?"')
claim alpine.no-compiler.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim alpine.no-compiler.names-gcc "$(grep -q 'missing: cc/gcc, make' <<<"$out" && echo yes || echo no)"
claim alpine.no-compiler.suggests-apk "$(grep -q 'apk add --no-cache --virtual .php-pie-deps build-base' <<<"$out" && echo yes || echo no)"
ipe=$(image ipe 1.5.5)
ipe_jobs() { docker run --rm "$@" "$ipe" sh -c 'install-php-extensions redis-6.3.0 2>&1' | grep -o 'running: make -j[0-9]*' | head -1 | grep -o '[0-9]*$'; }
cpus=$(docker run --rm "$ipe" nproc)
claim ipe.jobs-equal-cpus "$([ "$(ipe_jobs)" = "$cpus" ] && echo yes || echo no)"
claim ipe.jobs.cpus-2-equals-all "$([ "$(ipe_jobs --cpus=2)" = "$cpus" ] && echo yes || echo no)"
claim ipe.jobs.processor-count-2 "$(ipe_jobs -e IPE_PROCESSOR_COUNT=2)"
out=$(docker run --rm "$ipe" sh -c 'install-php-extensions redis-6.3.0 2>&1')
claim ipe.checks-loading "$(grep -q 'Check if the redis module can be loaded' <<<"$out" && echo yes || echo no)"
