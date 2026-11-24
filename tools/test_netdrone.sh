#!/usr/bin/env bash
# Test N-05: Client trennt -> Drohne erscheint (Host + Beobachter), wischt Flecken; Rejoin mit gleichem Namen entfernt sie.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 60 "$GODOT" --headless -s tests/net_drone.gd -- "$@" 2>&1 | grep "NETD"; }
run host $PORT > $D/host.log &
sleep 2
run watcher $PORT > $D/watch.log &
run leaver $PORT > $D/leaver.log &
sleep 12
run rejoin $PORT > $D/rejoin.log &
wait
cat $D/*.log
[ "$(cat $D/*.log | grep -c ' OK')" = "4" ] && echo "NETD OK" || { echo "NETD FAIL"; exit 1; }
