"""Färbt die alten Spielfenster (braun/gold) in den Desktop-App-Look um: nachtblaues Glas, heller Text, Akzentfarbe je App.
Aufruf: python tools/remap_app_farben.py <Quelle> <Ziel> <R,G,B-Akzent> [theme-pfad]
Warme Töne werden umgefärbt: Gold -> Akzent, Creme -> Weiß, Braun -> Nachtblau. Neutrale, rote und orange Warnfarben bleiben."""
import colorsys
import re
import sys

quelle, ziel, akz = sys.argv[1], sys.argv[2], tuple(float(v) for v in sys.argv[3].split(','))
theme = sys.argv[4] if len(sys.argv) > 4 else ''
t = open(quelle, encoding='utf-8', newline='').read()
NL = chr(10)


def fmt(v):
    return ('%.3f' % v).rstrip('0').rstrip('.') or '0'


def neu(m):
    r, g, b, a = (float(x) for x in m.group(1).split(','))
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    if s < 0.08 or not (0.0 <= h <= 0.2):
        return m.group(0)
    if v >= 0.85 and s >= 0.45:
        if h < 0.09:
            return m.group(0)         # Rot/Orange (Warnungen) bleibt
        nr, ng, nb = akz
    elif v >= 0.85:
        nr, ng, nb = 0.95, 0.96, 0.99  # Creme -> Weiß
    elif v >= 0.55:
        k = v / 0.78
        nr, ng, nb = 0.69 * k, 0.73 * k, 0.84 * k   # gedämpfter Text
    else:
        nr, ng, nb = colorsys.hsv_to_rgb(0.63, 0.5, min(1.0, v * 1.7 + 0.01))
    return 'Color(%s, %s, %s, %s)' % (fmt(min(nr, 1)), fmt(min(ng, 1)), fmt(min(nb, 1)), fmt(a))


t = re.sub(r'Color\(([^)]*)\)', lambda m: neu(m) if m.group(1).count(',') == 3 else m.group(0), t)
if theme:
    # Theme (Knöpfe, Eingabefelder …) am Wurzelknoten setzen
    ext = '[ext_resource type="Theme" path="%s" id="app_theme"]' % theme + NL
    t = re.sub(r'(\[gd_scene[^\n]*\]\n\n)', lambda m: m.group(1) + ext, t, count=1)
    m = re.search(r'\[node name="[^"]+" type="[^"]+"[^\]]*\]\n', t)
    t = t[:m.end()] + 'theme = ExtResource("app_theme")' + NL + t[m.end():]
if ziel != quelle:
    t = re.sub(r'^(\[(?:gd_scene|gd_resource)[^\]]*?) uid="[^"]*"', r'\1', t, count=1)
open(ziel, 'w', encoding='utf-8', newline='').write(t)
print('ok', ziel)
