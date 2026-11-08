#!/bin/sh
# usage: measure.sh <label> <command...>
# Samples every second: elapsed seconds, anonymous memory of the container in MiB (process memory, not page cache),
# and the 1-minute load average. Prints wall time, the highest anon sample and the highest load.
label=$1; shift
start=$(date +%s)
( while :; do
    anon=$(awk '$1 == "anon" { print int($2 / 1048576) }' /sys/fs/cgroup/memory.stat)
    echo "$(( $(date +%s) - start )) $anon $(cut -d' ' -f1 /proc/loadavg)" >> "/out/$label.timeline"; sleep 1
  done ) & mon=$!
"$@" > "/out/$label.log" 2>&1; rc=$?; end=$(date +%s); kill $mon
for f in /tmp/pie_make_output_*; do [ -f "$f" ] && cp "$f" "/out/$label.make-output"; done
# gcc reports a compiler the kernel killed for memory as "Killed signal terminated program cc1plus"
killed=$(cat "/out/$label.log" "/out/$label.make-output" 2>/dev/null | grep -c "Killed signal terminated program cc1plus")
echo "RESULT $label rc=$rc seconds=$((end - start)) max_anon_mib=$(sort -k2 -n "/out/$label.timeline" | tail -1 | cut -d' ' -f2) max_load=$(sort -k3 -n "/out/$label.timeline" | tail -1 | cut -d' ' -f3) compilers_killed=$killed"
php -r "echo \"LOADED \", extension_loaded(\"${EXT:-grpc}\") ? phpversion(\"${EXT:-grpc}\") : \"no\", PHP_EOL;"
