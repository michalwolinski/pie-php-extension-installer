#!/usr/bin/env bash
# pie.lock in a Docker build. PIE keeps pie.json and pie.lock in ~/.pie/php<major.minor>_<md5>, where the md5 covers
# the OS, the PHP binary path, the full PHP version, the architecture and thread safety. Does --from-lock reinstall the
# locked version in a fresh container, and what happens when the files are not where PIE looks?
source "$(dirname "$0")/lib.sh"
img=$(image tools 1.5.5)
dir=$(mktemp -d)
docker run --rm -v "$dir:/export" "$img" sh -c 'pie install "apcu/apcu:5.1.27" >/dev/null 2>&1;
    cp /root/.pie/php8.5_*/pie.json /root/.pie/php8.5_*/pie.lock /export/'
claim lock.locked-version "$(grep -A3 '"name": "apcu/apcu"' "$dir/pie.lock" | grep -o '"version": "[^"]*"' | cut -d'"' -f4)"
# The directory PIE looks in, asked from PIE itself rather than hard-coded.
fresh() { docker run --rm -v "$dir:/import:ro" "$img" sh -c "$1"' > /dev/null 2>&1;
    pie install --from-lock > /tmp/out 2>&1; echo "rc=$?"; grep -c "No lockfile found" /tmp/out | sed "s/^/no_lockfile=/";
    php -r "echo \"apcu=\", phpversion(\"apcu\") ?: \"none\", PHP_EOL;"'; }
out=$(fresh 'd=$(dirname "$(pie show -v 2>/dev/null | sed -n "s/^Using pie.json: //p" | head -1)"); mkdir -p "$d"; cp /import/pie.json /import/pie.lock "$d/"')
claim lock.right-dir.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim lock.right-dir.apcu "$(grep -o '^apcu=.*' <<<"$out" | cut -d= -f2)"
out=$(fresh 'mkdir -p /root/.pie/php8.5_0123456789abcdef0123456789abcdef; cp /import/pie.json /import/pie.lock /root/.pie/php8.5_0123456789abcdef0123456789abcdef/')
claim lock.wrong-dir.rc "$(grep -o '^rc=[0-9]*' <<<"$out" | cut -d= -f2)"
claim lock.wrong-dir.no-lockfile "$(grep -o '^no_lockfile=[0-9]*' <<<"$out" | cut -d= -f2)"
claim lock.wrong-dir.apcu "$(grep -o '^apcu=.*' <<<"$out" | cut -d= -f2)"

# The directory changes with the PHP patch version and with the architecture, so a lock copied to a hard-coded path
# stops being found when the base image moves from 8.5.11 to 8.5.12, or when the image is built for amd64.
piedir() { docker run --rm -q --platform "$2" -v "$(cd "$(dirname "$0")/.." && pwd)/docker/pie-dir.sh:/pie-dir.sh:ro" \
    --mount type=bind,src="$dir/pie",dst=/usr/local/bin/pie,readonly "$1" sh /pie-dir.sh; }
# The PIE image holds only the PHAR, so copy it out of a created (never started) container.
id=$(docker create "${PIE_155}" /pie); docker cp "$id:/pie" "$dir/pie" >/dev/null; docker rm "$id" >/dev/null
chmod +x "$dir/pie"
d1211=$(piedir 'php:8.5.11-cli-bookworm@sha256:878bbda19358b8be328c9c037b8812ce256f75be0af6869c8414aa65231a20d4' linux/arm64)
d1212=$(piedir 'php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0' linux/arm64)
d1212amd=$(piedir 'php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0' linux/amd64)
claim lock.dir.8.5.11-vs-8.5.12 "$([ -n "$d1211" ] && [ "$d1211" != "$d1212" ] && echo different || echo "same: $d1211")"
claim lock.dir.arm64-vs-amd64 "$([ -n "$d1212amd" ] && [ "$d1212amd" != "$d1212" ] && echo different || echo "same: $d1212amd")"
rm -rf "$dir"
