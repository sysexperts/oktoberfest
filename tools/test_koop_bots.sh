#!/usr/bin/env bash
# Koop-Probelauf mit vier Bots gegen den LIVE-Server (Vermittler + Code-Spiel):
# Warteraum, Zelt, Tische, Ware, Teamleiter-Sperre, Abstimmung Nein/Ja, Schicht
# mit Gästen, Rausfliegen und Wiederbeitritt per Code. Siehe tools/test_koop_bot.gd.
#
#   bash tools/test_koop_bots.sh
#
# Dauert etwa 4 Minuten. Die Bots speichern nichts lokal (Clients speichern nie),
# das Code-Spiel auf dem Server beendet sich 5 Minuten nach dem Test von selbst.

set -uo pipefail
cd "$(dirname "$0")/.."
mkdir -p build/bots
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
SSH=(ssh -i "$HOME/.ssh/id_vapur_admin" -o BatchMode=yes root@185.248.140.225)
CODE_DATEI="build/bots/code.txt"
rm -f build/bots/*

PIDS=()
for bot in chef koch lager putz; do
	"$GODOT" --headless --path . res://tools/test_koop_bot.tscn -- --bot "$bot" --datei "$(pwd)/$CODE_DATEI" > "build/bots/$bot.log" 2>&1 &
	PIDS+=($!)
done
trap 'kill "${PIDS[@]}" 2>/dev/null || true' EXIT
echo "Bots gestartet: ${PIDS[*]}"
for pid in "${PIDS[@]}"; do wait "$pid"; done

echo
for bot in chef koch lager putz; do
	grep -E "\[(OK  |FAIL)\]|ERGEBNIS|ABBRUCH|^\[$bot\] (Code|Geld|--)" "build/bots/$bot.log"
	echo "[$bot] Skriptfehler: $(grep -cE 'SCRIPT ERROR|Parse Error' "build/bots/$bot.log")"
	grep -E -A2 "SCRIPT ERROR" "build/bots/$bot.log" | head -12
	echo
done

CODE="$(cat "$CODE_DATEI" 2>/dev/null)"
if [ -n "$CODE" ]; then
	EINHEIT="sloptoberfest-spiel-$(echo "$CODE" | tr -d '-' | tr 'A-Z' 'a-z')"
	echo "=== Server-Log $EINHEIT"
	"${SSH[@]}" "journalctl -u $EINHEIT --no-pager | grep -E 'DEDICATED|SCRIPT ERROR|ERROR' | grep -v 'Unable to send packet\|invalid UID' | head -20; echo \"Skriptfehler: \$(journalctl -u $EINHEIT --no-pager | grep -c 'SCRIPT ERROR')\""
fi

FEHLER=0
for bot in chef koch lager putz; do
	grep -q "ERGEBNIS: BESTANDEN" "build/bots/$bot.log" || FEHLER=$((FEHLER + 1))
	[ "$(grep -cE 'SCRIPT ERROR|Parse Error' "build/bots/$bot.log")" = 0 ] || FEHLER=$((FEHLER + 1))
done
echo
echo "GESAMT: $([ "$FEHLER" = 0 ] && echo BESTANDEN || echo FEHLGESCHLAGEN) ($FEHLER)"
[ "$FEHLER" = 0 ]
