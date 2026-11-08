#!/usr/bin/env bash
# What PIE checks about a prebuilt binary, and what pie.lock records for it.
source "$(dirname "$0")/lib.sh"
img=$(image tools 1.5.5)
out=$(docker run --rm "$img" sh -c 'pie install "pie-extensions/redis:^6.2" 2>&1; echo ===;
    php -r "\$l = json_decode(file_get_contents(glob(\"/root/.pie/php8.5_*/pie.lock\")[0]), true);
        \$p = \$l[\"packages\"][0]; echo \$p[\"version\"], \" \", \$p[\"dist\"][\"url\"], \" shasum=[\", \$p[\"dist\"][\"shasum\"], \"]\";"')
claim integrity.note "$(grep -c 'dist-sha integrity check is not available for prebuilt-binary URLs' <<<"$out")"
claim integrity.used-binary "$(grep -c 'Pre-packaged binary found' <<<"$out")"
lock=$(sed -n '/===/,$p' <<<"$out" | tail -1)
claim lock.version "$(cut -d' ' -f1 <<<"$lock")"
claim lock.dist-is-source-zipball "$(grep -c 'zipball' <<<"$lock")"
claim lock.shasum "$(grep -o 'shasum=\[.*\]' <<<"$lock")"
