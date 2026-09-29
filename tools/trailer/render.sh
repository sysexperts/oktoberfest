#!/usr/bin/env bash
# Rendert eine Trailer-Szene (tools/trailer/szene_NN.tscn) als eigenes Video
# zum Schneiden: 1920x1080, 60 fps, ohne Musik (Spielgeräusche bleiben drin).
#   bash tools/trailer/render.sh 01      → build/trailer/szene_01.mp4
# Die Aufnahme läuft langsamer als Echtzeit (--write-movie), das Video nicht.
set -uo pipefail
cd "$(dirname "$0")/../.."
NR="${1:?Szenennummer, z. B. 01}"
FPS=60
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
FF="${FF:-/c/Users/vase/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.1-full_build/bin/ffmpeg}"
mkdir -p build/trailer
ROH="build/trailer/szene_${NR}_roh.avi"
LOG="build/trailer/szene_${NR}.log"
rm -f "$ROH"
# Der Aufnahmemodus nimmt die Fenstergröße aus project.godot (--resolution wird
# ignoriert): kurz auf 1920x1080 setzen und danach sicher zurückschreiben.
BREIT="$(sed -nE 's,^window/size/viewport_width=([0-9]+),\1,p' project.godot)"
HOCH="$(sed -nE 's,^window/size/viewport_height=([0-9]+),\1,p' project.godot)"
zurueck() {
	sed -i -E "s,^window/size/viewport_width=.*,window/size/viewport_width=$BREIT,; s,^window/size/viewport_height=.*,window/size/viewport_height=$HOCH," project.godot
}
trap zurueck EXIT
sed -i -E "s,^window/size/viewport_width=.*,window/size/viewport_width=1920,; s,^window/size/viewport_height=.*,window/size/viewport_height=1080," project.godot
"$GODOT" --path . --write-movie "$ROH" --fixed-fps $FPS "res://tools/trailer/szene_${NR}.tscn" -- --aufnahme > "$LOG" 2>&1
zurueck
grep -E "SCRIPT ERROR" "$LOG" | head -5
START="$(sed -nE 's/^SZENE_START ([0-9]+).*/\1/p' "$LOG" | head -1)"
ENDE="$(sed -nE 's/^SZENE_ENDE ([0-9]+).*/\1/p' "$LOG" | head -1)"
[ -s "$ROH" ] && [ -n "$START" ] && [ -n "$ENDE" ] || { echo "Aufnahme fehlgeschlagen, siehe $LOG"; exit 1; }
AB="$(awk "BEGIN{print $START / $FPS}")"
LANG="$(awk "BEGIN{print ($ENDE - $START) / $FPS}")"
"$FF" -y -loglevel error -ss "$AB" -t "$LANG" -i "$ROH" -c:v libx264 -preset slow -crf 14 -pix_fmt yuv420p \
	-c:a aac -b:a 192k "build/trailer/szene_${NR}.mp4"
rm -f "$ROH"
echo "Fertig: build/trailer/szene_${NR}.mp4 (${LANG} s)"
