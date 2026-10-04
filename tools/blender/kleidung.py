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
    # Methode (Stylized-Hair-Workflow): jede Frisur besteht aus einzelnen, dicken, abgeflachten Strähnen
    # (Locks), die vom Wirbel aus über die Kopfform laufen, zur Spitze hin schmaler werden und sich
    # in zwei bis drei Lagen überlappen — so entstehen sichtbare Strähnenkanten mit Schatten dazwischen.
    # Darunter liegt eine dünne Kopfhaut-Kappe, die Lücken schließt. Kein Voxel-Remesh (der würde
    # alles zu einem Klumpen verschmelzen).
    # Jede Frisur hängt starr am Kopfknochen, wird einzeln exportiert; "<name>_farbe" ist neutral grau
    # (Wurzel dunkler, Spitzen heller) und wird in Godot mit der Haarfarbe eingefärbt.
    HUETE = {}
    HC = Vector((0.0, 1.52, 0.0))                    # Mitte der Kopfkuppel (Godot-Koordinaten)
    HR = Vector((0.205, 0.175, 0.19))                # Halbachsen der Kuppel
    YUNTEN = 0.30                                    # unterhalb des Äquators fällt das Haar gerade

    def oberflaeche(u, lift):
        """Punkt auf der Kopfoberfläche zur Richtung u (Einheitsvektor, Godot), um `lift` nach außen.
        Unter dem Äquator bleibt der Querschnitt gleich (der Kopf ist dort ein Zylinder)."""
        if u.y >= 0:
            p = HC + Vector((HR.x * u.x, HR.y * u.y, HR.z * u.z))
            n = Vector((u.x / HR.x, u.y / HR.y, u.z / HR.z)).normalized()
        else:
            h = max(1e-4, math.hypot(u.x, u.z))
            p = HC + Vector((HR.x * u.x / h, YUNTEN * u.y, HR.z * u.z / h))
            n = Vector((u.x / (HR.x * h), 0.0, u.z / (HR.z * h))).normalized()
        return p + n * lift, n

    def rahmen(pol, vorn=Vector((0, 0, 1))):
        a = Vector(pol).normalized()
        e1 = (vorn - a * vorn.dot(a))
        if e1.length < 1e-4:
            e1 = Vector((1, 0, 0)) - a * a.x
        e1.normalize()
        e2 = a.cross(e1).normalized()
        return a, e1, e2

    def roehre_bm(bm, pfad, radien, normalen, flach=0.55, seg=8):
        """Abgeflachte Röhre (breit entlang der Kopfoberfläche, dünn nach außen) mit Spitze am Ende"""
        ringe = []
        n_p = len(pfad)
        for i, (p, r, nrm) in enumerate(zip(pfad, radien, normalen)):
            t = (pfad[min(i + 1, n_p - 1)] - pfad[max(i - 1, 0)]).normalized()
            b = t.cross(nrm)
            if b.length < 1e-5:
                b = t.cross(Vector((0, 1, 0)))
            b.normalize()
            nn = b.cross(t).normalized()
            ring = []
            for k in range(seg):
                w = k / seg * math.tau
                q = p + b * (math.cos(w) * r) + nn * (math.sin(w) * r * flach)
                ring.append(bm.verts.new(g2b(q)))
            ringe.append(ring)
        for i in range(n_p - 1):
            for k in range(seg):
                bm.faces.new([ringe[i][k], ringe[i][(k + 1) % seg], ringe[i + 1][(k + 1) % seg], ringe[i + 1][k]])
        spitze = bm.verts.new(g2b(pfad[-1] + (pfad[-1] - pfad[-2]).normalized() * radien[-1] * 1.4))
        for k in range(seg):
            bm.faces.new([ringe[-1][k], ringe[-1][(k + 1) % seg], spitze])
        wurzel = bm.verts.new(g2b(pfad[0] - normalen[0] * radien[0] * 0.4))
        for k in range(seg):
            bm.faces.new([ringe[0][(k + 1) % seg], ringe[0][k], wurzel])

    def strähne(bm, pol, vorn, psi, th0, th1, n=11, lift=(0.010, 0.014), bauch=0.0, breit=(0.030, 0.012),
                flach=0.55, haengen=0.0, schwung=0.0):
        """Eine Strähne: Meridian der Kopfkuppel um den Pol `pol` im Winkel psi, von th0 bis th1;
        bauch = zusätzliches Abheben in der Mitte (Volumen), haengen = gerade Verlängerung nach unten,
        schwung = seitliches Ausweichen (Wellen)"""
        a, e1, e2 = rahmen(pol, vorn)
        pfad, radien, normalen = [], [], []
        for k in range(n + 1):
            t = k / n
            th = th0 + (th1 - th0) * t
            ps = psi + schwung * math.sin(t * math.pi * 1.5)
            u = a * math.cos(th) + (e1 * math.cos(ps) + e2 * math.sin(ps)) * math.sin(th)
            l = lift[0] + (lift[1] - lift[0]) * t + bauch * math.sin(t * math.pi)
            p, nrm = oberflaeche(u.normalized(), l)
            pfad.append(p)
            normalen.append(nrm)
            radien.append(breit[0] + (breit[1] - breit[0]) * t ** 0.9)
        if haengen > 0.0:
            m = 5
            for k in range(1, m + 1):
                t = k / m
                p = pfad[n] + Vector((0, -haengen * t, 0)) + normalen[n] * (0.004 * t)
                pfad.append(p)
                normalen.append(normalen[n])
                radien.append(breit[1] * (1.0 - 0.45 * t))
        roehre_bm(bm, pfad, radien, normalen, flach)

    def haarlinie(phi, vorn=1.62, seite=1.96, hinten=2.20):
        """Endwinkel th (vom Scheitel aus) je Blickrichtung phi (0 = Gesicht): bestimmt die Haarlinie"""
        c = math.cos(phi)
        return seite + (vorn - seite) * c ** 1.5 if c >= 0 else seite + (hinten - seite) * (-c) ** 1.2

    def haube(name, vorn=1.505, seite=1.405, hinten=1.345, offset=0.008, oben_weg=None, vorn_weg=None):
        """Dünne Kopfhaut-Kappe aus dem Kopf des Körpers, an der Haarlinie beschnitten"""
        def weg(c):
            if c.z < 1.30:
                return True
            if oben_weg is not None and c.z > oben_weg:
                return True
            if vorn_weg is not None and (-c.y) > vorn_weg and c.z < 1.60:
                return True
            d = max(0.0001, math.hypot(c.x, c.y))
            cv = -c.y / d
            h = seite + (vorn - seite) * cv ** 1.5 if cv >= 0 else seite + (hinten - seite) * (-cv) ** 1.2
            return c.z < h
        return schale_ganz(name, lambda c: offset, weg, 3)

    def haar_grau(P):
        """Neutrales Haar: Wurzel dunkler, Spitzen/Oberseite heller, feine Strähnenlinien"""
        gx, gy, gz = P[:, 0], P[:, 1], P[:, 2]
        wink = np.arctan2(gz, gx)
        fein = ruis(P, 120.0)
        strahl = 0.5 + 0.5 * np.sin(wink * 55 + gy * 140 + ruis(P, 30.0) * 5.0)
        # Abstand von der Kopfachse (1 = Kopfoberfläche): je weiter außen, desto heller
        rad = np.sqrt((gx / 0.205) ** 2 + (gz / 0.19) ** 2)
        hoch = np.clip((gy - 1.40) / 0.30, 0, 1)
        v = 0.50 + 0.22 * strahl + 0.08 * fein + 0.20 * np.clip((rad - 1.0) * 3.0 + hoch * 0.5, 0, 1)
        return np.repeat(np.clip(v, 0, 1)[:, None], 3, axis=1)

    def frisur_fertig(name, bm, kappe=None):
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(name, me)
        scene.collection.objects.link(o)
        teile = [o] + ([kappe] if kappe is not None else [])
        if len(teile) > 1:
            o = vereinen(teile, name)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth()
        f = fertig(name + "_farbe", [o], haar_grau, 1024, 0.9)
        for g in list(f.vertex_groups):
            f.vertex_groups.remove(g)
        HUETE[name] = [f]

    import random
    OBEN = Vector((0, 1, 0))
    VORN = Vector((0, 0, 1))

    # ---- 1. Kurzhaar: zwei überlappende Lagen kurzer, dicker Strähnen vom Wirbel zur Haarlinie
    bm = bmesh.new()
    for ebene, (anz, versatz, th0, lift, breit) in enumerate([(26, 0.0, 0.10, (0.008, 0.010), (0.034, 0.020)),
                                                              (26, 0.5, 0.45, (0.016, 0.018), (0.030, 0.016))]):
        for i in range(anz):
            phi = (i + versatz) / anz * math.tau
            strähne(bm, OBEN, VORN, phi, th0, haarlinie(phi) - 0.04 * ebene, 9, lift, 0.004, breit, 0.55)
    frisur_fertig("kurzhaar", bm, haube("kurzhaar_kappe", offset=0.007))

    # ---- 2. Seitenscheitel: Strähnen laufen von einem Scheitel rechts über den Kopf nach links
    bm = bmesh.new()
    pol = Vector((1.0, 0.05, 0.0))
    for ebene, (anz, versatz, th0, lift, breit, schw) in enumerate([(15, 0.0, 0.30, (0.012, 0.012), (0.030, 0.016), 0.00),
                                                                    (14, 0.5, 0.55, (0.022, 0.016), (0.034, 0.018), 0.05)]):
        for i in range(anz):
            psi = -0.62 - 1.75 * (i + versatz) / anz           # von vorn-oben über die Kuppel bis nach hinten-oben
            th1 = 2.00 - 0.30 * abs(psi + 1.5) / 0.9
            strähne(bm, pol, VORN, psi, th0, th1, 12, lift, 0.012 if ebene else 0.006, breit, 0.55, 0.0, schw)
    # Sauber abgesetzter Scheitel rechts: ein paar kurze Strähnen davor
    for i in range(8):
        strähne(bm, OBEN, VORN, -0.9 + 0.26 * i, 0.12, 0.70, 6, (0.010, 0.012), 0.0, (0.026, 0.016), 0.5)
    frisur_fertig("seitenscheitel", bm, haube("scheitel_kappe", offset=0.007, vorn=1.515))

    # ---- 3. Tolle: Strähnen heben sich an der Stirn hoch und laufen nach hinten über die Kuppel
    bm = bmesh.new()
    pol = Vector((0.0, 0.10, 1.0))
    for ebene, (anz, versatz, th0, lift, breit) in enumerate([(13, 0.0, 0.95, (0.030, 0.014), (0.036, 0.020)),
                                                              (12, 0.5, 1.10, (0.040, 0.016), (0.036, 0.018))]):
        for i in range(anz):
            psi = -1.05 + 2.10 * (i + versatz) / anz            # ψ = 0 zeigt nach oben, ± zu den Seiten
            th1 = 2.25 - 0.55 * abs(psi) / 1.05
            strähne(bm, pol, OBEN, psi, th0 + 0.25 * abs(psi) / 1.05, th1, 12, lift, 0.060 if ebene == 0 else 0.045, breit, 0.55)
    # Seiten kurz
    for i in range(18):
        phi = (i / 18) * math.tau
        if abs(math.cos(phi)) > 0.80:
            continue
        strähne(bm, OBEN, VORN, phi, 0.9, haarlinie(phi, 1.62, 1.90, 2.12), 6, (0.008, 0.010), 0.0, (0.030, 0.020), 0.5)
    frisur_fertig("tolle", bm, haube("tolle_kappe", offset=0.007, vorn=1.50, seite=1.435, hinten=1.38))

    # ---- 4. Igel: kurze, spitze, dicke Stacheln vom Wirbel nach außen
    bm = bmesh.new()
    rnd = random.Random(5)
    for ebene, (anz, th_lo, th_hi, ln) in enumerate([(32, 0.15, 1.00, 0.085), (30, 0.95, 1.55, 0.070)]):
        for i in range(anz):
            phi = rnd.uniform(0, math.tau)
            th = rnd.uniform(th_lo, th_hi)
            if abs(phi) < 0.8 and th > 1.2:
                continue
            u = OBEN * math.cos(th) + (VORN * math.cos(phi) + Vector((1, 0, 0)) * math.sin(phi)) * math.sin(th)
            p, nrm = oberflaeche(u.normalized(), 0.004)
            richt = (nrm * 0.75 + OBEN * 0.7).normalized()
            pfad = [p + richt * ln * (k / 4) for k in range(5)]
            roehre_bm(bm, pfad, [0.026 - 0.018 * (k / 4) ** 1.4 for k in range(5)], [nrm] * 5, 0.9, 7)
    frisur_fertig("igel", bm, haube("igel_kappe", offset=0.007, vorn=1.51))

    # ---- 5. Langhaar: lange Strähnen laufen am Hinterkopf und an den Seiten bis auf die Schultern
    bm = bmesh.new()
    for ebene, (anz, versatz, th0, lift, breit, ende) in enumerate([(30, 0.0, 0.10, (0.012, 0.016), (0.036, 0.024), 0.40),
                                                                    (30, 0.5, 0.60, (0.022, 0.024), (0.036, 0.022), 0.33)]):
        for i in range(anz):
            phi = (i + versatz) / anz * math.tau
            c = math.cos(phi)
            if c > 0.84:
                # Stirnbereich: nur bis zur Haarlinie
                strähne(bm, OBEN, VORN, phi, th0, haarlinie(phi), 9, (lift[0], lift[0] + 0.004), 0.004, (breit[0], breit[1] * 0.7), 0.55)
            else:
                laenge = ende * (0.55 + 0.45 * (1.0 - c) / 2.0 * 1.2) if c < 0.0 else ende * 0.55
                strähne(bm, OBEN, VORN, phi, th0, haarlinie(phi, 1.62, 1.90, 1.92), 9, lift, 0.006, breit, 0.55, laenge,
                        0.04 * math.sin(phi * 3))
    frisur_fertig("langhaar", bm, haube("lang_kappe", offset=0.007, vorn=1.505, seite=1.31, hinten=1.28))

    # ---- 6. Dutt: Strähnen laufen von der Haarlinie nach oben-hinten zu einem Haarknoten
    bm = bmesh.new()
    pol = Vector((0.0, 0.50, -0.60))
    for ebene, (anz, versatz, lift, breit) in enumerate([(26, 0.0, (0.010, 0.020), (0.032, 0.018)),
                                                         (26, 0.5, (0.018, 0.026), (0.030, 0.014))]):
        for i in range(anz):
            psi = (i + versatz) / anz * math.tau
            # Start an der Haarlinie (großer Winkel), Ende am Knoten (th klein)
            th_start = 1.40 + 0.25 * math.cos(psi)
            strähne(bm, pol, VORN, psi, th_start, 0.10, 11, lift, 0.0, breit, 0.55)
    # Knoten: dicker Wulst aus zwei Ringen und Kuppe
    for r_, hh in ((0.074, 1.755), (0.060, 1.790)):
        pfad = []
        for k in range(14):
            w = k / 13 * math.tau
            pfad.append(Vector((0.052 * math.cos(w), hh, -0.085 + 0.052 * math.sin(w))))
        roehre_bm(bm, pfad + [pfad[0] + Vector((0, 0.002, 0))], [r_ * 0.62] * 14 + [r_ * 0.55], [OBEN] * 15, 0.95, 10)
    bm.verts.ensure_lookup_table()
    frisur_fertig("dutt", bm, haube("dutt_kappe", offset=0.007, vorn=1.51, seite=1.40, hinten=1.36))

    # ---- 7. Irokese: Kamm aus hohen, schmalen Strähnen, Seiten rasiert
    bm = bmesh.new()
    for i in range(15):
        t = i / 14
        z = 0.15 - 0.34 * t
        y0 = 1.69 - 0.035 * abs(t - 0.45) ** 1.3
        hoehe = 0.16 - 0.04 * abs(t - 0.35)
        pfad = [Vector((0.0, y0 + hoehe * (k / 6), z - 0.07 * (k / 6) ** 1.6)) for k in range(7)]
        roehre_bm(bm, pfad, [0.060 - 0.050 * (k / 6) ** 1.2 for k in range(7)], [Vector((1, 0, 0))] * 7, 0.34, 8)
    frisur_fertig("irokese", bm)

    # ---- 8. Locken: dichte Kuppel aus vielen dicken, runden Locken
    bm = bmesh.new()
    rnd = random.Random(11)
    zentren = []
    for lage, (anz, rad, lk) in enumerate([(110, 1.0, 0.062), (90, 1.16, 0.058), (30, 1.28, 0.056)]):
        for i in range(anz):
            u1 = rnd.uniform(0.0, 1.0)
            ph = rnd.uniform(0.0, math.tau)
            hy = 0.05 + 0.95 * (u1 ** 0.55)
            rr = math.sqrt(1.0 - hy * hy)
            u = Vector((rr * math.sin(ph), hy, rr * math.cos(ph)))
            if u.z > 0.50 and u.y < 0.55:
                continue                                   # Stirn frei
            zentren.append((HC + Vector((0.250 * u.x, 0.215 * u.y, 0.245 * u.z)) * rad + Vector((0, 0.02, -0.01)), lk))
    for (c, r_) in zentren:
        ico = bmesh.ops.create_icosphere(bm, subdivisions=2, radius=r_)
        for v in ico["verts"]:
            v.co = v.co + g2b(c)
    frisur_fertig("locken", bm, haube("locken_kappe", offset=0.012, vorn=1.52, seite=1.42, hinten=1.36))

    # ---- 9. Topfschnitt: gerade, dicke Strähnen fallen gleichmäßig bis zu einer Linie rund um den Kopf
    bm = bmesh.new()
    for ebene, (anz, versatz, th0, lift, breit) in enumerate([(30, 0.0, 0.10, (0.012, 0.018), (0.034, 0.028)),
                                                              (30, 0.5, 0.50, (0.022, 0.026), (0.034, 0.026))]):
        for i in range(anz):
            phi = (i + versatz) / anz * math.tau
            c = math.cos(phi)
            ende = 1.50 + (0.20 if c > 0 else 0.0) * 0   # Fransen enden überall auf gleicher Höhe (unten gerade)
            ziel_y = 1.545 if c > 0.5 else (1.455 if c > -0.5 else 1.43)
            ziel_th = math.acos(max(-0.99, min(0.99, (ziel_y - 1.52) / (0.175 if ziel_y >= 1.52 else YUNTEN))))
            strähne(bm, OBEN, VORN, phi, th0, min(ziel_th, 2.1), 9, lift, 0.004, breit, 0.55)
    frisur_fertig("topfschnitt", bm, haube("topf_kappe", offset=0.008, vorn=1.535, seite=1.43, hinten=1.385))

    # ---- 10. Haarkranz: Strähnen nur an Seiten und Hinterkopf, oben kahl
    bm = bmesh.new()
    for ebene, (anz, versatz, lift, breit) in enumerate([(40, 0.0, (0.012, 0.016), (0.030, 0.020)),
                                                         (40, 0.5, (0.020, 0.022), (0.028, 0.018))]):
        for i in range(anz):
            phi = (i + versatz) / anz * math.tau
            c = math.cos(phi)
            if c > 0.30:
                continue
            strähne(bm, OBEN, VORN, phi, 1.00 - 0.10 * ebene, haarlinie(phi, 1.9, 2.05, 2.35), 7, lift, 0.004, breit, 0.55, 0.0, 0.05 * math.sin(phi * 5))
    frisur_fertig("haarkranz", bm, haube("kranz_kappe", offset=0.007, vorn=1.40, seite=1.40, hinten=1.34, oben_weg=1.545, vorn_weg=0.09))

    # ---- Frisuren nach Quaternius-Vorlage (CC0, Universal Base Characters): die Haarformen der fertigen
    # Frisuren werden auf unseren Kopf skaliert, an die Kopfoberfläche gedrückt (Haaransatz sitzt an der Haut),
    # verdickt und zu einer glatten, kompakten Form verschmolzen — passend zum Stil des Körpers.
    if os.environ.get("QUATERNIUS") == "1":
        from mathutils.bvhtree import BVHTree
        HUETE = {}
        # Quelle: Quaternius "Universal Base Characters" (Standard, CC0), Ordner Hairstyles/Origin at 0/glTF (Godot),
        # dorthin kopiert: build/fremd/haare_gltf (nicht in Git). Aufruf: QUATERNIUS=1 EXPORT_ORDNER=frisuren_q OUTFIT=frisuren
        Q_ORDNER = os.path.join(ROOT, "build", "fremd", "haare_gltf")
        dg = bpy.context.evaluated_depsgraph_get()
        bvh = BVHTree.FromObject(koerper, dg)

        def glatt_schritt(t, a, b, x):
            u = max(0.0, min(1.0, (x - a) / (b - a)))
            return u * u * (3 - 2 * u)

        def q_haar(name, datei, skala, versatz, vorskal=1.0, dicke=0.012, voxel=0.0055, anhaften=0.014):
            vorher = set(bpy.data.objects)
            bpy.ops.import_scene.gltf(filepath=os.path.join(Q_ORDNER, datei))
            neu = [o for o in bpy.data.objects if o not in vorher]
            meshes = [o for o in neu if o.type == 'MESH']
            for o in neu:
                if o.type != 'MESH':
                    bpy.data.objects.remove(o, do_unlink=True)
            for o in meshes:
                o.parent = None
                bpy.context.view_layer.objects.active = o
                o.select_set(True)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
            ob = vereinen(meshes, name) if len(meshes) > 1 else meshes[0]
            ob.name = name
            ob.modifiers.clear()
            ob.vertex_groups.clear()
            roh = [Vector((v.co.x * vorskal, v.co.z * vorskal, -v.co.y * vorskal)) for v in ob.data.vertices]
            if versatz == "auto":
                # Mitte in x/z auf den Kopf, Oberkante auf die Kopfkuppel
                mn = Vector((min(p.x for p in roh), min(p.y for p in roh), min(p.z for p in roh)))
                mx = Vector((max(p.x for p in roh), max(p.y for p in roh), max(p.z for p in roh)))
                versatz = (-(mn.x + mx.x) / 2 * skala[0], 1.70 - mx.y * skala[1], -(mn.z + mx.z) / 2 * skala[2] + 0.0)
            for v, g in zip(ob.data.vertices, roh):
                gp = Vector((g.x * skala[0] + versatz[0], g.y * skala[1] + versatz[1], g.z * skala[2] + versatz[2]))
                v.co = g2b(gp)
            # an die Kopfoberfläche drücken: nahe Punkte setzen auf die Haut (Abstand `anhaften`)
            for v in ob.data.vertices:
                ort, nrm, _i, dist = bvh.find_nearest(v.co)
                if ort is None:
                    continue
                innen = (v.co - ort).dot(nrm) < 0
                t = 1.0 if innen else glatt_schritt(0, 0.075, 0.015, dist)
                ziel = ort + nrm * anhaften
                v.co = v.co.lerp(ziel, t)
            bm_ = bmesh.new()
            bm_.from_mesh(ob.data)
            bmesh.ops.recalc_face_normals(bm_, faces=bm_.faces)
            bm_.to_mesh(ob.data)
            bm_.free()
            bpy.context.view_layer.objects.active = ob
            so = ob.modifiers.new("Dicke", 'SOLIDIFY')
            so.thickness = dicke
            so.offset = 1.0
            bpy.ops.object.modifier_apply(modifier="Dicke")
            ob.data.remesh_voxel_size = voxel
            bpy.ops.object.voxel_remesh()
            sm = ob.modifiers.new("Glatt", 'SMOOTH')
            sm.factor = 0.5
            sm.iterations = 5
            bpy.ops.object.modifier_apply(modifier="Glatt")
            dz = ob.modifiers.new("Dez", 'DECIMATE')
            dz.ratio = 0.2
            bpy.ops.object.modifier_apply(modifier="Dez")
            bpy.ops.object.shade_smooth()
            f = fertig(name + "_farbe", [ob], haar_grau, 1024, 0.9)
            for g in list(f.vertex_groups):
                f.vertex_groups.remove(g)
            HUETE[name] = [f]

        S = (2.6, 1.55, 2.3)
        V = (0.0, 1.70 - 1.83 * S[1], 0.045)
        q_haar("q_kurzhaar", "Hair_Buzzed.gltf", S, V)
        q_haar("q_seitenscheitel", "Hair_SimpleParted.gltf", S, V)
        q_haar("q_langhaar", "Hair_Long.gltf", S, V)
        q_haar("q_dutt", "Hair_Buns.gltf", S, "auto", 0.01)
        q_haar("q_bart", "Hair_Beard.gltf", (2.4, 1.2, 1.9), (0.0, 1.27 - 1.689 * 1.2, 0.03), 1.0, 0.012, 0.0055, 0.016)

elif OUTFIT == "brillen":
    # ================================================================ Creator-Assets: Brillen
    # Gestell = "<name>_farbe" (neutral grau, wird im Creator eingefärbt), Gläser = "<name>_glas"
    # (Festfarbe, halbdurchsichtig). Alles sitzt starr am Kopfknochen, vor den großen Augen.
    HUETE = {}
    AY = haut_y(0.093, 1.30)                 # Hautoberfläche vorn bei den Augen (Blender-y, negativ)
    EBENE = AY - 0.056                        # Brillenebene vor Augäpfeln und Pupillen
    AUGE_X = 0.093
    AUGE_Z = 1.305

    def bm_neu():
        return bmesh.new()

    def kurve_roehre(bm, pts, r, seg=8, rs=None):
        """Röhre entlang der Punkte pts (Blender-Koordinaten), Radius r (oder Liste rs je Punkt)"""
        ringe = []
        n = len(pts)
        for i, p in enumerate(pts):
            t = (pts[min(i + 1, n - 1)] - pts[max(i - 1, 0)]).normalized()
            h = Vector((0, 0, 1)) if abs(t.z) < 0.9 else Vector((1, 0, 0))
            a = t.cross(h).normalized()
            b = t.cross(a).normalized()
            rr = rs[i] if rs else r
            ring = [bm.verts.new(p + a * (math.cos(k / seg * math.tau) * rr) + b * (math.sin(k / seg * math.tau) * rr)) for k in range(seg)]
            ringe.append(ring)
        for i in range(n - 1):
            for k in range(seg):
                bm.faces.new([ringe[i][k], ringe[i][(k + 1) % seg], ringe[i + 1][(k + 1) % seg], ringe[i + 1][k]])
        for ring in (ringe[0], ringe[-1]):
            bm.faces.new(ring if ring is ringe[0] else list(reversed(ring)))

    def form_pts(form, cx, cz, rx, rz, n=44):
        """Umriss einer Glasform als Liste von (x, z) im Uhrzeigersinn — Godot-x = Blender-x, z = Höhe"""
        out = []
        for i in range(n):
            w = i / n * math.tau
            c, s_ = math.cos(w), math.sin(w)
            if form == "rund":
                x, z = c, s_
            elif form == "eckig":
                e = 6.0
                x, z = math.copysign(abs(c) ** (2 / e), c), math.copysign(abs(s_) ** (2 / e), s_)
            elif form == "oval":
                x, z = c, s_ * 0.80
            elif form == "pilot":              # Tropfen: oben breit, unten schmal und nach innen gezogen
                x = c * (1.0 - 0.18 * (1 - s_) / 2) * (1.0 if s_ > 0 else (1.0 - 0.25 * -s_))
                z = s_ * 0.92 - 0.08 * (1 if s_ < 0 else 0) * 0
                x = x * 1.0
            elif form == "wayfarer":           # oben breiter, kräftig trapezförmig
                e = 3.2
                x, z = math.copysign(abs(c) ** (2 / e), c), math.copysign(abs(s_) ** (2 / e), s_) * 0.82
                x *= 1.0 + 0.14 * z
            elif form == "halb":               # Lesebrille: flach, niedrig
                e = 3.0
                x, z = math.copysign(abs(c) ** (2 / e), c), math.copysign(abs(s_) ** (2 / e), s_) * 0.52
            elif form == "herz":
                t = w
                x = 16 * math.sin(t) ** 3 / 17.0
                z = (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17.0 + 0.10
            elif form == "stern":
                rad = 0.62 + 0.38 * (0.5 + 0.5 * math.cos(5 * w))
                x, z = rad * c, rad * s_
            else:
                x, z = c, s_
            out.append((cx + rx * x, cz + rz * z))
        return out

    def glas_rahmen(bm, pts, dicke, tiefe, y):
        """Rahmen entlang des Umrisses: Querschnitt dicke (in der Ebene) x tiefe (nach vorn/hinten)"""
        n = len(pts)
        ringe = []
        for i, (x, z) in enumerate(pts):
            x0, z0 = pts[(i - 1) % n]
            x1, z1 = pts[(i + 1) % n]
            t = Vector((x1 - x0, 0, z1 - z0)).normalized()
            nrm = Vector((t.z, 0, -t.x))             # nach außen
            ring = []
            for k in range(8):
                w = k / 8 * math.tau
                p = Vector((x, y, z)) + nrm * (math.cos(w) * dicke) + Vector((0, 1, 0)) * (math.sin(w) * tiefe)
                ring.append(bm.verts.new(p))
            ringe.append(ring)
        for i in range(n):
            j = (i + 1) % n
            for k in range(8):
                bm.faces.new([ringe[i][k], ringe[i][(k + 1) % 8], ringe[j][(k + 1) % 8], ringe[j][k]])

    def glas_scheibe(bm, pts, y, dicke=0.003):
        v1 = [bm.verts.new(Vector((x, y - dicke, z))) for x, z in pts]
        v2 = [bm.verts.new(Vector((x, y + dicke, z))) for x, z in pts]
        bm.faces.new(v1)
        bm.faces.new(list(reversed(v2)))
        n = len(pts)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new([v1[i], v1[j], v2[j], v2[i]])

    def objekt(bm, name):
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        o = bpy.data.objects.new(name, me)
        scene.collection.objects.link(o)
        bpy.context.view_layer.objects.active = o
        bpy.ops.object.shade_smooth()
        return o

    def kopf_bogen(y0, hoehe, hinten=0.07, breite=0.222, tiefe=0.205, ab=-0.20):
        """Bügelverlauf: von der Gestellecke (vorn) an der Kopfseite entlang nach hinten, (links, rechts)"""
        links = []
        for t in np.linspace(0.0, 1.0, 14):
            y = y0 + (hinten - y0) * t
            x = breite * (1.0 - 0.55 * (1 - t) ** 3) if t > 0 else breite
            links.append(Vector((x, y, hoehe + ab * t * 0.0)))
        return links

    def brille(name, form, rx, rz, rahmen_d, rahmen_t, glas_farbe=None, bruecke_z=0.02, buegel_d=0.0065, dick_buegel=1.0,
               nur_rechts=False, extras=None, gx=AUGE_X, hoehe=AUGE_Z):
        bm = bm_neu()
        bg = bm_neu()
        seiten = [1.0] if nur_rechts else [-1.0, 1.0]
        for sx in seiten:
            pts = form_pts(form, sx * gx, hoehe, rx, rz)
            glas_rahmen(bm, pts, rahmen_d, rahmen_t, EBENE)
            if glas_farbe is not None:
                glas_scheibe(bg, pts, EBENE)
            # Bügel
            ax = sx * (gx + rx)
            pfad = [Vector((ax, EBENE, hoehe + rz * 0.35)), Vector((sx * 0.222, EBENE + 0.02, hoehe + rz * 0.30))]
            for t in np.linspace(0.12, 1.0, 10):
                pfad.append(Vector((sx * 0.224, EBENE + 0.03 + (0.30 - 0.03) * t, hoehe + rz * 0.30)))
            if not nur_rechts or True:
                kurve_roehre(bm, pfad, buegel_d * dick_buegel, 6)
        if not nur_rechts:
            # Nasenbrücke
            y_br = EBENE
            p0 = Vector((-gx + rx * 0.98, y_br, hoehe + rz * bruecke_z / 0.02 * 0.30))
            p1 = Vector((gx - rx * 0.98, y_br, hoehe + rz * bruecke_z / 0.02 * 0.30))
            mitte = Vector((0, y_br, hoehe + rz * 0.42))
            kurve_roehre(bm, [p0, p0.lerp(mitte, 0.5), mitte, p1.lerp(mitte, 0.5), p1], rahmen_d * 0.8, 6)
        if extras:
            extras(bm, bg)
        o = objekt(bm, name + "_farbe_roh")
        teile_out = [o]
        gl = None
        if glas_farbe is not None:
            gl = objekt(bg, name + "_glas")
            gl.data.materials.append(glas_mat(name + "_glas", glas_farbe))
        return o, gl

    def glas_mat(name, farbe):
        m = bpy.data.materials.new(name)
        m.use_nodes = True
        b = m.node_tree.nodes["Principled BSDF"]
        lin = srgb(farbe[:3])
        b.inputs["Base Color"].default_value = (*lin, 1.0)
        b.inputs["Alpha"].default_value = farbe[3]
        b.inputs["Roughness"].default_value = 0.15
        m.diffuse_color = (*lin, farbe[3])
        try:
            m.surface_render_method = 'BLENDED'
        except Exception:
            m.blend_method = 'BLEND'
        return m

    def gestell_grau(P):
        n1 = ruis(P, 60.0)
        v = 0.82 + 0.08 * n1
        return np.repeat(v[:, None], 3, axis=1)

    def brille_fertig(name, o, gl):
        f = fertig(name + "_farbe", [o], gestell_grau, 512, 0.5)
        for g in list(f.vertex_groups):
            f.vertex_groups.remove(g)
        teile = [f]
        if gl is not None:
            gl.parent = None
            teile.append(gl)
        HUETE[name] = teile

    # ---- 1. Rund (dünner Drahtrahmen)
    o, g = brille("rund", "rund", 0.080, 0.080, 0.0050, 0.0055, None)
    brille_fertig("rund", o, g)
    # ---- 2. Eckig (dickes Gestell)
    o, g = brille("eckig", "eckig", 0.084, 0.068, 0.0125, 0.012, None, buegel_d=0.010)
    brille_fertig("eckig", o, g)
    # ---- 3. Pilotenbrille
    o, g = brille("pilot", "pilot", 0.088, 0.086, 0.0050, 0.0055, (0.28, 0.20, 0.08, 0.62))
    brille_fertig("pilot", o, g)
    # ---- 4. Wayfarer (Sonnenbrille)
    o, g = brille("wayfarer", "wayfarer", 0.086, 0.070, 0.0150, 0.0135, (0.06, 0.06, 0.08, 0.82), buegel_d=0.0115)
    brille_fertig("wayfarer", o, g)
    # ---- 5. Lesebrille (Halbrand)
    o, g = brille("lesebrille", "halb", 0.080, 0.080, 0.0060, 0.0060, None)
    brille_fertig("lesebrille", o, g)
    # ---- 6. Opa-Brille (kleine Ovale)
    o, g = brille("oval", "oval", 0.076, 0.082, 0.0075, 0.0075, None, hoehe=AUGE_Z - 0.004)
    brille_fertig("oval", o, g)

    # ---- 7. Sportbrille (Wrap: ein durchgehendes Glas, schmale Ränder)
    def sport_extras(bm, bg):
        pts = []
        for i in range(60):
            w = i / 60 * math.tau
            c, s_ = math.cos(w), math.sin(w)
            e = 3.4
            x = math.copysign(abs(c) ** (2 / e), c) * 0.200
            z = math.copysign(abs(s_) ** (2 / e), s_) * 0.062 + AUGE_Z + 0.004
            pts.append((x, z))
        glas_rahmen(bm, pts, 0.0070, 0.0085, EBENE - 0.004)
        glas_scheibe(bg, pts, EBENE - 0.004)
        # Seitenschutz: Bügel greift nach hinten
        for sx in (-1.0, 1.0):
            kurve_roehre(bm, [Vector((sx * 0.200, EBENE - 0.004, AUGE_Z + 0.015)), Vector((sx * 0.222, EBENE + 0.03, AUGE_Z + 0.015)),
                              Vector((sx * 0.224, EBENE + 0.20, AUGE_Z + 0.015))], 0.0085, 6)
    bmx, bgx = bm_neu(), bm_neu()
    sport_extras(bmx, bgx)
    o = objekt(bmx, "sport_farbe_roh")
    g = objekt(bgx, "sport_glas")
    g.data.materials.append(glas_mat("sport_glas", (0.12, 0.28, 0.55, 0.72)))
    brille_fertig("sportbrille", o, g)
    bpy.data.objects.remove(bpy.data.objects.get("sport_farbe_roh.001") or bpy.data.objects.new("x", None), do_unlink=True) if False else None

    # ---- 8. Skibrille: große Maske mit Gummiband um den Kopf
    def ski_extras(bm, bg):
        pts = []
        for i in range(64):
            w = i / 64 * math.tau
            c, s_ = math.cos(w), math.sin(w)
            e = 3.0
            x = math.copysign(abs(c) ** (2 / e), c) * 0.225
            z = math.copysign(abs(s_) ** (2 / e), s_) * 0.100 + AUGE_Z + 0.004
            pts.append((x, z))
        glas_rahmen(bm, pts, 0.0125, 0.020, EBENE - 0.010)
        glas_scheibe(bg, pts, EBENE - 0.014, 0.004)
        # Band rund um den Kopf (Kopfform: Zylinder)
        band = []
        for i in range(48):
            w = i / 48 * math.tau
            band.append(Vector((0.222 * math.sin(w), 0.205 * math.cos(w) + 0.0, AUGE_Z + 0.012)))
        # Der Kopf liegt in Blender in -y vorn; Punkte (x, y, z): y = -(Godot-z)
        band = [Vector((p.x, -p.y * 0.0 + p.y, p.z)) for p in band]
        kurve_roehre(bm, band + [band[0]], 0.017, 8)
    bmx, bgx = bm_neu(), bm_neu()
    ski_extras(bmx, bgx)
    o = objekt(bmx, "ski_farbe_roh")
    g = objekt(bgx, "ski_glas")
    g.data.materials.append(glas_mat("ski_glas", (0.95, 0.55, 0.12, 0.62)))
    brille_fertig("skibrille", o, g)

    # ---- 9. Monokel (rechtes Auge) mit Kettchen
    def mono_extras(bm, bg):
        sx = 1.0
        pfad = [Vector((sx * (AUGE_X), EBENE, AUGE_Z - 0.088)), Vector((sx * 0.11, EBENE + 0.01, AUGE_Z - 0.16)),
                Vector((sx * 0.17, EBENE + 0.04, AUGE_Z - 0.23)), Vector((sx * 0.19, EBENE + 0.10, AUGE_Z - 0.30))]
        kurve_roehre(bm, pfad, 0.0025, 5)
    o, g = brille("monokel", "rund", 0.086, 0.086, 0.0070, 0.0075, (0.80, 0.90, 0.95, 0.16), nur_rechts=True, extras=mono_extras)
    brille_fertig("monokel", o, g)
    # ---- 10. Herzbrille (Partybrille)
    o, g = brille("herzbrille", "herz", 0.092, 0.088, 0.0095, 0.010, (0.95, 0.25, 0.45, 0.50), hoehe=AUGE_Z + 0.002)
    brille_fertig("herzbrille", o, g)

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
