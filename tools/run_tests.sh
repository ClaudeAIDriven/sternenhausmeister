#!/usr/bin/env bash
# Startet alle Selbsttests. GODOT kann per Umgebungsvariable gesetzt werden.
set -e
GODOT="${GODOT:-/home/claude/tools/Godot_v4.3-stable_linux.x86_64}"
cd "$(dirname "$0")/.."
out=$(timeout 120 "$GODOT" --headless --quit-after 120 -- --selftest 2>&1)
echo "$out" | grep -E "SELFTEST" 
echo "$out" | grep -q "SELFTEST OK" || { echo "TESTS FAIL"; exit 1; }
echo "TESTS OK"
