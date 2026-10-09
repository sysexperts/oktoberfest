"""Scherzbrille für die Casino-Tarnung (Gustavs Komplettset): runde schwarze Fassung, buschige Augenbrauen,
große Nase, Schnurrbart. Für Männer und Frauen gleich, im Charakter-Creator nicht auswählbar.
Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/tarnbrille.py
Ergebnis: assets/creator/brillen/tarnbrille.glb (Teile: rahmen_farbe, augenbrauen, nase, nasenspitze, nasenloecher, schnauzer)
und build/blender/tarnbrille.png (Vorschau). Maße wie die anderen Brillen (Kopfmitte y = 1,305, Vorderkante z ≈ 0,22).
Blickrichtung: Blender -Y entspricht Godot +Z. Die Funktion g() rechnet Godot-Koordinaten in Blender um.
"""
import math
import os
import random

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.makedirs(os.path.join(ROOT, "build", "blender"), exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
random.seed(7)


def g(x, y, z):
    """Godot (x rechts, y oben, z vorn) -> Blender (x, -z, y)"""
    return Vector((x, -z, y))


def srgb(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def mat(name, farbe, rauheit=0.7):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*srgb(farbe), 1.0)
    b.inputs["Roughness"].default_value = rauheit
    m.diffuse_color = (*srgb(farbe), 1.0)
    return m


SCHWARZ = mat("Schwarz", (0.03, 0.03, 0.035), 0.55)
HAUT = mat("NaseHaut", (0.93, 0.66, 0.55), 0.6)
ROSA = mat("NasenSpitze", (0.95, 0.60, 0.55), 0.5)


def fertig(obj, name, material, glatt=True):
    obj.name = name
    obj.data.name = name
    obj.data.materials.clear()
    obj.data.materials.append(material)
    if glatt:
        for p in obj.data.polygons:
            p.use_smooth = True
    return obj


def verbinden(liste, name, material, glatt=False):
    bpy.ops.object.select_all(action="DESELECT")
    for o in liste:
        o.select_set(True)
    bpy.context.view_layer.objects.active = liste[0]
    bpy.ops.object.join()
    return fertig(bpy.context.active_object, name, material, glatt)


def strecke(p1, p2, r, verts=8):
    """Zylinder von p1 nach p2 (Godot-Koordinaten)"""
    a, b = g(*p1), g(*p2)
    d = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    return o


def zacke(basis, richtung, laenge, radius):
    """Spitzer Büschel-Kegel: Basis und Richtung in Godot-Koordinaten"""
    a = g(*basis)
    d = g(*richtung).normalized() if False else (g(*richtung) - g(0, 0, 0)).normalized()
    bpy.ops.mesh.primitive_cone_add(vertices=5, radius1=radius, radius2=0.0, depth=laenge, location=a + d * laenge / 2)
    o = bpy.context.active_object
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = d.to_track_quat("Z", "Y")
    return o


# ------------------------------------------------------------------ Fassung
MITTE_Y = 1.305
FRONT_Z = 0.214
teile = []
for seite in (-1, 1):
    bpy.ops.mesh.primitive_torus_add(major_radius=0.074, minor_radius=0.0095, major_segments=32, minor_segments=8,
                                     location=g(seite * 0.098, MITTE_Y, FRONT_Z), rotation=(math.radians(90), 0, 0))
    teile.append(bpy.context.active_object)
    teile.append(strecke((seite * 0.172, MITTE_Y, FRONT_Z - 0.004), (seite * 0.212, MITTE_Y + 0.004, -0.08), 0.0075))
teile.append(strecke((-0.026, MITTE_Y + 0.012, FRONT_Z), (0.026, MITTE_Y + 0.012, FRONT_Z), 0.0075))
verbinden(teile, "rahmen_farbe", SCHWARZ, True)

# ------------------------------------------------------------------ Augenbrauen (buschig, nach oben abstehend)
brauen = []
for seite in (-1, 1):
    cx = seite * 0.098
    for i in range(22):
        t = (i / 21.0) * 2.0 - 1.0                      # -1 .. 1 über die Breite
        x = cx + t * 0.078
        y = MITTE_Y + 0.082 + 0.012 * (1.0 - t * t)      # leicht gewölbt
        z = FRONT_Z + random.uniform(-0.004, 0.012)
        # nach oben und nach außen abstehend
        rich = (seite * (0.35 + 0.25 * t * seite) + random.uniform(-0.15, 0.15), 1.0, random.uniform(0.0, 0.25))
        brauen.append(zacke((x, y, z), rich, random.uniform(0.032, 0.05), 0.010))
verbinden(brauen, "augenbrauen", SCHWARZ)

# ------------------------------------------------------------------ Nase (groß, knollig, wie bei der Scherzbrille)
def kugel(name, radius, pos, skala, material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=28, ring_count=18, radius=radius, location=g(*pos))
    o = bpy.context.active_object
    o.scale = skala
    bpy.ops.object.transform_apply(scale=True)
    return fertig(o, name, material)


nasenteile = []
# Nasenrücken: schmal zwischen den Gläsern, nach unten breiter, schiebt sich vor
nasenteile.append(kugel("n1", 0.024, (0.0, MITTE_Y - 0.008, FRONT_Z + 0.024), (0.95, 1.9, 1.2), HAUT))
nasenteile.append(kugel("n2", 0.032, (0.0, MITTE_Y - 0.040, FRONT_Z + 0.056), (1.0, 1.6, 1.3), HAUT))
# große Knolle und die beiden Nasenflügel
nasenteile.append(kugel("n3", 0.050, (0.0, MITTE_Y - 0.086, FRONT_Z + 0.088), (1.05, 0.92, 1.1), HAUT))
nasenteile.append(kugel("n4", 0.030, (-0.038, MITTE_Y - 0.096, FRONT_Z + 0.070), (1.0, 0.95, 0.95), HAUT))
nasenteile.append(kugel("n5", 0.030, (0.038, MITTE_Y - 0.096, FRONT_Z + 0.070), (1.0, 0.95, 0.95), HAUT))
verbinden(nasenteile, "nase", HAUT, True)
# rosa Spitze vorn, glänzend wie ein Clownsknopf
kugel("nasenspitze", 0.027, (0.0, MITTE_Y - 0.090, FRONT_Z + 0.134), (1.0, 0.9, 0.8), ROSA)
# zwei dunkle Nasenlöcher unter der Knolle
NASENLOCH = mat("Nasenloch", (0.25, 0.08, 0.08), 0.8)
loecher = [kugel("l1", 0.0105, (-0.017, MITTE_Y - 0.124, FRONT_Z + 0.112), (1.0, 0.7, 1.4), NASENLOCH),
           kugel("l2", 0.0105, (0.017, MITTE_Y - 0.124, FRONT_Z + 0.112), (1.0, 0.7, 1.4), NASENLOCH)]
verbinden(loecher, "nasenloecher", NASENLOCH, True)

# ------------------------------------------------------------------ Schnurrbart (borstig, unter der Nase)
bart = []
for i in range(52):
    t = (i / 51.0) * 2.0 - 1.0
    x = t * 0.098
    y = MITTE_Y - 0.122 - 0.010 * abs(t) + random.uniform(-0.004, 0.004)
    z = FRONT_Z + 0.094 - 0.046 * abs(t) + random.uniform(-0.004, 0.004)
    rich = (t * 0.8 + random.uniform(-0.2, 0.2), -1.0, random.uniform(0.15, 0.55))
    bart.append(zacke((x, y, z), rich, random.uniform(0.024, 0.040), 0.009))
verbinden(bart, "schnauzer", SCHWARZ)

# ------------------------------------------------------------------ Vorschau
bpy.ops.object.light_add(type="SUN", location=(0, -3, 3))
bpy.context.active_object.data.energy = 3.0
bpy.ops.object.camera_add(location=g(0.0, MITTE_Y - 0.02, 0.9))
kam = bpy.context.active_object
kam.rotation_euler = (math.radians(90), 0, math.radians(180))
kam.data.lens = 70
bpy.context.scene.camera = kam
bpy.context.scene.render.resolution_x = 700
bpy.context.scene.render.resolution_y = 600
bpy.context.scene.render.filepath = os.path.join(ROOT, "build", "blender", "tarnbrille.png")
bpy.context.scene.world = bpy.data.worlds.new("w")
bpy.context.scene.world.color = (0.9, 0.9, 0.92)
bpy.ops.render.render(write_still=True)

# ------------------------------------------------------------------ Export
for o in list(bpy.data.objects):
    if o.type in ("LIGHT", "CAMERA"):
        bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "assets", "creator", "brillen", "tarnbrille.glb"),
                          export_format="GLB", export_apply=True)
print("TARNBRILLE FERTIG")
