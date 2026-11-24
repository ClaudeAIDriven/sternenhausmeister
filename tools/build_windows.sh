#!/usr/bin/env bash
# Headless Windows-Export nach build/ (Sternenhausmeister.exe + Sternenhausmeister.pck).
# Braucht Godot 4.3 und die Export-Templates (werden bei Bedarf nach ~/.local/share/godot geladen).
set -e
GODOT="${GODOT:-$("$(dirname "$0")/setup_godot.sh")}"
cd "$(dirname "$0")/.."
T="${HOME}/.local/share/godot/export_templates/4.3.stable"
if [ ! -f "$T/windows_release_x86_64.exe" ]; then
  mkdir -p "$T"; tmp=$(mktemp -d)
  curl -sL --max-time 1500 -o "$tmp/t.tpz" https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_export_templates.tpz
  python3 -I -c "import sys,zipfile;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$tmp/t.tpz" "$tmp"
  cp -r "$tmp"/templates/. "$T"/; rm -rf "$tmp"
fi
[ -d .godot ] || timeout 180 "$GODOT" --headless --import >/dev/null 2>&1 || true
mkdir -p build
"$GODOT" --headless --export-release "Windows Desktop" build/Sternenhausmeister.exe
[ -f build/Sternenhausmeister.exe ] && [ -f build/Sternenhausmeister.pck ] || { echo "BUILD FAIL"; exit 1; }
ls -l build/Sternenhausmeister.*
echo "BUILD OK"
