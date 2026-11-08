#!/usr/bin/env bash
# Builds grpc 1.85.1 for PHP 8.5.12 in several ways, one at a time, and records wall time, the highest anonymous
# memory of the container (process memory, not page cache) and the highest load average.
#   ./timings/run.sh                    every method below, in order (well over an hour on 8 CPUs)
#   ./timings/run.sh pie-j4 pecl        only these; also ipe-default, ipe-j4 (install-php-extensions) and
#                                       alpine-pie-j4, alpine-ipe-j4 (built on Alpine)
#   ./timings/run.sh redis              redis 6.3.0 with pecl and with PIE, three times each, alternating
#   ./timings/run.sh sury               grpc from deb.sury.org's php8.5-grpc package, including apt-get update
#   ./timings/run.sh no-libtool         grpc with -j4 in the bare image plus unzip and zlib only: is libtool needed?
# Each run replaces its own timeline in timings/out/; results.txt keeps every run, failed ones included.
# Run it on an otherwise idle Docker: other containers change both the time and whether the build fits in memory.
set -euo pipefail
cd "$(dirname "$0")/.."
source checks/lib.sh
img=$(image tools 1.5.5)
mkdir -p timings/out
methods=("$@"); [ ${#methods[@]} -eq 0 ] && methods=(pie-binary pie-j8 pie-j4 pie-j2 pecl)
if [ "${methods[0]}" = redis ]; then
    for round in 1 2 3; do for method in pecl pie; do
        case $method in
            pecl) cmd=(sh -c "printf '\n\n\n\n\n\n\n' | pecl install redis-6.3.0 && docker-php-ext-enable redis") ;;
            pie)  cmd=(pie install phpredis/phpredis:6.3.0) ;;
        esac
        rm -f "timings/out/redis-$method-$round".*
        docker run --rm -v "$PWD/timings/measure.sh:/m.sh:ro" -v "$PWD/timings/out:/out" -e EXT=redis \
            "$img" /m.sh "redis-$method-$round" "${cmd[@]}" | tee -a timings/out/results.txt
    done; done
    exit 0
fi
if [ "${methods[0]}" = sury ]; then
    sury=$(docker build -q -f docker/sury.Dockerfile docker)
    rm -f timings/out/sury.*
    docker run --rm -v "$PWD/timings/measure.sh:/m.sh:ro" -v "$PWD/timings/out:/out" "$sury" \
        /m.sh sury sh -c 'apt-get update && apt-get install -y --no-install-recommends php8.5-grpc' | tee -a timings/out/results.txt
    exit 0
fi
if [ "${methods[0]}" = no-libtool ]; then
    bare=$(image bare 1.5.5)
    rm -f timings/out/no-libtool.*
    docker run --rm -v "$PWD/timings/measure.sh:/m.sh:ro" -v "$PWD/timings/out:/out" "$bare" sh -c \
        'apt-get update -qq && apt-get install -y -qq --no-install-recommends unzip zlib1g-dev > /dev/null && command -v libtoolize || echo "no libtoolize";
         /m.sh no-libtool pie install -j4 grpc/grpc-php-ext:1.85.1' | tee -a timings/out/results.txt
    exit 0
fi
for method in "${methods[@]}"; do
    run_img=$img env=()
    case $method in
        pie-binary)    cmd=(pie install extport/grpc:1.85.1) ;;
        pie-j*)        cmd=(pie install "-${method#pie-}" grpc/grpc-php-ext:1.85.1) ;;
        pecl)          cmd=(sh -c "printf '\n\n\n\n' | pecl install grpc-1.85.0 && docker-php-ext-enable grpc") ;;
        # install-php-extensions builds through pecl, so it gets PECL's newest grpc, 1.85.0.
        ipe-default)   run_img=$(image ipe 1.5.5); cmd=(install-php-extensions grpc-1.85.0) ;;
        ipe-j4)        run_img=$(image ipe 1.5.5); env=(-e IPE_PROCESSOR_COUNT=4); cmd=(install-php-extensions grpc-1.85.0) ;;
        # Alpine: PIE with the build tools installed up front; install-php-extensions installs its own.
        alpine-pie-j4) run_img=$(image alpine-build 1.5.5); cmd=(pie install -j4 grpc/grpc-php-ext:1.85.1) ;;
        alpine-ipe-j4) run_img=$(image ipe-alpine 1.5.5); env=(-e IPE_PROCESSOR_COUNT=4); cmd=(install-php-extensions grpc-1.85.0) ;;
        *) echo "unknown method $method" >&2; exit 1 ;;
    esac
    rm -f "timings/out/$method".*
    docker run --rm --name "pie-timing-$method" ${env[@]+"${env[@]}"} -v "$PWD/timings/measure.sh:/m.sh:ro" -v "$PWD/timings/out:/out" \
        "$run_img" /m.sh "$method" "${cmd[@]}" | tee -a timings/out/results.txt
done
