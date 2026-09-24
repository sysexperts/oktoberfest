#!/usr/bin/env bash
# Einzelne Trailer-Einstellungen als Standbild rendern (tools/trailer_szenen.gd).
#
#   bash tools/trailer_szenen.sh            # alle Szenen, leichte Stufe (1280x720)
#   bash tools/trailer_szenen.sh voll       # alle Szenen, volle Stufe (1920x1080)
#   bash tools/trailer_szenen.sh leicht kirmes_gasse zelt_voll
#
# Bilder: build/szenen/<name>.png

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/szenen
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
STUFE="leicht"
if [ "${1:-}" = "voll" ] || [ "${1:-}" = "leicht" ]; then STUFE="$1"; shift; fi
if [ "$STUFE" = "voll" ]; then AUFL="1920x1080"; else AUFL="1280x720"; fi
rm -f build/szenen_godot.log
"$GODOT" --path . res://tools/trailer_szenen.tscn --resolution "$AUFL" \
	-- "$STUFE" "$@" > build/szenen_godot.log 2>&1
grep -E "SZENE|SZENEN FERTIG|SCRIPT ERROR" build/szenen_godot.log | grep -v "invalid UID" | head -40
ls -la build/szenen/
