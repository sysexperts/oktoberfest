"""Erzeugt scenes/ui/casino_blackjack.tscn. Aufruf: python -X utf8 tools/casino_grafik/bauen_blackjack_tscn.py"""
import sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from tscn_bau import *

b = Bau("Blackjack", "res://scripts/ui/casino_blackjack.gd")
b.geruest("BJ_TITEL")
rueck = b.bild("res://assets/casino/karte_ruecken.png", "ruecken")

# Tisch: halbrunder Filz mit Aufschrift
b.node("Filz", "Panel", "Buehne", b.rect(200, 120, 1200, 600) + 'theme_override_styles/panel = SubResource("tisch")\n')
b.label("Regel", 300, 365, 1000, 50, "BJ_REGEL", 30, (0.91, 0.74, 0.33, 0.55), 1)
# Kartenstapel (Schlitten) rechts oben
b.node("StapelHinten", "TextureRect", "Buehne", b.rect(1296, 142, 150, 210) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\nmodulate = Color(0.7, 0.7, 0.7, 1)\n' % rueck)
b.node("Stapel", "TextureRect", "Buehne", b.rect(1288, 134, 150, 210) + 'texture = %s\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n' % rueck, True)
b.node("Karten", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\n", True)
b.label("BankName", 240, 130, 300, 40, "BJ_BANK", 28, (0.91, 0.74, 0.33, 1), 0)
b.label("BankWert", 240, 170, 300, 60, "", 44, (1, 1, 1, 1), 0)
b.label("SpielerName", 240, 470, 300, 40, "BJ_DU", 28, (0.91, 0.74, 0.33, 1), 0)
b.label("SpielerWert", 240, 510, 300, 60, "", 44, (1, 1, 1, 1), 0)
b.label("EinsatzTisch", 240, 640, 360, 60, "", 34, (1, 0.93, 0.7, 1), 0)

# Ergebnis-Banner (liegt über dem Filz, in der Mitte)
b.node("BannerPlatte", "Panel", "Buehne", b.rect(360, 346, 880, 98) + 'theme_override_styles/panel = SubResource("banner")\nmouse_filter = 2\nvisible = false\n', True)
b.label("Ergebnis", 380, 350, 840, 90, "", 40, (1, 0.93, 0.7, 1), 1, extra="autowrap_mode = 3\n")

# Unten: Wetten
b.label("JetonTitel", 60, 744, 400, 30, "BJ_JETON", 22, (0.85, 0.8, 0.6, 1), 0)
b.jetons(780, 70, auswahl=False)
b.label("Einsatz", 690, 770, 330, 60, "", 34, (1, 0.93, 0.7, 1), 2)
b.knopf("Leeren", 1040, 776, 180, 70, "ROULETTE_LEEREN")
b.knopf("Austeilen", 1260, 764, 300, 92, "BJ_AUSTEILEN", 40, True)
# Unten: Aktionen (während der Runde)
b.node("Aktionen", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\nvisible = false\n", True)
b.knopf("Karte", 400, 764, 260, 92, "BJ_KARTE", 36, True, "Buehne/Aktionen")
b.knopf("Halten", 700, 764, 260, 92, "BJ_HALTEN", 36, True, "Buehne/Aktionen")
b.knopf("Verdoppeln", 1000, 764, 300, 92, "BJ_VERDOPPELN", 32, False, "Buehne/Aktionen")
b.label("Hinweis", 60, 850, 1480, 34, "BJ_HINWEIS", 20, (0.75, 0.82, 0.7, 0.9), 1, uniq=False)
b.gewinnregen(800, 690)
b.schreiben("casino_blackjack.tscn")
