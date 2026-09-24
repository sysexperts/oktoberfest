#!/usr/bin/env bash
# Spielstand zum Fotografieren bauen (tools/screenshot_stand.gd).
#
#   bash tools/screenshot_stand.sh        # Platz 3
#   bash tools/screenshot_stand.sh 2      # Platz 2
#
# Ein vorhandener Stand wird nach slot_N.json.vorher gesichert.

set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
PLATZ="${1:-3}"
mkdir -p build
"$GODOT" --path . res://tools/screenshot_stand.tscn -- "$PLATZ" > build/stand_godot.log 2>&1
grep -E "STAND FERTIG|Alter Stand|SCRIPT ERROR|ERROR" build/stand_godot.log | grep -v "invalid UID" | head -20
