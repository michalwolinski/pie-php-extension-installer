#!/usr/bin/env bash
# The puzzle: the same Dockerfile and lock, built on PHP 8.5.12 and on PHP 8.5.11, both for arm64.
source "$(dirname "$0")/lib.sh"
build() { docker build --no-cache --platform linux/arm64 --build-arg BASE="$1" examples/puzzle 2>&1; }
out=$(build 'php:8.5.12-cli-bookworm@sha256:050713ce008e2360ea9dc96e1f9a075690132388d917fc3552806f7a7be6f2a0')
claim puzzle.8.5.12.builds "$(grep -qE 'ERROR|failed to solve' <<<"$out" && echo no || echo yes)"
out=$(build 'php:8.5.11-cli-bookworm@sha256:878bbda19358b8be328c9c037b8812ce256f75be0af6869c8414aa65231a20d4')
claim puzzle.8.5.11.builds "$(grep -qE 'ERROR|failed to solve' <<<"$out" && echo no || echo yes)"
claim puzzle.8.5.11.no-lockfile "$(grep -q 'No lockfile found' <<<"$out" && echo yes || echo no)"
