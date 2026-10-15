"""Erzeugt scenes/ui/casino_roulette.tscn (Tisch mit Wettfeldern). Danach ist die Szene normal im Godot-Editor bearbeitbar.
Aufruf: python -X utf8 tools/casino_grafik/bauen_roulette_tscn.py"""
import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ROT = {1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36}

subs = []


def stil(name, farbe, rand=(1, 1, 1, 0.55), breite=2, radius=6):
    subs.append('[sub_resource type="StyleBoxFlat" id="%s"]\nbg_color = Color(%s)\nborder_width_left = %d\nborder_width_top = %d\nborder_width_right = %d\nborder_width_bottom = %d\nborder_color = Color(%s)\ncorner_radius_top_left = %d\ncorner_radius_top_right = %d\ncorner_radius_bottom_right = %d\ncorner_radius_bottom_left = %d\n'
                % (name, ", ".join(str(x) for x in farbe), breite, breite, breite, breite, ", ".join(str(x) for x in rand), radius, radius, radius, radius))


def hell(c, f=1.35):
    return tuple(min(1.0, x * f) if i < 3 else x for i, x in enumerate(c))


FARBEN = {"rot": (0.72, 0.10, 0.14, 1), "schwarz": (0.07, 0.07, 0.09, 1), "gruen": (0.07, 0.46, 0.24, 1), "aussen": (0.04, 0.22, 0.13, 0.85)}
for k, c in FARBEN.items():
    stil(k + "_n", c)
    stil(k + "_h", hell(c, 1.5 if k != "schwarz" else 3.2), rand=(1, 0.9, 0.5, 1), breite=3)
stil("rahmen", (0.05, 0.27, 0.16, 1), rand=(0.91, 0.74, 0.33, 1), breite=7, radius=34)
stil("tisch", (0.03, 0.17, 0.10, 0.9), rand=(0.91, 0.74, 0.33, 0.6), breite=2, radius=12)
stil("leer", (0, 0, 0, 0), rand=(0, 0, 0, 0), breite=0, radius=0)
stil("gold_n", (0.88, 0.66, 0.22, 1), rand=(1, 0.93, 0.6, 1), breite=3, radius=16)
stil("gold_h", (1.0, 0.80, 0.34, 1), rand=(1, 1, 0.8, 1), breite=3, radius=16)
stil("gold_g", (0.35, 0.30, 0.18, 1), rand=(0.6, 0.55, 0.4, 1), breite=3, radius=16)
stil("knopf_n", (0.10, 0.12, 0.11, 0.92), rand=(0.91, 0.74, 0.33, 0.7), breite=2, radius=14)
stil("knopf_h", (0.18, 0.21, 0.19, 0.95), rand=(1, 0.9, 0.5, 1), breite=2, radius=14)

knoten = []


def node(name, typ, parent, eig="", uniq=False):
    t = '[node name="%s" type="%s"%s]\n' % (name, typ, ' parent="%s"' % parent if parent is not None else "")
    if uniq:
        t += "unique_name_in_owner = true\n"
    knoten.append(t + eig + "\n")


def rect(x, y, w, h):
    return "layout_mode = 0\noffset_left = %s\noffset_top = %s\noffset_right = %s\noffset_bottom = %s\n" % (x, y, x + w, y + h)


def feld_knopf(name, x, y, w, h, text, farbe, groesse=30):
    e = rect(x, y, w, h)
    e += "focus_mode = 0\ntheme_override_font_sizes/font_size = %d\ntheme_override_colors/font_color = Color(1, 1, 1, 1)\ntheme_override_colors/font_hover_color = Color(1, 1, 1, 1)\ntheme_override_colors/font_pressed_color = Color(1, 1, 1, 1)\n" % groesse
    e += 'theme_override_styles/normal = SubResource("%s_n")\ntheme_override_styles/hover = SubResource("%s_h")\ntheme_override_styles/pressed = SubResource("%s_h")\ntheme_override_styles/focus = SubResource("leer")\n' % (farbe, farbe, farbe)
    e += 'text = "%s"\n' % text
    node(name, "Button", "Buehne/Wettfelder", e)


def knopf(name, x, y, w, h, text, groesse=26, gold=False):
    if gold:
        s = ('theme_override_styles/normal = SubResource("gold_n")\ntheme_override_styles/hover = SubResource("gold_h")\ntheme_override_styles/pressed = SubResource("gold_h")\ntheme_override_styles/disabled = SubResource("gold_g")\n'
             'theme_override_colors/font_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_hover_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_pressed_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_disabled_color = Color(0.5, 0.45, 0.35, 1)\n')
    else:
        s = 'theme_override_styles/normal = SubResource("knopf_n")\ntheme_override_styles/hover = SubResource("knopf_h")\ntheme_override_styles/pressed = SubResource("knopf_h")\ntheme_override_styles/disabled = SubResource("knopf_n")\n'
    node(name, "Button", "Buehne", rect(x, y, w, h) + 'focus_mode = 0\ntheme_override_font_sizes/font_size = %d\ntheme_override_styles/focus = SubResource("leer")\n%stext = "%s"\n' % (groesse, s, text), True)


# ---------------------------------------------------------------- Gerüst
node("Roulette", "CanvasLayer", None, 'layer = 26\nscript = ExtResource("1_s")\n')
node("Dunkel", "ColorRect", "Roulette", "anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\ncolor = Color(0, 0, 0, 0.72)\n")
node("Buehne", "Control", "Roulette", 'layout_mode = 3\nanchors_preset = 8\nanchor_left = 0.5\nanchor_top = 0.5\nanchor_right = 0.5\nanchor_bottom = 0.5\noffset_left = -800.0\noffset_top = -450.0\noffset_right = 800.0\noffset_bottom = 450.0\ngrow_horizontal = 2\ngrow_vertical = 2\npivot_offset = Vector2(800, 450)\ntheme = ExtResource("2_theme")\n', True)
node("Rahmen", "Panel", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\n" + 'theme_override_styles/panel = SubResource("rahmen")\n')
node("Titel", "Label", "Buehne", rect(60, 26, 500, 80) + 'theme_override_colors/font_color = Color(1, 0.84, 0.35, 1)\ntheme_override_fonts/font = ExtResource("3_fraktur")\ntheme_override_font_sizes/font_size = 64\ntext = "ROULETTE_TITEL"\n')
node("Kasse", "Label", "Buehne", rect(1000, 40, 480, 60) + 'theme_override_colors/font_color = Color(1, 0.93, 0.7, 1)\ntheme_override_font_sizes/font_size = 36\nhorizontal_alignment = 2\nauto_translate_mode = 2\n', True)
node("Schliessen", "Button", "Buehne", rect(1510, 30, 60, 60) + 'focus_mode = 0\ntheme_override_font_sizes/font_size = 30\ntheme_override_styles/normal = SubResource("knopf_n")\ntheme_override_styles/hover = SubResource("knopf_h")\ntheme_override_styles/pressed = SubResource("knopf_h")\ntheme_override_styles/focus = SubResource("leer")\ntext = "X"\n', True)

# ---------------------------------------------------------------- Kessel
node("KesselSockel", "Panel", "Buehne", rect(36, 126, 548, 548) + 'theme_override_styles/panel = SubResource("tisch")\n')
node("Kessel", "TextureRect", "Buehne", rect(50, 140, 520, 520) + 'pivot_offset = Vector2(260, 260)\ntexture = ExtResource("4_rad")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\n', True)
node("Kugel", "TextureRect", "Buehne", rect(296, 376, 28, 28) + 'pivot_offset = Vector2(14, 14)\ntexture = ExtResource("5_kugel")\nexpand_mode = 1\nstretch_mode = 5\nmouse_filter = 2\nvisible = false\n', True)
node("Zeiger", "Label", "Buehne", rect(285, 98, 50, 40) + 'theme_override_colors/font_color = Color(1, 0.84, 0.35, 1)\ntheme_override_font_sizes/font_size = 34\ntext = "▼"\nhorizontal_alignment = 1\nmouse_filter = 2\n')
node("Gewinnzahl", "Label", "Buehne", rect(185, 335, 250, 110) + 'theme_override_font_sizes/font_size = 92\ntheme_override_fonts/font = ExtResource("3_fraktur")\ntheme_override_colors/font_outline_color = Color(0, 0, 0, 1)\ntheme_override_constants/outline_size = 12\nhorizontal_alignment = 1\nvertical_alignment = 1\nmouse_filter = 2\nvisible = false\n', True)
node("VerlaufTitel", "Label", "Buehne", rect(40, 700, 500, 30) + 'theme_override_colors/font_color = Color(0.85, 0.8, 0.6, 1)\ntheme_override_font_sizes/font_size = 22\ntext = "ROULETTE_VERLAUF"\n')
node("Verlauf", "HBoxContainer", "Buehne", rect(40, 736, 540, 60) + 'theme_override_constants/separation = 8\n', True)

# ---------------------------------------------------------------- Tisch
node("TischPlatte", "Panel", "Buehne", rect(626, 136, 952, 372) + 'theme_override_styles/panel = SubResource("tisch")\n')
node("Wettfelder", "Control", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\nmouse_filter = 2\n", True)
X0, Y0, W, H = 640, 150, 66, 76
feld_knopf("zahl_0", X0, Y0, W, 3 * H, "0", "gruen", 40)
for c in range(12):
    for r in range(3):
        n = 3 * c + 3 - r
        feld_knopf("zahl_%d" % n, X0 + W + c * W, Y0 + r * H, W, H, str(n), "rot" if n in ROT else "schwarz", 30)
for r in range(3):
    feld_knopf("spalte_%d" % (2 - r), X0 + W + 12 * W, Y0 + r * H, W, H, "2:1", "aussen", 24)
for k in range(3):
    feld_knopf("dutzend_%d" % k, X0 + W + k * 4 * W, Y0 + 3 * H + 6, 4 * W, 52, ["DUTZEND_1", "DUTZEND_2", "DUTZEND_3"][k], "aussen", 26)
for i, (t, txt, f) in enumerate([("niedrig", "1-18", "aussen"), ("gerade", "ROULETTE_GERADE", "aussen"), ("rot", "ROULETTE_ROT", "rot"), ("schwarz", "ROULETTE_SCHWARZ", "schwarz"), ("ungerade", "ROULETTE_UNGERADE", "aussen"), ("hoch", "19-36", "aussen")]):
    feld_knopf(t, X0 + W + i * 2 * W, Y0 + 3 * H + 64, 2 * W, 56, txt, f, 26)

# ---------------------------------------------------------------- Jetons und Aktionen
node("JetonTitel", "Label", "Buehne", rect(640, 524, 300, 30) + 'theme_override_colors/font_color = Color(0.85, 0.8, 0.6, 1)\ntheme_override_font_sizes/font_size = 22\ntext = "ROULETTE_JETON"\n')
node("JetonAuswahl", "Panel", "Buehne", rect(700, 556, 100, 100) + 'theme_override_styles/panel = SubResource("gold_n")\nmouse_filter = 2\n', True)
for i, wert in enumerate([10, 50, 100, 500, 1000]):
    node("jeton_%d" % wert, "TextureButton", "Buehne", rect(710 + i * 118, 566, 80, 80) + 'focus_mode = 0\ntexture_normal = ExtResource("c_%d")\nignore_texture_size = true\nstretch_mode = 5\n' % wert, True)
node("Einsatz", "Label", "Buehne", rect(1250, 540, 314, 50) + 'theme_override_colors/font_color = Color(1, 0.93, 0.7, 1)\ntheme_override_font_sizes/font_size = 34\nhorizontal_alignment = 2\nauto_translate_mode = 2\n', True)
knopf("Zurueck", 640, 690, 180, 66, "ROULETTE_ZURUECK")
knopf("Leeren", 836, 690, 180, 66, "ROULETTE_LEEREN")
knopf("Wiederholen", 1032, 690, 200, 66, "ROULETTE_WIEDERHOLEN")
knopf("Drehen", 1280, 676, 284, 94, "ROULETTE_DREHEN", 40, True)
node("Ergebnis", "Label", "Buehne", rect(640, 782, 924, 56) + 'theme_override_colors/font_color = Color(1, 0.93, 0.7, 1)\ntheme_override_font_sizes/font_size = 38\nhorizontal_alignment = 1\nvertical_alignment = 1\nauto_translate_mode = 2\n', True)
node("Hinweis", "Label", "Buehne", rect(640, 846, 924, 34) + 'theme_override_colors/font_color = Color(0.75, 0.82, 0.7, 0.9)\ntheme_override_font_sizes/font_size = 20\ntext = "ROULETTE_HINWEIS"\nhorizontal_alignment = 1\n')

node("Gewinnregen", "CPUParticles2D", "Buehne", 'position = Vector2(310, 420)\nemitting = false\namount = 46\nlifetime = 2.4\none_shot = true\nexplosiveness = 0.92\ntexture = ExtResource("c_10")\ndirection = Vector2(0, -1)\nspread = 55.0\ngravity = Vector2(0, 1100)\ninitial_velocity_min = 600.0\ninitial_velocity_max = 1100.0\nangular_velocity_min = -360.0\nangular_velocity_max = 360.0\nscale_amount_min = 0.22\nscale_amount_max = 0.42\nlocal_coords = true\n', True)

ext = '[gd_scene format=3]\n\n[ext_resource type="Script" path="res://scripts/ui/casino_roulette.gd" id="1_s"]\n[ext_resource type="Theme" path="res://assets/ui/menue_theme.tres" id="2_theme"]\n[ext_resource type="FontFile" path="res://assets/fonts/UnifrakturCook-Bold.ttf" id="3_fraktur"]\n[ext_resource type="Texture2D" path="res://assets/casino/roulette_rad.png" id="4_rad"]\n[ext_resource type="Texture2D" path="res://assets/casino/kugel.png" id="5_kugel"]\n'
for w in (10, 50, 100, 500, 1000):
    ext += '[ext_resource type="Texture2D" path="res://assets/casino/chip_%d.png" id="c_%d"]\n' % (w, w)
text = (ext + "\n" + "\n".join(subs) + "\n" + "".join(knoten)).replace('parent="Roulette"', 'parent="."')
open(os.path.join(ROOT, "scenes", "ui", "casino_roulette.tscn"), "w", encoding="utf-8", newline="\n").write(text.rstrip() + "\n")
print("fertig", len(knoten), "Knoten")
