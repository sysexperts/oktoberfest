#!/usr/bin/env bash
# Alle Testszenen nacheinander laufen lassen und das Ergebnis sammeln.
#
#   bash tools/alle_tests.sh              # alle
#   bash tools/alle_tests.sh test_huber   # nur diese
#
# Jede Szene laeuft headless mit eigenem Zeitlimit. Ausgaben landen einzeln in
# build/tests/<name>.log, die Zusammenfassung in build/tests/ergebnis.txt.
#
# Als bestanden gilt eine Szene, wenn ihre Ausgabe "ERGEBNIS: BESTANDEN" oder
# "ERGEBNIS: OK" enthaelt und kein "SCRIPT ERROR" auftaucht. Szenen ohne
# Ergebniszeile sind Sichtproben — sie werden als "ohne Urteil" gefuehrt, zaehlen
# aber als Fehler, sobald ein SCRIPT ERROR darin steht.

set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
ZEITLIMIT="${ZEITLIMIT:-420}"
AUS="build/tests"
mkdir -p "$AUS"
: > "$AUS/ergebnis.txt"

# Diese brauchen einen zweiten Prozess oder einen laufenden Server und werden
# hier uebersprungen — sie haben eigene Skripte (test_netz.sh, test_koop_bots.sh).
UEBERSPRINGEN="test_netz test_live_beitritt test_code_beitritt test_koop_bot"

if [ $# -gt 0 ]; then
	SZENEN="$*"
else
	SZENEN="$(ls tools/test_*.tscn | sed 's|tools/||;s|\.tscn||' | tr '\n' ' ')"
fi

GESAMT=0; GUT=0; SCHLECHT=0; UEBER=0
for T in $SZENEN; do
	case " $UEBERSPRINGEN " in
		*" $T "*)
			printf '%-22s uebersprungen (braucht Netz)\n' "$T" | tee -a "$AUS/ergebnis.txt"
			UEBER=$((UEBER+1)); continue;;
	esac
	GESAMT=$((GESAMT+1))
	LOG="$AUS/$T.log"
	timeout "$ZEITLIMIT" "$GODOT" --headless --path . "res://tools/$T.tscn" > "$LOG" 2>&1
	CODE=$?
	# Sichtproben speichern Bildschirmfotos. Headless gibt es keinen Bildinhalt,
	# also schlaegt save_png fehl — das ist kein Defekt des Spiels, sondern der
	# Preis dafuer, dass diese Tests hier ohne Fenster laufen.
	FEHLER="$(grep "SCRIPT ERROR" "$LOG" | grep -vc "save_png")"
	if grep -qE "ERGEBNIS: (BESTANDEN|OK)" "$LOG" && [ "$FEHLER" -eq 0 ]; then
		URTEIL="bestanden"
	elif grep -q "ERGEBNIS:" "$LOG"; then
		URTEIL="FEHLGESCHLAGEN — $(grep -m1 'ERGEBNIS:' "$LOG" | cut -c1-60)"
	elif [ "$CODE" -eq 124 ]; then
		URTEIL="ABBRUCH nach ${ZEITLIMIT}s"
	elif [ "$FEHLER" -gt 0 ]; then
		URTEIL="FEHLGESCHLAGEN — $FEHLER Skriptfehler"
	else
		URTEIL="ohne Urteil (Sichtprobe)"
	fi
	[ "$FEHLER" -gt 0 ] && URTEIL="$URTEIL, $FEHLER Skriptfehler"
	case "$URTEIL" in
		bestanden*|"ohne Urteil"*) GUT=$((GUT+1));;
		*) SCHLECHT=$((SCHLECHT+1));;
	esac
	printf '%-22s %s\n' "$T" "$URTEIL" | tee -a "$AUS/ergebnis.txt"
done

echo "" | tee -a "$AUS/ergebnis.txt"
echo "$GUT von $GESAMT in Ordnung, $SCHLECHT mit Befund, $UEBER uebersprungen" | tee -a "$AUS/ergebnis.txt"
[ "$SCHLECHT" -eq 0 ]
