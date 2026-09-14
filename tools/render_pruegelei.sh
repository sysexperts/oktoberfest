#!/usr/bin/env bash
# Nimmt den Demo-Ablauf der Prügelei-Testszene als Video auf (Einzelstreit,
# Massenschlägerei, Packen und Rauswurf) und speichert Standbilder.
#
#   bash tools/render_pruegelei.sh
#
# Video: build/pruegelei.avi (MJPEG, 30 fps) · Bilder: tools/pruegel_*.png
# Die Szene fasst keine Spielstände an.

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
rm -f tools/pruegel_*.png build/pruegelei.avi
"$GODOT" --path . res://scenes/tests/pruegelei_test.tscn --resolution 1280x720 \
	--write-movie build/pruegelei.avi --fixed-fps 30 -- --demo 2>&1 | grep -E "gespeichert|SCRIPT ERROR|ERROR" | grep -v "invalid UID"
ls -la build/pruegelei.avi tools/pruegel_*.png 2>/dev/null
