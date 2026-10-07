# Erzeugt scenes/wohnwagen_innen.tscn (Einmal-Werkzeug: python tools/bake_wohnwagen_innen.py)
# Länge x -3.1..3.1, Breite z -1.4..1.4, Wände 2.2 hoch, Dach mit Schrägen bis 2.5.
import math

M = "res://assets/zelt/materialien/"
mats = {k: M + v + ".tres" for k, v in dict(
    dielen="dielen", vert="vertaefelung", creme="creme_lack", holz="holz_hell", dunkel="holz_dunkel",
    rot="rot", weiss="weiss", orange="orange_lack", stoff="stoff", vorhang="vorhang_rot", messing="messing",
    schwarz="schwarz_lack", metall="metall", papier="papier", blau="blau", glas="glas").items()}
ext = [("Script", "res://scripts/wohnwagen_ding.gd", "ding"), ("Script", "res://scripts/welt_text.gd", "wt"),
       ("PackedScene", "res://scenes/wohnwagen_laptop.tscn", "laptop"), ("Script", "res://scripts/wagen_ausbau.gd", "ausbau")]
subs = []
sid = {}


def sub(typ, size):
    key = (typ, size)
    if key not in sid:
        i = "S%d" % len(sid)
        sid[key] = i
        subs.append('[sub_resource type="%s" id="%s"]\nsize = Vector3(%g, %g, %g)\n' % (typ, i, *size))
    return sid[key]


nodes = []


def node(name, parent, typ="Node3D", props="", pos=(0, 0, 0), rot=None, inst=None):
    t = "Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)" % pos
    if rot:
        t = "Transform3D(%s, %g, %g, %g)" % (rot, *pos)
    head = '[node name="%s"' % name
    if not inst:
        head += ' type="%s"' % typ
    if parent:
        head += ' parent="%s"' % parent
    if inst:
        head += ' instance=ExtResource("%s")' % inst
    head += "]"
    nodes.append(head + "\n" + ("transform = %s\n" % t if (pos != (0, 0, 0) or rot) else "") + props + "\n")


def box(name, parent, size, pos, mat, rot=None):
    node(name, parent, "MeshInstance3D",
         'mesh = SubResource("%s")\nsurface_material_override/0 = ExtResource("m_%s")\n' % (sub("BoxMesh", size), mat), pos, rot)


def koll(name, parent, size, pos):
    node(name, parent, "CollisionShape3D", 'shape = SubResource("%s")\n' % sub("BoxShape3D", size), pos)


def rotx(deg):
    c, s = math.cos(math.radians(deg)), math.sin(math.radians(deg))
    return "1, 0, 0, 0, %.4f, %.4f, 0, %.4f, %.4f" % (c, -s, s, c)


L, B, H = 6.2, 2.8, 2.2
node("WohnwagenInnen", "")
node("Huelle", ".", "StaticBody3D")
box("Boden", "Huelle", (L, 0.2, B), (0, -0.1, 0), "dielen")
koll("FormBoden", "Huelle", (L, 0.2, B), (0, -0.1, 0))
koll("FormDecke", "Huelle", (L, 0.2, B), (0, 2.5, 0))
koll("FormNord", "Huelle", (L, H, 0.1), (0, H / 2, -1.45))
koll("FormSued", "Huelle", (L, H, 0.1), (0, H / 2, 1.45))
koll("FormWest", "Huelle", (0.1, H, B), (-3.15, H / 2, 0))
koll("FormOst", "Huelle", (0.1, H, B), (3.15, H / 2, 0))
# Decke und Dachschrägen (Holzdecke mit Leisten)
box("Decke", "Huelle", (L, 0.08, 1.4), (0, 2.5, 0), "holz")
for nm, sg in (("DachSued", 1), ("DachNord", -1)):
    box(nm, "Huelle", (L, 0.08, 0.78), (0, 2.35, 1.05 * sg), "creme", rotx(23.2 * sg))
for i, z in enumerate((-0.7, 0.7)):
    box("LeisteMitte%d" % i, "Huelle", (L, 0.05, 0.06), (0, 2.45, z), "dunkel")
for i, x in enumerate((-2.4, -0.8, 0.8, 2.4)):
    box("Spant%d" % i, "Huelle", (0.08, 0.06, 2.8), (x, 2.46, 0), "dunkel")
# Stirnwände samt Dachkappen
for nm, x in (("West", -3.15), ("Ost", 3.15)):
    box("Wand%sU" % nm, "Huelle", (0.1, 1.0, B), (x, 0.5, 0), "vert")
    box("Wand%sO" % nm, "Huelle", (0.1, 1.2, B), (x, 1.6, 0), "creme")
    box("Kappe%s" % nm, "Huelle", (0.1, 0.46, 1.4), (x, 2.37, 0), "creme")
    for nn, sg in (("S", 1), ("N", -1)):
        box("Kappe%s%s" % (nm, nn), "Huelle", (0.1, 0.42, 0.78), (x, 2.33, 1.05 * sg), "creme", rotx(23.2 * sg))


def laengswand(name, z, innen, oeffnungen):
    """oeffnungen: (xmitte, breite, y0, y1). Wand in Segmente zerlegt, damit keine Lücken bleiben."""
    segs = []
    cur = -3.1
    for xm, w, y0, y1 in sorted(oeffnungen):
        segs.append((cur, xm - w / 2))
        cur = xm + w / 2
    segs.append((cur, 3.1))
    n = 0
    for a, b in segs:
        if b - a > 0.001:
            for (ya, yb, m) in ((0, 1.0, "vert"), (1.0, H, "creme")):
                box("%s_%d%s" % (name, n, m), "Huelle", (b - a, yb - ya, 0.1), ((a + b) / 2, (ya + yb) / 2, z), m)
            n += 1
    for xm, w, y0, y1 in oeffnungen:
        for (ya, yb) in ((0, y0), (y1, H)):
            if yb - ya > 0.001:
                if ya < 1.0 < yb:
                    box("%s_Br%d" % (name, n), "Huelle", (w, 1.0 - ya, 0.1), (xm, (ya + 1.0) / 2, z), "vert")
                    box("%s_Cr%d" % (name, n), "Huelle", (w, yb - 1.0, 0.1), (xm, (1.0 + yb) / 2, z), "creme")
                else:
                    box("%s_Br%d" % (name, n), "Huelle", (w, yb - ya, 0.1), (xm, (ya + yb) / 2, z), "vert" if yb <= 1.0 else "creme")
                n += 1
        box("%s_RahmenL%d" % (name, n), "Huelle", (0.06, y1 - y0, 0.14), (xm - w / 2 + 0.03, (y0 + y1) / 2, z), "dunkel")
        box("%s_RahmenR%d" % (name, n), "Huelle", (0.06, y1 - y0, 0.14), (xm + w / 2 - 0.03, (y0 + y1) / 2, z), "dunkel")
        box("%s_RahmenO%d" % (name, n), "Huelle", (w, 0.06, 0.14), (xm, y1 - 0.03, z), "dunkel")
        if y0 > 0.05:
            vz = z + innen * 0.08
            box("%s_RahmenU%d" % (name, n), "Huelle", (w, 0.06, 0.14), (xm, y0 + 0.03, z), "dunkel")
            box("%s_Sprosse%d" % (name, n), "Huelle", (0.04, y1 - y0, 0.08), (xm, (y0 + y1) / 2, z), "dunkel")
            box("%s_Scheibe%d" % (name, n), "Huelle", (w - 0.1, y1 - y0 - 0.1, 0.02), (xm, (y0 + y1) / 2, z), "glas")
            box("%s_VorhangL%d" % (name, n), "Huelle", (0.28, y1 - y0 + 0.15, 0.03), (xm - w / 2 + 0.14, (y0 + y1) / 2, vz), "vorhang")
            box("%s_VorhangR%d" % (name, n), "Huelle", (0.28, y1 - y0 + 0.15, 0.03), (xm + w / 2 - 0.14, (y0 + y1) / 2, vz), "vorhang")
            box("%s_Gardine%d" % (name, n), "Huelle", (w + 0.1, 0.03, 0.03), (xm, y1 + 0.1, vz), "messing")
            box("%s_Sims%d" % (name, n), "Huelle", (w + 0.12, 0.04, 0.12), (xm, y0 - 0.02, vz), "holz")
        n += 1
    box(name + "_Fuss", "Huelle", (L, 0.1, 0.03), (0, 0.05, z + innen * 0.065), "dunkel")
    box(name + "_Zier", "Huelle", (L, 0.05, 0.04), (0, 1.0, z + innen * 0.07), "dunkel")


laengswand("Nord", -1.45, 1, [(-1.9, 1.0, 1.15, 1.75), (0.6, 1.0, 1.15, 1.75)])
laengswand("Sued", 1.45, -1, [(-2.0, 1.0, 1.15, 1.75), (1.7, 1.0, 1.15, 1.75), (-0.2, 1.0, 0.0, 2.05)])
for nm, x, si in (("West", -3.1, 1), ("Ost", 3.1, -1)):
    box("Fuss" + nm, "Huelle", (0.03, 0.1, B - 0.1), (x + si * 0.015, 0.05, 0), "dunkel")
    box("Zier" + nm, "Huelle", (0.04, 0.05, B - 0.1), (x + si * 0.02, 1.0, 0), "dunkel")
# Läufer, Dachluke
box("Teppich", ".", (2.0, 0.02, 0.9), (-0.2, 0.011, 0.0), "rot")
box("TeppichRand", ".", (2.1, 0.015, 1.0), (-0.2, 0.008, 0.0), "orange")
box("LukeRahmen", ".", (0.7, 0.04, 0.7), (1.2, 2.5, 0.0), "dunkel")
box("LukeGlas", ".", (0.56, 0.02, 0.56), (1.2, 2.47, 0.0), "glas")
# Küchenzeile an der Südwand (Ostende)
box("KuecheSockel", ".", (1.8, 0.82, 0.55), (2.0, 0.41, 1.12), "holz")
for i, x in enumerate((1.45, 2.05, 2.65)):
    box("KuecheTuer%d" % i, ".", (0.55, 0.62, 0.02), (x, 0.4, 0.84), "dunkel")
box("KuechePlatte", ".", (1.84, 0.05, 0.58), (2.0, 0.845, 1.1), "weiss")
box("Spuele", ".", (0.5, 0.03, 0.36), (1.5, 0.87, 1.12), "metall")
box("Hahn", ".", (0.04, 0.2, 0.04), (1.5, 0.98, 1.3), "messing")
for i, (x, z) in enumerate(((2.2, 1.0), (2.55, 1.0), (2.2, 1.28), (2.55, 1.28))):
    box("Herdplatte%d" % i, ".", (0.2, 0.02, 0.2), (x, 0.88, z), "schwarz")
box("KuechenSchrank", ".", (1.8, 0.5, 0.34), (2.0, 1.95, 1.23), "holz")
node("KuecheBody", ".", "StaticBody3D")
koll("KuecheForm", "KuecheBody", (1.8, 0.85, 0.55), (2.0, 0.425, 1.12))
# Bett (Skript) am Westende, längs an der Nordwand
node("Bett", ".", "Node3D", 'script = ExtResource("ding")\nart = "bett"\n', (-1.95, 0, -0.82))
box("Rahmen", "Bett", (2.0, 0.35, 1.1), (0, 0.175, 0), "holz")
box("Matratze", "Bett", (1.92, 0.2, 1.02), (0, 0.45, 0), "weiss")
box("Decke", "Bett", (1.3, 0.08, 1.06), (0.3, 0.58, 0), "orange")
box("Kissen", "Bett", (0.5, 0.12, 0.8), (-0.7, 0.6, 0), "stoff")
box("Kopfteil", "Bett", (0.08, 0.7, 1.1), (-1.04, 0.55, 0), "dunkel")
node("Body", "Bett", "StaticBody3D")
koll("Form", "Bett/Body", (2.0, 0.6, 1.1), (0, 0.3, 0))
node("Label", "Bett", "Label3D", 'billboard = 1\npixel_size = 0.005\nfont_size = 40\nmodulate = Color(1, 0.9, 0.6, 1)\ntext = "WORLD_BETT"\nscript = ExtResource("wt")\nschluessel = "WORLD_BETT"\n', (0, 1.4, 0))
box("SchrankBett", ".", (1.7, 0.4, 0.38), (-1.9, 2.0, -1.2), "holz")
box("SchrankSofa", ".", (1.7, 0.4, 0.38), (0.6, 2.0, -1.2), "holz")
node("Laptop", ".", inst="laptop", rot="0, 0, 1, 0, 1, 0, -1, 0, 0", pos=(2.4, 0, -0.5))
# Ausgang (Tür in der Südwand)
node("Ausgang", ".", "Node3D", 'script = ExtResource("ding")\nart = "ausgang"\n', (-0.2, 0, 1.41))
box("Blatt", "Ausgang", (0.95, 2.05, 0.06), (0, 1.025, -0.03), "holz")
box("TuerFuellung", "Ausgang", (0.7, 0.8, 0.02), (0, 1.5, -0.07), "dunkel")
box("TuerFuellung2", "Ausgang", (0.7, 0.8, 0.02), (0, 0.55, -0.07), "dunkel")
box("Griff", "Ausgang", (0.04, 0.04, 0.1), (0.32, 1.0, -0.1), "messing")
node("Label", "Ausgang", "Label3D", 'billboard = 1\npixel_size = 0.005\nfont_size = 40\nmodulate = Color(1, 0.9, 0.6, 1)\ntext = "WORLD_WAGEN_AUSGANG"\nscript = ExtResource("wt")\nschluessel = "WORLD_WAGEN_AUSGANG"\n', (0, 2.3, -0.1))
node("Eingang", ".", "Marker3D", pos=(-0.2, 0.1, 0.7))
node("Lampe", ".", "OmniLight3D", 'light_color = Color(1, 0.88, 0.7, 1)\nlight_energy = 0.9\nomni_range = 5.0\n', (0, 2.2, 0))
box("LampenSchirm", ".", (0.3, 0.06, 0.3), (0, 2.44, 0), "weiss")
# Ausbau: Kindernamen = Kaufschlüssel (scripts/wagen_ausbau.gd)
node("Ausbau", ".", "Node3D", 'script = ExtResource("ausbau")\n')
node("Sofa", "Ausbau", pos=(0.6, 0, -0.95))
box("Sitz", "Ausbau/Sofa", (1.8, 0.4, 0.8), (0, 0.2, 0), "stoff")
box("Lehne", "Ausbau/Sofa", (1.8, 0.55, 0.22), (0, 0.55, -0.3), "stoff")
box("ArmL", "Ausbau/Sofa", (0.22, 0.3, 0.8), (-0.9, 0.45, 0), "stoff")
box("ArmR", "Ausbau/Sofa", (0.22, 0.3, 0.8), (0.9, 0.45, 0), "stoff")
box("Kissen", "Ausbau/Sofa", (0.4, 0.4, 0.12), (-0.55, 0.62, -0.12), "orange", rotx(-12))
box("Poster", "Ausbau", (0.7, 0.9, 0.02), (2.3, 1.55, -1.39), "papier")
box("PosterRahmen", "Ausbau", (0.78, 0.98, 0.015), (2.3, 1.55, -1.395), "dunkel")
node("Pflanze", "Ausbau", pos=(2.75, 0, -1.1))
box("Topf", "Ausbau/Pflanze", (0.3, 0.3, 0.3), (0, 0.15, 0), "orange")
nodes.append('[node name="Laub" type="MeshInstance3D" parent="Ausbau/Pflanze"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.6, 0)\nmesh = SubResource("Laub")\nsurface_material_override/0 = SubResource("Gruen")\n')
node("Regal", "Ausbau", pos=(-2.85, 1.3, 0.55))
box("Brett", "Ausbau/Regal", (0.3, 0.05, 1.2), (0, 0, 0), "dunkel")
nodes.append('[node name="GoldKrug" type="MeshInstance3D" parent="Ausbau/Regal"]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0.105, 0)\nvisible = false\nmesh = SubResource("Krug")\nsurface_material_override/0 = SubResource("Gold")\n')

out = ["[gd_scene format=3]\n"]
for typ, path, i in ext:
    out.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, path, i))
for k, p in mats.items():
    out.append('[ext_resource type="Material" path="%s" id="m_%s"]' % (p, k))
out.append("")
out += subs
out.append('[sub_resource type="SphereMesh" id="Laub"]\nradius = 0.32\nheight = 0.64\n')
out.append('[sub_resource type="StandardMaterial3D" id="Gruen"]\nalbedo_color = Color(0.2, 0.55, 0.25, 1)\n')
out.append('[sub_resource type="CylinderMesh" id="Krug"]\ntop_radius = 0.07\nbottom_radius = 0.06\nheight = 0.16\n')
out.append('[sub_resource type="StandardMaterial3D" id="Gold"]\nalbedo_color = Color(0.95, 0.75, 0.2, 1)\nmetallic = 0.9\nroughness = 0.25\n')
out += nodes
open("scenes/wohnwagen_innen.tscn", "w", encoding="utf-8", newline="\n").write("\n".join(out))
