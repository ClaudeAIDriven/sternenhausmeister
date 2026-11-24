#!/usr/bin/env bash
# Lädt Godot 4.3 (Linux, headless-fähig) nach ~/tools, falls nicht vorhanden. Gibt den Pfad aus.
set -e
D="${HOME}/tools"; B="$D/Godot_v4.3-stable_linux.x86_64"
if [ ! -x "$B" ]; then
  mkdir -p "$D"; cd "$D"
  curl -sL --max-time 600 -o godot.zip https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_linux.x86_64.zip
  python3 -I -c "import zipfile;zipfile.ZipFile('godot.zip').extractall('.')"
  chmod +x "$B"; rm -f godot.zip
fi
echo "$B"
