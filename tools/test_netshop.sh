#!/usr/bin/env bash
# Test I-10: Kauf im Netz: Client kauft, Host bucht ab, beide haben Stufe 1 und denselben Staubabzug.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 40 "$GODOT" --headless -s tests/net_shop.gd -- "$@" 2>&1 | grep "NETB"; }
run host $PORT > $D/host.log &
sleep 2
run buyer $PORT > $D/buyer.log &
wait
cat $D/*.log
[ "$(cat $D/*.log | grep -c ' OK ')" = "2" ] && echo "NETB OK" || { echo "NETB FAIL"; exit 1; }
