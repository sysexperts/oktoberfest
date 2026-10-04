"""Kleidung für den Standardkörper (wird von standardkoerper.py kurz vor dem Export
ausgeführt und benutzt dessen Namen: koerper, arm_obj, POS, GPOS, material, kugel ...).

Methode (wie in Blender/Spielen üblich): jedes Stück ist eine Kopie des Körper-Meshes, die
entlang der Oberfläche etwas aufgeblasen wird (Abstand je Stück und Höhe) und dann mit
Ebenen sauber zugeschnitten wird (Saum, Ärmelenden, Hals, Schulternaht). So sitzt jedes
Stück genau über dem Körper, hat dieselben Proportionen, Ärmel und Achseln. Ausschnitte (V vorn)
kommen per Boolean, Details (Knöpfe, Klappen, Plakette, Hut) sind kleine eigene Formen.

Gewichte: vom nächsten Körperpunkt übernommen, jedes Stück bewegt sich in jeder Animation mit.
Aussehen: bemalte Textur je Stück (Funktionen der Raumposition auf die UV-Karte gebacken),
dazu Formschatten und eingebackene Ambient Occlusion.

Outfits entstehen später in Godot, indem pro Figurszene Stücke ein- oder ausgeblendet werden.
"""
import numpy as np
from mathutils import kdtree

kleidung_objekte = []
_bemalt = []      # (Objekt, Bild, Farbfeld) für das Einbacken der Schatten


# =================================================================== Texturen malen
def _hash3(ix, iy, iz):
    h = (ix * 374761393 + iy * 668265263 + iz * 2147483647) & 0xFFFFFFFF
    h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
    return ((h ^ (h >> 16)) & 0xFFFF) / 65535.0


def ruis(P, skala):
    """Weiches 3D-Wertrauschen 0..1 an den Punkten P (N,3)"""
    q = P * skala
    i = np.floor(q).astype(np.int64)
    f = q - i
    f = f * f * (3 - 2 * f)
    out = 0.0
    for dx in (0, 1):
        for dy in (0, 1):
            for dz in (0, 1):
                w = (f[:, 0] if dx else 1 - f[:, 0]) * (f[:, 1] if dy else 1 - f[:, 1]) * (f[:, 2] if dz else 1 - f[:, 2])
                out = out + w * _hash3(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz)
    return out


def mischen(a, b, m):
    """Farbe a zu Farbe b mit Maske m (N,)"""
    m = np.clip(m, 0, 1)[:, None]
    return a * (1 - m) + b * m


def hart(x, kante, breite=0.002):
    """Weiche Kante: 1 wenn x < kante"""
    return np.clip((kante - x) / breite + 0.5, 0, 1)


def uv_auspacken(o):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(70), island_margin=0.004)
    bpy.ops.object.mode_set(mode='OBJECT')


def bemalen(o, farbe_fn, groesse=1024):
    """UV-Karte anlegen und die Farbfunktion (Godot-Koordinaten → sRGB) auf die Textur backen"""
    uv_auspacken(o)
    me = o.data
    me.calc_loop_triangles()
    uvl = me.uv_layers.active.data
    bild = np.zeros((groesse, groesse, 3), np.float32)
    belegt = np.zeros((groesse, groesse), bool)
    pos = np.array([(v.co.x, v.co.z, -v.co.y) for v in me.vertices], np.float32)   # Blender → Godot
    nrm = np.array([(v.normal.x, v.normal.z, -v.normal.y) for v in me.vertices], np.float32)
    LICHT = np.array([0.35, 0.65, 0.68], np.float32)       # von oben vorn links
    LICHT /= np.linalg.norm(LICHT)
    # Lücken (Randtexel, winzige Dreiecke) nie schwarz lassen: mit der Mittelfarbe vorfüllen
    mitte = farbe_fn(pos[len(pos) // 2: len(pos) // 2 + 200].astype(np.float64))
    bild[:] = np.median(mitte, axis=0).astype(np.float32)
    for tri in me.loop_triangles:
        uv = np.array([uvl[l].uv[:] for l in tri.loops], np.float32) * groesse
        p3 = pos[list(tri.vertices)]
        x0, y0 = np.floor(uv.min(axis=0)).astype(int)
        x1, y1 = np.ceil(uv.max(axis=0)).astype(int)
        x0, y0 = max(x0, 0), max(y0, 0)
        x1, y1 = min(x1, groesse - 1), min(y1, groesse - 1)
        if x1 < x0 or y1 < y0:
            continue
        xs, ys = np.meshgrid(np.arange(x0, x1 + 1), np.arange(y0, y1 + 1))
        px = np.stack([xs.ravel() + 0.5, ys.ravel() + 0.5], axis=1)
        a, b, c = uv
        d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(d) < 1e-9:
            continue
        w1 = ((b[1] - c[1]) * (px[:, 0] - c[0]) + (c[0] - b[0]) * (px[:, 1] - c[1])) / d
        w2 = ((c[1] - a[1]) * (px[:, 0] - c[0]) + (a[0] - c[0]) * (px[:, 1] - c[1])) / d
        w3 = 1 - w1 - w2
        eps = -0.02
        innen = (w1 >= eps) & (w2 >= eps) & (w3 >= eps)
        if not innen.any():
            continue
        W = np.stack([w1[innen], w2[innen], w3[innen]], axis=1)
        P = W @ p3
        N = W @ nrm[list(tri.vertices)]
        N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-6)
        farbe = farbe_fn(P)
        # Formschatten: Licht von oben vorn — Unterseiten und Schattenseiten werden etwas dunkler
        # und wärmer, Oberseiten heller. Das gibt der flachen Farbe Volumen.
        licht = np.clip(N @ LICHT, -1, 1)
        schatten = np.clip(0.5 - licht * 0.5, 0, 1)[:, None]
        farbe = farbe * (0.80 + 0.26 * (1 - schatten)) + schatten * 0.02 * np.array([1.0, 0.5, 0.3])[None, :]
        bild[ys.ravel()[innen], xs.ravel()[innen]] = farbe
        belegt[ys.ravel()[innen], xs.ravel()[innen]] = True
    # Ränder der Inseln auffüllen, damit an den Nähten keine Lücken durchscheinen
    for _ in range(10):
        neu = belegt.copy()
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            quelle = np.roll(np.roll(bild, dy, 0), dx, 1)
            qm = np.roll(np.roll(belegt, dy, 0), dx, 1)
            fuellen = (~neu) & qm
            bild[fuellen] = quelle[fuellen]
            neu |= fuellen
        belegt = neu
    img = bpy.data.images.new(o.name + "_tex", groesse, groesse, alpha=False)
    rgba = np.concatenate([np.clip(bild, 0, 1), np.ones((groesse, groesse, 1), np.float32)], axis=2)
    img.pixels.foreach_set(rgba.ravel())   # Zeile 0 = v 0 (Blender zählt von unten) — passt zu y = v * Größe
    img.pack()
    img.update()
    _bemalt.append((o, img, bild.copy(), groesse))
    return img


def stoff_material(name, img, rauheit=0.9):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    n = m.node_tree.nodes
    b = n["Principled BSDF"]
    b.inputs["Roughness"].default_value = rauheit
    t = n.new("ShaderNodeTexImage")
    t.image = img
    m.node_tree.links.new(t.outputs["Color"], b.inputs["Base Color"])
    return m


# =================================================================== Binden an das Skelett
ARM_KNOCHEN = ("LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand", "RightShoulder", "RightArm", "RightForeArm", "RightHand")


def binden(o, ohne_arme=False, starr_ab=None):
    """Gewichte vom nächsten Körperpunkt übernehmen, Armature-Modifier, Eltern.
    ohne_arme: Gürtel und Hose sollen nicht an den Armen hängen, die neben ihnen herunterhängen."""
    namen = {g.index: g.name for g in koerper.vertex_groups}
    baum = kdtree.KDTree(len(koerper.data.vertices))
    for i, v in enumerate(koerper.data.vertices):
        if ohne_arme:
            dom = max(v.groups, key=lambda g: g.weight) if len(v.groups) else None
            if dom is not None and namen[dom.group] in ARM_KNOCHEN:
                continue
        baum.insert(v.co, i)
    baum.balance()
    gruppen = {}
    for v in o.data.vertices:
        _, idx, _ = baum.find(v.co)
        for g in koerper.data.vertices[idx].groups:
            gruppen.setdefault(namen[g.group], []).append((v.index, g.weight))
    if starr_ab is not None:
        # Am Halsansatz fest an den oberen Rücken ("Spine"): die Körpergewichte springen dort zwischen
        # Kopf, Hals und Rücken, das zerreißt die dünne Kante in der Pose.
        hoehe0, hoehe1 = starr_ab
        neu = {}
        for n, liste in gruppen.items():
            for i, w in liste:
                z = o.data.vertices[i].co.z
                t = max(0.0, min(1.0, (z - hoehe0) / (hoehe1 - hoehe0)))
                neu.setdefault(n, {})[i] = neu.get(n, {}).get(i, 0.0) + w * (1.0 - t)
        for i, v in enumerate(o.data.vertices):
            t = max(0.0, min(1.0, (v.co.z - hoehe0) / (hoehe1 - hoehe0)))
            if t > 0.0:
                neu.setdefault("Spine", {})[i] = neu.get("Spine", {}).get(i, 0.0) + t
        gruppen = {n: list(d.items()) for n, d in neu.items()}
    for n, liste in gruppen.items():
        vg = o.vertex_groups.new(name=n)
        for i, w in liste:
            vg.add([i], w, 'REPLACE')
    # Keine Glättung: alle Schichten (Haut, Hemd, Jacke, Hose) müssen exakt dieselben Gewichte haben,
    # sonst drückt sich eine Schicht durch die andere.
    mod = o.modifiers.new("Armature", 'ARMATURE')
    mod.object = arm_obj
    o.parent = arm_obj


def hoehe_y(obj, x, zh):
    """Blender-y der Oberfläche vorn bei (x, Höhe zh) — Strahl von vorn auf das Stück"""
    bpy.context.view_layer.update()      # neu erzeugte Objekte erst auswerten lassen
    treffer, ort, _n, _i = obj.ray_cast(Vector((x, -1.0, zh)), Vector((0, 1, 0)))
    if not treffer:
        raise RuntimeError("Kein Treffer %s bei x=%.3f h=%.3f" % (obj.name, x, zh))
    return ort.y


# =================================================================== Formen
def teil(name, teile, voxel, schnitte=(), ausschnitt=None, glaetten=6, anteil=0.16):
    """Ein Stück aus Kugelketten: Voxel-Remesh, Boolean-Ausschnitt, Schnitte mit Ebenen
    (alles auf der Seite der Normalen wird abgeschnitten und die Fläche geschlossen)."""
    o = vereinen(teile, name)
    o.data.remesh_voxel_size = voxel
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.voxel_remesh()
    print("DEBUG", name, "nach Remesh", len(o.data.polygons), [round(x, 3) for x in o.dimensions])
    werkzeuge = [] if ausschnitt is None else (ausschnitt if isinstance(ausschnitt, list) else [ausschnitt])
    for werkzeug in werkzeuge:
        # Ausschnitt abziehen. Je nach Lösung kommt Unsinn heraus (leer, oder nichts geschnitten) —
        # deshalb wird das Ergebnis geprüft: nicht leer und die Fläche hat sich verändert.
        sicher = o.data.copy()
        vorher = len(o.data.polygons)
        erfolg = False
        for loesung in ('MANIFOLD', 'EXACT', 'FLOAT'):
            o.data = sicher.copy()
            b = o.modifiers.new("Ausschnitt", 'BOOLEAN')
            b.operation = 'DIFFERENCE'
            b.solver = loesung
            b.object = werkzeug
            bpy.ops.object.modifier_apply(modifier="Ausschnitt")
            bpy.context.view_layer.update()
            print("DEBUG", name, "Boolean", loesung, vorher, "->", len(o.data.polygons))
            if len(o.data.polygons) > vorher * 0.5 and len(o.data.polygons) != vorher:
                erfolg = True
                break
        if not erfolg:
            raise RuntimeError("Ausschnitt %s schneidet nicht" % name)
        bpy.data.objects.remove(werkzeug, do_unlink=True)
    if schnitte:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        for punkt, normale in schnitte:
            geo = list(bm.verts) + list(bm.edges) + list(bm.faces)
            bmesh.ops.bisect_plane(bm, geom=geo, plane_co=punkt, plane_no=normale, clear_outer=True)
            rand = [e for e in bm.edges if e.is_boundary]
            if rand:
                bmesh.ops.holes_fill(bm, edges=rand, sides=100000)
        bm.to_mesh(o.data)
        bm.free()
    # Normalen nach dem Schneiden einheitlich nach außen: sonst reißt der nächste Voxel-Remesh Löcher
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bm.calc_volume(signed=True) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
    print("DEBUG", name, "offene Kanten nach Schnitten:", len([e for e in bm.edges if e.is_boundary]))
    bm.to_mesh(o.data)
    bm.free()
    m = o.modifiers.new("Glatt", 'SMOOTH')
    m.factor = 0.7
    m.iterations = glaetten
    bpy.ops.object.modifier_apply(modifier="Glatt")
    if anteil < 1.0:
        d = o.modifiers.new("Dez", 'DECIMATE')
        d.ratio = anteil
        bpy.ops.object.modifier_apply(modifier="Dez")
        bm2 = bmesh.new()
        bm2.from_mesh(o.data)
        print("DEBUG", name, "offene Kanten nach Decimate:", len([e for e in bm2.edges if e.is_boundary]))
        bm2.free()
    bpy.ops.object.shade_smooth()
    return o


def fertig(name, objekte, farbe_fn, groesse=1024, rauheit=0.9, ohne_arme=False, starr_ab=None):
    """Teile verbinden, bemalen, an das Skelett binden"""
    o = objekte[0] if len(objekte) == 1 else vereinen(objekte, name)
    o.name = name
    o.data.name = name
    o.data.materials.clear()
    for poly in o.data.polygons:
        poly.material_index = 0
        poly.use_smooth = True
    img = bemalen(o, farbe_fn, groesse)
    o.data.materials.append(stoff_material(name, img, rauheit))
    binden(o, ohne_arme, starr_ab)
    kleidung_objekte.append(o)
    return o


def keil(punkte_xz, tiefe_von, tiefe_bis):
    """Prisma (Boolean-Werkzeug) für Ausschnitte: Querschnitt in der x/z-Ebene (Godot),
    in der Tiefe von bis (Godot-z, vorn positiv)."""
    bm = bmesh.new()
    unten = [bm.verts.new(Vector((x, -tiefe_von, z))) for x, z in punkte_xz]
    oben = [bm.verts.new(Vector((x, -tiefe_bis, z))) for x, z in punkte_xz]
    bm.faces.new(unten)
    bm.faces.new(list(reversed(oben)))
    n = len(unten)
    for i in range(n):
        bm.faces.new([unten[i], unten[(i + 1) % n], oben[(i + 1) % n], oben[i]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bm.calc_volume(signed=True) < 0:      # Normalen müssen nach außen zeigen, sonst fügt der Boolean hinzu
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
    me = bpy.data.meshes.new("keil")
    bm.to_mesh(me)
    bm.free()
    o = bpy.data.objects.new("keil", me)
    scene.collection.objects.link(o)
    return o


def armkette(seite, r_schulter, r_ellbogen, r_ende, ende_anteil, name):
    """Ärmel: Schulter → Ellbogen → Unterarm bis ende_anteil. Gibt Teile, Endpunkt, Richtung"""
    s = 1.0 if seite == "Left" else -1.0
    sch, ell, han = POS[seite + "Arm"], POS[seite + "ForeArm"], POS[seite + "Hand"]
    ende = ell + (han - ell) * ende_anteil
    teile = roehre(g2b(s * 0.10, 1.09, -0.01), sch, r_schulter + 0.006, r_schulter, name + "s", 6)
    teile += roehre(sch, ell, r_schulter, r_ellbogen, name + "o", 8)
    teile += roehre(ell, ende, r_ellbogen, r_ende, name + "u", 8)
    return teile, ende, (han - ell).normalized()


# Unterarm-Achsen in Godot-Koordinaten (für den Ärmel-Besatz)
UNTERARM = {s: (np.array(GPOS[s + "ForeArm"]), np.array(GPOS[s + "Hand"] - GPOS[s + "ForeArm"])) for s in ("Left", "Right")}


def arm_t(P, seite):
    """Position entlang des Unterarms: 0 = Ellbogen, 1 = Handgelenk"""
    a, ab = UNTERARM[seite]
    return ((P - a) @ ab) / float(ab @ ab)


# =================================================================== Farben
GRUEN = np.array([0.06, 0.27, 0.14])
GRUEN_HELL = np.array([0.14, 0.42, 0.22])
CREME = np.array([0.82, 0.76, 0.58])


def wolle(P, basis, st=1.0):
    """Grobes Gewebe: Flecken + feines Gitter"""
    n1 = ruis(P, 14.0)
    n2 = ruis(P, 55.0)
    gewebe = 0.5 + 0.5 * np.sin(P[:, 0] * 380) * np.sin(P[:, 1] * 380)
    f = 0.93 + 0.08 * n1 + 0.04 * n2 + 0.02 * gewebe
    return np.array(basis)[None, :] * (1 + (f[:, None] - 1) * st)


# =================================================================== Schalen aus dem Körper
def schale(name, offset_fn, ebenen, glaetten=2):
    """Kopie des Körpers, entlang der Oberfläche aufgeblasen (offset_fn(Blender-Koordinate) in m)
    und danach mit Ebenen zugeschnitten: erst aufblasen, dann schneiden, damit die Schnittkanten
    exakt auf den Ebenen liegen. ebenen: (Punkt, Normale), alles auf der Normalen-Seite fällt weg."""
    o = koerper.copy()
    o.data = koerper.data.copy()
    o.name = name
    o.data.name = name
    o.modifiers.clear()
    o.parent = None
    for g in list(o.vertex_groups):
        o.vertex_groups.remove(g)
    scene.collection.objects.link(o)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.normal_update()
    for v in bm.verts:
        v.co = v.co + v.normal * offset_fn(v.co)
    bm.to_mesh(o.data)
    bm.free()
    bpy.context.view_layer.objects.active = o
    if glaetten:
        m = o.modifiers.new("Glatt", 'SMOOTH')
        m.factor = 0.5
        m.iterations = glaetten
        bpy.ops.object.modifier_apply(modifier="Glatt")
    bm = bmesh.new()
    bm.from_mesh(o.data)
    for punkt, normale in ebenen:
        geo = list(bm.verts) + list(bm.edges) + list(bm.faces)
        bmesh.ops.bisect_plane(bm, geom=geo, plane_co=punkt, plane_no=normale, clear_outer=True)
        rand = [e for e in bm.edges if e.is_boundary]
        if rand:
            bmesh.ops.holes_fill(bm, edges=rand, sides=100000)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bm.calc_volume(signed=True) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
    nm = [e for e in bm.edges if not e.is_manifold]
    print("DEBUG schale", name, "Flaechen", len(bm.faces), "nicht-manifold Kanten", len(nm), "Volumen %.4f" % bm.calc_volume(signed=True))
    bm.to_mesh(o.data)
    bm.free()
    o.data.materials.clear()
    bpy.ops.object.shade_smooth()
    return o


def schale_ganz(name, offset_fn, weg_fn, glaetten=2, offen_fn=None):
    """Wie schale(), aber Rumpf und Ärmel bleiben EIN Stück (keine Naht): weg_fn(co) -> True löscht
    den Punkt (Hals, Saum, Beine, Ärmelende, Hände); die offenen Ränder werden geschlossen."""
    o = koerper.copy()
    o.data = koerper.data.copy()
    o.name = name
    o.data.name = name
    o.modifiers.clear()
    o.parent = None
    for g in list(o.vertex_groups):
        o.vertex_groups.remove(g)
    scene.collection.objects.link(o)
    bm = bmesh.new()
    bm.from_mesh(o.data)
    # Fein unterteilen, damit Schnittkanten (Saum, Ärmelende, Hals) sauber statt zackig werden
    bmesh.ops.subdivide_edges(bm, edges=list(bm.edges), cuts=3, use_grid_fill=True)
    bm.normal_update()
    for v in bm.verts:
        v.co = v.co + v.normal * offset_fn(v.co)
    bm.to_mesh(o.data)
    bm.free()
    bpy.context.view_layer.objects.active = o
    m = o.modifiers.new("Glatt", 'SMOOTH')
    m.factor = 0.5
    m.iterations = glaetten
    bpy.ops.object.modifier_apply(modifier="Glatt")
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if weg_fn(v.co)], context='VERTS')
    rand = [e for e in bm.edges if e.is_boundary]
    if rand:
        bmesh.ops.holes_fill(bm, edges=rand, sides=100000)
    # Offene Stellen (z. B. Jackenausschnitt vorn), die NICHT geschlossen werden
    if offen_fn is not None:
        bmesh.ops.delete(bm, geom=[v for v in bm.verts if offen_fn(v.co)], context='VERTS')
    # lose Reste (Hände, Gesichtsteile ...) entfernen: nur die größte zusammenhängende Fläche behalten
    bm.verts.ensure_lookup_table()
    gesehen = set()
    inseln = []
    for v0 in bm.verts:
        if v0.index in gesehen:
            continue
        stapel, insel = [v0], []
        gesehen.add(v0.index)
        while stapel:
            v = stapel.pop()
            insel.append(v)
            for e in v.link_edges:
                w = e.other_vert(v)
                if w.index not in gesehen:
                    gesehen.add(w.index)
                    stapel.append(w)
        inseln.append(insel)
    inseln.sort(key=len, reverse=True)
    for insel in inseln[1:]:
        bmesh.ops.delete(bm, geom=[v for v in insel if v.is_valid], context='VERTS')
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    if bm.calc_volume(signed=True) < 0:
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
    print("DEBUG", name, "Flaechen", len(bm.faces), "Inseln", len(inseln), "Kanten offen", len([e for e in bm.edges if e.is_boundary]))
    bm.to_mesh(o.data)
    bm.free()
    # Zackige Schnittkanten glätten (die Kanten wandern mit), danach Flächen sparen
    m2 = o.modifiers.new("Glatt2", 'SMOOTH')
    m2.factor = 0.6
    m2.iterations = 8
    bpy.ops.object.modifier_apply(modifier="Glatt2")
    o.data.materials.clear()
    bpy.ops.object.shade_smooth()
    return o


def arm_jenseits(co, anteil):
    """Punkt liegt (im Blender-Raum) hinter dem Ärmelende eines der beiden Arme"""
    if abs(co.x) < 0.2:
        return False
    seite = "Left" if co.x > 0 else "Right"
    punkt, richtung = ende_ebene(seite, anteil)
    return (co - punkt).dot(richtung) > 0


def ausschneiden(o, werkzeug):
    """Werkzeug (z. B. V-Keil) mit Boolean abziehen; MANIFOLD zuerst, das Ergebnis wird geprüft"""
    sicher = o.data.copy()
    vorher = len(o.data.polygons)
    for loesung in ('MANIFOLD', 'EXACT', 'FLOAT'):
        o.data = sicher.copy()
        b = o.modifiers.new("Ausschnitt", 'BOOLEAN')
        b.operation = 'DIFFERENCE'
        b.solver = loesung
        b.object = werkzeug
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.modifier_apply(modifier="Ausschnitt")
        print("DEBUG ausschneiden", o.name, loesung, vorher, "->", len(o.data.polygons))
        if len(o.data.polygons) > vorher * 0.5 and len(o.data.polygons) != vorher:
            bpy.data.objects.remove(werkzeug, do_unlink=True)
            return
    raise RuntimeError("Ausschnitt an %s schneidet nicht" % o.name)


# Schnittebenen (Blender-Koordinaten; Höhe = z, Breite = x)
def unter(z):
    return (Vector((0, 0, z)), Vector((0, 0, -1)))        # alles unterhalb z weg


def ueber(z):
    return (Vector((0, 0, z)), Vector((0, 0, 1)))         # alles oberhalb z weg


def breiter_als(x):
    """alles ausserhalb |x| weg (Arme)"""
    return [(Vector((x, 0, 0)), Vector((1, 0, 0))), (Vector((-x, 0, 0)), Vector((-1, 0, 0)))]


def nur_arm(seite, x):
    """nur der Arm dieser Seite (alles innerhalb |x| weg)"""
    if seite == "Left":
        return [(Vector((x, 0, 0)), Vector((-1, 0, 0)))]
    return [(Vector((-x, 0, 0)), Vector((1, 0, 0)))]


def ende_ebene(seite, anteil):
    """Ärmelende: Ebene quer zum Unterarm bei `anteil` seiner Länge"""
    ell, han = POS[seite + "ForeArm"], POS[seite + "Hand"]
    return (ell + (han - ell) * anteil, (han - ell).normalized())


def schraege(seite):
    """Schräge Ebene am Arm: schneidet den Körper-Steg zwischen Arm und Hüfte ab (x + z < HEM + Nahtbreite),
    damit am Saum keine Zipfel am Rumpf überstehen"""
    n = Vector((-1, 0, -1)).normalized() if seite == "Left" else Vector((1, 0, -1)).normalized()
    x0 = SCHULTERNAHT if seite == "Left" else -SCHULTERNAHT
    return (Vector((x0, 0, 0.76)), n)


def sanft(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


SCHULTERNAHT = 0.200       # hier wird Rumpf von Ärmel getrennt (wie eine Naht)

if OUTFIT == "bean":
    # =================================================================== Hemd (Karo)
    def verschweissen(teile, name, dist=0.0002):
        """Mehrere Teile (Rumpf + Ärmel), die an einer gemeinsamen Schnittebene mit gleichem Abstand
        aufgeblasen wurden, zu EINER Fläche vereinen: die Punkte auf der Naht liegen exakt
        aufeinander und werden verschmolzen."""
        o = vereinen(teile, name)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=dist)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(o.data)
        bm.free()
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth()
        return o


    HEMD_OFF = lambda c: 0.010
    hemd_teile = [schale("hemd_rumpf", HEMD_OFF, [unter(0.90), ueber(1.14)] + breiter_als(SCHULTERNAHT), 0)]
    for seite in ("Left", "Right"):
        hemd_teile.append(schale("hemd_" + seite, HEMD_OFF, nur_arm(seite, SCHULTERNAHT) + [ueber(1.14), ende_ebene(seite, 0.82)], 0))
    hemd_koerper = verschweissen(hemd_teile, "Hemd")
    hemd_teile = [hemd_koerper]


    def hemd_farbe(P):
        s = 0.034
        kx = np.floor(P[:, 0] / s) % 2
        ky = np.floor(P[:, 1] / s) % 2
        weiss = np.array([0.94, 0.94, 0.90])
        mitte = np.array([0.50, 0.62, 0.48])
        dunkel = np.array([0.14, 0.27, 0.17])
        summe = kx + ky    # Gingham: weiss / Halbton (ein Streifen) / dunkel (beide)
        col = np.where((summe == 0)[:, None], weiss, np.where((summe == 1)[:, None], mitte, dunkel))
        return col * (0.93 + 0.12 * ruis(P, 70.0))[:, None]


    hemd = fertig("Hemd", hemd_teile, hemd_farbe, 2048)

    # ==================================================== Janker (Trachtenjacke)
    HEM = 0.76                                                   # Saum: auf Hüfthöhe, über der Hose
    OEFF_UNTEN, OEFF_OBEN = 0.060, 0.108


    def janker_offset(c):
        # oben an Schultern und Hals etwas weiter, damit keine Haut am Kragen durchschaut
        return 0.022 + 0.014 * sanft(0.90, HEM, c.z)             # unten etwas ausgestellt


    jk_rumpf = schale("janker_rumpf", janker_offset, [unter(HEM), ueber(1.14)] + breiter_als(SCHULTERNAHT), 6)
    # Vorn offen: V, unten schmal und oben breiter; die Rückseite bleibt geschlossen
    ausschneiden(jk_rumpf, keil([(-OEFF_UNTEN, 0.70), (OEFF_UNTEN, 0.70), (OEFF_OBEN, 1.24), (-OEFF_OBEN, 1.24)], 0.30, -0.02))
    jk_teile = [jk_rumpf]
    for seite in ("Left", "Right"):
        jk_teile.append(schale("janker_" + seite, janker_offset, nur_arm(seite, SCHULTERNAHT) + [ueber(1.14), ende_ebene(seite, 0.62), schraege(seite)], 6))
    janker_haupt = verschweissen(jk_teile, "Janker")


    def oeff_breite(z):
        return OEFF_UNTEN + (z - 0.70) / (1.24 - 0.70) * (OEFF_OBEN - OEFF_UNTEN)


    # Details: vier Knöpfe an der Kante, zwei Taschenklappen
    details = []
    knopf_pos = []
    for z in (0.835, 0.905, 0.975, 1.045):
        x = oeff_breite(z) + 0.034
        knopf_pos.append((x, z))
        details.append(kugel(Vector((x, hoehe_y(janker_haupt, x, z) + 0.002, z)), (0.015, 0.008, 0.015), "knopf", 14))
    for sx in (1, -1):
        x, z = sx * 0.130, 0.84
        details.append(kugel(Vector((x, hoehe_y(janker_haupt, x, z) + 0.004, z)), (0.046, 0.012, 0.024), "klappe", 16))


    def janker_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        col = wolle(P, [0.37, 0.38, 0.39])
        trim = np.zeros(len(P))
        trim = np.maximum(trim, hart(gy, HEM + 0.022, 0.004) * (np.abs(gx) < 0.2))             # Saum
        kante = np.abs(np.abs(gx) - oeff_breite(gy))                                              # Öffnungskante
        trim = np.maximum(trim, hart(kante, 0.013, 0.003) * (gz > -0.02) * (gy > HEM))
        for seite, vz in (("Left", 1.0), ("Right", -1.0)):                                        # Ärmelbündchen
            trim = np.maximum(trim, ((arm_t(P, seite) > 0.55) & (vz * gx > 0.15)) * 1.0)
        for sx in (1, -1):                                                                        # Klappenränder
            dx = (gx - sx * 0.130) / 0.048
            dy = (gy - 0.84) / 0.026
            rand = np.abs(np.maximum(np.abs(dx), np.abs(dy)) - 1.0)
            trim = np.maximum(trim, hart(rand, 0.07, 0.03) * (gz > 0.05))
        col = mischen(col, GRUEN[None, :] * (0.9 + 0.2 * ruis(P, 60.0))[:, None], trim)
        for kx, kz in knopf_pos:                                                                  # Knöpfe holzbraun
            d = np.hypot(gx - kx, gy - kz)
            col = mischen(col, np.array([0.40, 0.23, 0.13])[None, :] * (0.9 + 0.25 * ruis(P, 90.0))[:, None],
                          hart(d, 0.016, 0.003) * (gz > 0.05))
        return col


    janker = fertig("Janker", [janker_haupt] + details, janker_farbe, 2048, 0.95)

    # =================================================================== Lederhose
    def hose_offset(c):
        return 0.012 + 0.012 * sanft(0.62, 0.50, c.z)            # Beinabschluss etwas weiter


    hose_koerper = schale("Lederhose", hose_offset, [unter(0.50), ueber(0.87)] + breiter_als(0.200))


    def hose_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        col = wolle(P, [0.20, 0.17, 0.12], 1.4)                                  # dunkles Leder, fleckig
        col = mischen(col, GRUEN[None, :], hart(gy, 0.512, 0.004) * (gy > 0.40))   # Saumkante
        for sx in (1, -1):                                                         # Stickerei vorn
            for cy, ang, ln in ((0.64, 0.0, 0.050), (0.60, 0.9, 0.032), (0.60, -0.9, 0.032), (0.56, 0.0, 0.026)):
                u, v = gx - sx * 0.108, gy - cy
                ca, sa = math.cos(ang), math.sin(ang)
                uu, vv = u * ca - v * sa, u * sa + v * ca
                blatt = (np.abs(uu) < 0.016 * np.clip(1 - (vv / ln) ** 2, 0, 1)) & (np.abs(vv) < ln)
                col = mischen(col, GRUEN_HELL[None, :], (blatt & (gz > 0.02)) * 1.0)
            mitte = hart(np.abs(gx - sx * 0.108), 0.0035, 0.002) * (gy > 0.52) * (gy < 0.70) * (gz > 0.02)
            col = mischen(col, CREME[None, :] * 0.8, mitte)
        return col


    hose = fertig("Lederhose", [hose_koerper], hose_farbe, 2048, 0.9, True)

    # =================================================================== Gürtel (Taille)
    gurt_koerper = schale("Gurt", lambda c: 0.012, [unter(0.835), ueber(0.895)] + breiter_als(0.200))
    gurt_y = hoehe_y(gurt_koerper, 0.0, 0.865)
    plakette = kugel(Vector((0, gurt_y - 0.004, 0.865)), (0.060, 0.014, 0.036), "plakette", 20)


    def gurt_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        leder = wolle(P, [0.10, 0.14, 0.10], 1.2)
        r = np.hypot(gx / 0.060, (gy - 0.865) / 0.036)
        pl = np.tile(np.array([0.12, 0.30, 0.17]), (len(P), 1))
        pl = mischen(pl, CREME[None, :], hart(np.abs(r - 0.82), 0.12, 0.05))
        pl = mischen(pl, CREME[None, :], hart(np.abs(gx), 0.006, 0.003) * (r < 0.7))
        pl = pl * (0.92 + 0.14 * ruis(P, 70.0))[:, None]
        ist_plakette = (r < 1.03) & (gz > 0.18)
        return np.where(ist_plakette[:, None], pl, leder)


    gurt_obj = fertig("Gurt", [gurt_koerper, plakette], gurt_farbe, 1024, 0.8, True)

    # =================================================================== Hut (starr am Kopfknochen)
    HUT_UNTEN = 1.498          # Krempe direkt über den Brauen (Brauen sitzen bei 1.428)
    teile = []
    teile.append(kugel(g2b(0, HUT_UNTEN, 0.0), (0.290, 0.268, 0.030), "krempe", 32))
    for i in range(11):
        t = i / 10
        teile.append(kugel(g2b(0, HUT_UNTEN + 0.02 + 0.20 * t, 0.0), (0.235 - 0.022 * t, 0.215 - 0.020 * t, 0.032), "krone", 28))
    hut = vereinen(teile, "Hut")
    hut.data.remesh_voxel_size = 0.010
    bpy.context.view_layer.objects.active = hut
    bpy.ops.object.voxel_remesh()
    gl = hut.modifiers.new("Glatt", 'SMOOTH')
    gl.factor = 0.6
    gl.iterations = 6
    bpy.ops.object.modifier_apply(modifier="Glatt")
    dz = hut.modifiers.new("Dez", 'DECIMATE')
    dz.ratio = 0.13
    bpy.ops.object.modifier_apply(modifier="Dez")
    bpy.ops.object.shade_smooth()
    band = kugel(g2b(0, HUT_UNTEN + 0.055, 0.0), (0.240, 0.220, 0.034), "band", 32)
    feder = kugel(Vector((0, 0, 0)), (0.012, 0.045, 0.085), "feder", 14)
    feder.rotation_euler = (math.radians(-18), math.radians(22), math.radians(18))
    feder.location = g2b(0.225, HUT_UNTEN + 0.19, 0.0) + Vector((0, 0.01, 0.0))


    def hut_farbe(P):
        col = wolle(P, [0.24, 0.31, 0.19], 1.5)      # Filz
        return col


    hut_ob = fertig("Hut", [hut], hut_farbe, 1024, 0.95)
    band.data.materials.append(material("Hutband", (0.07, 0.07, 0.06), 0.8))
    feder.data.materials.append(material("Feder", (0.74, 0.68, 0.55), 0.9))
    for o in (band, feder):
        o.parent = arm_obj
        vg = o.vertex_groups.new(name="Head")
        vg.add([v.index for v in o.data.vertices], 1.0, 'REPLACE')
        mod = o.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm_obj
        kleidung_objekte.append(o)
    # Hut starr am Kopf (statt der übernommenen Körpergewichte)
    for g in list(hut_ob.vertex_groups):
        hut_ob.vertex_groups.remove(g)
    kg = hut_ob.vertex_groups.new(name="Head")
    kg.add([v.index for v in hut_ob.data.vertices], 1.0, 'REPLACE')



elif OUTFIT == "franz":
    # ================================================================ Franz: Weste, Leinenhemd, grüne Lederhose, Tirolerhut, Schnurrbart
    LODEN = np.array([0.13, 0.22, 0.27])
    LEDER_GRUEN = np.array([0.10, 0.20, 0.12])
    LEINEN = np.array([0.93, 0.91, 0.84])
    HOLZ = np.array([0.80, 0.72, 0.52])

    def verschweissen(teile, name, dist=0.0002):
        o = vereinen(teile, name)
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=dist)
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        bm.to_mesh(o.data)
        bm.free()
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth()
        return o

    # ---- Leinenhemd (lange Ärmel, vorn ein Schlitz mit Knopfleiste)
    HEMD_OFF = lambda c: 0.010
    hemd_teile = [schale("hemd_rumpf", HEMD_OFF, [unter(0.84), ueber(1.14)] + breiter_als(SCHULTERNAHT), 0)]
    for seite in ("Left", "Right"):
        hemd_teile.append(schale("hemd_" + seite, HEMD_OFF, nur_arm(seite, SCHULTERNAHT) + [ueber(1.14), ende_ebene(seite, 0.92)], 0))
    hemd_koerper = verschweissen(hemd_teile, "Hemd")

    def hemd_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        col = wolle(P, LEINEN, 0.7)
        faden = 0.97 + 0.03 * np.sin(gy * 420) * np.sin(gx * 420)
        col = col * faden[:, None]
        # Knopfleiste in der Mitte und Bündchen
        col = mischen(col, LEINEN[None, :] * 0.82, hart(np.abs(gx), 0.012, 0.003) * (gz > 0.05) * (gy > 0.9))
        for seite, vz in (("Left", 1.0), ("Right", -1.0)):
            col = mischen(col, LEINEN[None, :] * 0.78, ((arm_t(P, seite) > 0.80) & (vz * gx > 0.15)) * 1.0)
        return col

    hemd = fertig("Hemd", [hemd_koerper], hemd_farbe, 2048)

    # ---- Trachtenweste (ohne Ärmel, vorn offen, Knöpfe)
    WESTE_UNTEN, WESTE_OBEN = 0.050, 0.100
    def weste_oeff(z):
        return WESTE_UNTEN + (z - 0.70) / (1.24 - 0.70) * (WESTE_OBEN - WESTE_UNTEN)

    weste_off = lambda c: 0.024 + 0.010 * sanft(0.92, 0.80, c.z)
    weste = schale("weste", weste_off, [unter(0.80), ueber(1.13)] + breiter_als(0.176), 4)
    ausschneiden(weste, keil([(-WESTE_UNTEN, 0.70), (WESTE_UNTEN, 0.70), (WESTE_OBEN, 1.24), (-WESTE_OBEN, 1.24)], 0.30, -0.02))
    weste_details = []
    weste_knoepfe = []
    for z in (0.84, 0.91, 0.98, 1.05):
        x = weste_oeff(z) + 0.030
        weste_knoepfe.append((x, z))
        weste_details.append(kugel(Vector((x, hoehe_y(weste, x, z) + 0.002, z)), (0.013, 0.007, 0.013), "knopf", 14))

    def weste_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        col = wolle(P, LODEN)
        rand = np.zeros(len(P))
        rand = np.maximum(rand, hart(gy, 0.80 + 0.020, 0.004))                               # Saum
        rand = np.maximum(rand, hart(np.abs(np.abs(gx) - weste_oeff(gy)), 0.010, 0.003) * (gz > -0.02))
        rand = np.maximum(rand, hart(np.abs(np.abs(gx) - 0.176), 0.010, 0.003))              # Armloch
        col = mischen(col, CREME[None, :] * 0.85, rand)
        # Zierstickerei: kleine Rauten entlang der Brust
        for sx in (1, -1):
            for cy in (0.88, 0.97, 1.06):
                d = np.abs(gx - sx * 0.130) / 0.018 + np.abs(gy - cy) / 0.018
                col = mischen(col, GRUEN_HELL[None, :], hart(d, 1.0, 0.25) * (gz > 0.05))
        for kx, kz in weste_knoepfe:
            d = np.hypot(gx - kx, gy - kz)
            col = mischen(col, HOLZ[None, :], hart(d, 0.015, 0.003) * (gz > 0.05))
        return col

    weste_obj = fertig("Weste", [weste] + weste_details, weste_farbe, 2048, 0.9)

    # ---- Lederhose, grün, mit Latz und heller Naht
    hose_off = lambda c: 0.020 + 0.012 * sanft(0.62, 0.50, c.z)
    hose_koerper = schale("Lederhose", hose_off, [unter(0.50), ueber(0.87)] + breiter_als(0.235), 2)

    def hose_farbe(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        col = wolle(P, LEDER_GRUEN, 1.5)
        col = mischen(col, CREME[None, :] * 0.8, hart(gy, 0.512, 0.004) * (gy > 0.40))     # Saum hell
        # Latz: Rechteck vorn mit heller Naht
        latz = np.maximum(np.abs(gx) / 0.075, np.abs(gy - 0.80) / 0.065)
        col = mischen(col, CREME[None, :] * 0.8, hart(np.abs(latz - 1.0), 0.07, 0.03) * (gz > 0.03))
        # Naht an den Oberschenkeln
        for sx in (1, -1):
            naht = hart(np.abs(gx - sx * 0.110), 0.003, 0.002) * (gy > 0.52) * (gy < 0.74) * (gz > 0.02)
            col = mischen(col, CREME[None, :] * 0.8, naht)
        return col

    hose = fertig("Lederhose", [hose_koerper], hose_farbe, 2048, 0.9, True)

    # ---- Tirolerhut mit Gamsbart (starr am Kopf)
    HUT_UNTEN = 1.498
    teile = [kugel(g2b(0, HUT_UNTEN, 0.0), (0.262, 0.242, 0.026), "krempe", 32)]
    for i in range(12):
        t = i / 11
        teile.append(kugel(g2b(0, HUT_UNTEN + 0.02 + 0.22 * t, 0.0), (0.222 - 0.060 * t, 0.202 - 0.058 * t, 0.032), "krone", 28))
    hut = vereinen(teile, "Hut")
    hut.data.remesh_voxel_size = 0.010
    bpy.context.view_layer.objects.active = hut
    bpy.ops.object.voxel_remesh()
    _m = hut.modifiers.new("Glatt", 'SMOOTH')
    _m.factor = 0.6
    _m.iterations = 6
    bpy.ops.object.modifier_apply(modifier="Glatt")
    _d = hut.modifiers.new("Dez", 'DECIMATE')
    _d.ratio = 0.13
    bpy.ops.object.modifier_apply(modifier="Dez")
    bpy.ops.object.shade_smooth()

    def hut_farbe(P):
        gy = P[:, 1]
        col = wolle(P, [0.24, 0.17, 0.12], 1.5)
        band_m = hart(np.abs(gy - (HUT_UNTEN + 0.06)), 0.024, 0.004)
        col = mischen(col, np.array([0.26, 0.34, 0.20])[None, :], band_m)
        flecht = hart(np.abs(np.sin((P[:, 0] + P[:, 2]) * 120)), 0.35, 0.2) * band_m
        return mischen(col, CREME[None, :] * 0.7, flecht * 0.5)

    hut_ob = fertig("Hut", [hut], hut_farbe, 1024, 0.95)
    for g in list(hut_ob.vertex_groups):
        hut_ob.vertex_groups.remove(g)
    _kg = hut_ob.vertex_groups.new(name="Head")
    _kg.add([v.index for v in hut_ob.data.vertices], 1.0, 'REPLACE')

    # Gamsbart: Büschel aus schmalen Ellipsoiden am Band
    bart_teile = []
    for i in range(9):
        w = (i - 4) / 4.0
        pos = g2b(0.196 + 0.010 * w, HUT_UNTEN + 0.15 + 0.012 * abs(w), 0.028 * w)
        k = kugel(Vector((0, 0, 0)), (0.008, 0.008, 0.075), "gams", 8)
        k.location = pos
        k.rotation_euler = (math.radians(-20 + 6 * w), math.radians(16 + 4 * w), math.radians(12 * w))
        bart_teile.append(k)
    gams = vereinen(bart_teile, "Gamsbart")
    gams.data.materials.append(material("Gamsbart", (0.62, 0.55, 0.42), 0.9))

    # Bayerischer Schnauzer, richtig modelliert: dicker Körper aus Kugelketten (verjüngt, schwingt
    # über die Mundwinkel nach unten und läuft in einer hochgezwirbelten Spitze aus), danach zu einer
    # geschlossenen, glatten Form verschmolzen und mit Haarsträhnen bemalt.
    HAAR = np.array([0.52, 0.52, 0.54])
    teile_b = []
    for sx in (1, -1):
        punkte = []
        for i in range(30):
            t = i / 29.0
            x = sx * (0.008 + 0.125 * t)
            # Höhe: über der Lippe, nach außen fallend, am Ende steil nach oben gezwirbelt
            h = 1.226 - 0.040 * math.sin(min(t / 0.62, 1.0) * math.pi * 0.5) + 0.095 * max(0.0, (t - 0.62) / 0.38) ** 1.7
            r = 0.026 * (1.0 - 0.80 * t ** 1.3) + 0.005
            punkte.append((x, h, r))
        for x, h, r in punkte:
            teile_b.append(kugel(Vector((x, haut_y(max(-0.19, min(0.19, x)), h) + 0.004 + r * 0.55, h)), (r * 1.15, r * 0.85, r), "bart", 12))
    # Mitte schließen
    for i in range(5):
        teile_b.append(kugel(Vector((0.0, haut_y(0.0, 1.226) + 0.012, 1.226 - 0.004 * i)), (0.020, 0.014, 0.020), "bart_mitte", 12))
    schnurrbart = vereinen(teile_b, "Schnurrbart")
    schnurrbart.data.remesh_voxel_size = 0.0028
    bpy.context.view_layer.objects.active = schnurrbart
    bpy.ops.object.voxel_remesh()
    _m = schnurrbart.modifiers.new("Glatt", 'SMOOTH')
    _m.factor = 0.6
    _m.iterations = 6
    bpy.ops.object.modifier_apply(modifier="Glatt")
    _d = schnurrbart.modifiers.new("Dez", 'DECIMATE')
    _d.ratio = 0.22
    bpy.ops.object.modifier_apply(modifier="Dez")
    bpy.ops.object.shade_smooth()

    def bart_farbe(P):
        gx, gy = P[:, 0], P[:, 1]
        # Haarsträhnen: feine Linien, die von der Mitte nach außen laufen und mit der Höhe leicht abfallen
        strahl = np.sin((gy + 0.35 * np.abs(gx)) * 900) * 0.5 + 0.5
        fein = ruis(P, 150.0)
        col = HAAR[None, :] * (0.78 + 0.30 * strahl + 0.20 * fein)[:, None]
        return mischen(col, HAAR[None, :] * 1.6, hart(strahl, 0.15, 0.2) * 0.35)

    schnurrbart = fertig("Schnurrbart", [schnurrbart], bart_farbe, 1024, 0.9)

    # Augenlider: halbe Hauben über den oberen Augen, innen tiefer (grummeliger Blick)
    LID = material("Lid", (0.66, 0.43, 0.32), 0.8)
    lider = []
    for sx in (1, -1):
        ay = haut_y(sx * 0.093, 1.30)
        lid = kugel(Vector((sx * 0.093, ay + 0.010, 1.30)), (0.0715, 0.0480, 0.0715), "lid", 72)
        bmx = bmesh.new()
        bmx.from_mesh(lid.data)
        # Schnittebene durch das Auge, zur Nase hin abfallend (innen tiefer = grummeliger Blick);
        # sauber mit bisect statt Punkte löschen, damit die Lidkante glatt ist
        nz = Vector((0.0, 0.0, 1.0))     # Normale zeigt nach oben, außen etwas höher
        bmesh.ops.bisect_plane(bmx, geom=list(bmx.verts) + list(bmx.edges) + list(bmx.faces),
                               plane_co=Vector((sx * 0.093, 0.0, 1.309)), plane_no=-nz, clear_outer=True)
        rand_k = [e for e in bmx.edges if e.is_boundary]
        if rand_k:
            bmesh.ops.holes_fill(bmx, edges=rand_k, sides=100000)
        bmesh.ops.recalc_face_normals(bmx, faces=bmx.faces)
        bmx.to_mesh(lid.data)
        bmx.free()
        lid.data.materials.append(LID)
        bpy.context.view_layer.objects.active = lid
        bpy.ops.object.shade_smooth()
        lider.append(lid)
    for o in lider:
        o.parent = arm_obj
        vg = o.vertex_groups.new(name="Head")
        vg.add([v.index for v in o.data.vertices], 1.0, 'REPLACE')
        mod = o.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm_obj
        kleidung_objekte.append(o)

    for g in list(schnurrbart.vertex_groups):
        schnurrbart.vertex_groups.remove(g)
    _kopf = schnurrbart.vertex_groups.new(name="Head")
    _kopf.add([v.index for v in schnurrbart.data.vertices], 1.0, 'REPLACE')
    gams.parent = arm_obj
    _vg = gams.vertex_groups.new(name="Head")
    _vg.add([v.index for v in gams.data.vertices], 1.0, 'REPLACE')
    _mod = gams.modifiers.new("Armature", 'ARMATURE')
    _mod.object = arm_obj
    kleidung_objekte.append(gams)

elif OUTFIT == "huete":
    # ================================================================ Creator-Assets: Hüte
    # Jeder Hut ist ein eigenes Teil (Modell-Koordinaten des Standardkörpers, Ursprung = Modellursprung),
    # wird einzeln als GLB exportiert und in Godot an den Kopfknochen gehängt. Das Teil "<name>_farbe"
    # ist neutral grau gemalt und wird im Creator per albedo_color eingefärbt; Band, Feder usw. sind
    # eigene Teile mit Festfarbe.
    HUETE = {}
    BR = 1.498            # Höhe der Krempe (über den Brauen bei 1.428)

    def kette(y0, y1, profil, n, dicke=0.032, seg=26):
        """Ringe von y0 bis y1; profil(t) -> (rx, ry): Halbachsen in x und Tiefe"""
        out = []
        for i in range(n):
            t = i / (n - 1)
            rx, ry = profil(t)
            out.append(kugel(g2b(0, y0 + (y1 - y0) * t, 0.0), (rx, ry, dicke), "ring", seg))
        return out

    def formen(name, teile, voxel=0.010, glaetten=6, anteil=0.14):
        o = vereinen(teile, name)
        o.data.remesh_voxel_size = voxel
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.voxel_remesh()
        m = o.modifiers.new("Glatt", 'SMOOTH')
        m.factor = 0.6
        m.iterations = glaetten
        bpy.ops.object.modifier_apply(modifier="Glatt")
        d = o.modifiers.new("Dez", 'DECIMATE')
        d.ratio = anteil
        bpy.ops.object.modifier_apply(modifier="Dez")
        bpy.ops.object.shade_smooth()
        return o

    def grau(P, hell=0.86):
        """Neutrales Gewebe/Filz in Grau — wird in Godot eingefärbt"""
        n1 = ruis(P, 16.0)
        n2 = ruis(P, 70.0)
        v = hell * (0.92 + 0.10 * n1 + 0.05 * n2)
        return np.repeat(v[:, None], 3, axis=1)

    def fest(name, o, farbe, rauheit=0.85):
        o.name = name
        o.data.name = name
        o.data.materials.clear()
        o.data.materials.append(material(name, farbe, rauheit))
        bpy.ops.object.select_all(action='DESELECT')
        return o

    def hut_fertig(name, farbteile, details, bemalen_fn=grau, groesse=1024):
        haupt = farbteile if not isinstance(farbteile, list) else farbteile[0]
        o = fertig(name + "_farbe", [haupt], bemalen_fn, groesse, 0.95)
        for g in list(o.vertex_groups):
            o.vertex_groups.remove(g)
        HUETE[name] = [o] + details

    # ---- 1. Filzhut mit Feder (Bean)
    krempe = kugel(g2b(0, BR, 0.0), (0.290, 0.268, 0.030), "krempe", 32)
    krone = kette(BR + 0.02, BR + 0.20, lambda t: (0.235 - 0.022 * t, 0.215 - 0.020 * t), 11)
    h = formen("filzhut", [krempe] + krone)
    band = fest("filzhut_band", kugel(g2b(0, BR + 0.055, 0.0), (0.240, 0.220, 0.034), "band", 32), (0.07, 0.07, 0.06), 0.8)
    feder = kugel(Vector((0, 0, 0)), (0.012, 0.045, 0.085), "feder", 14)
    feder.rotation_euler = (math.radians(-18), math.radians(22), math.radians(18))
    feder.location = g2b(0.225, BR + 0.19, 0.0) + Vector((0, 0.01, 0.0))
    fest("filzhut_feder", feder, (0.74, 0.68, 0.55), 0.9)
    hut_fertig("filzhut", h, [band, feder])

    # ---- 2. Tirolerhut mit Gamsbart
    krempe = kugel(g2b(0, BR, 0.0), (0.262, 0.242, 0.026), "krempe", 32)
    krone = kette(BR + 0.02, BR + 0.24, lambda t: (0.222 - 0.060 * t, 0.202 - 0.058 * t), 12)
    h = formen("tirolerhut", [krempe] + krone)
    band = fest("tirolerhut_band", kugel(g2b(0, BR + 0.06, 0.0), (0.236, 0.216, 0.026), "band", 32), (0.26, 0.34, 0.20), 0.85)
    bart_t = []
    for i in range(9):
        w = (i - 4) / 4.0
        k = kugel(Vector((0, 0, 0)), (0.008, 0.008, 0.075), "gams", 8)
        k.location = g2b(0.196 + 0.010 * w, BR + 0.15 + 0.012 * abs(w), 0.028 * w)
        k.rotation_euler = (math.radians(-20 + 6 * w), math.radians(16 + 4 * w), math.radians(12 * w))
        bart_t.append(k)
    gams = vereinen(bart_t, "gams")
    fest("tirolerhut_gams", gams, (0.62, 0.55, 0.42), 0.9)
    hut_fertig("tirolerhut", h, [band, gams])

    # ---- 3. Schiebermütze
    krone = kette(BR - 0.01, BR + 0.215, lambda t: (0.226 - 0.040 * t ** 2.2, 0.206 - 0.036 * t ** 2.2), 12, 0.036)
    schirm = kugel(Vector((0, 0, 0)), (0.125, 0.110, 0.022), "schirm", 36)
    schirm.rotation_euler = (math.radians(10), 0, 0)
    schirm.location = g2b(0, BR + 0.005, 0.225)
    h = formen("schiebermuetze", krone + [schirm], 0.006)
    knopf = fest("schiebermuetze_knopf", kugel(g2b(0, BR + 0.225, 0.0), (0.018, 0.018, 0.012), "knopf", 12), (0.2, 0.2, 0.2), 0.8)
    hut_fertig("schiebermuetze", h, [knopf])

    # ---- 4. Strohhut
    krempe = kugel(g2b(0, BR, 0.0), (0.340, 0.320, 0.014), "krempe", 40)
    krone = kette(BR + 0.01, BR + 0.22, lambda t: (0.232 - 0.016 * t, 0.212 - 0.014 * t), 10)
    h = formen("strohhut", [krempe] + krone, 0.009)
    band = fest("strohhut_band", kugel(g2b(0, BR + 0.05, 0.0), (0.236, 0.216, 0.030), "band", 32), (0.60, 0.12, 0.10), 0.8)

    def stroh(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        flecht = 0.88 + 0.10 * np.sin(np.hypot(gx, gz) * 520) * np.sin(np.arctan2(gz, gx) * 90)
        return np.repeat((flecht * (0.9 + 0.12 * ruis(P, 40.0)))[:, None], 3, axis=1)

    hut_fertig("strohhut", h, [band], stroh)

    # ---- 5. Zylinder
    krempe = kugel(g2b(0, BR, 0.0), (0.300, 0.280, 0.018), "krempe", 36)
    krone = kette(BR + 0.01, BR + 0.40, lambda t: (0.240, 0.220), 14)
    h = formen("zylinder", [krempe] + krone, 0.009)
    band = fest("zylinder_band", kugel(g2b(0, BR + 0.07, 0.0), (0.243, 0.223, 0.044), "band", 32), (0.55, 0.10, 0.10), 0.7)
    hut_fertig("zylinder", h, [band], lambda P: grau(P, 0.80))

    # ---- 6. Wollmütze mit Bommel
    krone = kette(BR - 0.01, BR + 0.26, lambda t: (0.228 * math.sqrt(max(0.0, 1.0 - t ** 2.6)) + 0.012, 0.208 * math.sqrt(max(0.0, 1.0 - t ** 2.6)) + 0.012), 14, 0.036)
    umschlag = kette(BR - 0.012, BR + 0.05, lambda t: (0.238, 0.218), 4, 0.030)
    h = formen("wollmuetze", krone + umschlag, 0.008)
    bommel = kugel(g2b(0, BR + 0.30, 0.0), (0.050, 0.050, 0.050), "bommel", 20)
    bommel_o = formen("wollmuetze_bommel", [bommel], 0.006, 3, 0.4)

    def wolle_gestrickt(P):
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        wirk = 0.80 + 0.14 * np.sin(gy * 520) + 0.07 * np.sin(np.arctan2(gz, gx) * 120)
        return np.repeat((wirk * (0.92 + 0.10 * ruis(P, 50.0)))[:, None], 3, axis=1)

    hut_fertig("wollmuetze", h, [], wolle_gestrickt)
    # Bommel nutzt dieselbe Farbe: gleich mit zum Haupt-Teil
    HUETE["wollmuetze"] = [HUETE["wollmuetze"][0], fertig("wollmuetze_bommel_farbe", [bommel_o], wolle_gestrickt, 512, 0.95)]
    for g in list(HUETE["wollmuetze"][1].vertex_groups):
        HUETE["wollmuetze"][1].vertex_groups.remove(g)

    # ---- 7. Melone (Bowler)
    krempe = kugel(g2b(0, BR, 0.0), (0.268, 0.248, 0.020), "krempe", 36)
    krone = kette(BR + 0.01, BR + 0.27, lambda t: (0.236 * math.sqrt(max(0.0, 1.0 - t ** 2.4)) + 0.020, 0.216 * math.sqrt(max(0.0, 1.0 - t ** 2.4)) + 0.020), 13, 0.034)
    h = formen("melone", [krempe] + krone, 0.009)
    band = fest("melone_band", kugel(g2b(0, BR + 0.05, 0.0), (0.244, 0.224, 0.028), "band", 32), (0.08, 0.08, 0.08), 0.7)
    hut_fertig("melone", h, [band], lambda P: grau(P, 0.78))

    # ---- 8. Baseballcap (Schirm vorn)
    krone = kette(BR - 0.01, BR + 0.22, lambda t: (0.228 * math.sqrt(max(0.0, 1.0 - t ** 3.0)) + 0.012, 0.208 * math.sqrt(max(0.0, 1.0 - t ** 3.0)) + 0.012), 13, 0.036)
    schirm = kugel(Vector((0, 0, 0)), (0.120, 0.130, 0.022), "schirm", 40)
    schirm.rotation_euler = (math.radians(14), 0, 0)
    schirm.location = g2b(0, BR + 0.0, 0.250)
    h = formen("baseballcap", krone + [schirm], 0.005)
    knopf = fest("baseballcap_knopf", kugel(g2b(0, BR + 0.232, 0.0), (0.016, 0.016, 0.010), "knopf", 12), (0.12, 0.12, 0.12), 0.8)
    hut_fertig("baseballcap", h, [knopf], lambda P: grau(P, 0.85))

    # ---- 9. Fischerhut (Bucket Hat)
    krone = kette(BR - 0.005, BR + 0.20, lambda t: (0.228 - 0.030 * t, 0.208 - 0.028 * t), 11, 0.034)
    krempe = kugel(g2b(0, BR + 0.005, 0.0), (0.300, 0.280, 0.016), "krempe", 40)
    krempe2 = kugel(g2b(0, BR - 0.02, 0.0), (0.268, 0.250, 0.014), "krempe2", 40)
    h = formen("fischerhut", [krempe, krempe2] + krone, 0.008)
    hut_fertig("fischerhut", h, [], lambda P: grau(P, 0.88))

    # ---- 10. Cowboyhut (aufgebogene Krempe)
    krempe_t = []
    for k in range(48):
        w = k / 48 * math.tau
        sx, cz = math.sin(w), math.cos(w)
        hoch = 0.050 * (sx ** 2)          # seitlich nach oben gebogen
        krempe_t.append(kugel(g2b(0.300 * sx, BR + hoch, 0.275 * cz), (0.045, 0.045, 0.014), "krempe", 10))
    krone = kette(BR + 0.02, BR + 0.26, lambda t: (0.226 - 0.012 * t, 0.206 - 0.010 * t), 12, 0.036)
    delle = kugel(g2b(0, BR + 0.27, 0.0), (0.120, 0.130, 0.020), "delle", 20)
    h = formen("cowboyhut", krempe_t + krone + [delle], 0.008)
    band = fest("cowboyhut_band", kugel(g2b(0, BR + 0.06, 0.0), (0.232, 0.212, 0.030), "band", 32), (0.20, 0.12, 0.07), 0.8)
    hut_fertig("cowboyhut", h, [band], lambda P: grau(P, 0.84))

    # ---- 11. Stirnband
    band_k = kette(BR - 0.04, BR + 0.04, lambda t: (0.226, 0.206), 4, 0.024)
    h = formen("stirnband", band_k, 0.006, 4, 0.3)
    hut_fertig("stirnband", h, [], lambda P: grau(P, 0.90))

elif OUTFIT == "frisuren":
    # ================================================================ Creator-Assets: Frisuren (männlich)
    # Jede Frisur hängt starr am Kopfknochen, wird einzeln exportiert; "<name>_farbe" ist neutral grau
    # gemalt (Strähnen, Wirbel) und wird im Creator mit der Haarfarbe eingefärbt.
    HUETE = {}

    def hairline(c, vorn, seite, hinten):
        """Unterkante der Haube je Blickwinkel: vorn (Stirn), seitlich, hinten (Nacken)"""
        d = max(0.0001, math.hypot(c.x, c.y))
        cos_v = -c.y / d                      # +1 = Gesicht, -1 = Nacken
        if cos_v >= 0:
            return seite + (vorn - seite) * cos_v ** 1.5
        return seite + (hinten - seite) * (-cos_v) ** 1.2

    def haube(name, vorn=1.505, seite=1.405, hinten=1.345, offset=0.016, oben_weg=None, vorn_weg=None):
        """Kappe aus dem Kopf des Körpers (folgt dessen Form), aufgeblasen und an der Haarlinie beschnitten"""
        def weg(c):
            if c.z < 1.30:
                return True
            if oben_weg is not None and c.z > oben_weg:
                return True
            if vorn_weg is not None and (-c.y) > vorn_weg and c.z < 1.60:
                return True
            return c.z < hairline(c, vorn, seite, hinten)
        return schale_ganz(name, lambda c: offset, weg, 3)

    def stachel(pos, richtung, laenge, dicke, name="stachel"):
        """Kegelartiger Stachel/Strähne: pos in Godot-Koordinaten, richtung als Godot-Vektor"""
        k = kugel(Vector((0, 0, 0)), (dicke, dicke, laenge), name, 10)
        d = g2b(Vector(richtung)).normalized()
        k.rotation_euler = d.to_track_quat('Z', 'Y').to_euler()
        k.location = g2b(Vector(pos)) + d * laenge * 0.75
        return k

    def kugel_g(pos, radien, name="k", seg=16):
        """Kugel an Godot-Position pos, radien (x breit, y hoch, z tief) in Godot-Achsen"""
        return kugel(g2b(Vector(pos)), (radien[0], radien[2], radien[1]), name, seg)

    def formen_f(name, teile, voxel=0.008, glaetten=6, anteil=0.16):
        o = vereinen(teile, name)
        o.data.remesh_voxel_size = voxel
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.voxel_remesh()
        m = o.modifiers.new("Glatt", 'SMOOTH')
        m.factor = 0.6
        m.iterations = glaetten
        bpy.ops.object.modifier_apply(modifier="Glatt")
        d = o.modifiers.new("Dez", 'DECIMATE')
        d.ratio = anteil
        bpy.ops.object.modifier_apply(modifier="Dez")
        bpy.ops.object.shade_smooth()
        return o

    def haar_grau(P, laenge=1.0):
        """Neutrales, gesträhntes Haar in Grau (Haarfarbe wird in Godot aufgetragen)"""
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        wink = np.arctan2(gz, gx)
        strahl = 0.5 + 0.5 * np.sin(wink * 70 + gy * 90 + ruis(P, 25.0) * 6.0)
        fein = ruis(P, 140.0)
        v = 0.62 + 0.26 * strahl + 0.10 * fein
        # Spitzen und Oberseiten etwas heller, Wurzel am Kopf dunkler
        v = v * (0.84 + 0.22 * np.clip((gy - 1.35) / 0.35, 0, 1))
        return np.repeat(np.clip(v, 0, 1)[:, None], 3, axis=1)

    def frisur_fertig(name, o):
        f = fertig(name + "_farbe", [o], haar_grau, 1024, 0.9)
        for g in list(f.vertex_groups):
            f.vertex_groups.remove(g)
        HUETE[name] = [f]

    # ---- 1. Kurzhaar (Bürstenschnitt)
    frisur_fertig("kurzhaar", haube("kurzhaar", offset=0.012))

    # ---- 2. Seitenscheitel
    k = haube("scheitel_kappe", offset=0.022, vorn=1.515, seite=1.40, hinten=1.34)
    welle = [kugel_g((-0.075, 1.690, 0.075), (0.125, 0.052, 0.105), "welle", 22),
             kugel_g((-0.130, 1.655, 0.040), (0.085, 0.070, 0.115), "welle", 22),
             kugel_g((-0.040, 1.715, 0.020), (0.130, 0.040, 0.120), "welle", 22),
             kugel_g((0.095, 1.700, -0.015), (0.105, 0.035, 0.150), "welle", 22),
             kugel_g((-0.100, 1.585, 0.150), (0.100, 0.050, 0.050), "welle", 18)]
    frisur_fertig("seitenscheitel", formen_f("seitenscheitel", [k] + welle, 0.006, 8))

    # ---- 3. Tolle (Pompadour mit kurzen Seiten)
    k = haube("tolle_kappe", offset=0.012, vorn=1.50, seite=1.435, hinten=1.38)
    tolle = []
    for i in range(10):
        t = i / 9
        tolle.append(kugel_g((0.0, 1.650 + 0.095 * math.sin(t * 2.4), 0.060 + 0.200 * t), (0.150 - 0.040 * t, 0.060 + 0.020 * math.sin(t * math.pi), 0.075), "tolle", 20))
    frisur_fertig("tolle", formen_f("tolle", [k] + tolle, 0.006, 8))

    # ---- 4. Igel (Stachelhaare)
    k = haube("igel_kappe", offset=0.014, vorn=1.51)
    st = []
    import random
    rnd = random.Random(7)
    for i in range(70):
        w = rnd.uniform(0, math.tau)
        rr = math.sqrt(rnd.uniform(0.0, 1.0))
        x = 0.185 * rr * math.sin(w)
        z = 0.172 * rr * math.cos(w)
        if z > 0.07 and rr > 0.55:
            continue                                  # Stirn frei halten
        y = 1.692 - 0.13 * rr ** 2.2
        n = Vector((x * 1.3, 0.9, z * 1.3)).normalized()
        st.append(stachel((x, y - 0.012, z), (n.x, n.y, n.z), 0.075, 0.019))
    frisur_fertig("igel", formen_f("igel", [k] + st, 0.006, 4, 0.2))

    # ---- 5. Langhaar (schulterlang)
    k = haube("lang_kappe", offset=0.016, vorn=1.505, seite=1.31, hinten=1.28)
    lang = []
    for i in range(14):
        t = i / 13
        y = 1.46 - 0.40 * t
        lang.append(kugel_g((0.0, y, -0.205 - 0.025 * t), (0.200 - 0.015 * t, 0.040, 0.055), "lang", 18))
    for sx in (1, -1):
        for i in range(8):
            t = i / 7
            lang.append(kugel_g((sx * (0.207 + 0.01 * t), 1.47 - 0.22 * t, -0.04 - 0.07 * t), (0.034, 0.040, 0.15 - 0.02 * t), "lang_s", 14))
    frisur_fertig("langhaar", formen_f("langhaar", [k] + lang, 0.008))

    # ---- 6. Dutt (Männerdutt)
    k = haube("dutt_kappe", offset=0.014, vorn=1.51)
    dutt = [kugel_g((0.0, 1.745, -0.085), (0.075, 0.062, 0.075), "dutt", 22),
            kugel_g((0.0, 1.700, -0.060), (0.060, 0.040, 0.060), "dutt_fuss", 16)]
    frisur_fertig("dutt", formen_f("dutt", [k] + dutt, 0.006))

    # ---- 7. Irokese
    k = haube("iro_kappe", offset=0.009, vorn=1.51, seite=1.455, hinten=1.40)
    iro = []
    for i in range(11):
        t = i / 10
        z = 0.14 - 0.30 * t
        y = 1.690 - 0.02 * abs(t - 0.45) ** 1.5
        iro.append(stachel((0.0, y - 0.01, z), (0.0, 1.0, 0.18 - 0.5 * t), 0.115 - 0.02 * abs(t - 0.4), 0.026))
    frisur_fertig("irokese", formen_f("irokese", [k] + iro, 0.006, 4, 0.2))

    # ---- 8. Locken (Afro)
    cloud = [kugel_g((0.0, 1.595, -0.02), (0.250, 0.200, 0.235), "afro", 28)]
    rnd = random.Random(11)
    for i in range(130):
        # Punkte auf der oberen Halbkugel, nicht vor dem Gesicht
        u = rnd.uniform(0.0, 1.0)
        v = rnd.uniform(0.0, math.tau)
        hy = 0.10 + 0.90 * u
        rr = math.sqrt(1.0 - hy * hy)
        dx, dz = rr * math.sin(v), rr * math.cos(v)
        px, py, pz = 0.255 * dx, 1.595 + 0.215 * hy, -0.02 + 0.240 * dz
        if pz > 0.08 and py < 1.640:
            continue
        cloud.append(kugel_g((px, py, pz), (0.052, 0.052, 0.052), "locke", 10))
    frisur_fertig("locken", formen_f("locken", cloud, 0.010, 5, 0.12))

    # ---- 9. Topfschnitt (Pilzkopf)
    k = haube("topf_kappe", offset=0.020, vorn=1.535, seite=1.43, hinten=1.385)
    topf = []
    for i in range(24):
        w = (i / 24) * math.tau
        if math.cos(w) < -0.1:
            continue
        topf.append(kugel_g((0.212 * math.sin(w), 1.54, 0.20 * math.cos(w)), (0.030, 0.038, 0.030), "franse", 10))
    frisur_fertig("topfschnitt", formen_f("topfschnitt", [k] + topf, 0.007))

    # ---- 10. Haarkranz (Halbglatze)
    k = haube("kranz_kappe", offset=0.022, vorn=1.40, seite=1.375, hinten=1.320, oben_weg=1.575, vorn_weg=0.085)
    frisur_fertig("haarkranz", k)

# =================================================================== Haut malen (Körper und Hände)
HAUT_BASIS = np.array([0.66, 0.43, 0.32])


def haut_farbe(P):
    """Warmer Hautton mit sanftem Verlauf und leichter Fleckigkeit"""
    gy = P[:, 1]
    verlauf = 0.94 + 0.10 * np.clip((gy - 0.2) / 1.5, 0, 1)         # unten etwas dunkler
    n = 0.97 + 0.05 * ruis(P, 18.0) + 0.025 * ruis(P, 60.0)
    return HAUT_BASIS[None, :] * (verlauf * n)[:, None]


def haut_bemalen(o, groesse):
    img = bemalen(o, haut_farbe, groesse)
    o.data.materials.clear()
    for poly in o.data.polygons:
        poly.material_index = 0
    o.data.materials.append(stoff_material(o.name, img, 0.8))


haut_bemalen(koerper, 2048)
for hand_obj, _seite in haende:
    haut_bemalen(hand_obj, 1024)


# =================================================================== Weiche Schatten einbacken (Ambient Occlusion)
def ao_einbacken(staerke=0.55):
    haut_namen = ("Koerper", "HandLeft", "HandRight")
    """Cycles-AO auf jede bemalte Textur backen und in die Farben einrechnen — Falten, Ärmel,
    Kragen und Ansätze bekommen weiche Schatten, wie bei einem fertig gemalten Spielmodell."""
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    scene.render.bake.margin = 6
    scene.world = bpy.data.worlds.new("AOWelt")
    scene.world.light_settings.distance = 0.30
    for o, img, bild, groesse in _bemalt:
        ao_img = bpy.data.images.new(o.name + "_ao", groesse, groesse, alpha=False)
        mat = o.data.materials[0]
        knoten = mat.node_tree.nodes.new("ShaderNodeTexImage")
        knoten.image = ao_img
        mat.node_tree.nodes.active = knoten
        bpy.ops.object.select_all(action='DESELECT')
        o.select_set(True)
        bpy.context.view_layer.objects.active = o
        # Haut und Hände: AO ohne Kleidung backen, sonst stehen Schatten von Jacke und Hut im nackten
        # Körper (Creator: Glatze und nackte Beine hätten dann einen anderen Hautton)
        versteckt = []
        if o.name in haut_namen:
            for k in kleidung_objekte:
                if not k.hide_render:
                    k.hide_render = True
                    versteckt.append(k)
        bpy.ops.object.bake(type='AO', margin=6, use_clear=True)
        for k in versteckt:
            k.hide_render = False
        ao = np.array(ao_img.pixels[:], np.float32).reshape(groesse, groesse, 4)[:, :, 0]
        st = 0.22 if o.name in haut_namen else staerke
        fertig_bild = np.clip(bild * (1.0 - st + st * ao[:, :, None]), 0, 1)
        rgba = np.concatenate([fertig_bild, np.ones((groesse, groesse, 1), np.float32)], axis=2)
        img.pixels.foreach_set(rgba.ravel())
        img.pack()
        img.update()
        mat.node_tree.nodes.remove(knoten)
        bpy.data.images.remove(ao_img)
        try:
            img.filepath_raw = os.path.join(OUT, "tex_%s.png" % o.name)
            img.file_format = 'PNG'
            img.save()
        except Exception as e:
            print("Textur nicht gespeichert:", e)
        print("AO eingebacken:", o.name)
    scene.render.engine = 'BLENDER_WORKBENCH'


ao_einbacken()

print("Kleidung:", [(o.name, len(o.data.polygons), [round(x, 2) for x in o.dimensions]) for o in kleidung_objekte])
