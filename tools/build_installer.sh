#!/usr/bin/env bash
# Baut build/StarScrubber-Setup.exe mit NSIS (makensis). Ruft bei Bedarf build_windows.sh auf.
set -e
cd "$(dirname "$0")/.."
if ! command -v makensis >/dev/null 2>&1; then
  (apt-get install -y nsis >/dev/null 2>&1 || sudo apt-get install -y nsis >/dev/null 2>&1) || true
fi
command -v makensis >/dev/null 2>&1 || { echo "makensis fehlt (apt install nsis)"; exit 1; }
if [ ! -f build/StarScrubber.exe ] || [ ! -f build/StarScrubber.pck ]; then
  tools/build_windows.sh
fi
makensis -V2 installer.nsi
[ -f build/StarScrubber-Setup.exe ] || { echo "INSTALLER FAIL"; exit 1; }
ls -l build/StarScrubber-Setup.exe
echo "INSTALLER OK"
