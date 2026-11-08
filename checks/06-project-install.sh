#!/usr/bin/env bash
# pie install inside a project directory without a terminal: which packages does PIE pick for the extensions that
# composer.json requires? PIE reads them from composer.lock, which project/ ships.
source "$(dirname "$0")/lib.sh"
run() { # run <version> <extra args...>
    local img; img=$(image tools "$1"); shift
    docker run --rm -v "$PWD/project:/app:ro" -w /app "$img" sh -c "pie install $* 2>&1; echo rc=\$?;
        php -r 'echo \"loaded=\", (int) extension_loaded(\"redis\"), (int) extension_loaded(\"pcov\"), PHP_EOL;'"
}
out=$(run 1.5.5)
claim project.1.5.5.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.1.5.5.loaded "$(grep -o '^loaded=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.1.5.5.pcov-candidates "$(grep -o -- '--select=pcov=[^ ]*' <<<"$out" | sed 's/--select=pcov=//' | sort | paste -sd, -)"
out=$(run 1.5.5 --select=pcov=pecl/pcov --select=redis=phpredis/phpredis)
claim project.1.5.5.select.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.1.5.5.select.loaded "$(grep -o '^loaded=[0-9]*' <<<"$out" | cut -d= -f2)"
out=$(run 1.6.0-rc.1)
claim project.1.6.0-rc.1.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.1.6.0-rc.1.loaded "$(grep -o '^loaded=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.1.6.0-rc.1.picked "$(grep -o 'Found package: [^ ]*' <<<"$out" | sed 's/Found package: //; s/:.*//' | sort | paste -sd, -)"
# PIE reads the required extensions from composer.lock. Without one:
nolock=$(mktemp -d); cp project/composer.json "$nolock/"
out=$(docker run --rm -v "$nolock:/app:ro" -w /app "$(image tools 1.6.0-rc.1)" sh -c 'pie install 2>&1; echo rc=$?')
claim project.no-composer-lock.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim project.no-composer-lock.message "$(grep -q 'No lockfile found' <<<"$out" && echo yes || echo no)"
rm -rf "$nolock"
