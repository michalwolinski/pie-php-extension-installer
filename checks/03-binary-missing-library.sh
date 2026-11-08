#!/usr/bin/env bash
# A prebuilt grpc binary on Alpine without the C++ runtime it links against: what does PIE report and return?
source "$(dirname "$0")/lib.sh"
for version in 1.5.5 1.6.0-rc.1; do
    img=$(image alpine "$version")
    for libs in none libstdcxx; do
        apk=''; [ "$libs" = libstdcxx ] && apk='apk add --no-cache -q libstdc++ libgcc &&'
        out=$(docker run --rm "$img" sh -c "$apk pie install --no-build-tools-check extport/grpc:1.85.1 > /tmp/pie.log 2>&1; echo pie_rc=\$?;
            grep -c 'NOT been automatically enabled' /tmp/pie.log | sed 's/^/not_enabled_warning=/';
            ls /usr/local/etc/php/conf.d/docker-php-ext-grpc.ini >/dev/null 2>&1 && echo ini_left=1 || echo ini_left=0;
            php -m 2>&1 | grep -c 'Unable to load dynamic library .grpc.' | sed 's/^/startup_warning=/';
            php --ri grpc >/dev/null 2>&1; echo ri_rc=\$?")
        for key in pie_rc not_enabled_warning ini_left startup_warning ri_rc; do
            claim "alpine.$version.$libs.$key" "$(grep -o "^$key=[0-9]*" <<<"$out" | cut -d= -f2)"
        done
    done
done
