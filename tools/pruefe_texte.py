"""Prüft locale/texte.csv: leere Übersetzungen, unterschiedliche Platzhalter (%s %d %%), das geschützte Wort Wiesn,
doppelte Schlüssel. Aufruf: python tools/pruefe_texte.py   (Ausgabe: Zahl der Probleme, Exit-Code 1 bei Fehlern)
Nur Schlüssel, die zum Spiel gehören — Texte im Plan-Dokument werden nicht geprüft.
"""
import csv
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PFAD = os.path.join(ROOT, "locale", "texte.csv")
PLATZ = re.compile(r"%(?:\d+\$)?[sdfi]|%%")

def platzhalter(t):
    return sorted(PLATZ.findall(t.replace("%%", "")))

def main():
    probleme = []
    schluessel = set()
    with open(PFAD, encoding="utf-8", newline="") as f:
        zeilen = list(csv.reader(f))
    kopf = zeilen[0]
    for nr, z in enumerate(zeilen[1:], start=2):
        if not z or not z[0].strip():
            continue
        k = z[0]
        if k in schluessel:
            probleme.append(f"Zeile {nr}: Schlüssel doppelt: {k}")
        schluessel.add(k)
        if len(z) < 4:
            probleme.append(f"Zeile {nr}: {k}: nur {len(z)} Spalten")
            continue
        de, en, tr = z[1], z[2], z[3]
        for sprache, t in (("de", de), ("en", en), ("tr", tr)):
            if not t.strip():
                probleme.append(f"Zeile {nr}: {k}: {sprache} ist leer")
        if "wiesn" in (de + en + tr).lower():
            probleme.append(f"Zeile {nr}: {k}: enthält das geschützte Wort Wiesn")
        if de.strip() and en.strip() and tr.strip():
            pd, pe, pt = platzhalter(de), platzhalter(en), platzhalter(tr)
            if len(pd) != len(pe) or len(pd) != len(pt):
                probleme.append(f"Zeile {nr}: {k}: Platzhalter verschieden (de {pd}, en {pe}, tr {pt})")
    # Schlüssel, die im Code oder in den Daten vorkommen, aber nicht in der Tabelle stehen
    import glob
    muster = re.compile(r'"((?:MSG|HINT|Q|MAIL|MS|STAFF|WAGEN|AUSBAU|FEST|ZEITUNG|ABSENDER|DESKTOP_APP|SAB|CROUPIER|BJ|GUSTAV|MEISTER|QUESTS|REZEPT|BIER_STUFE|WUNSCH|GRUPPE|KONRAD|HUBER|CHEF|POPUP|WORLD|EREIGNIS|SOCIAL|REPORT|SIGN)_[A-Z0-9_\-]*[A-Z0-9])"')
    dateien = glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)
    dateien += glob.glob(os.path.join(ROOT, "daten", "*.json")) + glob.glob(os.path.join(ROOT, "scenes", "**", "*.tscn"), recursive=True)
    fehlend = {}
    for d in dateien:
        if d.endswith("meilensteine.gd"):
            continue   # dort stehen IDs, die Texte heißen MS_<id>_TITLE
        for m in muster.finditer(open(d, encoding="utf-8", errors="ignore").read()):
            k = m.group(1)
            if k in schluessel or k + "_DU" in schluessel or k + "_IHR" in schluessel:
                continue
            if k.endswith("_") and any(x.startswith(k) for x in schluessel):
                continue
            fehlend.setdefault(k, os.path.relpath(d, ROOT))
    for k, d in sorted(fehlend.items()):
        probleme.append(f"Schlüssel fehlt in der Tabelle: {k} (benutzt in {d})")
    for p in probleme:
        print(p)
    print(f"{len(zeilen) - 1} Zeilen geprüft, {len(probleme)} Probleme")
    return 1 if probleme else 0

if __name__ == "__main__":
    sys.exit(main())
