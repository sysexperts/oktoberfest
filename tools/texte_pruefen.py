"""Übersetzungen prüfen: fehlende Schlüssel, leere Sprachen, fest eingebaute
Texte in Szenen und Code, die an der Übersetzung vorbeigehen.
Aufruf: python tools/texte_pruefen.py
"""
import csv, glob, re, os
os.chdir(os.path.join(os.path.dirname(__file__), '..'))

zeilen = list(csv.reader(open('locale/texte.csv', encoding='utf-8')))
kopf = zeilen[0]
keys = {r[0]: r for r in zeilen[1:] if r}

print('== Leere Übersetzungen')
for k, r in keys.items():
    for i, sprache in enumerate(kopf[1:], 1):
        if len(r) <= i or not r[i].strip():
            print(f'  {k}: {sprache} leer')

print('== Szenen: fester Text ohne Schlüssel')
for f in sorted(glob.glob('scenes/**/*.tscn', recursive=True)):
    if 'werkzeuge' in f:
        continue
    s = open(f, encoding='utf-8').read()
    for blk in re.split(r'\n(?=\[node )', s):
        if 'auto_translate_mode = 2' in blk:
            continue   # wird im Code befüllt
        for m in re.finditer(r'^(text|placeholder_text|tooltip_text) = "((?:[^"\\]|\\.)*)"', blk, re.M):
            t = m.group(2)
            if t in keys or len(t) < 3 or not re.search(r'[A-Za-zÄÖÜäöüß]{3}', t):
                continue
            name = re.search(r'name="([^"]+)"', blk)
            print(f'  {f} [{name.group(1) if name else "?"}] {m.group(1)}: {t[:70]}')

print('== Code: Schlüssel ohne Eintrag')
for f in sorted(glob.glob('scripts/**/*.gd', recursive=True) + glob.glob('autoload/*.gd')):
    for m in re.finditer(r'"([A-Z][A-Z0-9]+_[A-Z0-9_]+)"', open(f, encoding='utf-8').read()):
        k = m.group(1)
        if k not in keys and not k.endswith('_'):
            print(f'  {f}: {k}')

print('== Code: deutsche/türkische Texte direkt im Code')
wort = re.compile(r'"([^"\n]*\b(?:und|nicht|Zelt|Gäste|Geld|kaufen|bitte|oder|ç|ş|ğ|ı|ile|için|oyun)\b[^"\n]*)"')
for f in sorted(glob.glob('scripts/**/*.gd', recursive=True) + glob.glob('autoload/*.gd')):
    for nr, zeile in enumerate(open(f, encoding='utf-8'), 1):
        z = zeile.strip()
        if z.startswith('#') or 'print(' in z or 'push_' in z:
            continue
        for m in wort.finditer(zeile):
            if '##' in zeile.split('"')[0]:
                continue
            print(f'  {f}:{nr}: {m.group(1)[:70]}')
