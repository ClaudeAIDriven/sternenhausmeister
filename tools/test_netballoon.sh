#!/usr/bin/env bash
# Test M-12: Ballon im Netz: Host rechnet, Client lenkt per RPC und sieht die Host-Position.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 40 "$GODOT" --headless -s tests/net_balloon.gd -- "$@" 2>&1 | grep "NETL"; }
run host $PORT > $D/host.log &
sleep 2
run client $PORT > $D/buyer.log &
wait
cat $D/*.log
[ "$(cat $D/*.log | grep -c ' OK ')" = "2" ] && echo "NETL OK" || { echo "NETL FAIL"; exit 1; }
