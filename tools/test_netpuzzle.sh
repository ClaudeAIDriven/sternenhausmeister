#!/usr/bin/env bash
# Test I-04: Sternbild-Rätsel im Netz: falsche Reihenfolge setzt bei allen zurück, richtige löst bei allen.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 50 "$GODOT" --headless -s tests/net_puzzle.gd -- "$@" 2>&1 | grep "NETZ"; }
run host $PORT > $D/host.log &
sleep 2
run wiper $PORT > $D/wiper.log &
run watcher $PORT > $D/watch.log &
wait
cat $D/*.log
[ "$(cat $D/*.log | grep -c ' OK ')" = "3" ] && echo "NETZ OK" || { echo "NETZ FAIL"; exit 1; }
