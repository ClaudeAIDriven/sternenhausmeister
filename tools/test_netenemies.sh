#!/usr/bin/env bash
# Test G-28: Wollmaus weggeputzt (bei allen weg), Spinne übersteht den Wedel.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 50 "$GODOT" --headless -s tests/net_enemies.gd -- "$@" 2>&1 | grep "NETZ"; }
run host $PORT > $D/host.log &
sleep 2
run a $PORT > $D/wiper.log &
run b $PORT > $D/watch.log &
wait
cat $D/*.log
[ "$(cat $D/*.log | grep -c ' OK ')" = "3" ] && echo "NETZ OK" || { echo "NETZ FAIL"; exit 1; }
