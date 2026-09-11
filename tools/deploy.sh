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
#   3 Release-Paket exportieren
#   4 Serverquellen per Prüfsumme abgleichen — nur Abweichendes wird übertragen
#   5 Server: überschriebene Dateien sichern, entpacken, zweimal importieren
#   6 Paket als game.pck.neu hochladen, Prüfsumme vergleichen
#   7 erst dann tauschen, dann version.json, Dienst neu starten, Journal prüfen
#   8 über HTTPS nachprüfen, Git-Tag deploy-v<Version>
#
# Warum: Beim Handdeploy fehlten einmal vier Stand-Modelle zwei Tage auf dem
# Server, ein andermal war version.json durch Anführungszeichen zerschossen.
# Bash statt PowerShell, weil PowerShell 5.1 Anführungszeichen an ssh verfälscht.

set -euo pipefail

SERVER="root@185.248.140.225"
SCHLUESSEL="$HOME/.ssh/id_vapur_admin"
WEB="/var/www/survival"
QUELLEN="/opt/oktoberfest"
GODOT_SERVER="/opt/godot/Godot_v4.7.2-stable_linux.x86_64"
URL="https://survival.vapur-it.de"
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
PRESET="Windows Desktop"
# Was der Server nicht braucht (Werkzeuge, Doku, Build-Ausgaben)
NICHT_AUF_DEN_SERVER='^(docs|tools|build)/|^\.git'

PROBE=0
[ "${1:-}" = "--probe" ] && PROBE=1

cd "$(dirname "$0")/.."
mkdir -p build

ssh_server() { ssh -i "$SCHLUESSEL" -o BatchMode=yes "$SERVER" "$@"; }
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
LIVE="$(curl -fsS "$URL/version.json" | tr -cd '0-9')"
echo "Commit $COMMIT · Version lokal $VERSION · live $LIVE"
# In git lfs ls-files steht "-" statt "*", wenn nur der Zeiger ausgecheckt ist
if git lfs ls-files | grep -q ' - '; then
	abbruch "LFS-Dateien nur als Zeiger vorhanden — git lfs pull."
fi
if [ "$PROBE" = 0 ] && [ "$VERSION" -le "$LIVE" ]; then
	abbruch "Version $VERSION ist nicht neuer als live ($LIVE) — project.godot hochzählen."
fi

# ------------------------------------------------------------------ 4 Abgleich (auch für --probe)
abgleich() {
	git ls-files | grep -vE "$NICHT_AUF_DEN_SERVER" > build/deploy_liste.txt
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

# ------------------------------------------------------------------ 3 Release-Paket
schritt "3/8 Release-Paket exportieren"
rm -f build/game.pck
"$GODOT" --headless --path . --export-pack "$PRESET" build/game.pck > build/deploy_export.log 2>&1 || true
[ -s build/game.pck ] || abbruch "Release-Paket nicht exportiert (build/deploy_export.log)."
SHA="$(sha256sum build/game.pck | cut -c1-64)"
echo "game.pck $(stat -c %s build/game.pck) Bytes · sha256 $SHA"

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
	tar -xzf /tmp/deploy_quellen.tgz
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
schritt "6/8 Spieler-Paket hochladen und prüfen"
printf '{"version": %s}' "$VERSION" > build/version.json
scp_server build/game.pck "$SERVER:$WEB/game.pck.neu"
scp_server build/version.json "$SERVER:$WEB/version.json.neu"
SHA_SERVER="$(ssh_server "sha256sum '$WEB/game.pck.neu' | cut -c1-64")"
[ "$SHA" = "$SHA_SERVER" ] || abbruch "Prüfsumme auf dem Server weicht ab — nichts getauscht."
echo "Prüfsumme stimmt"

# ------------------------------------------------------------------ 7 Tauschen und neu starten
schritt "7/8 Tauschen, version.json, Server neu starten"
ssh_server bash -s -- "$WEB" <<'SERVER_EOF'
set -euo pipefail
WEB="$1"
cd "$WEB"
chown www-data:www-data game.pck.neu version.json.neu
# Reihenfolge: erst das Paket, dann die Version — sonst laden Spieler eine halbe Datei
mv game.pck.neu game.pck
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
FEHLER="$(journalctl -u oktoberfest --since "@$START" --no-pager | grep -cE 'SCRIPT ERROR|Parse Error' || true)"
echo "Skriptfehler seit Neustart: $FEHLER"
[ "$FEHLER" = 0 ]
SERVER_EOF

# ------------------------------------------------------------------ 8 Nachprüfen
schritt "8/8 Über HTTPS nachprüfen"
LIVE_NEU="$(curl -fsS "$URL/version.json" | tr -cd '0-9')"
SHA_HTTPS="$(curl -fsS "$URL/game.pck" | sha256sum | cut -c1-64)"
echo "version.json: $LIVE_NEU · game.pck: $SHA_HTTPS"
[ "$LIVE_NEU" = "$VERSION" ] || abbruch "version.json über HTTPS ist $LIVE_NEU statt $VERSION."
[ "$SHA_HTTPS" = "$SHA" ] || abbruch "game.pck über HTTPS weicht ab."
git tag -f "deploy-v$VERSION" > /dev/null
git push -q -f origin "deploy-v$VERSION"
echo; echo "DEPLOY v$VERSION FERTIG ($COMMIT)"
