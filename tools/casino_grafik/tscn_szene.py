"""Kleiner Baukasten, um eine .tscn-Szene aus Python zu schreiben (Materialien, Meshes, Knoten, Transformationen).
Wird von bauen_casino_tscn.py benutzt. Die erzeugte Szene ist danach normal im Godot-Editor bearbeitbar."""
import math
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))


def mat_mul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]


def drehung(ry=0.0, rx=0.0, rz=0.0):
    """Zeilenmatrix R = Ry * Rx * Rz (Winkel in Grad, Godot: Drehung um Y positiv = gegen den Uhrzeigersinn von oben)"""
    a, b, c = math.radians(ry), math.radians(rx), math.radians(rz)
    my = [[math.cos(a), 0, math.sin(a)], [0, 1, 0], [-math.sin(a), 0, math.cos(a)]]
    mx = [[1, 0, 0], [0, math.cos(b), -math.sin(b)], [0, math.sin(b), math.cos(b)]]
    mz = [[math.cos(c), -math.sin(c), 0], [math.sin(c), math.cos(c), 0], [0, 0, 1]]
    return mat_mul(my, mat_mul(mx, mz))


def tf(x=0.0, y=0.0, z=0.0, ry=0.0, rx=0.0, rz=0.0, skala=None):
    r = drehung(ry, rx, rz)
    if skala:
        sx, sy, sz = skala
        r = [[r[i][0] * sx, r[i][1] * sy, r[i][2] * sz] for i in range(3)]
    f = lambda v: ("%.5f" % v).rstrip("0").rstrip(".") if abs(v) > 1e-9 else "0"
    return "transform = Transform3D(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)\n" % (
        f(r[0][0]), f(r[0][1]), f(r[0][2]), f(r[1][0]), f(r[1][1]), f(r[1][2]), f(r[2][0]), f(r[2][1]), f(r[2][2]), f(x), f(y), f(z))


class Szene:
    def __init__(self):
        self.ext = []
        self.subs = []
        self.knoten = []
        self.ids = set()
        self.zaehler = {}

    def res(self, typ, pfad, name):
        if name not in self.ids:
            self.ids.add(name)
            self.ext.append('[ext_resource type="%s" path="%s" id="%s"]' % (typ, pfad, name))
        return 'ExtResource("%s")' % name

    def sub(self, name, typ, eig):
        if name not in self.ids:
            self.ids.add(name)
            self.subs.append('[sub_resource type="%s" id="%s"]\n%s' % (typ, name, eig))
        return 'SubResource("%s")' % name

    # ------------------------------------------------------------ Materialien und Meshes
    def material(self, name, farbe, rau=0.7, metall=0.0, leuchte=None, energie=1.0, textur=None, kachel=None, transparenz=None, uv=None):
        eig = "albedo_color = Color(%s)\nroughness = %s\nmetallic = %s\n" % (", ".join(str(c) for c in farbe), rau, metall)
        if textur:
            eig += "albedo_texture = %s\n" % textur
        if kachel:
            eig += "uv1_triplanar = true\nuv1_scale = Vector3(%s, %s, %s)\ntexture_filter = 5\n" % (kachel, kachel, kachel)
        if uv:
            eig += "uv1_scale = Vector3(%s, %s, 1)\n" % uv
        if leuchte:
            eig += "emission_enabled = true\nemission = Color(%s)\nemission_energy_multiplier = %s\n" % (", ".join(str(c) for c in leuchte), energie)
        if transparenz:
            eig += "transparency = %d\nalpha_scissor_threshold = 0.4\ncull_mode = 2\n" % transparenz
        return self.sub(name, "StandardMaterial3D", eig)

    def box(self, groesse):
        n = "B_%s_%s_%s" % tuple(str(round(v, 3)).replace(".", "_").replace("-", "m") for v in groesse)
        return self.sub(n, "BoxMesh", "size = Vector3(%s, %s, %s)\n" % tuple(groesse))

    def zylinder(self, r_oben, r_unten, hoehe, seg=16):
        n = "Z_%s_%s_%s_%d" % (str(r_oben).replace(".", "_"), str(r_unten).replace(".", "_"), str(hoehe).replace(".", "_"), seg)
        return self.sub(n, "CylinderMesh", "top_radius = %s\nbottom_radius = %s\nheight = %s\nradial_segments = %d\nrings = 1\n" % (r_oben, r_unten, hoehe, seg))

    def kugel(self, r, seg=12):
        n = "K_%s_%d" % (str(r).replace(".", "_"), seg)
        return self.sub(n, "SphereMesh", "radius = %s\nheight = %s\nradial_segments = %d\nrings = %d\n" % (r, r * 2, seg, seg // 2))

    def quad(self, b, h):
        n = "Q_%s_%s" % (str(b).replace(".", "_"), str(h).replace(".", "_"))
        return self.sub(n, "QuadMesh", "size = Vector2(%s, %s)\n" % (b, h))

    def torus(self, innen, aussen):
        n = "T_%s_%s" % (str(innen).replace(".", "_"), str(aussen).replace(".", "_"))
        return self.sub(n, "TorusMesh", "inner_radius = %s\nouter_radius = %s\nrings = 24\nring_segments = 8\n" % (innen, aussen))

    def prisma(self, b, h, l):
        n = "P_%s_%s_%s" % (str(b).replace(".", "_"), str(h).replace(".", "_"), str(l).replace(".", "_"))
        return self.sub(n, "PrismMesh", "size = Vector3(%s, %s, %s)\n" % (b, h, l))

    # ------------------------------------------------------------ Knoten
    def node(self, name, typ, parent, eig="", gruppen=None, instanz=None):
        p = "" if parent is None else ' parent="%s"' % parent
        g = ' groups=["%s"]' % '", "'.join(gruppen) if gruppen else ""
        if instanz:
            self.knoten.append('[node name="%s"%s instance=%s]\n%s\n' % (name, p, instanz, eig))
        else:
            self.knoten.append('[node name="%s" type="%s"%s%s]\n%s\n' % (name, typ, p, g, eig))

    def mesh(self, name, parent, mesh, mat, pos=(0, 0, 0), ry=0.0, rx=0.0, rz=0.0, schatten=True):
        eig = tf(pos[0], pos[1], pos[2], ry, rx, rz) + "mesh = %s\nsurface_material_override/0 = %s\n" % (mesh, mat)
        if not schatten:
            eig += "cast_shadow = 0\n"
        self.node(name, "MeshInstance3D", parent, eig)

    def fest(self, name, parent, groesse, pos, mat, ry=0.0, mit_form=True):
        """StaticBody3D mit sichtbarem Quader und Kollision"""
        self.node(name, "StaticBody3D", parent, tf(pos[0], pos[1], pos[2], ry))
        p = name if parent in (None, ".") else parent + "/" + name
        self.node("Mesh", "MeshInstance3D", p, "mesh = %s\nsurface_material_override/0 = %s\n" % (self.box(groesse), mat))
        if mit_form:
            shape = self.sub("S_%s_%s_%s" % tuple(str(round(v, 3)).replace(".", "_") for v in groesse), "BoxShape3D", "size = Vector3(%s, %s, %s)\n" % tuple(groesse))
            self.node("Form", "CollisionShape3D", p, "shape = %s\n" % shape)

    def licht(self, name, parent, pos, farbe=(1, 0.8, 0.55), energie=2.0, reichweite=8.0):
        farbe = tuple(farbe) + (1,) * (4 - len(farbe))
        self.node(name, "OmniLight3D", parent, tf(*pos) + "light_color = Color(%s)\nlight_energy = %s\nomni_range = %s\nlight_specular = 0.3\n" % (", ".join(str(c) for c in farbe), energie, reichweite))

    def schreiben(self, pfad):
        text = "[gd_scene format=3]\n\n" + "\n".join(self.ext) + "\n\n" + "\n".join(self.subs) + "\n" + "".join(self.knoten)
        open(os.path.join(ROOT, pfad), "w", encoding="utf-8", newline="\n").write(text.rstrip() + "\n")
        print("geschrieben", pfad, len(self.knoten), "Knoten")
