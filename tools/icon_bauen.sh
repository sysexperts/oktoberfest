#!/usr/bin/env bash
# Programmsymbol bauen: schneidet die Brezn aus dem Logo und packt sie als
# Windows-.ico mit allen Groessen, die Explorer, Taskleiste und Steam brauchen.
#
#   bash tools/icon_bauen.sh
#
# Ergebnis: assets/ui/icon.ico (in export_presets.cfg eingetragen)
#           assets/ui/icon_256.png (fuer Steam und die Store-Seite)
#
# Der Ausschnitt ist auf assets/ui/sloptoberfest_logo.png (1774x887) abgestimmt.
# Ein neues Logo heisst: AUSSCHNITT neu bestimmen.

set -euo pipefail
cd "$(dirname "$0")/.."
FF="${FF:-/c/Users/vase/AppData/Local/Microsoft/WinGet/Packages/Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe/ffmpeg-9.0.1-full_build/bin/ffmpeg}"
QUELLE="assets/ui/sloptoberfest_logo.png"
AUSSCHNITT="crop=330:310:725:570"
TMP="build/icon"
mkdir -p "$TMP"

for G in 256 128 64 48 32 16; do
	"$FF" -y -loglevel error -i "$QUELLE" -vf "$AUSSCHNITT,scale=$G:$G:flags=lanczos" "$TMP/icon_$G.png"
done
cp "$TMP/icon_256.png" assets/ui/icon_256.png

python - <<'PY'
import struct, io, os
groessen = [256, 128, 64, 48, 32, 16]
bilder = []
for g in groessen:
    with open(f"build/icon/icon_{g}.png", "rb") as f:
        bilder.append((g, f.read()))
# ICO: Kopf (6 Byte) + je Bild ein Verzeichniseintrag (16 Byte) + die PNG-Daten.
# 0 in Breite/Hoehe bedeutet 256 — deshalb g % 256.
kopf = struct.pack("<HHH", 0, 1, len(bilder))
offset = 6 + 16 * len(bilder)
verzeichnis = b""
daten = b""
for g, roh in bilder:
    verzeichnis += struct.pack("<BBBBHHII", g % 256, g % 256, 0, 0, 1, 32, len(roh), offset)
    daten += roh
    offset += len(roh)
with open("assets/ui/icon.ico", "wb") as f:
    f.write(kopf + verzeichnis + daten)
print("assets/ui/icon.ico  %d Bytes, %d Groessen" % (os.path.getsize("assets/ui/icon.ico"), len(bilder)))
PY
