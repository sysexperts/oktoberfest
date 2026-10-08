"""Grillgut für die Kochstelle (scenes/food_station.tscn): Bratwurst, Brezn, Hendl.
Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/grillgut.py
Ergebnis: assets/models/grill_wurst.glb, grill_brezn.glb, grill_hendl.glb und build/blender/grillgut.png (Vorschau).
Ursprung = Unterseite, Länge der Wurst entlang Z. Die Farbe (roh → gar → verkohlt) setzt scripts/food_station.gd.
"""
import math
import os

import bpy
import bmesh
from mathutils import Vector

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
os.makedirs(os.path.join(ROOT, "build", "blender"), exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)


def srgb(c):
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def mat(name, farbe, rauheit=0.5):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*srgb(farbe), 1.0)
    b.inputs["Roughness"].default_value = rauheit
    return m


GAR = mat("gar", (0.62, 0.34, 0.16))
DUNKEL = mat("dunkel", (0.3, 0.15, 0.07))
KNOCHEN = mat("knochen", (0.93, 0.9, 0.8))


def aktiv(o):
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o


def glatt(o, stufen=1):
    aktiv(o)
    bpy.ops.object.shade_smooth()
    if stufen:
        m = o.modifiers.new("sub", "SUBSURF")
        m.levels = stufen
        m.render_levels = stufen
        bpy.ops.object.modifier_apply(modifier="sub")


def kugel(name, ort, skala, material, seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, location=ort)
    o = bpy.context.active_object
    o.name = name
    o.scale = skala
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(material)
    bpy.ops.object.shade_smooth()
    return o


def zusammen(teile, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in teile:
        o.select_set(True)
    bpy.context.view_layer.objects.active = teile[0]
    bpy.ops.object.join()
    o = bpy.context.active_object
    o.name = name
    return o


def exportieren(o, datei):
    aktiv(o)
    bpy.ops.export_scene.gltf(filepath=os.path.join(ROOT, "assets", "models", datei), export_format="GLB", use_selection=True, export_apply=True)


# ---------------------------------------------------------------- Bratwurst
# Länge 0,3 entlang Z, leicht gebogen, Enden zugedreht, Quetschfalten
bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=24, location=(0, 0, 0))
w = bpy.context.active_object
w.name = "wurst"
bm = bmesh.new()
bm.from_mesh(w.data)
for v in bm.verts:
    t = v.co.z  # -1 … 1 auf der Kugel
    sin_t = math.sqrt(max(1e-9, 1.0 - t * t))
    profil = (1.0 - abs(t) ** 6) ** 0.5            # walzenförmig mit runden Enden (nicht eiförmig)
    fx = v.co.x / sin_t * profil
    fy = v.co.y / sin_t * profil
    v.co.x = fx * 0.042 + 0.012 * (1.0 - t * t)    # ganz leichte Banane
    v.co.z = fy * 0.042
    v.co.y = t * 0.15
bm.to_mesh(w.data)
bm.free()
w.location = (0, 0, 0)
aktiv(w)
bpy.ops.object.transform_apply(location=True, scale=True)
w.location.z = 0.042
bpy.ops.object.transform_apply(location=True)
w.data.materials.append(GAR)
glatt(w, 0)
# Zipfel an den Enden
zip1 = kugel("zip1", (0.0, 0.152, 0.042), (0.01, 0.014, 0.01), DUNKEL, 8)
zip2 = kugel("zip2", (0.0, -0.152, 0.042), (0.01, 0.014, 0.01), DUNKEL, 8)
wurst = zusammen([w, zip1, zip2], "GrillWurst")
exportieren(wurst, "grill_wurst.glb")

# ---------------------------------------------------------------- Brezn
# Echte Brezelform: unten eine große Schlaufe, die Arme kreuzen sich in der Mitte und
# liegen mit den Enden auf der gegenüberliegenden Schulter (Kurve in der XY-Ebene, Z = oben)
def pfad(punkte):
    return punkte


R = 0.105
schlaufe = []
for i in range(0, 25):
    a = math.radians(160 + i * (220.0 / 24.0))   # von links oben über unten bis rechts oben
    schlaufe.append((R * 1.12 * math.cos(a), R * 0.95 * math.sin(a) - 0.02, 0.0))
arm_rechts = [schlaufe[-1], (0.075, 0.045, 0.0), (0.02, 0.085, 0.012), (-0.035, 0.105, 0.03), (-0.085, 0.085, 0.022)]
arm_links = [schlaufe[0], (-0.075, 0.045, 0.0), (-0.02, 0.085, 0.034), (0.035, 0.105, 0.03), (0.085, 0.085, 0.022)]
kurve = bpy.data.curves.new("brezn", "CURVE")
kurve.dimensions = "3D"
for pts in (schlaufe + arm_rechts[1:], arm_links):
    sp = kurve.splines.new("NURBS")
    sp.points.add(len(pts) - 1)
    for p_, (x, y, z) in zip(sp.points, pts):
        p_.co = (x, y, z, 1.0)
    sp.order_u = 4
    sp.use_endpoint_u = True
kurve.bevel_depth = 0.021
kurve.bevel_resolution = 6
kurve.resolution_u = 24
kurve.use_fill_caps = True
obj = bpy.data.objects.new("brezn", kurve)
bpy.context.collection.objects.link(obj)
aktiv(obj)
bpy.ops.object.convert(target="MESH")
b = bpy.context.active_object
b.data.materials.append(GAR)
bpy.ops.object.shade_smooth()
mn = min((b.matrix_world @ v.co).z for v in b.data.vertices)
b.location.z -= mn
bpy.ops.object.transform_apply(location=True)
exportieren(b, "grill_brezn.glb")

# ---------------------------------------------------------------- Hendl
teile = []
teile.append(kugel("rumpf", (0, 0.0, 0.1), (0.1, 0.15, 0.095), GAR, 28))      # Körper
teile.append(kugel("brust", (0, -0.03, 0.145), (0.085, 0.1, 0.075), GAR, 24))  # Brust obenauf
teile.append(kugel("buerzel", (0, 0.15, 0.1), (0.03, 0.03, 0.03), GAR, 10))
for s_, x in (("l", -1), ("r", 1)):
    # Keule: dicker Oberschenkel + Knochen
    teile.append(kugel("keule_" + s_, (x * 0.1, 0.07, 0.07), (0.05, 0.09, 0.05), GAR, 16))
    bpy.ops.mesh.primitive_cylinder_add(vertices=12, radius=0.012, depth=0.1, location=(x * 0.13, 0.16, 0.05), rotation=(math.radians(-80), 0, math.radians(x * 15)))
    k = bpy.context.active_object
    k.name = "knochen_" + s_
    k.data.materials.append(KNOCHEN)
    bpy.ops.object.shade_smooth()
    teile.append(k)
    teile.append(kugel("kopf_" + s_, (x * 0.135, 0.215, 0.05), (0.02, 0.02, 0.02), KNOCHEN, 10))
    teile.append(kugel("fluegel_" + s_, (x * 0.105, -0.07, 0.115), (0.025, 0.07, 0.04), DUNKEL, 12))
huhn = zusammen(teile, "GrillHendl")
mn = min((huhn.matrix_world @ v.co).z for v in huhn.data.vertices)
huhn.location.z -= mn
bpy.ops.object.transform_apply(location=True)
exportieren(huhn, "grill_hendl.glb")

# ---------------------------------------------------------------- Vorschau
bpy.ops.object.light_add(type="SUN", location=(2, 4, 3))
bpy.context.active_object.data.energy = 3.0
bpy.context.active_object.rotation_euler = (math.radians(50), 0, math.radians(30))
bpy.ops.object.camera_add(location=(0.0, -0.9, 0.9), rotation=(math.radians(52), 0, 0))
bpy.context.active_object.data.type = 'ORTHO'
bpy.context.active_object.data.ortho_scale = 1.0
bpy.context.scene.camera = bpy.context.active_object
bpy.context.scene.render.resolution_x = 960
bpy.context.scene.render.resolution_y = 480
bpy.context.scene.render.filepath = os.path.join(ROOT, "build", "blender", "grillgut.png")
bpy.context.scene.world = bpy.data.worlds.new("w")
bpy.context.scene.world.color = (0.5, 0.5, 0.55)
for o, x in ((wurst, -0.3), (b, 0.0), (huhn, 0.32)):
    o.location.x = x
try:
    bpy.context.scene.render.engine = "BLENDER_EEVEE"
except TypeError:
    pass
bpy.ops.render.render(write_still=True)
print("FERTIG")
