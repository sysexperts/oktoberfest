"""Die Sau (Gefallen „Die Sau ist los"): rundes Cartoon-Schwein im Stil der Figuren (cremeweisse Augen, dicke Formen).
Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/sau.py
Ergebnis: assets/models/sau.glb (Knoten Koerper, BeinVL, BeinVR, BeinHL, BeinHR — die Beine drehen sich um die Hüfte,
das Laufen übernimmt scripts/gefallen_taeter.gd) und build/blender/sau.png (Vorschau).
Blickrichtung wie bei den Figuren: Blender -Y, im Spiel wird das Modell um 180° gedreht.
"""
import math
import os

import bpy
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.makedirs(os.path.join(ROOT, "build", "blender"), exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


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


ROSA = mat("rosa", (0.96, 0.64, 0.68))
DUNKELROSA = mat("dunkelrosa", (0.86, 0.46, 0.52))
CREME = mat("creme", (0.97, 0.95, 0.88), 0.4)
SCHWARZ = mat("schwarz", (0.06, 0.05, 0.05), 0.5)
HUF = mat("huf", (0.35, 0.22, 0.2))


def kugel(name, ort, skala, material, segmente=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segmente, ring_count=segmente // 2, location=ort)
    o = bpy.context.active_object
    o.name = name
    o.scale = skala
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def zylinder(name, ort, radius, tiefe, material, drehung=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=radius, depth=tiefe, location=ort, rotation=drehung)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def kegel(name, ort, radius, tiefe, material, drehung=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=16, radius1=radius, radius2=0.0, depth=tiefe, location=ort, rotation=drehung)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


HOEHE = 0.34   # Beinlänge: Bauchunterkante
teile = []
# Körper (liegt längs der Y-Achse, Kopf vorn bei -Y)
teile.append(kugel("rumpf", (0, 0.05, HOEHE + 0.26), (0.34, 0.5, 0.31), ROSA))
teile.append(kugel("kopf", (0, -0.5, HOEHE + 0.3), (0.26, 0.24, 0.24), ROSA))
# Rüssel mit Nasenlöchern
teile.append(zylinder("ruessel", (0, -0.7, HOEHE + 0.27), 0.12, 0.12, DUNKELROSA, (math.radians(90), 0, 0)))
teile.append(kugel("nase_l", (-0.04, -0.765, HOEHE + 0.27), (0.025, 0.012, 0.035), SCHWARZ, 10))
teile.append(kugel("nase_r", (0.04, -0.765, HOEHE + 0.27), (0.025, 0.012, 0.035), SCHWARZ, 10))
# Augen (cremeweiss mit Pupille, wie bei den Figuren)
for s, x in (("l", -0.13), ("r", 0.13)):
    teile.append(kugel("auge_" + s, (x, -0.67, HOEHE + 0.4), (0.075, 0.05, 0.085), CREME, 14))
    teile.append(kugel("pupille_" + s, (x * 1.02, -0.715, HOEHE + 0.4), (0.035, 0.02, 0.045), SCHWARZ, 10))
# Ohren
for s, x in (("l", -0.17), ("r", 0.17)):
    teile.append(kegel("ohr_" + s, (x, -0.47, HOEHE + 0.55), 0.09, 0.2, DUNKELROSA, (math.radians(-20), 0, math.radians(25 if s == "r" else -25))))
# Ringelschwanz
bpy.ops.mesh.primitive_torus_add(location=(0, 0.58, HOEHE + 0.36), major_radius=0.06, minor_radius=0.018, rotation=(0, math.radians(90), 0))
schwanz = bpy.context.active_object
schwanz.name = "schwanz"
schwanz.data.materials.append(DUNKELROSA)
teile.append(schwanz)

# Alles Starre zu einem Mesh „Koerper"
bpy.ops.object.select_all(action="DESELECT")
for o in teile:
    o.select_set(True)
bpy.context.view_layer.objects.active = teile[0]
bpy.ops.object.join()
koerper = bpy.context.active_object
koerper.name = "Koerper"
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")

# Beine: Ursprung an der Hüfte (oben), damit sie sich dort drehen
beine = {}
for name, x, y in (("BeinVL", -0.19, -0.3), ("BeinVR", 0.19, -0.3), ("BeinHL", -0.19, 0.38), ("BeinHR", 0.19, 0.38)):
    bein = zylinder(name, (x, y, HOEHE / 2 + 0.02), 0.075, HOEHE + 0.04, ROSA)
    huf = zylinder(name + "_huf", (x, y, 0.035), 0.082, 0.07, HUF)
    bpy.ops.object.select_all(action="DESELECT")
    bein.select_set(True)
    huf.select_set(True)
    bpy.context.view_layer.objects.active = bein
    bpy.ops.object.join()
    bein = bpy.context.active_object
    bein.name = name
    bpy.context.scene.cursor.location = (x, y, HOEHE + 0.02)
    bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
    beine[name] = bein
bpy.context.scene.cursor.location = (0, 0, 0)

# Licht und Kamera für die Vorschau
bpy.ops.object.light_add(type="SUN", location=(2, -3, 4))
bpy.context.active_object.data.energy = 3.0
bpy.ops.object.camera_add(location=(1.7, -2.2, 1.1), rotation=(math.radians(76), 0, math.radians(38)))
bpy.context.scene.camera = bpy.context.active_object
bpy.context.scene.render.resolution_x = 640
bpy.context.scene.render.resolution_y = 480
bpy.context.scene.render.filepath = os.path.join(ROOT, "build", "blender", "sau.png")
bpy.context.scene.world = bpy.data.worlds.new("w")
bpy.context.scene.world.color = (0.6, 0.75, 0.9)
try:
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
except TypeError:
    pass
bpy.ops.render.render(write_still=True)

# Export
bpy.ops.object.select_all(action="DESELECT")
koerper.select_set(True)
for b in beine.values():
    b.select_set(True)
bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "assets", "models", "sau.glb"), export_format="GLB", use_selection=True, export_apply=True)
print("FERTIG")
