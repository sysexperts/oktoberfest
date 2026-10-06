"""Standardkörper für alle Figuren (Sloptoberfest): ein Körper, ein Skelett — Kleidung,
Hüte, Brillen und Haare machen daraus die einzelnen Charaktere. Der Look (hohe
Wurst-Köpfe, riesige cremeweiße Augen, dicke Brauen, dünne Röhren-Glieder) stammt
von den bisherigen Figuren und darf sich nicht ändern.

Aufruf (Windows):
  "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b -P tools/blender/standardkoerper.py
Ergebnis: build/blender/standardkoerper.blend, Vorschau-PNGs und
assets/character/standard/standardkoerper.glb

Koordinaten: die Maße stammen aus Godot (y oben, +z vorn) und werden in Blender-Raum
umgesetzt (x, -z, y) — die Figur blickt nach -Y, der glTF-Export macht daraus wieder +Z.
Skelett: dieselben Knochennamen und Positionen wie character2 (Wilhelm), damit alle
gemeinsamen Animationen ohne Umrechnung laufen
(build/blender/wilhelm_knochen.json), dazu Fingerknochen.
"""
import bpy, bmesh, json, math, os
from mathutils import Vector

OUTFIT = os.environ.get("OUTFIT", "bean")      # bean | franz: nur die Kleidung unterscheidet sich
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "build", "blender")
os.makedirs(OUT, exist_ok=True)


def g2b(v, y=None, z=None):
    """Godot-Koordinate -> Blender-Koordinate (Vektor oder drei Zahlen)"""
    if y is not None:
        v = Vector((v, y, z))
    return Vector((v.x, -v.z, v.y))


bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene


def srgb(c):
    """sRGB-Farbe (wie im Bild) -> lineare Farbe fuer Blender/glTF"""
    return tuple(((x + 0.055) / 1.055) ** 2.4 if x > 0.04045 else x / 12.92 for x in c)


def material(name, farbe_srgb, rauheit=0.8):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    lin = srgb(farbe_srgb)
    b.inputs["Base Color"].default_value = (*lin, 1.0)
    b.inputs["Roughness"].default_value = rauheit
    m.diffuse_color = (*lin, 1.0)
    return m


# Farben aus den bisherigen Figuren (Texturen von character2/Bean)
HAUT = material("Haut", (0.66, 0.43, 0.32))
AUGAPFEL = material("Augapfel", (0.99, 0.93, 0.87), 0.5)
PUPILLE = material("Pupille", (0.03, 0.03, 0.03), 0.35)
BRAUE = material("Braue", (0.45, 0.39, 0.26) if OUTFIT in ("bean", "basis", "augen", "kleidung") else (0.52, 0.52, 0.54))   # Franz: Haarfarbe wie der Bart (grau)
MUND = material("Mund", (0.66, 0.40, 0.31))


def kugel(mitte, radien, name="k", segmente=24):
    """Ellipsoid; mitte in Blender-Koordinaten, radien (rx, ry, rz) in Blender-Achsen"""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segmente, v_segments=max(4, segmente // 2), radius=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * radien[0], v.co.y * radien[1], v.co.z * radien[2])) + mitte
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new(name, me)
    scene.collection.objects.link(o)
    return o


def roehre(a, b, r1, r2, name="r", schritte=10, segmente=12):
    """Verjuengte Roehre aus ueberlappenden Kugeln von a nach b (Blender-Koordinaten)"""
    teile = []
    for i in range(schritte + 1):
        t = i / schritte
        r = r1 + (r2 - r1) * t
        teile.append(kugel(a.lerp(b, t), (r, r, r), "%s%d" % (name, i), segmente))
    return teile


def vereinen(objekte, name):
    bpy.ops.object.select_all(action='DESELECT')
    for o in objekte:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objekte[0]
    bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    return o


def verschmelzen(o, voxel, glaetten, anteil):
    """Alle Teile zu einer geschlossenen, glatten Haut"""
    o.data.remesh_voxel_size = voxel
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.voxel_remesh()
    m = o.modifiers.new("Glatt", 'SMOOTH')
    m.factor = 0.8
    m.iterations = glaetten
    bpy.ops.object.modifier_apply(modifier="Glatt")
    d = o.modifiers.new("Dez", 'DECIMATE')
    d.ratio = anteil
    bpy.ops.object.modifier_apply(modifier="Dez")
    bpy.ops.object.shade_smooth()
    o.data.materials.append(HAUT)


# ------------------------------------------------------------------ Skelett (Wilhelm)
KNOCHEN = json.load(open(os.path.join(OUT, "wilhelm_knochen.json")))
GPOS = {k["name"]: Vector(k["pos"]) for k in KNOCHEN}   # Godot-Koordinaten
POS = {n: g2b(p) for n, p in GPOS.items()}
ELTERN = {k["name"]: (KNOCHEN[k["parent"]]["name"] if k["parent"] >= 0 else None) for k in KNOCHEN}

# ------------------------------------------------------------------ Körper
teile = []
teile.append(kugel(g2b(0, 0.80, 0.02), (0.185, 0.15, 0.17), "becken"))
for y in (0.88, 0.96, 1.04):
    teile.append(kugel(g2b(0, y, 0.025), (0.170, 0.16, 0.17), "rumpf"))
teile.append(kugel(g2b(0, 1.10, 0.0), (0.175, 0.15, 0.17), "brust"))
# Kopf: hohe Wurst, fast zylindrisch mit runder Kuppe, sitzt direkt auf dem Rumpf
for y in (1.20, 1.28, 1.36, 1.44, 1.50):
    teile.append(kugel(g2b(0, y, 0.0), (0.205, 0.19, 0.14), "kopf", 32))
teile.append(kugel(g2b(0, 1.52, 0.0), (0.205, 0.19, 0.175), "kuppe", 32))
# Arme bis zum Handgelenk (die Hand ist ein eigenes Mesh mit Fingern)
for s in (1, -1):
    seite = "Left" if s == 1 else "Right"
    sch, ell, han = POS[seite + "Arm"], POS[seite + "ForeArm"], POS[seite + "Hand"]
    teile += roehre(g2b(s * 0.10, 1.09, -0.01), sch, 0.075, 0.062, "schulter")
    teile += roehre(sch, ell, 0.062, 0.052, "oberarm")
    ende = han - (han - ell).normalized() * 0.05
    teile += roehre(ell, ende, 0.052, 0.0455, "unterarm")
    teile += roehre(ende, han - (han - ell).normalized() * 0.02, 0.0455, 0.040, "unterarm_ende", 3)
# Beine: Hüfte -> Knie -> Knöchel, Füße
for s in (1, -1):
    seite = "Left" if s == 1 else "Right"
    hue, kni, kno = POS[seite + "UpLeg"], POS[seite + "Leg"], POS[seite + "Foot"]
    zeh, ze2 = POS[seite + "ToeBase"], POS[seite + "Toe_end"]
    teile += roehre(hue, kni, 0.085, 0.062, "oberschenkel")
    teile += roehre(kni, kno, 0.062, 0.050, "unterschenkel")
    teile += roehre(kno, zeh, 0.050, 0.046, "fuss")
    teile += roehre(zeh, ze2, 0.046, 0.040, "zehen", 4)
    teile.append(kugel(zeh.lerp(ze2, 0.5), (0.052, 0.07, 0.036), "ballen"))
koerper = vereinen(teile, "Koerper")
verschmelzen(koerper, 0.015, 12, 0.13)
print("Körper:", len(koerper.data.polygons), "Flächen")

# ------------------------------------------------------------------ Hände mit Fingern
# Die Hand setzt den Arm in gerader Linie fort (Richtung Unterarm), ist so breit wie der
# Arm, hat keinen Bund am Handgelenk — vier kurze, dicke Finger und einen kleinen Daumen,
# der innen herunterhängt.
FINGER = [  # Name, Versatz quer zur Hand (Richtung "vorn"), Längen der zwei Glieder
    ("Index", 0.0305, (0.047, 0.037)),
    ("Middle", 0.0105, (0.052, 0.041)),
    ("Ring", -0.0105, (0.047, 0.037)),
    ("Pinky", -0.0305, (0.038, 0.030)),
]
FINGER_R = 0.0112
finger_knochen = {}   # Name -> (Eltern, Kopf, Schwanz) in Blender-Koordinaten
haende = []
for s in (1, -1):
    seite = "Left" if s == 1 else "Right"
    H = GPOS[seite + "Hand"]
    d = (H - GPOS[seite + "ForeArm"]).normalized()  # Richtung des Unterarms
    m = Vector((-s, 0, 0))                         # zur Körpermitte (Handfläche)
    m = (m - d * m.dot(d)).normalized()
    q = Vector((0, 0, 1))                          # nach vorn (Daumenseite)
    q = (q - d * q.dot(d))
    q = (q - m * q.dot(m)).normalized()
    teile = []
    # Handgelenk bis Fingeransatz als ein Verlauf: der Querschnitt wird vom runden Arm
    # (r = 0.0455) stetig flacher (Dicke b) und schmaler (Breite a). Innen im Arm
    # (t < 0) etwas dünner, damit keine Kante entsteht.
    verlauf = [(-0.14, 0.036, 0.036), (-0.07, 0.0415, 0.0415), (-0.02, 0.0450, 0.0450), (0.0, 0.0455, 0.0455),
               (0.02, 0.043, 0.036), (0.045, 0.041, 0.029), (0.07, 0.040, 0.025), (0.09, 0.039, 0.024)]
    schritte = 5
    for i in range(len(verlauf) - 1):
        t0, a0, b0 = verlauf[i]
        t1, a1, b1 = verlauf[i + 1]
        for k in range(schritte):
            f = k / schritte
            t, aa, bb = t0 + (t1 - t0) * f, a0 + (a1 - a0) * f, b0 + (b1 - b0) * f
            n = 1 if aa - bb < 0.004 else 3
            for j in range(n):
                off = 0.0 if n == 1 else (j - 1) * (aa - bb)
                teile.append(kugel(g2b(H + d * t + q * off), (bb, bb, bb), "hand", 12))
    for fname, off, laengen in FINGER:
        basis = H + d * 0.088 + q * off
        r1, r2 = FINGER_R, FINGER_R * 0.9
        richtung1 = (d * math.cos(0.25) + m * math.sin(0.25)).normalized()
        richtung2 = (d * math.cos(0.70) + m * math.sin(0.70)).normalized()
        p1 = basis + richtung1 * laengen[0]
        p2 = p1 + richtung2 * laengen[1]
        teile += roehre(g2b(basis), g2b(p1), r1, r1 * 0.96, "f1", 4, 10)
        teile += roehre(g2b(p1), g2b(p2), r1 * 0.96, r2, "f2", 4, 10)
        teile.append(kugel(g2b(p2), (r2, r2, r2), "kuppe_f", 10))
        finger_knochen["%sHand%s1" % (seite, fname)] = ("%sHand" % seite, g2b(basis), g2b(p1))
        finger_knochen["%sHand%s2" % (seite, fname)] = ("%sHand%s1" % (seite, fname), g2b(p1), g2b(p2))
    # Daumen: klein, an der Innenseite, hängt neben der Hand nach unten
    tb = H + d * 0.040 + q * 0.026 + m * 0.018
    t1 = (d * 0.70 + m * 0.50 + q * 0.50).normalized()
    t2 = (d * 0.85 + m * 0.30 + q * 0.40).normalized()
    tp1 = tb + t1 * 0.038
    tp2 = tp1 + t2 * 0.030
    teile += roehre(g2b(tb), g2b(tp1), 0.023, 0.020, "d1", 4, 10)
    teile += roehre(g2b(tp1), g2b(tp2), 0.020, 0.018, "d2", 4, 10)
    teile.append(kugel(g2b(tp2), (0.018, 0.018, 0.018), "kuppe_d", 10))
    finger_knochen["%sHandThumb1" % seite] = ("%sHand" % seite, g2b(tb), g2b(tp1))
    finger_knochen["%sHandThumb2" % seite] = ("%sHandThumb1" % seite, g2b(tp1), g2b(tp2))
    hand = vereinen(teile, "Hand" + seite)
    verschmelzen(hand, 0.0035, 10, 0.14)
    haende.append((hand, seite))
    print("Hand", seite, len(hand.data.polygons), "Flächen")

# ------------------------------------------------------------------ Gesicht
gesicht = []


def haut_y(x, zh):
    """Blender-y der Hautoberflaeche vorn bei (x, Hoehe zh): Strahl von vorn auf den Koerper.
    So sitzen Augen, Brauen und Mund wirklich auf der Haut, egal wie das Mesh geformt ist."""
    treffer, ort, _n, _i = koerper.ray_cast(Vector((x, -1.0, zh)), Vector((0, 1, 0)))
    if not treffer:
        raise RuntimeError("Kein Treffer bei x=%.3f h=%.3f" % (x, zh))
    return ort.y


AUGE_Y, AUGE_X, AUGE_R = 1.30, 0.093, 0.066     # riesig: ein Drittel der Kopfbreite
for s in (1, -1):
    ay = haut_y(s * AUGE_X, AUGE_Y)
    # Auge halb in der Haut: Mittelpunkt etwas hinter der Oberflaeche
    if OUTFIT not in ("basis", "augen", "baerte", "kleidung"):          # Creator-Basiskörper hat keine Augen, die kommen als Bausteine
        a = kugel(Vector((s * AUGE_X, ay + 0.010, AUGE_Y)), (AUGE_R, 0.036, AUGE_R), "auge", 28)
        a.data.materials.append(AUGAPFEL)
        p = kugel(Vector((s * (AUGE_X - 0.002), ay - 0.019, AUGE_Y - 0.002)), (0.040, 0.010, 0.040), "pupille", 20)
        p.data.materials.append(PUPILLE)
        gesicht += [a, p]
    # Braue: dicker Balken, innen höher (leicht besorgt-freundlich)
    bx, bh = s * 0.105, 1.428
    if OUTFIT not in ("basis", "augen", "emotionen", "baerte", "kleidung"):       # Creator: Brauen und Mund kommen als Emotions-Baustein
        br = kugel(Vector((0, 0, 0)), (0.058, 0.022, 0.021), "braue", 16)
        br.rotation_euler = (0, math.radians(s * 12), 0)
        br.location = Vector((bx, haut_y(bx, bh) + 0.008, bh))
        br.data.materials.append(BRAUE)
        gesicht.append(br)
# Mund: dünner, kaum sichtbarer Strich als flaches Lächeln, auf die Haut gelegt
mund_teile = []
for i in range(25):
    t = (i - 12) / 12.0
    mx, mh = t * 0.05, 1.195 + 0.010 * t * t
    mund_teile.append(kugel(Vector((mx, haut_y(mx, mh) + 0.002, mh)), (0.005, 0.004, 0.005), "mundteil", 6))
mund = vereinen(mund_teile, "mund")
mund.data.materials.append(MUND)
if OUTFIT not in ("basis", "augen", "emotionen", "baerte", "kleidung"):
    gesicht.append(mund)
else:
    bpy.data.objects.remove(mund, do_unlink=True)

# ------------------------------------------------------------------ Armature
bpy.ops.object.armature_add(enter_editmode=True)
arm_obj = bpy.context.active_object
arm_obj.name = "Armature"
arm = arm_obj.data
arm.name = "Armature"
for b in list(arm.edit_bones):
    arm.edit_bones.remove(b)
kinder = {}
for n, p in ELTERN.items():
    kinder.setdefault(p, []).append(n)
for n in POS:
    eb = arm.edit_bones.new(n)
    eb.head = POS[n]
    ks = [k for k in kinder.get(n, []) if k not in ("headfront", "head_end")] or kinder.get(n, [])
    if ks:
        eb.tail = POS[ks[0]]
    else:
        e = ELTERN[n]
        r = (POS[n] - POS[e]) if e else Vector((0, 0, 0.05))
        eb.tail = POS[n] + (r.normalized() * 0.05 if r.length > 0 else Vector((0, 0, 0.05)))
    if (eb.tail - eb.head).length < 0.01:
        eb.tail = eb.head + Vector((0, 0, 0.03))
for n, p in ELTERN.items():
    if p:
        arm.edit_bones[n].parent = arm.edit_bones[p]
for seite in ("Left", "Right"):
    arm.edit_bones[seite + "Hand"].tail = POS[seite + "Hand_End"]
for n, (eltern, kopf, schwanz) in finger_knochen.items():
    eb = arm.edit_bones.new(n)
    eb.head, eb.tail = kopf, schwanz
    eb.parent = arm.edit_bones[eltern]
bpy.ops.object.mode_set(mode='OBJECT')

# ------------------------------------------------------------------ Haut an Skelett binden
bpy.ops.object.select_all(action='DESELECT')
koerper.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.parent_set(type='ARMATURE_AUTO')
# Kopfhaut starr am Kopfknochen: sonst bleibt sie beim Neigen am Hals hängen und das
# Gesicht (Augen, Brauen, Mund hängen zu 100 % am Kopf) schwebt vor der Haut
kg = koerper.vertex_groups["Head"]
for v in koerper.data.vertices:
    h = v.co.z
    if abs(v.co.x) > 0.19 and h < 1.30:
        continue    # Schultern und Arme
    if h >= 1.185:
        anteil = 1.0
    elif h >= 1.14 and abs(v.co.x) < 0.15:
        anteil = (h - 1.14) / 0.045
    else:
        continue
    alt = {koerper.vertex_groups[g.group].name: g.weight for g in v.groups}
    rest = sum(w for n, w in alt.items() if n != "Head")
    kopf_w = alt.get("Head", 0.0)
    ziel_kopf = kopf_w + (1.0 - kopf_w) * anteil
    for n, w in alt.items():
        if n != "Head" and rest > 0:
            koerper.vertex_groups[n].add([v.index], w / rest * (1.0 - ziel_kopf), 'REPLACE')
    kg.add([v.index], ziel_kopf, 'REPLACE')
for o in gesicht:
    o.parent = arm_obj
    vg = o.vertex_groups.new(name="Head")
    vg.add([v.index for v in o.data.vertices], 1.0, 'REPLACE')
    mod = o.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj


def segment_abstand(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


# Hand: Gewichte nach Abstand zu Handknochen, Fingerknochen und Unterarm
for hand, seite in haende:
    segs = {}
    for name in [seite + "Hand", seite + "ForeArm"] + [n for n in finger_knochen if n.startswith(seite)]:
        eb = arm_obj.data.bones[name]
        segs[name] = (eb.head_local.copy(), eb.tail_local.copy())
    for name in segs:
        hand.vertex_groups.new(name=name)
    for v in hand.data.vertices:
        ds = {n: segment_abstand(v.co, a, b) for n, (a, b) in segs.items()}
        dmin = min(ds.values())
        w = {n: max(0.0, 1.0 - (d - dmin) / 0.010) for n, d in ds.items()}
        gesamt = sum(w.values())
        for n, x in w.items():
            if x / gesamt > 0.03:
                hand.vertex_groups[n].add([v.index], x / gesamt, 'REPLACE')
    hand.parent = arm_obj
    mod = hand.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj

# ------------------------------------------------------------------ Kleidung (tools/blender/kleidung.py)
exec(open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "kleidung.py"), encoding="utf-8").read(), globals())

# ------------------------------------------------------------------ Vorschau (Workbench)
scene.render.engine = 'BLENDER_WORKBENCH'
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.render.resolution_x = 700
scene.render.resolution_y = 900
scene.world = bpy.data.worlds.new("W")
scene.world.color = (0.5, 0.5, 0.55)
kam_d = bpy.data.cameras.new("Kam")
kam = bpy.data.objects.new("Kam", kam_d)
scene.collection.objects.link(kam)
scene.camera = kam
kam_d.type = 'ORTHO'
ziel = bpy.data.objects.new("Ziel", None)
scene.collection.objects.link(ziel)
tc = kam.constraints.new('TRACK_TO')
tc.target = ziel
tc.track_axis = 'TRACK_NEGATIVE_Z'
tc.up_axis = 'UP_Y'
for name, loc, zp, sk in [("vorn", (0, -6, 0.85), (0, 0, 0.85), 2.0), ("schraeg", (3.5, -4.5, 1.3), (0, 0, 0.85), 2.0),
                          ("gesicht", (1.5, -4.0, 1.45), (0, 0, 1.38), 0.7),
                          ("hand", (-2.0, -3.0, 0.7), (0.4, 0, 0.62), 0.5),
                          ("hand_seite", (4.0, 0, 0.55), (0.37, 0, 0.55), 0.4)]:
    kam.location = loc
    ziel.location = zp
    kam_d.ortho_scale = sk
    scene.render.filepath = os.path.join(OUT, "standard_%s.png" % name)
    bpy.ops.render.render(write_still=True)

# ------------------------------------------------------------------ Speichern und Export
for o in [koerper] + gesicht + [h for h, _ in haende] + kleidung_objekte:
    o.data.validate(verbose=False)
    for poly in o.data.polygons:
        poly.use_smooth = True
if OUTFIT == "kleidung":
    # Creator-Assets: jedes Stück einzeln als GLB, mit dem Skelett (das Netz hängt daran)
    ordner = os.path.join(ROOT, "assets", "creator", "kleidung")
    os.makedirs(ordner, exist_ok=True)
    for kname, teile_k in KLEIDUNG.items():
        if os.environ.get("NUR") and kname not in os.environ["NUR"].split(","):
            continue
        bpy.ops.object.select_all(action='DESELECT')
        arm_obj.select_set(True)
        for o in teile_k:
            o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(ordner, kname + ".glb"), use_selection=True,
                                  export_format='GLB', export_yup=True, export_skins=True,
                                  export_vertex_color='ACTIVE')
        print("Kleidung exportiert:", kname)
    print("FERTIG Kleidung")
    raise SystemExit
if OUTFIT in ("huete", "frisuren", "frauenhaar", "brillen", "augen", "emotionen", "baerte"):
    # Creator-Assets: jeder Hut / jede Frisur einzeln als GLB (ohne Skelett, Modell-Koordinaten des Standardkörpers)
    ordner = os.path.join(ROOT, "assets", "creator", os.environ.get("EXPORT_ORDNER", OUTFIT))
    os.makedirs(ordner, exist_ok=True)
    for hname, teile_h in HUETE.items():
        if os.environ.get("NUR") and hname not in os.environ["NUR"].split(","):
            continue
        bpy.ops.object.select_all(action='DESELECT')
        for o in teile_h:
            o.parent = None
            o.modifiers.clear()
            for g in list(o.vertex_groups):
                o.vertex_groups.remove(g)
            o.select_set(True)
        bpy.ops.export_scene.gltf(filepath=os.path.join(ordner, hname + ".glb"), use_selection=True,
                                  export_format='GLB', export_yup=True, export_skins=False)
        print("Hut exportiert:", hname)
    print("FERTIG Hüte")
    raise SystemExit
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, "standardkoerper.blend"))
bpy.ops.object.select_all(action='DESELECT')
for o in [arm_obj, koerper] + gesicht + [h for h, _ in haende] + kleidung_objekte:
    o.select_set(True)
glb = os.path.join(ROOT, "assets", "character", "standard", "standardkoerper.glb" if OUTFIT == "bean" else OUTFIT + ".glb")
os.makedirs(os.path.dirname(glb), exist_ok=True)
bpy.ops.export_scene.gltf(filepath=glb, use_selection=True, export_format='GLB',
                          export_yup=True, export_skins=True)
print("FERTIG", glb)
