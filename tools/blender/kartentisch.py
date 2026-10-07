"""Kartentisch (Blackjack) fürs Casino hinter Konrads Zelt: halbrunder Tisch mit grünem Tuch, Karten und Chips.
Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/kartentisch.py
Ergebnis: assets/models/kartentisch.glb und build/blender/kartentisch.png (Vorschau).
Die Spieler stehen auf der runden Seite (-Y), der Croupier auf der geraden Seite (+Y).
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
LEDER = mat("leder", (0.12, 0.06, 0.05), 0.5)
WEISS = mat("weiss", (0.96, 0.95, 0.9), 0.5)
ROT = mat("rot", (0.75, 0.08, 0.08), 0.5)
SCHWARZ = mat("schwarz", (0.05, 0.05, 0.06), 0.5)
GOLD = mat("gold", (0.9, 0.7, 0.2), 0.3, 0.8)


def leer(name):
    o = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(o)
    return o


def zylinder(name, ort, radius, tiefe, material, eltern, ecken=40):
    bpy.ops.mesh.primitive_cylinder_add(vertices=ecken, radius=radius, depth=tiefe, location=ort)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    o.parent = eltern
    return o


def quader(name, ort, groesse, material, eltern, drehung=0.0):
    bpy.ops.mesh.primitive_cube_add(location=ort)
    o = bpy.context.active_object
    o.name = name
    o.scale = (groesse[0] / 2, groesse[1] / 2, groesse[2] / 2)
    o.rotation_euler = (0, 0, drehung)
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    o.parent = eltern
    return o


tisch = leer("Tisch")
# Halbrunde Platte: Zylinder, vorne (+Y) mit einem Quader abgeschnitten gedacht — hier als runde Platte mit Rand
zylinder("Platte", (0, 0, 0.84), 1.35, 0.08, HOLZ, tisch)
zylinder("Tuch", (0, 0, 0.885), 1.22, 0.02, TUCH, tisch)
zylinder("Fuss", (0, 0, 0.42), 0.14, 0.84, HOLZ, tisch, 16)
zylinder("Sockel", (0, 0, 0.03), 0.55, 0.06, HOLZ, tisch)

# Karten (offen liegen drei Stück) und Chips
for i, (x, y, w) in enumerate([(-0.3, -0.3, 0.2), (-0.12, -0.28, 0.0), (0.06, -0.3, -0.18)]):
    quader("Karte", (x, y, 0.91), (0.12, 0.17, 0.004), WEISS, tisch, w)
    quader("Kartenzeichen", (x, y, 0.913), (0.05, 0.05, 0.002), ROT if i % 2 == 0 else SCHWARZ, tisch, w)
for i, (x, y, farbe) in enumerate([(0.55, -0.35, ROT), (0.55, -0.35, SCHWARZ), (-0.6, -0.4, GOLD), (-0.6, -0.4, ROT)]):
    zylinder("Chip", (x, y, 0.905 + (i % 2) * 0.012), 0.05, 0.012, farbe, tisch, 20)

bpy.ops.object.light_add(type="SUN", location=(3, -3, 5))
bpy.context.active_object.data.energy = 3.0
bpy.ops.object.camera_add(location=(2.4, -3.0, 2.2))
kam = bpy.context.active_object
kam.rotation_euler = (math.radians(62), 0, math.radians(38))
bpy.context.scene.camera = kam
bpy.context.scene.render.resolution_x = 800
bpy.context.scene.render.resolution_y = 600
bpy.context.scene.render.filepath = os.path.join(ROOT, "build", "blender", "kartentisch.png")
bpy.context.scene.world = bpy.data.worlds.new("w")
bpy.context.scene.world.color = (0.5, 0.55, 0.6)
bpy.ops.render.render(write_still=True)

for o in list(bpy.data.objects):
    if o.type in ("LIGHT", "CAMERA"):
        bpy.data.objects.remove(o)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "assets", "models", "kartentisch.glb"), export_format="GLB",
                          export_apply=True)
print("KARTENTISCH FERTIG")
