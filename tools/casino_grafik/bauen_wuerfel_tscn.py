"""Erzeugt scenes/ui/casino_wuerfel.tscn. Aufruf: python -X utf8 tools/casino_grafik/bauen_wuerfel_tscn.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from tscn_bau import *

b = Bau("Wuerfel", "res://scripts/ui/casino_wuerfel.gd")
b.geruest("WUERFEL_TITEL")
b.stil("feld_n", (0.04, 0.22, 0.13, 0.9), rand=(0.91, 0.74, 0.33, 0.8), breite=2, radius=14)
b.stil("feld_h", (0.10, 0.36, 0.22, 0.95), rand=(1, 0.9, 0.5, 1), breite=3, radius=14)
b.stil("holz", (0.30, 0.17, 0.08, 1), rand=(0.12, 0.06, 0.02, 1), breite=6, radius=26)
b.stil("filz", (0.05, 0.36, 0.20, 1), rand=(0.02, 0.18, 0.10, 1), breite=3, radius=14)
becher = b.bild("res://assets/casino/wuerfel_becher.png", "becher")
w = [b.bild("res://assets/casino/wuerfel_%d.png" % i, "w%d" % i) for i in range(1, 7)]

# Würfelbahn: Holzrand mit Filz
b.node("Bahn", "Panel", "Buehne", b.rect(50, 130, 900, 560) + 'theme_override_styles/panel = SubResource("holz")\nmouse_filter = 2\n')
b.node("BahnFilz", "Panel", "Buehne", b.rect(74, 154, 852, 512) + 'theme_override_styles/panel = SubResource("filz")\nmouse_filter = 2\n')
b.node("Summe", "Label", "Buehne", b.rect(100, 160, 300, 150) + 'theme_override_colors/font_color = Color(1, 0.93, 0.7, 1)\ntheme_override_colors/font_outline_color = Color(0, 0, 0, 1)\ntheme_override_constants/outline_size = 12\ntheme_override_fonts/font = ExtResource("fraktur")\ntheme_override_font_sizes/font_size = 128\nvisible = false\nmouse_filter = 2\nauto_translate_mode = 2\n', True)
b.node("Wuerfel0", "TextureRect", "Buehne", b.rect(300, 340, 230, 230) + 'pivot_offset = Vector2(115, 115)\ntexture = %s\nexpand_mode = 1\nstretch_mode = 5\nvisible = false\nmouse_filter = 2\n' % w[0], True)
b.node("Wuerfel1", "TextureRect", "Buehne", b.rect(540, 380, 230, 230) + 'pivot_offset = Vector2(115, 115)\ntexture = %s\nexpand_mode = 1\nstretch_mode = 5\nvisible = false\nmouse_filter = 2\n' % w[1], True)
b.node("Becher", "TextureRect", "Buehne", b.rect(640, 300, 260, 288) + 'pivot_offset = Vector2(130, 144)\ntexture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % becher, True)

# Wettfelder rechts
b.node("Wettfelder", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\n", True)
for i, (name, key) in enumerate([("tief", "WUERFEL_FELD_TIEF"), ("sieben", "WUERFEL_FELD_SIEBEN"), ("hoch", "WUERFEL_FELD_HOCH"), ("pasch", "WUERFEL_FELD_PASCH")]):
    b.node(name, "Button", "Buehne/Wettfelder", b.rect(990, 136 + i * 94, 560, 82) + 'focus_mode = 0\ntheme_override_font_sizes/font_size = 30\ntheme_override_colors/font_color = Color(1, 1, 1, 1)\ntheme_override_colors/font_hover_color = Color(1, 1, 1, 1)\ntheme_override_colors/font_pressed_color = Color(1, 1, 1, 1)\ntheme_override_styles/normal = SubResource("feld_n")\ntheme_override_styles/hover = SubResource("feld_h")\ntheme_override_styles/pressed = SubResource("feld_h")\ntheme_override_styles/focus = SubResource("leer")\ntext = "%s"\nalignment = 0\n' % key)

b.label("JetonTitel", 990, 520, 400, 30, "ROULETTE_JETON", 22, (0.85, 0.8, 0.6, 1), 0, uniq=False)
b.jetons(560, 1010)
b.label("Einsatz", 990, 650, 560, 50, "", 34, (1, 0.93, 0.7, 1), 2)
b.knopf("Zurueck", 990, 710, 170, 64, "ROULETTE_ZURUECK")
b.knopf("Leeren", 1170, 710, 170, 64, "ROULETTE_LEEREN")
b.knopf("Wiederholen", 1350, 710, 200, 64, "ROULETTE_WIEDERHOLEN")
b.knopf("Drehen", 50, 710, 900, 90, "WUERFEL_WERFEN", 40, True)
b.label("Ergebnis", 50, 806, 1500, 48, "", 36, (1, 0.93, 0.7, 1), 1)
b.label("Hinweis", 60, 860, 1480, 30, "WUERFEL_HINWEIS", 18, (0.75, 0.82, 0.7, 0.9), 1, uniq=False)
b.gewinnregen(500, 420)
b.schreiben("casino_wuerfel.tscn")
