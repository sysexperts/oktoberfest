#!/usr/bin/env bash
# Netztest (Plan 5.5): startet einen dedizierten Server auf 127.0.0.1 und einen
# Test-Client (tools/test_netz.tscn), beendet den Server mitten im Spiel und
# prüft, dass der Client sauber mit Meldung im Menü landet.
#
#   bash tools/test_netz.sh
#
# Der dedizierte Server speichert in denselben Ordner wie das echte Spiel —
# Spielstände und Einstellungen werden deshalb vorher gesichert und am Ende
# (auch bei Abbruch) zurückgespielt.

set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
DATEN="$APPDATA/Godot/app_userdata/Oktoberfest Simulator"
SICHERUNG="build/netztest_sicherung"
SERVER_LOG="build/netztest_server.log"
CLIENT_LOG="build/netztest_client.log"

rm -rf "$SICHERUNG"
mkdir -p "$SICHERUNG"
[ -d "$DATEN/saves" ] && cp -r "$DATEN/saves" "$SICHERUNG/"
[ -f "$DATEN/einstellungen.cfg" ] && cp "$DATEN/einstellungen.cfg" "$SICHERUNG/"

SERVER_PID=""
CLIENT_PID=""
aufraeumen() {
	[ -n "$SERVER_PID" ] && kill "$SERVER_PID" 2>/dev/null || true
	[ -n "$CLIENT_PID" ] && kill "$CLIENT_PID" 2>/dev/null || true
	sleep 1
	rm -rf "$DATEN/saves"
	[ -d "$SICHERUNG/saves" ] && cp -r "$SICHERUNG/saves" "$DATEN/"
	[ -f "$SICHERUNG/einstellungen.cfg" ] && cp "$SICHERUNG/einstellungen.cfg" "$DATEN/"
	echo "Spielstände und Einstellungen zurückgespielt"
}
trap aufraeumen EXIT

warte_auf() {  # Datei, Muster, Sekunden
	for _ in $(seq 1 "$3"); do
		grep -q "$2" "$1" 2>/dev/null && return 0
		sleep 1
	done
	return 1
}

echo "=== Server starten (nur 127.0.0.1)"
"$GODOT" --headless --path . -- --server --nur-lokal > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!
warte_auf "$SERVER_LOG" "DEDICATED" 90 || { tail -20 "$SERVER_LOG"; echo "Server kam nicht hoch"; exit 1; }
grep "DEDICATED" "$SERVER_LOG"

echo "=== Client starten"
"$GODOT" --headless --path . res://tools/test_netz.tscn > "$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!
if warte_auf "$CLIENT_LOG" "BEREIT" 150; then
	echo "=== Client ist im Spiel — Server wird beendet"
	kill "$SERVER_PID" 2>/dev/null || true
	SERVER_PID=""
fi
for _ in $(seq 1 90); do
	grep -q "ERGEBNIS" "$CLIENT_LOG" 2>/dev/null && break
	sleep 1
done
grep -E "^\s+--|\[OK|\[FAIL|ERGEBNIS|SCRIPT ERROR|Parse Error" "$CLIENT_LOG" || true
echo "--- Server-Log (Fehler):"
grep -E "SCRIPT ERROR|Parse Error" "$SERVER_LOG" | head -5 || true
grep -q "ERGEBNIS: BESTANDEN" "$CLIENT_LOG"
