#!/usr/bin/env python3
"""Steam-Texte aus dem Spiel ziehen, statt sie doppelt zu pflegen.

    python tools/steam_texte.py

Schreibt docs/steam/errungenschaften_texte.md — die Tabelle zum Einpflegen in
Steamworks, in allen drei Sprachen. Quelle ist locale/texte.csv; die Reihenfolge
und die Auswahl der IDs kommen aus scripts/meilensteine.gd, damit eine neue
Errungenschaft hier nicht vergessen wird.
"""
import csv
import io
import os
import re
import sys

WURZEL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CSV = os.path.join(WURZEL, "locale", "texte.csv")
MEILENSTEINE = os.path.join(WURZEL, "scripts", "meilensteine.gd")
ZIEL = os.path.join(WURZEL, "docs", "steam", "errungenschaften_texte.md")

KOPF = """# Errungenschaften: Texte zum Einpflegen

Erzeugt aus `locale/texte.csv` mit `tools/steam_texte.py` — nicht von Hand
aendern, sondern die CSV pflegen und neu erzeugen.

In Steamworks unter *Stats & Achievements -> Achievements*: API-Name **genau**
so uebernehmen, sonst loest die Errungenschaft nie aus. Danach je Sprache die
Zeile einsetzen und **Publish** druecken.

Je Errungenschaft fehlen noch zwei Symbole (64x64: erreicht und grau).

"""


def ids_aus_meilensteinen():
    text = io.open(MEILENSTEINE, encoding="utf-8").read()
    return re.findall(r'\{"id":\s*"([A-Z0-9_]+)"', text)


def main():
    zeilen = {r[0]: r for r in csv.reader(io.open(CSV, encoding="utf-8")) if r}
    ids = ids_aus_meilensteinen()
    if not ids:
        print("Keine Meilensteine gefunden — Muster in meilensteine.gd geaendert?")
        return 1
    aus = io.StringIO()
    aus.write(KOPF)
    fehlend = []
    for i in ids:
        titel = zeilen.get("MS_%s_TITLE" % i)
        text = zeilen.get("MS_%s_TEXT" % i)
        if not titel or not text:
            fehlend.append(i)
            continue
        aus.write("## %s\n\n" % i)
        aus.write("| Sprache | Name | Beschreibung |\n|---|---|---|\n")
        for sprache, spalte in (("Deutsch", 1), ("English", 2), ("Turkce", 3)):
            aus.write("| %s | %s | %s |\n" % (sprache, titel[spalte], text[spalte]))
        aus.write("\n")
    if fehlend:
        aus.write("## Ohne Text\n\nFuer diese fehlen MS_<ID>_TITLE / _TEXT in texte.csv:\n\n")
        for i in fehlend:
            aus.write("- %s\n" % i)
    io.open(ZIEL, "w", encoding="utf-8").write(aus.getvalue())
    print("%s: %d Errungenschaften%s" % (
        os.path.relpath(ZIEL, WURZEL), len(ids) - len(fehlend),
        ", %d ohne Text" % len(fehlend) if fehlend else ""))
    return 1 if fehlend else 0


if __name__ == "__main__":
    sys.exit(main())
