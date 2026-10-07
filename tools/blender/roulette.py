"""Roulette-Tisch fürs Casino hinter Konrads Zelt: Holzgestell, grünes Tuch, Kessel mit rot-schwarzen Fächern.
Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/roulette.py
Ergebnis: assets/models/roulette.glb (Knoten Tisch, Kessel — der Kessel dreht sich um die Hochachse, das macht
scripts/kasino/roulette.gd) und build/blender/roulette.png (Vorschau).
Blickrichtung wie bei den Figuren: Blender -Y; der Kessel liegt am +X-Ende des Tisches.
"""
import math
import os

import bpy

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.makedirs(os.path.join(ROOT, "build", "blender"), exist_ok=True)
os.makedirs(os.path.join(ROOT, "assets", "models"), exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def srgb(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def mat(name, farbe, rauheit=0.7, metall=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*srgb(farbe), 1.0)
    b.inputs["Roughness"].default_value = rauheit
    b.inputs["Metallic"].default_value = metall
    m.diffuse_color = (*srgb(farbe), 1.0)
    return m


HOLZ = mat("holz", (0.28, 0.15, 0.08), 0.6)
TUCH = mat("tuch", (0.05, 0.38, 0.18), 0.95)
ROT = mat("rot", (0.75, 0.08, 0.08), 0.5)
SCHWARZ = mat("schwarz", (0.05, 0.05, 0.06), 0.5)
GOLD = mat("gold", (0.9, 0.7, 0.2), 0.3, 0.8)
WEISS = mat("weiss", (0.95, 0.94, 0.9), 0.5)


def quader(name, ort, groesse, material, eltern=None):
    bpy.ops.mesh.primitive_cube_add(location=ort)
    o = bpy.context.active_object
    o.name = name
    o.scale = (groesse[0] / 2, groesse[1] / 2, groesse[2] / 2)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    if eltern:
        o.parent = eltern
    return o


def zylinder(name, ort, radius, tiefe, material, eltern=None, ecken=32):
    bpy.ops.mesh.primitive_cylinder_add(vertices=ecken, radius=radius, depth=tiefe, location=ort)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    if eltern:
        o.parent = eltern
    return o


def leer(name, ort=(0, 0, 0)):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    o.location = ort
    return o


tisch = leer("Tisch")
# Gestell: vier Beine, Rahmen, Platte mit Tuch
quader("Platte", (0, 0, 0.88), (2.6, 1.1, 0.08), HOLZ, tisch)
quader("Tuch", (-0.2, 0, 0.93), (2.0, 0.94, 0.02), TUCH, tisch)
quader("Rahmen", (0, 0, 0.8), (2.5, 1.0, 0.1), HOLZ, tisch)
for x in (-1.15, 1.15):
    for y in (-0.42, 0.42):
        quader("Bein", (x, y, 0.4), (0.12, 0.12, 0.8), HOLZ, tisch)
# Zahlenfelder: rot-schwarze Kacheln auf dem Tuch
for i in range(12):
    for j in range(3):
        farbe = ROT if (i + j) % 2 == 0 else SCHWARZ
        quader("Feld", (-1.0 + i * 0.13, -0.25 + j * 0.25, 0.945), (0.115, 0.22, 0.008), farbe, tisch)

# Kessel am +X-Ende: dunkle Schale, rot-schwarze Fächer, goldene Nabe
kessel = leer("Kessel", (1.05, 0, 0.95))
kessel.parent = tisch
kessel.location = (1.05, 0, 0.95)
zylinder("Schale", (0, 0, 0.0), 0.38, 0.06, HOLZ, kessel)
zylinder("Ring", (0, 0, 0.04), 0.3, 0.03, WEISS, kessel)
for k in range(16):
    w = 2 * math.pi * k / 16
    bpy.ops.mesh.primitive_cube_add(location=(math.cos(w) * 0.2, math.sin(w) * 0.2, 0.065))
    f = bpy.context.active_object
    f.name = "Fach"
    f.scale = (0.07, 0.025, 0.012)
    f.rotation_euler = (0, 0, w)
    bpy.ops.object.transform_apply(scale=True)
    f.data.materials.append(ROT if k % 2 == 0 else SCHWARZ)
    f.parent = kessel
bpy.ops.mesh.primitive_cone_add(vertices=20, radius1=0.08, radius2=0.01, depth=0.14, location=(0, 0, 0.1))
nabe = bpy.context.active_object
nabe.name = "Nabe"
nabe.data.materials.append(GOLD)
nabe.parent = kessel

# Kugel (weiß) liegt im Kessel
bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.018, location=(0.24, 0, 0.08))
kugel = bpy.context.active_object
kugel.name = "Kugel"
kugel.data.materials.append(WEISS)
kugel.parent = kessel

# Vorschau
bpy.ops.object.light_add(type="SUN", location=(3, -3, 5))
bpy.context.active_object.data.energy = 3.0
bpy.ops.object.camera_add(location=(2.6, -3.2, 2.2))
kam = bpy.context.active_object
kam.rotation_euler = (math.radians(65), 0, math.radians(38))
bpy.context.scene.camera = kam
bpy.context.scene.render.resolution_x = 900
bpy.context.scene.render.resolution_y = 600
bpy.context.scene.render.filepath = os.path.join(ROOT, "build", "blender", "roulette.png")
bpy.context.scene.world = bpy.data.worlds.new("w")
bpy.context.scene.world.color = (0.5, 0.55, 0.6)
bpy.ops.render.render(write_still=True)

# Export
for o in list(bpy.data.objects):
    if o.type in ("LIGHT", "CAMERA"):
        bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "assets", "models", "roulette.glb"), export_format="GLB",
                          export_apply=True)
print("ROULETTE FERTIG")
