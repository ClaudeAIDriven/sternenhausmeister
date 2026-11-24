#!/usr/bin/env bash
# Startet Host + 3 Clients (4 Instanzen) lokal und prüft, dass alle 4 Spieler sich sehen.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
run() { timeout 40 "$GODOT" --headless -s tests/net4.gd -- "$@" 2>&1 | grep "NET4"; }
run host $PORT > /tmp/net4_host.log &
sleep 2
for n in A B C; do run client $PORT $n > /tmp/net4_$n.log & done
wait
cat /tmp/net4_*.log
[ "$(cat /tmp/net4_*.log | grep -c 'OK 4 Spieler')" = "4" ] && echo "NET4 OK" || { echo "NET4 FAIL"; exit 1; }
