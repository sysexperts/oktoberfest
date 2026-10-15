"""Erzeugt scenes/ui/casino_slot.tscn (Spielautomat mit drei Walzen und fünf Gewinnlinien).
Aufruf: python -X utf8 tools/casino_grafik/bauen_slot_tscn.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from tscn_bau import *

# Walzenstreifen: gleich wie GameManager.SLOT_STREIFEN; 0 Maß, 1 Brezn, 2 Hendl, 3 Herz, 4 Edelweiß, 5 Sieben, 6 Raute
STREIFEN = [1, 5, 0, 1, 2, 2, 6, 3, 2, 1, 2, 4, 6, 3, 3, 1, 1, 0, 3, 1, 0, 4, 2]
NAMEN = ["mass", "brezn", "hendl", "herz", "edelweiss", "sieben", "raute"]
ZELLE_H = 140
ZELLE_B = 220
WALZE_X = [380, 630, 880]
WALZE_Y = 190

b = Bau("Slot", "res://scripts/ui/casino_slot.gd")
b.geruest("SLOT_TITEL")
b.stil("rahmen", (0.30, 0.05, 0.08, 1), rand=GOLD, breite=7, radius=34)   # eigener Rahmen: dunkles Weinrot
b.stil("fenster", (0.96, 0.93, 0.84, 1), rand=(0.91, 0.74, 0.33, 1), breite=8, radius=18)
b.stil("lcd", (0.03, 0.05, 0.04, 1), rand=(0.91, 0.74, 0.33, 0.8), breite=3, radius=12)
b.stil("lampe", (1, 0.85, 0.3, 1), rand=(1, 0.95, 0.7, 1), breite=2, radius=14)
b.stil("hebel_stab", (0.80, 0.80, 0.84, 1), rand=(0.45, 0.45, 0.5, 1), breite=2, radius=8)
b.stil("hebel_kugel", (0.85, 0.10, 0.12, 1), rand=(1, 0.6, 0.6, 1), breite=3, radius=32)
b.stil("wahl_n", (0.10, 0.04, 0.05, 0.9), rand=(0.91, 0.74, 0.33, 0.7), breite=2, radius=12)
b.stil("wahl_h", (0.22, 0.09, 0.10, 0.95), rand=(1, 0.9, 0.5, 1), breite=2, radius=12)
b.stil("tafel", (0.12, 0.03, 0.05, 0.85), rand=(0.91, 0.74, 0.33, 0.6), breite=2, radius=14)

sym = [b.bild("res://assets/casino/slot_%s.png" % n, "s_" + n) for n in NAMEN]

# Lampenkranz oben und unten
b.node("Lampen", "Control", "Buehne", "layout_mode = 0\nmouse_filter = 2\n", True)
anzahl = 15
for i in range(anzahl):
    x = 330 + i * 58
    b.node("LampeO%d" % i, "Panel", "Buehne/Lampen", b.rect(x, 128, 28, 28) + 'theme_override_styles/panel = SubResource("lampe")\nmouse_filter = 2\n')
    b.node("LampeU%d" % i, "Panel", "Buehne/Lampen", b.rect(x, 660, 28, 28) + 'theme_override_styles/panel = SubResource("lampe")\nmouse_filter = 2\n')

# Fenster mit den Walzen
b.node("Fenster", "Panel", "Buehne", b.rect(350, 170, 780, 460) + 'theme_override_styles/panel = SubResource("fenster")\nmouse_filter = 2\n')
for r in range(3):
    b.node("Walze%d" % r, "Control", "Buehne", b.rect(WALZE_X[r], WALZE_Y, ZELLE_B, 3 * ZELLE_H) + "clip_contents = true\nmouse_filter = 2\n", True)
    b.node("Streifen", "Control", "Buehne/Walze%d" % r, "layout_mode = 0\nmouse_filter = 2\n")
    for i in range(len(STREIFEN) + 3):
        s = STREIFEN[i % len(STREIFEN)]
        b.node("Z%d" % i, "TextureRect", "Buehne/Walze%d/Streifen" % r, b.rect(10, i * ZELLE_H, ZELLE_B - 20, ZELLE_H) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % sym[s])
    # Trennlinien zwischen den Walzen
    if r > 0:
        b.node("Trenner%d" % r, "ColorRect", "Buehne", b.rect(WALZE_X[r] - 14, WALZE_Y, 3, 3 * ZELLE_H) + "color = Color(0.7, 0.6, 0.4, 0.7)\nmouse_filter = 2\n")
# Schatten oben/unten im Fenster (Tiefe)
b.node("SchattenOben", "ColorRect", "Buehne", b.rect(370, WALZE_Y, 740, 46) + "color = Color(0, 0, 0, 0.28)\nmouse_filter = 2\n")
b.node("SchattenUnten", "ColorRect", "Buehne", b.rect(370, WALZE_Y + 3 * ZELLE_H - 46, 740, 46) + "color = Color(0, 0, 0, 0.28)\nmouse_filter = 2\n")

# Gewinnlinien (leuchten bei einem Treffer)
farben = ["1, 0.85, 0.2, 1", "0.3, 1, 0.5, 1", "0.3, 0.8, 1, 1", "1, 0.5, 0.9, 1", "1, 0.5, 0.3, 1"]
reihen = [[1, 1, 1], [0, 0, 0], [2, 2, 2], [0, 1, 2], [2, 1, 0]]
b.node("Linien", "Control", "Buehne", "layout_mode = 0\nmouse_filter = 2\n", True)
for li, rr in enumerate(reihen):
    pts = []
    for r in range(3):
        pts.append("%d, %d" % (WALZE_X[r] + ZELLE_B / 2, WALZE_Y + rr[r] * ZELLE_H + ZELLE_H / 2))
    # kleine Verlängerung nach links und rechts
    pts.insert(0, "%d, %d" % (WALZE_X[0] - 12, WALZE_Y + rr[0] * ZELLE_H + ZELLE_H / 2))
    pts.append("%d, %d" % (WALZE_X[2] + ZELLE_B + 12, WALZE_Y + rr[2] * ZELLE_H + ZELLE_H / 2))
    b.node("Linie%d" % li, "Line2D", "Buehne/Linien", 'points = PackedVector2Array(%s)\nwidth = 10.0\ndefault_color = Color(%s)\njoint_mode = 2\nbegin_cap_mode = 2\nend_cap_mode = 2\nvisible = false\n' % (", ".join(pts), farben[li]))

# Anzeige: Gewinn, Ergebnis
b.node("LcdPlatte", "Panel", "Buehne", b.rect(350, 700, 780, 90) + 'theme_override_styles/panel = SubResource("lcd")\nmouse_filter = 2\n')
b.label("LcdText", 370, 706, 740, 78, "", 54, (0.5, 1, 0.6, 1), 1)
b.label("Ergebnis", 350, 796, 780, 44, "", 30, (1, 0.93, 0.7, 1), 1)

EINSATZ_KNOPF = ("custom_minimum_size = Vector2(0, 26)\nlayout_mode = 2\nfocus_mode = 0\ntoggle_mode = true\ntheme_override_font_sizes/font_size = 20\n"
                 'theme_override_styles/normal = SubResource("wahl_n")\ntheme_override_styles/hover = SubResource("wahl_h")\ntheme_override_styles/pressed = SubResource("gold_n")\n'
                 'theme_override_styles/hover_pressed = SubResource("gold_h")\ntheme_override_styles/focus = SubResource("leer")\n'
                 'theme_override_colors/font_pressed_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_hover_pressed_color = Color(0.15, 0.08, 0.02, 1)\ntext = "%d"\n')
# Einsatz wählen
b.label("EinsatzTitel", 70, 640, 260, 30, "SLOT_EINSATZ", 22, (0.85, 0.8, 0.6, 1), 0, uniq=False)
b.node("EinsatzWahl", "VBoxContainer", "Buehne", b.rect(70, 676, 240, 190) + "theme_override_constants/separation = 8\n", True)
for e in (50, 100, 250, 500, 1000):
    b.node("einsatz_%d" % e, "Button", "Buehne/EinsatzWahl", EINSATZ_KNOPF % e, True)
# Auszahlungstafel links
b.node("Tafel", "Panel", "Buehne", b.rect(50, 150, 280, 480) + 'theme_override_styles/panel = SubResource("tafel")\nmouse_filter = 2\n')
b.label("TafelTitel", 60, 158, 260, 40, "SLOT_TAFEL", 26, (0.91, 0.74, 0.33, 1), 1, uniq=False)
pay = [("sieben", 5, "x60"), ("edelweiss", 4, "x25"), ("mass", 0, "x14"), ("herz", 3, "x9"), ("hendl", 2, "x5"), ("brezn", 1, "x4")]
for i, (n, idx, text) in enumerate(pay):
    y = 204 + i * 62
    b.node("TafelBild%d" % i, "TextureRect", "Buehne", b.rect(70, y, 60, 60) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % sym[idx])
    b.label("TafelWert%d" % i, 140, y + 8, 170, 44, "3 " + text, 28, (1, 0.93, 0.7, 1), 0, uniq=False)
b.node("TafelWild", "TextureRect", "Buehne", b.rect(70, 578, 50, 50) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % sym[6])
b.label("TafelWildText", 126, 580, 200, 48, "SLOT_WILD", 20, (0.85, 0.8, 0.6, 1), 0, uniq=False)

# Hebel
b.node("Hebel", "Control", "Buehne", b.rect(1190, 430, 40, 20) + "pivot_offset = Vector2(20, 10)\nmouse_filter = 2\n", True)
b.node("Stab", "Panel", "Buehne/Hebel", b.rect(11, -130, 18, 140) + 'theme_override_styles/panel = SubResource("hebel_stab")\nmouse_filter = 2\n')
b.node("Kugel", "Panel", "Buehne/Hebel", b.rect(-12, -186, 64, 64) + 'theme_override_styles/panel = SubResource("hebel_kugel")\nmouse_filter = 2\n')
b.node("HebelSockel", "Panel", "Buehne", b.rect(1166, 430, 88, 44) + 'theme_override_styles/panel = SubResource("lcd")\nmouse_filter = 2\n')
b.knopf("Drehen", 1160, 520, 380, 110, "SLOT_DREHEN", 46, True)
b.label("Kasse2", 1160, 650, 380, 40, "", 26, (0.85, 0.8, 0.6, 1), 1)
b.label("Hinweis", 60, 862, 1480, 26, "SLOT_HINWEIS", 18, (0.9, 0.8, 0.7, 0.8), 1, uniq=False)
b.gewinnregen(740, 470)
b.schreiben("casino_slot.tscn")
