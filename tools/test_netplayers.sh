#!/usr/bin/env bash
# Test N-02: 4 Instanzen mit Spielern, Host-Position wird an Clients synchronisiert.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
run() { timeout 50 "$GODOT" --headless -s tests/net_players.gd -- "$@" 2>&1 | grep "NETP"; }
run host $PORT > /tmp/netp_host.log &
sleep 2
for n in A B C; do run client $PORT $n > /tmp/netp_$n.log & done
wait
cat /tmp/netp_*.log
[ "$(cat /tmp/netp_*.log | grep -c 'OK 4 Spieler')" = "4" ] && echo "NETP OK" || { echo "NETP FAIL"; exit 1; }
