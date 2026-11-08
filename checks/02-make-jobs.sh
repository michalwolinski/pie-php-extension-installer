#!/usr/bin/env bash
# How many make jobs do pecl and PIE run? pecl's log names the make command; PIE prints it with -v.
source "$(dirname "$0")/lib.sh"
img=$(image tools 1.5.5)
pecl=$(docker run --rm "$img" sh -c "printf '\n\n\n\n\n\n\n' | pecl install redis-6.3.0 2>&1")
claim pecl.make-command "$(grep -m1 -o 'running: make$' <<<"$pecl" | sed 's/running: //')"
make_jobs() { docker run --rm "$@" "$img" sh -c 'pie install -v phpredis/phpredis:6.3.0 2>&1' |
    grep -o 'Running make step with: .*' | grep -o '\-j[0-9]*' | tr -d -- '-j'; }
cpus=$(docker run --rm "$img" nproc)
claim pie.jobs-equal-cpus "$([ "$(make_jobs)" = "$cpus" ] && echo yes || echo "no: $(make_jobs) jobs, $cpus cpus")"
claim pie.jobs.cpus-2 "$(make_jobs --cpus=2)"
claim pie.jobs.cpuset-2 "$(make_jobs --cpuset-cpus=0-1)"
claim nproc.cpus-2-equals-all "$([ "$(docker run --rm --cpus=2 "$img" nproc)" = "$cpus" ] && echo yes || echo no)"
claim pie.jobs.explicit-j2 "$(docker run --rm "$img" sh -c 'pie install -v -j2 phpredis/phpredis:6.3.0 2>&1' |
    grep -o 'Running make step with: .*' | grep -o '\-j[0-9]*' | tr -d -- '-j')"
