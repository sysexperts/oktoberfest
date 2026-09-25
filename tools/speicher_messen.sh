#!/usr/bin/env bash
# Speicher- und Rechenlast des Bots ueber eine ganze Saison messen.
#
#   bash tools/speicher_messen.sh [tage]     (Vorgabe 20)
#
# Warum extern gemessen wird: OS.get_static_memory_usage() aus dem Spiel heraus
# zeigt nur Godots eigene Allokationen. Der Prozess belegte bei Tag 21 aber 3 GB,
# waehrend die Zahl aus dem Spiel bei 1,4 GB stand — der Rest steckt in
# Texturen, Treiberpuffern und allem, was Godot nicht selbst zaehlt.
#
# Ergebnis: build/speicher_kurve.csv (Sekunde, MB, CPU-Sekunden)
#           build/speicher_lauf.txt  (Ausgabe des Bots)

set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/Users/vase/OneDrive - Intelego GmbH/Desktop/Godot.exe}"
TAGE="${1:-20}"
mkdir -p build
echo "sekunde,speicher_mb,cpu_s" > build/speicher_kurve.csv

"$GODOT" --headless --path . res://tools/sim_saison.tscn -- --tage "$TAGE" > build/speicher_lauf.txt 2>&1 &
GODOT_PID=$!

START=$(date +%s)
while kill -0 "$GODOT_PID" 2>/dev/null; do
	powershell -NoProfile -Command "
		\$p = Get-Process Godot -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending | Select-Object -First 1
		# Ganze Zahlen: auf einem deutschen Windows schreibt PowerShell sonst ein
		# Dezimalkomma und zerlegt damit die CSV-Spalten.
		if (\$p) { '{0},{1}' -f [int](\$p.WorkingSet64/1MB), [int]\$p.TotalProcessorTime.TotalSeconds }
	" 2>/dev/null | tr -d '\r' | while read -r ZEILE; do
		[ -n "$ZEILE" ] && echo "$(( $(date +%s) - START )),$ZEILE" >> build/speicher_kurve.csv
	done
	sleep 20
done
wait "$GODOT_PID"
echo "fertig — $(wc -l < build/speicher_kurve.csv) Messpunkte"
grep -E "Tag [0-9]+ ·" build/speicher_lauf.txt | tail -3
