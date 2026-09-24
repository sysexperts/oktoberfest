#!/usr/bin/env bash
# Steam-Trailer aufnehmen (tools/render_trailer.gd) und fertig machen:
#   1 Aufnahme in 1920x1080, 30 fps (--write-movie, dauert mehrere Minuten)
#   2 MP4 ohne Musik (nur Spielgeräusche)       → build/trailer_ohne_musik.mp4
#   3 MP4 mit Musik (Vorgabe assets/music/Gamesound.mp3, per MUSIK= anderswohin)
#                                                → build/trailer_mit_musik.mp4
# ACHTUNG: Die Musikrechte sind laut docs/lizenzen/README.md noch nicht geklaert
# — die Fassung mit Musik ist bis dahin nur ein Entwurf.
#
#   bash tools/render_trailer.sh

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
FF="${FF:-/c/Users/vase/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.1-full_build/bin/ffmpeg}"
rm -f build/trailer.avi build/trailer_lauf_godot.log
# Der Aufnahmemodus nimmt immer die Fenstergröße aus project.godot — --resolution
# wird dabei ignoriert (gemessen: Godot meldete weiter 1440x810). Also für die
# Aufnahme kurz hochsetzen und danach zurückschreiben, egal wie der Lauf ausgeht.
BREIT="$(sed -nE 's,^window/size/viewport_width=([0-9]+),\1,p' project.godot)"
HOCH="$(sed -nE 's,^window/size/viewport_height=([0-9]+),\1,p' project.godot)"
aufloesung_zurueck() {
	sed -i -E "s,^window/size/viewport_width=.*,window/size/viewport_width=$BREIT,; s,^window/size/viewport_height=.*,window/size/viewport_height=$HOCH," project.godot
}
trap aufloesung_zurueck EXIT
sed -i -E "s,^window/size/viewport_width=.*,window/size/viewport_width=1920,; s,^window/size/viewport_height=.*,window/size/viewport_height=1080," project.godot
"$GODOT" --path . --write-movie build/trailer.avi --fixed-fps 30 \
	res://tools/render_trailer.tscn > build/trailer_lauf_godot.log 2>&1
aufloesung_zurueck
grep -E "TRAILER|SCRIPT ERROR" build/trailer_lauf_godot.log | grep -v "invalid UID" | head -20
[ -s build/trailer.avi ] || { echo "Aufnahme fehlgeschlagen"; exit 1; }
# Aufbau (Ladebildschirm, Zelt aufstellen) wegschneiden: ab der Schnittmarke
START="$(sed -nE 's/^TRAILER_START ([0-9.]+).*/\1/p' build/trailer_lauf_godot.log | head -1)"
START="${START:-0}"
"$FF" -y -loglevel error -ss "$START" -i build/trailer.avi -c:v mjpeg -q:v 2 -c:a pcm_s16le build/trailer_geschnitten.avi
DAUER="$("$FF" -i build/trailer_geschnitten.avi 2>&1 | sed -nE 's/.*Duration: ([0-9:.]+).*/\1/p' | awk -F: '{print $1*3600+$2*60+$3}')"
AUS="$(awk "BEGIN{print $DAUER - 3}")"
"$FF" -y -loglevel error -i build/trailer_geschnitten.avi -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
	-c:a aac -b:a 192k build/trailer_ohne_musik.mp4
"$FF" -y -loglevel error -i build/trailer_geschnitten.avi -i "${MUSIK:-assets/music/Gamesound.mp3}" \
	-filter_complex "[1:a]volume=0.55,afade=t=in:d=1.5,afade=t=out:st=${AUS}:d=3[m];[0:a]volume=1.3[s];[s][m]amix=inputs=2:duration=first:dropout_transition=0[a]" \
	-map 0:v -map "[a]" -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k build/trailer_mit_musik.mp4
ls -la build/trailer_*.mp4
echo "Dauer: ${DAUER}s"
