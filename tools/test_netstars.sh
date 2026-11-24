#!/usr/bin/env bash
# Test N-03: Wisch eines Clients ist bei Host, anderem Client und Nachzügler gleich sichtbar.
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
PORT=$((25000 + RANDOM % 2000))
D=$(mktemp -d)
run() { timeout 50 "$GODOT" --headless -s tests/net_stars.gd -- "$@" 2>&1 | grep "NETS"; }
run host $PORT > $D/host.log &
sleep 2
run wiper $PORT > $D/wiper.log &
run watcher $PORT > $D/watch.log &
sleep 9
run late $PORT > $D/late.log &
wait
cat $D/*.log
n=$(cat $D/*.log | grep RESULT | sed 's/.*RESULT//' | sort -u | wc -l)
[ "$(cat $D/*.log | grep -c 'RESULT clean0=true')" = "4" ] && [ "$n" = "1" ] && echo "NETS OK" || { echo "NETS FAIL"; exit 1; }
