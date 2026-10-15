"""Hängt Übersetzungen an locale/texte.csv an, ohne den Rest umzuformatieren:
python -X utf8 tools/texte_hinzu.py datei.py   (Datei definiert NEU = [(key, de, en, tr), ...]; vorhandene Schlüssel werden ersetzt)"""
import sys
pfad = "locale/texte.csv"
ns = {}
exec(open(sys.argv[1], encoding="utf-8").read(), ns)
neu = {n[0]: n for n in ns["NEU"]}

def feld(t):
    return '"' + t.replace('"', '""') + '"' if any(c in t for c in ',"\n') else t

def zeile(n):
    return ",".join(feld(x) for x in n)

roh = open(pfad, encoding="utf-8", newline="").read()
zeilen = roh.split("\r\n")
aus = []
for z in zeilen:
    k = z.split(",", 1)[0]
    if k in neu:
        aus.append(zeile(neu.pop(k)))
    else:
        aus.append(z)
while aus and aus[-1] == "":
    aus.pop()
aus += [zeile(n) for n in neu.values()]
open(pfad, "w", encoding="utf-8", newline="").write("\r\n".join(aus) + "\r\n")
print("ok", len(aus))
