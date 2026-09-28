#!/usr/bin/env bash
# Baut den Steam-Export und lädt ihn per SteamCMD ins Depot 5327191 hoch.
#   bash tools/steam_upload.sh              Export + Upload (Build danach in Steamworks auf einen Branch setzen)
#   bash tools/steam_upload.sh --ohne-export nur hochladen, was in build/steam liegt
# Erstes Mal: SteamCMD fragt nach Passwort und Steam-Guard-Code (selbst eintippen), danach bleibt man angemeldet.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe"
STEAMCMD="${STEAMCMD:-/c/Users/vase/steamcmd/steamcmd.exe}"
KONTO="${STEAM_KONTO:-rushgamer1024}"
VERSION="$(sed -nE 's/^config\/version="([0-9]+)"/\1/p' project.godot)"

if [[ "${1:-}" != "--ohne-export" ]]; then
	echo "=== Export Windows Steam (v$VERSION)"
	"$GODOT" --headless --path . --export-release "Windows Steam" build/steam/Sloptoberfest.exe
fi
for f in Sloptoberfest.exe steam_api64.dll libgodotsteam.windows.template_release.x86_64.dll; do
	[[ -f "build/steam/$f" ]] || { echo "Fehlt: build/steam/$f"; exit 1; }
done

echo "=== Upload v$VERSION"
mkdir -p build/steam_ausgabe
BAU="build/steam_ausgabe/app_build.vdf"
WIN="$(cygpath -m "$PWD")"
sed -e "s/BESCHREIBUNG/v$VERSION $(git rev-parse --short HEAD)/" 	-e "s#\"\.\./\.\./build/#\"$WIN/build/#g" tools/steam/app_build.vdf > "$BAU"
cp tools/steam/depot_5327191.vdf build/steam_ausgabe/
"$STEAMCMD" +login "$KONTO" +run_app_build "$(cygpath -w "$PWD/$BAU")" +quit
echo "=== Fertig. In Steamworks: SteamPipe -> Builds -> Build auf Branch setzen -> Veröffentlichen"
