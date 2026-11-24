#!/usr/bin/env bash
# Test G-22: Zwei Clients greifen dieselbe Frucht, nur einer bekommt sie.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 50 "$GODOT" --headless -s tests/net_fruit.gd -- "$@" 2>&1 | grep "NETZ"; }
run host $PORT > $D/host.log &
sleep 2
run a $PORT > $D/wiper.log &
run b $PORT > $D/watch.log &
wait
cat $D/*.log
TOTAL=$(cat $D/*.log | grep -o "items=[0-9]*" | cut -d= -f2 | paste -sd+ | bc)
[ "$(cat $D/*.log | grep -c " OK ")" = "3" ] && [ "$TOTAL" = "1" ] && echo "NETZ OK" || { echo "NETZ FAIL (Früchte insgesamt: $TOTAL)"; exit 1; }
