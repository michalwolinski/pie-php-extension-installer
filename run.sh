#!/usr/bin/env bash
# Runs every check in checks/ and compares its claims with expectations.txt.
#   ./run.sh                 all checks (about 20 minutes, needs network access to Packagist and GitHub)
#   ./run.sh 03 04           only the checks whose file names start with these prefixes
# The grpc build timings are separate and slow: see timings/run.sh.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p runs
out="runs/claims.txt"
: > "$out"
for check in checks/[0-9]*.sh; do
    name=$(basename "$check" .sh)
    if [ $# -gt 0 ] && ! printf '%s\n' "$@" | grep -qx "${name%%-*}"; then continue; fi
    echo "== $name" >&2
    bash "$check" | tee -a "$out"
done

met=0 unmet=0
while read -r _ check key expected; do
    # Skip the claims of checks this run did not select. A selected check that printed nothing for a claim
    # counts as unmet, so a check that dies early cannot pass by staying silent.
    if [ $# -gt 0 ] && ! printf '%s\n' "$@" | grep -qx "$check"; then continue; fi
    actual=$(awk -v k="$key" '$1 == "claim" && $2 == k { $1 = ""; $2 = ""; sub(/^  /, ""); print }' "$out")
    if ! grep -q "^claim $key " "$out"; then
        unmet=$((unmet + 1)); echo "UNMET $key: expected [$expected], no claim printed"; continue
    fi
    if [ "$actual" = "$expected" ]; then met=$((met + 1)); else unmet=$((unmet + 1)); echo "UNMET $key: expected [$expected], got [$actual]"; fi
done < <(grep '^expect ' expectations.txt)
echo "== expectations: $met met, $unmet unmet"
[ "$unmet" -eq 0 ]
