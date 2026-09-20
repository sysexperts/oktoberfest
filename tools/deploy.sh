#!/usr/bin/env bash
# Deploy aus einem Guss (Plan 5.6): Spieler-Paket und Serverquellen aus
# demselben Git-Stand, geprüft statt Datei für Datei von Hand.
#
#   bash tools/deploy.sh           kompletter Deploy der Version aus project.godot
#   bash tools/deploy.sh --probe   nur prüfen: Git-Stand und Abweichungen auf dem
#                                  Server anzeigen, nichts exportieren oder ändern
#
# Ablauf:
#   1 Git sauber, gepusht, Version neuer als live, LFS-Dateien wirklich geladen
#   2 Test-Paket MIT tools/ exportieren, test_phase1 daraus muss bestehen
#   3 Release-Pakete exportieren (spiel.pck immer, inhalt.pck nur bei Bedarf)
#   4 Serverquellen per Prüfsumme abgleichen — nur Abweichendes wird übertragen
#   5 Server: überschriebene Dateien sichern, entpacken, zweimal importieren
#   6 Pakete als *.pck.neu hochladen, Prüfsumme vergleichen
#   7 erst dann tauschen, dann version.json, Dienst neu starten, Journal prüfen
#   8 über HTTPS nachprüfen, Git-Tag deploy-v<Version>
#
# Warum: Beim Handdeploy fehlten einmal vier Stand-Modelle zwei Tage auf dem
# Server, ein andermal war version.json durch Anführungszeichen zerschossen.
# Bash statt PowerShell, weil PowerShell 5.1 Anführungszeichen an ssh verfälscht.
#
# Ob die beiden Pakete zusammen noch ein lauffähiges Spiel ergeben, prüft
# tools/paket_test (siehe docs/RELEASE_CHECKLISTE.md Abschnitt 11) — hier läuft
# das nicht mit, weil die Release-Pakete tools/ nicht enthalten.

set -euo pipefail

SERVER="root@185.248.140.225"
SCHLUESSEL="$HOME/.ssh/id_vapur_admin"
WEB="/var/www/survival"
QUELLEN="/opt/oktoberfest"
GODOT_SERVER="/opt/godot/Godot_v4.7.2-stable_linux.x86_64"
URL="https://survival.vapur-it.de"
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
PRESET="Windows Desktop"
# Aufteilung der Spieldaten (ab v205, siehe scripts/boot.gd): Bis v204 ging bei
# jedem Deploy ein einziges game.pck mit 815 MB raus — hoch, zur Kontrolle wieder
# runter, und zu jedem Spieler. Jetzt gibt es zwei Pakete:
#   inhalt.pck  voller Export (~815 MB), nur wenn sich die großen Ordner ändern
#   spiel.pck   alles außer denen (~61 MB), bei jedem Deploy
# Groß und stabil: gehört ins selten erneuerte inhalt.pck. An EINER Stelle
# gepflegt, damit Exportfilter und Änderungserkennung nicht auseinanderlaufen.
GROSS_ORDNER="assets/models assets/character assets/music addons"
GROSS="$(echo "$GROSS_ORDNER" | sed 's#[^ ]*#&/*#g' | tr ' ' ',')"
# Auf dieser Version bleiben alte .exe (Programm-Generation <= 3) stehen: sie
# kennen nur game.pck und den Schlüssel "version" in version.json. Beides bleibt
# eingefroren liegen, damit sie nicht jedes Mal 815 MB ziehen; menu_eingang.gd
# zeigt ihnen den Hinweis zum Neu-Herunterladen.
UEBERGANG=205
# Was der Server nicht braucht (Werkzeuge, Doku, Build-Ausgaben)
NICHT_AUF_DEN_SERVER='^(docs|tools|build)/|^\.git'

PROBE=0
MIT_ZIP=0
ALTPAKET=0
for arg in "$@"; do
	case "$arg" in
		--probe) PROBE=1 ;;
		# Auch die Download-ZIP mit aktueller .exe bauen und verlinken — nötig, wenn
		# application/config/programm_generation gestiegen ist (alte .exe zeigen dann
		# einen Hinweis zum Neu-Herunterladen und brauchen eine aktuelle ZIP).
		--mit-zip) MIT_ZIP=1 ;;
		# Zusätzlich das alte game.pck auf den Stand von inhalt.pck bringen. Nur
		# einmal beim Übergang nötig, damit alte .exe den Hinweis zum
		# Neu-Herunterladen überhaupt zu sehen bekommen.
		--altpaket) ALTPAKET=1 ;;
		*) echo "Unbekannte Option: $arg"; exit 2 ;;
	esac
done

cd "$(dirname "$0")/.."
mkdir -p build

# Keepalive: der Serverimport vieler neuer Modelle dauert Minuten ohne Ausgabe —
# ohne Lebenszeichen trennte die Verbindung (v128: "Connection reset by peer").
ssh_server() { ssh -i "$SCHLUESSEL" -o BatchMode=yes -o ServerAliveInterval=20 -o ServerAliveCountMax=60 "$SERVER" "$@"; }
scp_server() { scp -q -i "$SCHLUESSEL" -o BatchMode=yes "$@"; }
schritt() { echo; echo "=== $*"; }
abbruch() { echo; echo "ABBRUCH: $*" >&2; exit 1; }

# ------------------------------------------------------------------ 1 Git
schritt "1/8 Git-Stand"
[ -z "$(git status --porcelain)" ] || abbruch "Arbeitskopie nicht sauber — erst committen."
git fetch -q origin
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] || abbruch "HEAD ist nicht origin/main — erst pushen."
COMMIT="$(git rev-parse --short HEAD)"
VERSION="$(sed -nE 's/^config\/version="([0-9]+)"/\1/p' project.godot)"
[ -n "$VERSION" ] || abbruch "Keine application/config/version in project.godot."
# version.json führt drei Zahlen: "spiel" und "inhalt" für aktuelle .exe,
# "version" eingefroren für alte. Fehlt "spiel", ist noch der Stand vor der
# Aufteilung online — dann zählt "version".
VJSON="$(curl -fsS "$URL/version.json")"
feld() { echo "$VJSON" | sed -nE "s/.*\"$1\"[: ]*([0-9]+).*/\1/p"; }
LIVE="$(feld spiel)"; [ -n "$LIVE" ] || LIVE="$(feld version)"
LIVE_INHALT="$(feld inhalt)"; [ -n "$LIVE_INHALT" ] || LIVE_INHALT=0
echo "Commit $COMMIT · Version lokal $VERSION · live spiel $LIVE · live inhalt $LIVE_INHALT"
[ -n "$LIVE" ] || abbruch "version.json vom Server nicht lesbar — Deploy abgebrochen."
# In git lfs ls-files steht "-" statt "*", wenn nur der Zeiger ausgecheckt ist
if git lfs ls-files | grep -q ' - '; then
	abbruch "LFS-Dateien nur als Zeiger vorhanden — git lfs pull."
fi
if [ "$PROBE" = 0 ] && [ "$VERSION" -le "$LIVE" ]; then
	abbruch "Version $VERSION ist nicht neuer als live ($LIVE) — project.godot hochzählen."
fi

# ------------------------------------------------------------------ 4 Abgleich (auch für --probe)
abgleich() {
	# core.quotepath=false: sonst schreibt git Namen mit Umlauten in
	# Anführungszeichen und Oktal-Escapes ("assets/music/Festliche Br\303\274cke.mp3"),
	# und sha1sum sucht danach eine Datei, die es so nicht gibt (Deploy v206).
	git -c core.quotepath=false ls-files | grep -vE "$NICHT_AUF_DEN_SERVER" > build/deploy_liste.txt
	tr '\n' '\0' < build/deploy_liste.txt | xargs -0 sha1sum -b | sort > build/deploy_lokal.sha1
	# Fehlende Dateien liefern keine Zeile — genau das wollen wir
	ssh_server "cd '$QUELLEN' && xargs -d '\n' sha1sum -b 2>/dev/null" < build/deploy_liste.txt \
		| sort > build/deploy_server.sha1 || true
	comm -23 build/deploy_lokal.sha1 build/deploy_server.sha1 | cut -c43- > build/deploy_geaendert.txt
	GEAENDERT="$(wc -l < build/deploy_geaendert.txt | tr -d ' ')"
	echo "$GEAENDERT von $(wc -l < build/deploy_liste.txt | tr -d ' ') Dateien auf dem Server fehlen oder weichen ab"
	head -15 build/deploy_geaendert.txt | sed 's/^/  /'
	[ "$GEAENDERT" -gt 15 ] && echo "  … (vollständig in build/deploy_geaendert.txt)"
	# Nur melden, nie löschen: Dateien auf dem Server, die es im Git nicht gibt
	ssh_server "cd '$QUELLEN' && find scripts scenes autoload locale assets -type f 2>/dev/null" \
		| sort > build/deploy_server_dateien.txt || true
	sort build/deploy_liste.txt | comm -13 - build/deploy_server_dateien.txt > build/deploy_uebrig.txt
	UEBRIG="$(wc -l < build/deploy_uebrig.txt | tr -d ' ')"
	[ "$UEBRIG" -gt 0 ] && echo "Hinweis: $UEBRIG Dateien liegen nur auf dem Server (bleiben liegen, siehe build/deploy_uebrig.txt)"
	return 0
}

if [ "$PROBE" = 1 ]; then
	schritt "Abgleich Serverquellen (nur prüfen)"
	abgleich
	echo; echo "PROBE FERTIG — nichts verändert."
	exit 0
fi

# ------------------------------------------------------------------ 2 Test aus dem Paket
schritt "2/8 Test-Paket mit tools/ exportieren und prüfen"
cp export_presets.cfg build/export_presets.cfg.bak
# Das Preset muss in jedem Fall wieder hergestellt werden, auch bei Abbruch
trap 'cp build/export_presets.cfg.bak export_presets.cfg' EXIT
sed -i 's#exclude_filter="tools/\*"#exclude_filter=""#' export_presets.cfg
rm -f build/test.pck
"$GODOT" --headless --path . --export-pack "$PRESET" build/test.pck > build/deploy_export_test.log 2>&1 || true
cp build/export_presets.cfg.bak export_presets.cfg
grep -q 'exclude_filter="tools/\*"' export_presets.cfg || abbruch "Preset nicht wiederhergestellt."
[ -s build/test.pck ] || abbruch "Test-Paket nicht exportiert (build/deploy_export_test.log)."
timeout 600 "$GODOT" --headless --main-pack build/test.pck res://tools/test_phase1.tscn > build/deploy_test.log 2>&1 || true
if ! grep -q "ERGEBNIS: BESTANDEN" build/deploy_test.log; then
	grep -E "FAIL|SCRIPT ERROR|Parse Error|ERGEBNIS" build/deploy_test.log | head -20
	abbruch "Test aus dem exportierten Paket nicht bestanden (build/deploy_test.log)."
fi
grep -E "ERGEBNIS" build/deploy_test.log

# ------------------------------------------------------------------ 3 Release-Pakete
schritt "3/8 Release-Pakete exportieren"
# Braucht inhalt.pck überhaupt einen neuen Stand? Maßgeblich sind die Blob-Hashes
# der großen Ordner aus dem Git-Index — deterministisch, anders als der Export
# selbst. Der Server merkt sich den zuletzt ausgelieferten Wert in inhalt.quelle.
INHALT_QUELLE="$(git -c core.quotepath=false ls-files -s $GROSS_ORDNER | sha1sum | cut -c1-40)"
INHALT_SERVER="$(ssh_server "cat '$WEB/inhalt.quelle' 2>/dev/null" || true)"
if [ "$INHALT_QUELLE" = "$INHALT_SERVER" ] && [ "$LIVE_INHALT" -gt 0 ]; then
	INHALT_NEU=0
	INHALT_VERSION="$LIVE_INHALT"
	echo "inhalt.pck unverändert (v$INHALT_VERSION) — wird nicht neu gebaut"
else
	INHALT_NEU=1
	INHALT_VERSION="$VERSION"
	echo "inhalt.pck muss neu (Quelle $INHALT_QUELLE, Server ${INHALT_SERVER:-keine})"
fi

# spiel.pck: alles außer den großen Ordnern. Wird über inhalt.pck gelegt und
# gewinnt bei Dateien, die in beiden stecken (scripts/boot.gd lädt in der
# Reihenfolge inhalt, spiel).
rm -f build/spiel.pck
sed -i "s#exclude_filter=\"tools/\*\"#exclude_filter=\"tools/*,$GROSS\"#" export_presets.cfg
"$GODOT" --headless --path . --export-pack "$PRESET" build/spiel.pck > build/deploy_export.log 2>&1 || true
cp build/export_presets.cfg.bak export_presets.cfg
grep -q 'exclude_filter="tools/\*"' export_presets.cfg || abbruch "Preset nicht wiederhergestellt."
[ -s build/spiel.pck ] || abbruch "spiel.pck nicht exportiert (build/deploy_export.log)."
SHA="$(sha256sum build/spiel.pck | cut -c1-64)"
echo "spiel.pck $(stat -c %s build/spiel.pck) Bytes · sha256 $SHA"

if [ "$INHALT_NEU" = 1 ] || [ "$ALTPAKET" = 1 ]; then
	rm -f build/inhalt.pck
	"$GODOT" --headless --path . --export-pack "$PRESET" build/inhalt.pck > build/deploy_export_inhalt.log 2>&1 || true
	[ -s build/inhalt.pck ] || abbruch "inhalt.pck nicht exportiert (build/deploy_export_inhalt.log)."
	SHA_INHALT="$(sha256sum build/inhalt.pck | cut -c1-64)"
	echo "inhalt.pck $(stat -c %s build/inhalt.pck) Bytes · sha256 $SHA_INHALT"
fi

# ------------------------------------------------------------------ 4 Abgleich
schritt "4/8 Serverquellen abgleichen"
abgleich

# ------------------------------------------------------------------ 5 Server
schritt "5/8 Serverquellen einspielen und importieren"
if [ "$GEAENDERT" -gt 0 ]; then
	tar -czf build/deploy_quellen.tgz -T build/deploy_geaendert.txt
	scp_server build/deploy_quellen.tgz build/deploy_geaendert.txt "$SERVER:/tmp/"
fi
ssh_server bash -s -- "$QUELLEN" "$GODOT_SERVER" "$LIVE" "$GEAENDERT" <<'SERVER_EOF'
set -euo pipefail
QUELLEN="$1"; GODOT="$2"; ALT="$3"; ANZAHL="$4"
cd "$QUELLEN"
if [ "$ANZAHL" -gt 0 ]; then
	mkdir -p /opt/_deploy_sicherung
	# Nur sichern, was es schon gibt und gleich überschrieben wird
	vorhanden="$(mktemp)"
	while IFS= read -r f; do [ -f "$f" ] && echo "$f"; done < /tmp/deploy_geaendert.txt > "$vorhanden"
	if [ -s "$vorhanden" ]; then
		tar -czf "/opt/_deploy_sicherung/vor_v${ALT}_$(date +%Y%m%d_%H%M%S).tgz" -T "$vorhanden"
	fi
	# --no-same-owner: das Archiv trägt Windows-Benutzerkennungen, die das
	# Server-Dateisystem ablehnt — sonst endet tar mit Fehler (Deploy v104)
	tar --no-same-owner -xzf /tmp/deploy_quellen.tgz
	echo "$ANZAHL Dateien eingespielt"
fi
for lauf in 1 2; do
	timeout 600 "$GODOT" --headless --path . --import > "/tmp/deploy_import_$lauf.log" 2>&1 || true
done
# Der erste Lauf meldet bei neuen Dateien fehlende Importe — zählt nur der zweite
FEHLER="$(grep -cE 'SCRIPT ERROR|Parse Error' /tmp/deploy_import_2.log || true)"
echo "Skriptfehler im Import: $FEHLER"
[ "$FEHLER" = 0 ] || { grep -E 'SCRIPT ERROR|Parse Error' /tmp/deploy_import_2.log | head -10; exit 1; }
SERVER_EOF

# ------------------------------------------------------------------ 6 Paket hochladen
schritt "6/8 Spieler-Pakete hochladen und prüfen"
printf '{"version": %s, "spiel": %s, "inhalt": %s}' "$UEBERGANG" "$VERSION" "$INHALT_VERSION" > build/version.json
scp_server build/spiel.pck "$SERVER:$WEB/spiel.pck.neu"
scp_server build/version.json "$SERVER:$WEB/version.json.neu"
SHA_SERVER="$(ssh_server "sha256sum '$WEB/spiel.pck.neu' | cut -c1-64")"
[ "$SHA" = "$SHA_SERVER" ] || abbruch "Prüfsumme von spiel.pck weicht ab — nichts getauscht."
echo "spiel.pck: Prüfsumme stimmt"
if [ "$INHALT_NEU" = 1 ] || [ "$ALTPAKET" = 1 ]; then
	scp_server build/inhalt.pck "$SERVER:$WEB/inhalt.pck.neu"
	SHA_INHALT_SERVER="$(ssh_server "sha256sum '$WEB/inhalt.pck.neu' | cut -c1-64")"
	[ "$SHA_INHALT" = "$SHA_INHALT_SERVER" ] || abbruch "Prüfsumme von inhalt.pck weicht ab — nichts getauscht."
	echo "inhalt.pck: Prüfsumme stimmt"
fi

# ------------------------------------------------------------------ 7 Tauschen und neu starten
schritt "7/8 Tauschen, version.json, Server neu starten"
ssh_server bash -s -- "$WEB" "$INHALT_NEU" "$ALTPAKET" "$INHALT_QUELLE" <<'SERVER_EOF'
set -euo pipefail
WEB="$1"; INHALT_NEU="$2"; ALTPAKET="$3"; INHALT_QUELLE="$4"
cd "$WEB"
chown www-data:www-data spiel.pck.neu version.json.neu
# Reihenfolge: erst die Pakete, dann die Version — sonst lädt ein Spieler eine
# halbe Datei und merkt sich trotzdem die neue Nummer
if [ -f inhalt.pck.neu ]; then
	chown www-data:www-data inhalt.pck.neu
	mv inhalt.pck.neu inhalt.pck
fi
mv spiel.pck.neu spiel.pck
if [ "$INHALT_NEU" = 1 ]; then
	echo -n "$INHALT_QUELLE" > inhalt.quelle
fi
# Einmal beim Übergang: das alte Einzelpaket auf denselben Stand bringen, damit
# alte .exe es noch einmal ziehen und dann den Hinweis zum Neu-Herunterladen
# zeigen. Danach bleibt game.pck unberührt liegen.
if [ "$ALTPAKET" = 1 ]; then
	cp inhalt.pck game.pck.neu
	chown www-data:www-data game.pck.neu
	mv game.pck.neu game.pck
	echo "game.pck für alte .exe aufgefrischt"
fi
mv version.json.neu version.json
cat version.json; echo
START="$(date +%s)"
systemctl restart oktoberfest
for i in $(seq 1 60); do
	journalctl -u oktoberfest --since "@$START" --no-pager | grep -q "DEDICATED" && break
	sleep 1
done
systemctl is-active oktoberfest
journalctl -u oktoberfest --since "@$START" --no-pager | grep "DEDICATED" | tail -1
# Laufende Code-Spiele haben den alten Stand im Speicher — speichern sich beim
# Beenden nicht, darum nur beenden, wenn niemand drin ist, sonst Hinweis
for e in $(systemctl list-units 'sloptoberfest-spiel-*' --no-legend --plain | awk '{print $1}'); do
	echo "Hinweis: Code-Spiel $e läuft noch mit altem Stand (endet von selbst, wenn alle raus sind)"
done
FEHLER="$(journalctl -u oktoberfest --since "@$START" --no-pager | grep -cE 'SCRIPT ERROR|Parse Error' || true)"
echo "Skriptfehler seit Neustart: $FEHLER"
[ "$FEHLER" = 0 ]
SERVER_EOF

# Vermittler für Warteräume (tools/server/vermittler.py) nur bei Änderung neu starten
scp_server tools/server/vermittler.py "$SERVER:/tmp/vermittler.neu.py"
ssh_server 'cmp -s /tmp/vermittler.neu.py /opt/sloptoberfest-vermittler/vermittler.py || { install -m 755 /tmp/vermittler.neu.py /opt/sloptoberfest-vermittler/vermittler.py && systemctl restart sloptoberfest-vermittler && echo "Vermittler aktualisiert"; }; systemctl is-active sloptoberfest-vermittler'

# ------------------------------------------------------------------ 8 Nachprüfen
schritt "8/8 Über HTTPS nachprüfen"
VJSON_NEU="$(curl -fsS "$URL/version.json")"
feld_neu() { echo "$VJSON_NEU" | sed -nE "s/.*\"$1\"[: ]*([0-9]+).*/\1/p"; }
[ "$(feld_neu spiel)" = "$VERSION" ] || abbruch "version.json über HTTPS meldet spiel $(feld_neu spiel) statt $VERSION."
[ "$(feld_neu inhalt)" = "$INHALT_VERSION" ] || abbruch "version.json über HTTPS meldet inhalt $(feld_neu inhalt) statt $INHALT_VERSION."
# spiel.pck ganz nachrechnen — bei rund 60 MB ist das in Sekunden erledigt.
SHA_HTTPS="$(curl -fsS "$URL/spiel.pck" | sha256sum | cut -c1-64)"
[ "$SHA_HTTPS" = "$SHA" ] || abbruch "spiel.pck über HTTPS weicht ab."
# inhalt.pck nur auf Länge prüfen: die Prüfsumme stand schon auf dem Server fest,
# und die Datei noch einmal zu ziehen wären 815 MB für nichts.
LAENGE="$(curl -fsSI "$URL/inhalt.pck" | sed -nE 's/^[Cc]ontent-[Ll]ength: *([0-9]+).*/\1/p' | tr -d '\r')"
[ -n "$LAENGE" ] && [ "$LAENGE" -gt 0 ] || abbruch "inhalt.pck ist über HTTPS nicht erreichbar."
if [ "$INHALT_NEU" = 1 ] || [ "$ALTPAKET" = 1 ]; then
	[ "$LAENGE" = "$(stat -c %s build/inhalt.pck)" ] || abbruch "inhalt.pck über HTTPS hat $LAENGE Bytes statt $(stat -c %s build/inhalt.pck)."
fi
echo "version.json: spiel $VERSION · inhalt $INHALT_VERSION · spiel.pck $SHA_HTTPS · inhalt.pck $LAENGE Bytes"

# ------------------------------------------------------------------ Download-ZIP
if [ "$MIT_ZIP" = 1 ]; then
	schritt "ZIP: aktuelle .exe bauen, hochladen, auf der Download-Seite verlinken"
	ZIP_NAME="OktoberfestSimulator_v$VERSION.zip"
	rm -rf build/zip "build/$ZIP_NAME"
	mkdir -p build/zip
	"$GODOT" --headless --path . --export-release "$PRESET" build/zip/OktoberfestSimulator.exe > build/deploy_export_exe.log 2>&1 || true
	[ -s build/zip/OktoberfestSimulator.exe ] || abbruch "exe-Export fehlgeschlagen (build/deploy_export_exe.log)."
	ls build/zip
	powershell -NoProfile -Command "Compress-Archive -Path 'build/zip/*' -DestinationPath 'build/$ZIP_NAME' -Force"
	[ -s "build/$ZIP_NAME" ] || abbruch "ZIP nicht erstellt."
	ZIP_SHA="$(sha256sum "build/$ZIP_NAME" | cut -c1-64)"
	scp_server "build/$ZIP_NAME" "$SERVER:$WEB/$ZIP_NAME.neu"
	[ "$(ssh_server "sha256sum '$WEB/$ZIP_NAME.neu' | cut -c1-64")" = "$ZIP_SHA" ] || abbruch "ZIP-Prüfsumme auf dem Server weicht ab."
	ssh_server bash -s -- "$WEB" "$ZIP_NAME" "$VERSION" <<'SERVER_EOF'
set -euo pipefail
WEB="$1"; ZIP="$2"; VERSION="$3"
cd "$WEB"
chown www-data:www-data "$ZIP.neu"
mv "$ZIP.neu" "$ZIP"
# Link und Versionsangabe auf der Download-Seite umstellen (Sicherung daneben)
cp index.html "index.html.vor_v$VERSION"
sed -i -E "s/OktoberfestSimulator_v[0-9]+\.zip/$ZIP/g; s/· v[0-9]+</· v$VERSION</g" index.html
grep -o "href=\"[^\"]*zip\"" index.html
SERVER_EOF
	ZIP_HTTPS="$(curl -fsS "$URL/$ZIP_NAME" | sha256sum | cut -c1-64)"
	[ "$ZIP_HTTPS" = "$ZIP_SHA" ] || abbruch "ZIP über HTTPS weicht ab."
	curl -fsS "$URL/" | grep -q "$ZIP_NAME" || abbruch "Download-Seite verlinkt $ZIP_NAME nicht."
	echo "ZIP $ZIP_NAME online und verlinkt"
fi
git tag -f "deploy-v$VERSION" > /dev/null
git push -q -f origin "deploy-v$VERSION"
echo; echo "DEPLOY v$VERSION FERTIG ($COMMIT)"
