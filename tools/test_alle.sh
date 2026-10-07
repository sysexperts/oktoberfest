#!/bin/bash
# Lässt alle Story- und Systemtests nacheinander laufen und zeigt eine Übersicht.
#   bash tools/test_alle.sh            (alle)
#   bash tools/test_alle.sh kapitel    (nur Tests, deren Name "kapitel" enthält)
# Godot-Pfad aus der Umgebung (GODOT) oder der übliche Pfad auf diesem Rechner.
GODOT="${GODOT:-C:/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
TESTS="test_story test_kapitel2 test_kapitel3 test_kapitel4 test_kapitel5 test_gefallen test_wohnwagen test_braeumeister test_streiche test_kontrolle test_fakes test_abwerben test_gustav test_sabotage test_blackjack test_happyhour test_fest test_meister test_wagen test_ausbau test_kirmesquests test_meilensteine test_gaeste test_zwischenfaelle test_personal"
cd "$(dirname "$0")/.." || exit 1
"$GODOT" --headless --import > /dev/null 2>&1
ok=0
fehl=0
for t in $TESTS; do
	if [ -n "$1" ] && [[ "$t" != *"$1"* ]]; then
		continue
	fi
	ausgabe=$(timeout 300 "$GODOT" --headless --path . "res://tools/$t.tscn" 2>&1)
	if echo "$ausgabe" | grep -q "ERGEBNIS: OK\|ERGEBNIS: BESTANDEN" && ! echo "$ausgabe" | grep -q "\[FAIL\]"; then
		echo "OK    $t"
		ok=$((ok + 1))
	else
		echo "FAIL  $t"
		echo "$ausgabe" | grep "FAIL\|SCRIPT ERROR" | head -3 | sed 's/^/        /'
		fehl=$((fehl + 1))
	fi
done
echo "----"
echo "Gesamt: $ok ok, $fehl fehlgeschlagen"
[ "$fehl" -eq 0 ]
