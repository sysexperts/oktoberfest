"""Erzeugt scenes/ui/watten.tscn (Watten gegen Konrads Bank mit bayerischem Blatt). Aufruf: python -X utf8 tools/casino_grafik/bauen_watten_tscn.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from tscn_bau import *

b = Bau("Watten", "res://scripts/ui/watten.gd")
b.geruest("WATTEN_TITEL")
rueck = b.bild("res://assets/casino/karte_ruecken.png", "ruecken")
b.stil("hand_n", (0, 0, 0, 0), rand=(0, 0, 0, 0), breite=0, radius=8)
b.stil("hand_h", (1, 0.9, 0.4, 0.18), rand=(1, 0.9, 0.5, 1), breite=3, radius=10)

b.node("Filz", "Panel", "Buehne", b.rect(200, 120, 1200, 620) + 'theme_override_styles/panel = SubResource("tisch")\nmouse_filter = 2\n')
b.node("StapelHinten", "TextureRect", "Buehne", b.rect(1296, 142, 150, 210) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\nmodulate = Color(0.7, 0.7, 0.7, 1)\n' % rueck)
b.node("Stapel", "TextureRect", "Buehne", b.rect(1288, 134, 150, 210) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % rueck, True)
b.label("BankName", 240, 130, 300, 40, "BJ_BANK", 28, (0.91, 0.74, 0.33, 1), 0)
b.label("StichBank", 240, 170, 300, 50, "", 40, (1, 1, 1, 1), 0)
b.label("SpielerName", 240, 470, 300, 40, "BJ_DU", 28, (0.91, 0.74, 0.33, 1), 0)
b.label("StichSpieler", 240, 510, 300, 50, "", 40, (1, 1, 1, 1), 0)
b.label("EinsatzTisch", 240, 640, 360, 50, "", 32, (1, 0.93, 0.7, 1), 0)
b.label("Regel", 300, 330, 1000, 50, "WATTEN_REGEL", 28, (0.91, 0.74, 0.33, 0.55), 1)
b.label("BankMeldung", 700, 590, 600, 50, "", 28, (0.95, 0.7, 0.55, 1), 1)

# Hier landen die gelegten Karten (zur Laufzeit erzeugt)
b.node("Karten", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\n", True)
# Die drei Handkarten des Spielers (anklickbar)
for i in range(3):
    b.node("Hand%d" % i, "TextureButton", "Buehne", b.rect(560 + i * 170, 500, 150, 210) + 'focus_mode = 0\nignore_texture_size = true\nstretch_mode = 5\npivot_offset = Vector2(75, 105)\nvisible = false\n', True)

b.node("BannerPlatte", "Panel", "Buehne", b.rect(360, 346, 880, 98) + 'theme_override_styles/panel = SubResource("banner")\nmouse_filter = 2\nvisible = false\n', True)
b.label("Ergebnis", 380, 350, 840, 90, "", 38, (1, 0.93, 0.7, 1), 1, extra="autowrap_mode = 3\n")

# Unten: Einsatz setzen (vor der Runde)
b.label("JetonTitel", 60, 744, 400, 30, "BJ_JETON", 22, (0.85, 0.8, 0.6, 1), 0)
b.jetons(780, 70, auswahl=False)
b.label("Einsatz", 690, 770, 330, 60, "", 34, (1, 0.93, 0.7, 1), 2)
b.knopf("Leeren", 1040, 776, 180, 70, "ROULETTE_LEEREN")
b.knopf("Austeilen", 1260, 764, 300, 92, "BJ_AUSTEILEN", 40, True)
# Unten: Watten! und neue Runde (während/nach der Runde)
b.node("Aktionen", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\nvisible = false\n", True)
b.knopf("Watten", 560, 764, 480, 92, "WATTEN_WATTEN", 34, True, "Buehne/Aktionen")
b.knopf("Neu", 1100, 764, 400, 92, "WATTEN_NEU", 34, True, "Buehne/Aktionen")
b.label("Hinweis", 60, 858, 1480, 30, "WATTEN_HINWEIS", 18, (0.75, 0.82, 0.7, 0.9), 1, uniq=False)
b.gewinnregen(800, 690)
b.schreiben("watten.tscn")
