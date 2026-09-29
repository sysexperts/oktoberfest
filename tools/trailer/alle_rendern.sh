#!/usr/bin/env bash
# Legt die Szenen aus szenen_plan.py an, prüft jede Kamerafahrt (bei Problemen
# schrittweise höher, bis zu 4 Versuche) und rendert sie in build/trailer/clips.
#   bash tools/trailer/alle_rendern.sh            alle aus dem Plan
#   bash tools/trailer/alle_rendern.sh 05 09      nur diese
set -uo pipefail
cd "$(dirname "$0")/../.."
NRN="${*:-$(python -c "import sys; sys.path.insert(0,'tools/trailer'); import szenen_plan as p; print(' '.join(sorted(p.SZENEN)))")}"
for NR in $NRN; do
	HOEHER=0
	OK=0
	for VERSUCH in 1 2 3 4 5; do
		python tools/trailer/szenen_plan.py "$NR" --hoeher "$HOEHER" > /dev/null
		ERG="$(bash tools/trailer/pruefen.sh "$NR")"
		if echo "$ERG" | grep -q "PRUEFUNG: SAUBER"; then OK=1; break; fi
		echo "szene_$NR (+${HOEHER} m): $(echo "$ERG" | grep -c '^  t=') Stellen"
		HOEHER=$(awk "BEGIN{print $HOEHER + 1.5}")
	done
	if [ "$OK" = 1 ]; then
		echo "szene_$NR sauber (+${HOEHER} m) — rendere"
		bash tools/trailer/render.sh "$NR" | tail -1
	else
		echo "szene_$NR NICHT sauber, trotzdem gerendert (Stellen siehe oben)"
		bash tools/trailer/render.sh "$NR" | tail -1
	fi
done
echo "ALLE FERTIG"
