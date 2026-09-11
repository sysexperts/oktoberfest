#!/usr/bin/env bash
# Test mit echten exportierten .exe-Dateien.
#
# Exportierte Vorlagen verhalten sich anders als der Editor — v101 bis v104
# starteten alte .exe mit --main-pack neu, was die Vorlagen verweigern: Das
# Spiel schloss sich für Spieler sofort, im Editor lief es. Dieser Test prüft
# den Weg, den Spieler wirklich nehmen:
#   1 alte .exe (build/alt_v100.exe, Generation 1) + aktuelles Paket im
#     Update-Lager → bleibt offen und zeigt den Download-Hinweis
#   2 neue .exe (aktuelle Generation) + aktuelles Paket → ins Hauptmenü
#   3 neue .exe mit Darstellung "Leistung" → Neustart mit --rendering-method,
#     der neue Prozess läuft weiter
#
#   bash tools/test_exe.sh
#
# Spielstände, Einstellungen und Update-Lager werden vorher gesichert und am
# Ende (auch bei Abbruch) zurückgespielt. Der Test lädt nichts herunter.

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
DATEN="$APPDATA/Godot/app_userdata/Oktoberfest Simulator"
ALT="build/alt_v100.exe"
NEU_ORDNER="build/test_exe"
NEU="$NEU_ORDNER/OktoberfestSimulator.exe"
PAKET="build/test_exe_paket.pck"
SICHERUNG="build/test_exe_sicherung"
DATEIEN=(saves einstellungen.cfg game.pck version.txt)
FEHLER=0

pruefe() {  # Name, Bedingung-Ergebnis (0 = ok), Info
	if [ "$2" = 0 ]; then echo "  [OK  ] $1  $3"; else echo "  [FAIL] $1  $3"; FEHLER=$((FEHLER + 1)); fi
}
alle_beenden() {
	taskkill //F //IM OktoberfestSimulator.exe >/dev/null 2>&1 || true
	taskkill //F //IM alt_v100.exe >/dev/null 2>&1 || true
}
anzahl_prozesse() {  # Image-Name
	tasklist //FI "IMAGENAME eq $1" //NH 2>/dev/null | grep -ci "$1" || true
}

[ -f "$ALT" ] || { echo "Alte .exe fehlt ($ALT) — das ist die v100-.exe aus der Download-ZIP."; exit 2; }

rm -rf "$SICHERUNG"
mkdir -p "$SICHERUNG"
for f in "${DATEIEN[@]}"; do [ -e "$DATEN/$f" ] && cp -r "$DATEN/$f" "$SICHERUNG/"; done
zurueckspielen() {
	alle_beenden
	sleep 1
	for f in "${DATEIEN[@]}"; do
		rm -rf "$DATEN/$f"
		[ -e "$SICHERUNG/$f" ] && cp -r "$SICHERUNG/$f" "$DATEN/"
	done
	echo "Spieldaten zurückgespielt"
}
trap zurueckspielen EXIT

echo "=== neue .exe und Paket exportieren"
rm -rf "$NEU_ORDNER" "$PAKET"
mkdir -p "$NEU_ORDNER"
"$GODOT" --headless --path . --export-release "Windows Desktop" "$NEU" > build/test_exe_export.log 2>&1 || true
"$GODOT" --headless --path . --export-pack "Windows Desktop" "$PAKET" >> build/test_exe_export.log 2>&1 || true
if [ ! -s "$NEU" ] || [ ! -s "$PAKET" ]; then tail -20 build/test_exe_export.log; echo "Export fehlgeschlagen"; exit 2; fi
VERSION="$(sed -nE 's/^config\/version="([0-9]+)"/\1/p' project.godot)"
ls "$NEU_ORDNER"

# Update-Lager wie bei einem Spieler, der das aktuelle Paket schon geladen hat.
# version.txt = aktuelle Version, damit keine .exe beim Server nachlädt.
lager_vorbereiten() {
	alle_beenden
	rm -rf "$DATEN/saves" "$DATEN/einstellungen.cfg" "$DATEN/game.pck.tmp"
	cp "$PAKET" "$DATEN/game.pck"
	printf "%s" "$VERSION" > "$DATEN/version.txt"
}

echo "=== 1 alte .exe (Generation 1) + Paket v$VERSION"
lager_vorbereiten
"$ALT" > build/test_exe_1.log 2>&1 &
sleep 20
LAEUFT=$(anzahl_prozesse alt_v100.exe)
pruefe "alte .exe schließt sich nicht" "$([ "$LAEUFT" -ge 1 ] && echo 0 || echo 1)" "$LAEUFT Prozess(e) nach 20 s"
pruefe "zeigt den Download-Hinweis" "$(grep -q "Hinweis zum Neu-Herunterladen" build/test_exe_1.log && echo 0 || echo 1)" \
	"$(grep -oE "Programm-Generation [0-9]+, dieses Paket braucht [0-9]+" build/test_exe_1.log | head -1)"
pruefe "kein --main-pack-Abbruch" "$(grep -q "main-pack" build/test_exe_1.log && echo 1 || echo 0)" ""
alle_beenden

echo "=== 2 neue .exe + Paket v$VERSION"
lager_vorbereiten
"$NEU" > build/test_exe_2.log 2>&1 &
sleep 30
LAEUFT=$(anzahl_prozesse OktoberfestSimulator.exe)
pruefe "neue .exe läuft" "$([ "$LAEUFT" -ge 1 ] && echo 0 || echo 1)" "$LAEUFT Prozess(e) nach 30 s"
pruefe "kommt ins Hauptmenü" "$(grep -q "weiter ins Hauptmenü" build/test_exe_2.log && echo 0 || echo 1)" ""
pruefe "keine Skriptfehler" "$(grep -qE "SCRIPT ERROR|Parse Error" build/test_exe_2.log && echo 1 || echo 0)" \
	"$(grep -cE "SCRIPT ERROR|Parse Error" build/test_exe_2.log) Treffer"
alle_beenden

echo "=== 3 neue .exe, Darstellung Leistung → Neustart mit --rendering-method"
lager_vorbereiten
printf '[grafik]\n\nrenderer="gl_compatibility"\n' > "$DATEN/einstellungen.cfg"
"$NEU" > build/test_exe_3.log 2>&1 &
sleep 30
LAEUFT=$(anzahl_prozesse OktoberfestSimulator.exe)
ZEILE="$(powershell -NoProfile -Command "(Get-CimInstance Win32_Process -Filter \"Name='OktoberfestSimulator.exe'\" | Select-Object -First 1).CommandLine" 2>/dev/null | tr -d '\r')"
pruefe "Neustart angestoßen" "$(grep -q "Neustart mit --rendering-method gl_compatibility" build/test_exe_3.log && echo 0 || echo 1)" ""
pruefe "neuer Prozess läuft weiter" "$([ "$LAEUFT" -ge 1 ] && echo 0 || echo 1)" "$LAEUFT Prozess(e) nach 30 s"
pruefe "mit --rendering-method gestartet" "$(echo "$ZEILE" | grep -q "rendering-method" && echo 0 || echo 1)" "$ZEILE"
alle_beenden

echo
echo "ERGEBNIS: $([ "$FEHLER" = 0 ] && echo BESTANDEN || echo FEHLGESCHLAGEN) ($FEHLER Fehler)"
[ "$FEHLER" = 0 ]
