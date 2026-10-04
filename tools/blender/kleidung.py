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

    # Schnurrbart: auf die Haut gelegt, am Kopf befestigt
    schnurr = []
    for i in range(21):
        t = (i - 10) / 10.0
        mx, mh = t * 0.075, 1.232 - 0.016 * abs(t) ** 1.5
        schnurr.append(kugel(Vector((mx, haut_y(mx, mh) + 0.006, mh)), (0.015, 0.010, 0.013 - 0.003 * abs(t)), "bart", 10))
    schnurrbart = vereinen(schnurr, "Schnurrbart")
    schnurrbart.data.materials.append(material("Schnurrbart", (0.22, 0.14, 0.09), 0.9))

    for o in (gams, schnurrbart):
        o.parent = arm_obj
        vg = o.vertex_groups.new(name="Head")
        vg.add([v.index for v in o.data.vertices], 1.0, 'REPLACE')
        mod = o.modifiers.new("Armature", 'ARMATURE')
        mod.object = arm_obj
        kleidung_objekte.append(o)

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
        bpy.ops.object.bake(type='AO', margin=6, use_clear=True)
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
