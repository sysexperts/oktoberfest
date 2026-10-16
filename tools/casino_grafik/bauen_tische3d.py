"""Erzeugt die Auflagen der Casino-Tische im Raum: scenes/kasino/auflage_blackjack.tscn, auflage_wuerfel.tscn, auflage_watten.tscn
(Aufdruck auf dem Tuch, Karten, Würfel, Becher, Jetonstapel). Aufruf: python -X utf8 tools/casino_grafik/bauen_tische3d.py"""
import os
import math

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AUFDRUCK_DREHUNG = 0
Y = 0.918          # Höhe des Tuchs im Tischmodell (kartentisch.glb)


class Szene:
    def __init__(self, wurzel, skript=None):
        self.wurzel = wurzel
        self.ext = []
        self.subs = []
        self.knoten = []
        self.ids = {}
        if skript:
            self.res("Script", skript, "skript")
        self.n = 0

    def res(self, typ, pfad, name):
        if name not in self.ids:
            self.ids[name] = 1
            self.ext.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, pfad, name))
        return 'ExtResource("%s")' % name

    def tex(self, pfad, name):
        return self.res("Texture2D", pfad, name)

    def sub(self, name, typ, eig):
        if name not in self.ids:
            self.ids[name] = 1
            self.subs.append('[sub_resource type="%s" id="%s"]\n%s' % (typ, name, eig))
        return 'SubResource("%s")' % name

    def node(self, name, typ, parent, eig=""):
        p = "" if parent is None else ' parent="%s"' % parent
        self.knoten.append('[node name="%s" type="%s"%s]\n%s\n' % (name, typ, p, eig))

    def schreiben(self, datei):
        text = "[gd_scene format=3]\n\n" + "\n".join(self.ext) + "\n\n" + "\n".join(self.subs) + "\n" + "".join(self.knoten)
        pfad = os.path.join(ROOT, "scenes", "kasino", datei)
        open(pfad, "w", encoding="utf-8", newline="\n").write(text.rstrip() + "\n")
        print("geschrieben", datei)


def tf(x=0.0, y=Y, z=0.0, ry=0.0, rx=0.0, rz=0.0):
    """Transform3D aus Position und Drehung (Grad, Reihenfolge Y, X, Z)"""
    a, b, c = math.radians(ry), math.radians(rx), math.radians(rz)
    ca, sa, cb, sb, cc, sc = math.cos(a), math.sin(a), math.cos(b), math.sin(b), math.cos(c), math.sin(c)
    # R = Ry * Rx * Rz
    r = [
        [ca * cc + sa * sb * sc, -ca * sc + sa * sb * cc, sa * cb],
        [cb * sc, cb * cc, -sb],
        [-sa * cc + ca * sb * sc, sa * sc + ca * sb * cc, ca * cb],
    ]
    return "transform = Transform3D(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n" % (
        r[0][0], r[1][0], r[2][0], r[0][1], r[1][1], r[2][1], r[0][2], r[1][2], r[2][2], x, y, z)


def aufdruck(s, name):
    tex = s.tex("res://assets/casino/tisch_%s.png" % name, "t_" + name)
    mat = s.sub("M_" + name, "StandardMaterial3D", "transparency = 2\nalpha_scissor_threshold = 0.35\nalbedo_texture = %s\nroughness = 1.0\ncull_mode = 2\n" % tex)
    mesh = s.sub("Q_" + name, "QuadMesh", "material = %s\nsize = Vector2(2.44, 2.44)\n" % mat)
    s.node("Aufdruck", "MeshInstance3D", ".", tf(0, Y + 0.002, 0, rx=90, ry=AUFDRUCK_DREHUNG) + "mesh = %s\ncast_shadow = 0\n" % mesh)


def karte(s, name, pfad, x, z, ry=0.0, bayr=False, ruecken=False):
    tex = s.tex(pfad, "k_" + pfad.split("/")[-1].replace(".png", ""))
    s.node(name, "Sprite3D", ".", tf(x, Y + 0.006, z, ry=ry) + "pixel_size = 0.00029\naxis = 1\ntexture = %s\n" % tex)


def stapel(s, name, x, z, n, farbe, ry=0.0):
    h = 0.011 * n
    mesh = s.sub("C_%s" % name, "CylinderMesh", "top_radius = 0.026\nbottom_radius = 0.026\nheight = %s\nradial_segments = 20\nrings = 1\n" % h)
    mat = s.sub("MC_%s" % name, "StandardMaterial3D", "albedo_color = Color(%s)\nroughness = 0.5\n" % farbe)
    s.node(name, "MeshInstance3D", ".", tf(x, Y + h / 2, z) + "mesh = %s\nsurface_material_override/0 = %s\n" % (mesh, mat))
    rmesh = s.sub("CR_%s" % name, "CylinderMesh", "top_radius = 0.0275\nbottom_radius = 0.0275\nheight = 0.004\nradial_segments = 20\nrings = 1\n")
    rmat = s.sub("MR_%s" % name, "StandardMaterial3D", "albedo_color = Color(0.96, 0.95, 0.9, 1)\nroughness = 0.5\n")
    s.node(name + "Rand", "MeshInstance3D", ".", tf(x, Y + h / 2, z) + "mesh = %s\nsurface_material_override/0 = %s\n" % (rmesh, rmat))


ROT = "0.8, 0.12, 0.14, 1"
BLAU = "0.15, 0.3, 0.75, 1"
GRUEN = "0.1, 0.55, 0.28, 1"
SCHWARZ = "0.08, 0.08, 0.1, 1"


def bj():
    s = Szene("AuflageBlackjack")
    s.node("AuflageBlackjack", "Node3D", None)
    aufdruck(s, "blackjack")
    karte(s, "BankKarte0", "res://assets/casino/karte_pik_ass.png", -0.05, -0.62, ry=4)
    karte(s, "BankKarte1", "res://assets/casino/karte_ruecken.png", 0.05, -0.62, ry=-3)
    karte(s, "SpielerKarte0", "res://assets/casino/karte_herz_koenig.png", -0.05, 0.2, ry=-5)
    karte(s, "SpielerKarte1", "res://assets/casino/karte_karo_9.png", 0.06, 0.2, ry=3)
    stapel(s, "Stapel0", 0.0, 0.786, 4, ROT)
    stapel(s, "Stapel1", -0.39, 0.68, 3, BLAU)
    stapel(s, "Stapel2", 0.39, 0.68, 6, SCHWARZ)
    s.schreiben("auflage_blackjack.tscn")


def wuerfel():
    s = Szene("AuflageWuerfel", "res://scripts/kasino/wuerfel_tisch.gd")
    s.node("AuflageWuerfel", "Node3D", None, 'script = ExtResource("skript")\n')
    aufdruck(s, "wuerfel")
    kante = s.sub("W_Mesh", "BoxMesh", "size = Vector3(0.07, 0.07, 0.07)\n")
    elfenbein = s.sub("W_Mat", "StandardMaterial3D", "albedo_color = Color(0.96, 0.93, 0.84, 1)\nroughness = 0.35\n")
    for i, (x, z, ry) in enumerate(((-0.12, -0.02, 20), (0.1, 0.06, -35))):
        s.node("Wuerfel%d" % i, "MeshInstance3D", ".", tf(x, Y + 0.035, z, ry=ry) + "mesh = %s\nsurface_material_override/0 = %s\n" % (kante, elfenbein))
        tex = s.tex("res://assets/casino/wuerfel_%d.png" % (i + 3), "w%d" % i)
        s.node("Augen", "Sprite3D", "Wuerfel%d" % i, tf(0, 0.0375, 0, rx=0) + "shaded = false\npixel_size = 0.0004\naxis = 1\ntexture = %s\nunique_name_in_owner = false\n" % tex)
    # Becher liegt daneben
    bm = s.sub("B_Mesh", "CylinderMesh", "top_radius = 0.06\nbottom_radius = 0.045\nheight = 0.14\nradial_segments = 20\nrings = 1\n")
    bmat = s.sub("B_Mat", "StandardMaterial3D", "albedo_color = Color(0.42, 0.24, 0.1, 1)\nroughness = 0.7\n")
    s.node("Becher", "MeshInstance3D", ".", tf(0.42, Y + 0.06, -0.12, ry=25, rz=90) + "mesh = %s\nsurface_material_override/0 = %s\n" % (bm, bmat))
    # Jetons auf den Wettfeldern (unterer Bogen)
    for i, (n, farbe) in enumerate(((3, ROT), (5, BLAU), (2, GRUEN))):
        w = math.radians(140 - [0, 1, 2][i] * 33.3 - 33.3 * (1 if i == 0 else 0))
        x = 0.82 * math.cos(w)
        z = 0.82 * math.sin(w)
        stapel(s, "Stapel%d" % i, x, z, n, farbe)
    s.schreiben("auflage_wuerfel.tscn")


def watten():
    s = Szene("AuflageWatten")
    s.node("AuflageWatten", "Node3D", None)
    aufdruck(s, "watten")
    karte(s, "BankKarte", "res://assets/casino/bkarte_laub_ober.png", -0.27, 0.0, ry=5, bayr=True)
    karte(s, "SpielerKarte", "res://assets/casino/bkarte_eichel_koenig.png", 0.27, 0.0, ry=-4, bayr=True)
    for i, (n, ry) in enumerate((("herz_ass", 14), ("schellen_10", 0), ("laub_unter", -14))):
        karte(s, "Hand%d" % i, "res://assets/casino/bkarte_%s.png" % n, -0.12 + i * 0.12, 0.62, ry=ry, bayr=True)
    stapel(s, "Stapel0", 0.0, 0.3, 5, ROT)
    stapel(s, "Stapel1", 0.07, 0.34, 2, BLAU)
    s.schreiben("auflage_watten.tscn")


bj()
wuerfel()
watten()
