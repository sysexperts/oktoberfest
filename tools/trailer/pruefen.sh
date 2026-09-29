#!/usr/bin/env bash
# Prüft eine Trailer-Szene vor dem Rendern: fährt die Kamera ab (30 fps, ohne
# Aufnahme) und meldet, wo sie in Bäumen/Buden steckt oder die Sicht aufs
# Blickziel verdeckt ist.   bash tools/trailer/pruefen.sh 02
set -uo pipefail
cd "$(dirname "$0")/../.."
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
"$GODOT" --path . --fixed-fps 30 --resolution 640x360 "res://tools/trailer/szene_${1:?Szenennummer}.tscn" -- --pruefen 2>&1 \
	| grep -E "^  t=|Hindernisse erfasst|PRUEFUNG|SCRIPT ERROR"
