"""Gemeinsame Bausteine, um die Casino-Fenster (scenes/ui/casino_*.tscn) als normale Godot-Szenen zu erzeugen.
Die erzeugten Szenen sind danach ganz normal im Editor bearbeitbar; neu erzeugen überschreibt Änderungen daran."""
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
GOLD = (0.91, 0.74, 0.33, 1)


def hell(c, f=1.35):
    return tuple(min(1.0, x * f) if i < 3 else x for i, x in enumerate(c))


class Bau:
    def __init__(self, wurzel, skript):
        self.wurzel = wurzel
        self.subs = []
        self.knoten = []
        self.ext = []
        self.ext_ids = {}
        self.ressource("Script", skript, "skript")
        self.ressource("Theme", "res://assets/ui/menue_theme.tres", "theme")
        self.ressource("FontFile", "res://assets/fonts/UnifrakturCook-Bold.ttf", "fraktur")
        self.standard_stile()

    # ------------------------------------------------------------ Ressourcen
    def ressource(self, typ, pfad, name):
        self.ext.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, pfad, name))
        self.ext_ids[name] = name
        return name

    def bild(self, pfad, name):
        if name not in self.ext_ids:
            self.ressource("Texture2D", pfad, name)
        return 'ExtResource("%s")' % name

    def stil(self, name, farbe, rand=(1, 1, 1, 0.55), breite=2, radius=6):
        self.subs = [x for x in self.subs if not x.startswith('[sub_resource type="StyleBoxFlat" id="%s"]' % name)]
        self.subs.append('[sub_resource type="StyleBoxFlat" id="%s"]\nbg_color = Color(%s)\nborder_width_left = %d\nborder_width_top = %d\nborder_width_right = %d\nborder_width_bottom = %d\nborder_color = Color(%s)\ncorner_radius_top_left = %d\ncorner_radius_top_right = %d\ncorner_radius_bottom_right = %d\ncorner_radius_bottom_left = %d\n'
                         % (name, ", ".join(str(x) for x in farbe), breite, breite, breite, breite, ", ".join(str(x) for x in rand), radius, radius, radius, radius))

    def standard_stile(self):
        self.stil("rahmen", (0.05, 0.27, 0.16, 1), rand=GOLD, breite=7, radius=34)
        self.stil("tisch", (0.03, 0.17, 0.10, 0.9), rand=(0.91, 0.74, 0.33, 0.6), breite=2, radius=12)
        self.stil("leer", (0, 0, 0, 0), rand=(0, 0, 0, 0), breite=0, radius=0)
        self.stil("gold_n", (0.88, 0.66, 0.22, 1), rand=(1, 0.93, 0.6, 1), breite=3, radius=16)
        self.stil("gold_h", (1.0, 0.80, 0.34, 1), rand=(1, 1, 0.8, 1), breite=3, radius=16)
        self.stil("gold_g", (0.35, 0.30, 0.18, 1), rand=(0.6, 0.55, 0.4, 1), breite=3, radius=16)
        self.stil("knopf_n", (0.10, 0.12, 0.11, 0.92), rand=(0.91, 0.74, 0.33, 0.7), breite=2, radius=14)
        self.stil("knopf_h", (0.18, 0.21, 0.19, 0.95), rand=(1, 0.9, 0.5, 1), breite=2, radius=14)
        self.stil("knopf_g", (0.10, 0.12, 0.11, 0.5), rand=(0.5, 0.45, 0.3, 0.5), breite=2, radius=14)
        self.stil("banner", (0.02, 0.08, 0.05, 0.88), rand=GOLD, breite=3, radius=22)

    # ------------------------------------------------------------ Knoten
    def node(self, name, typ, parent, eig="", uniq=False):
        t = '[node name="%s" type="%s"%s]\n' % (name, typ, ' parent="%s"' % parent if parent is not None else "")
        if uniq:
            t += "unique_name_in_owner = true\n"
        self.knoten.append(t + eig + "\n")

    @staticmethod
    def rect(x, y, w, h):
        return "layout_mode = 0\noffset_left = %s\noffset_top = %s\noffset_right = %s\noffset_bottom = %s\n" % (x, y, x + w, y + h)

    def geruest(self, titel_key):
        self.node(self.wurzel, "CanvasLayer", None, 'layer = 26\nscript = ExtResource("skript")\n')
        self.node("Dunkel", "ColorRect", self.wurzel, "anchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\ncolor = Color(0, 0, 0, 0.45)\n")
        self.node("Buehne", "Control", self.wurzel, 'layout_mode = 3\nanchors_preset = 8\nanchor_left = 0.5\nanchor_top = 0.5\nanchor_right = 0.5\nanchor_bottom = 0.5\noffset_left = -800.0\noffset_top = -450.0\noffset_right = 800.0\noffset_bottom = 450.0\ngrow_horizontal = 2\ngrow_vertical = 2\npivot_offset = Vector2(800, 450)\ntheme = ExtResource("theme")\n', True)
        self.node("Rahmen", "Panel", "Buehne", "layout_mode = 0\noffset_right = 1600.0\noffset_bottom = 900.0\n" + 'theme_override_styles/panel = SubResource("rahmen")\n')
        self.node("Titel", "Label", "Buehne", self.rect(60, 26, 700, 80) + 'theme_override_colors/font_color = Color(1, 0.84, 0.35, 1)\ntheme_override_fonts/font = ExtResource("fraktur")\ntheme_override_font_sizes/font_size = 64\ntext = "%s"\n' % titel_key)
        self.node("Kasse", "Label", "Buehne", self.rect(1000, 40, 480, 60) + 'theme_override_colors/font_color = Color(1, 0.93, 0.7, 1)\ntheme_override_font_sizes/font_size = 36\nhorizontal_alignment = 2\nauto_translate_mode = 2\n', True)
        self.node("Schliessen", "Button", "Buehne", self.rect(1510, 30, 60, 60) + 'focus_mode = 0\ntheme_override_font_sizes/font_size = 30\ntheme_override_styles/normal = SubResource("knopf_n")\ntheme_override_styles/hover = SubResource("knopf_h")\ntheme_override_styles/pressed = SubResource("knopf_h")\ntheme_override_styles/focus = SubResource("leer")\ntext = "X"\n', True)

    def knopf(self, name, x, y, w, h, text, groesse=26, gold=False, parent="Buehne"):
        if gold:
            s = ('theme_override_styles/normal = SubResource("gold_n")\ntheme_override_styles/hover = SubResource("gold_h")\ntheme_override_styles/pressed = SubResource("gold_h")\ntheme_override_styles/disabled = SubResource("gold_g")\n'
                 'theme_override_colors/font_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_hover_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_pressed_color = Color(0.15, 0.08, 0.02, 1)\ntheme_override_colors/font_disabled_color = Color(0.5, 0.45, 0.35, 1)\n')
        else:
            s = 'theme_override_styles/normal = SubResource("knopf_n")\ntheme_override_styles/hover = SubResource("knopf_h")\ntheme_override_styles/pressed = SubResource("knopf_h")\ntheme_override_styles/disabled = SubResource("knopf_g")\ntheme_override_colors/font_disabled_color = Color(0.5, 0.5, 0.45, 1)\n'
        self.node(name, "Button", parent, self.rect(x, y, w, h) + 'focus_mode = 0\ntheme_override_font_sizes/font_size = %d\ntheme_override_styles/focus = SubResource("leer")\n%stext = "%s"\n' % (groesse, s, text), True)

    def label(self, name, x, y, w, h, text="", groesse=30, farbe=(1, 0.93, 0.7, 1), ausrichtung=0, parent="Buehne", uniq=True, extra=""):
        self.node(name, "Label", parent, self.rect(x, y, w, h) + 'theme_override_colors/font_color = Color(%s)\ntheme_override_font_sizes/font_size = %d\nhorizontal_alignment = %d\nvertical_alignment = 1\nauto_translate_mode = %d\nmouse_filter = 2\n%s%s'
                  % (", ".join(str(c) for c in farbe), groesse, ausrichtung, 1 if text.startswith("") and text and text.isupper() else 2, 'text = "%s"\n' % text if text else "", extra), uniq)

    def jetons(self, y, x0=60, werte=(10, 50, 100, 500, 1000), abstand=118, auswahl=True):
        """Jetons zum Anklicken mit Auswahlrahmen: jeton_<wert>, JetonAuswahl"""
        if auswahl:
            self.node("JetonAuswahl", "Panel", "Buehne", self.rect(x0 - 10, y - 10, 100, 100) + 'theme_override_styles/panel = SubResource("gold_n")\nmouse_filter = 2\n', True)
        for i, wert in enumerate(werte):
            b = self.bild("res://assets/casino/chip_%d.png" % wert, "c_%d" % wert)
            self.node("jeton_%d" % wert, "TextureButton", "Buehne", self.rect(x0 + i * abstand, y, 80, 80) + 'focus_mode = 0\ntexture_normal = %s\nignore_texture_size = true\nstretch_mode = 5\n' % b, True)

    def gewinnregen(self, x, y):
        b = self.bild("res://assets/casino/chip_10.png", "c_10")
        self.node("Gewinnregen", "CPUParticles2D", "Buehne", 'position = Vector2(%s, %s)\nemitting = false\namount = 46\nlifetime = 2.4\none_shot = true\nexplosiveness = 0.92\ntexture = %s\ndirection = Vector2(0, -1)\nspread = 55.0\ngravity = Vector2(0, 1100)\ninitial_velocity_min = 600.0\ninitial_velocity_max = 1100.0\nangular_velocity_min = -360.0\nangular_velocity_max = 360.0\nscale_amount_min = 0.22\nscale_amount_max = 0.42\nlocal_coords = true\n' % (x, y, b), True)

    def schreiben(self, name):
        text = ("[gd_scene format=3]\n\n" + "\n".join(self.ext) + "\n\n" + "\n".join(self.subs) + "\n" + "".join(self.knoten)).replace('parent="%s"' % self.wurzel, 'parent="."')
        pfad = os.path.join(ROOT, "scenes", "ui", name)
        open(pfad, "w", encoding="utf-8", newline="\n").write(text.rstrip() + "\n")
        print("geschrieben", pfad, len(self.knoten), "Knoten")
