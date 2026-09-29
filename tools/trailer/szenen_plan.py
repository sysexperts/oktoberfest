"""Legt die Trailer-Szenen 04 bis 20 als tools/trailer/szene_NN.tscn an.
Jede Szene ist danach ganz normal im Godot-Editor bearbeitbar (Pfad ziehen,
Blickziel verschieben, Werte am Wurzelknoten).

    python tools/trailer/szenen_plan.py            alle anlegen
    python tools/trailer/szenen_plan.py 07 09      nur diese
    python tools/trailer/szenen_plan.py 07 --hoeher 2   Fahrt 2 m höher legen

Orte aus daten/karte.json: Riesenrad (-38.5, 19.5), Top Spin (-37, -22.5),
Schiffschaukel (10, -68), Karussell (-51.5, 23.5), Maibaum (13.5, -14),
Hubers Zelt (44, -21), Festzelt bei (0, 0), Eingang Richtung +z.
"""
import math, sys, os

HIER = os.path.dirname(os.path.abspath(__file__))


def kreis(mitte, radius, hoehe, von, bis, schritte=6, steigen=0.0):
    """Punkte auf einem Kreisbogen (Grad), optional steigend."""
    pts = []
    for i in range(schritte + 1):
        t = i / schritte
        w = math.radians(von + (bis - von) * t)
        pts.append((mitte[0] + math.sin(w) * radius, hoehe + steigen * t, mitte[1] + math.cos(w) * radius))
    return pts


# name, Punkte der Fahrt, Blickziel, Einstellungen, Zusatz
SZENEN = {
    "04": dict(titel="Riesenrad in der Abenddämmerung, Kamera umkreist es",
               punkte=kreis((-38.5, 19.5), 26, 9, 150, 60, steigen=4), blick=(-38.5, 11, 19.5),
               werte=dict(dauer=8, uhr=19.5, besucher=0.6, sichtfeld=55, unscharf_ab=60, dunst=0.01)),
    "05": dict(titel="Nacht: hoher Kran über die leuchtende Kirmes",
               punkte=[(-60, 30, 70), (-30, 34, 55), (0, 38, 45)], blick=(0, 0, -5),
               werte=dict(dauer=8, uhr=22, besucher=0.5, sichtfeld=58, unscharf_ab=0, dunst=0.012)),
    "06": dict(titel="Zelt innen: Tanz auf den Tischen, Seitenfahrt",
               punkte=[(-10.4, 3.6, 7.5), (-10.4, 3.6, 1.5), (-10.4, 3.6, -4.5)], blick=(0, 1.8, -1),
               werte=dict(dauer=7, uhr=21, besucher=0, sichtfeld=60, unscharf_ab=20, dunst=0.004),
               zelt=dict(tanzen=0.7)),
    "07": dict(titel="Ansturm senkrecht von oben, Kamera fährt mit",
               punkte=[(0, 19, 66), (0, 19, 50), (0, 19, 36)], blick=(0, 0, 50),
               werte=dict(dauer=7, uhr=16, besucher=0, sichtfeld=55, unscharf_ab=0, dunst=0.004),
               ansturm=dict(z=74, anzahl=120, tempo_min=3.6, tempo_max=4.4), blick_folgt=True),
    "08": dict(titel="Ansturm: Kamera steht am Rand, Horde rauscht vorbei",
               punkte=[(-3.6, 2.2, 44), (-3.4, 2.4, 42.5), (-3.2, 2.6, 41)], blick=(0, 1.5, 55),
               werte=dict(dauer=7, uhr=17, besucher=0, sichtfeld=70, unscharf_ab=35, dunst=0.006),
               ansturm=dict(z=74, anzahl=110, tempo_min=3.8, tempo_max=4.6), blick_folgt=True),
    "09": dict(titel="Top Spin am Nachmittag, halber Orbit",
               punkte=kreis((-37, -22.5), 20, 7, 20, 110), blick=(-37, 4, -22.5),
               werte=dict(dauer=7, uhr=15, besucher=0.7, sichtfeld=55, unscharf_ab=50, dunst=0.008)),
    "10": dict(titel="Hubers Zelt: der Rivale — langsamer Push-in",
               punkte=[(72, 7, -21), (64, 5.5, -21), (58, 4.5, -21)], blick=(44, 4, -21),
               werte=dict(dauer=6, uhr=18, besucher=0.3, sichtfeld=50, unscharf_ab=40, dunst=0.008)),
    "11": dict(titel="Flug über die Ringstraße am Abend, voller Betrieb",
               punkte=kreis((0, -2), 58, 12, 200, 250, schritte=6), blick=(0, 0, -2),
               werte=dict(dauer=8, uhr=19, besucher=0.9, sichtfeld=60, unscharf_ab=70, dunst=0.01)),
    "12": dict(titel="Maibaum: Kamera steigt am Stamm hoch",
               punkte=[(17.5, 2, -10), (16.5, 9, -11), (15.5, 17, -12)], blick=(13.5, 20, -14),
               werte=dict(dauer=6, uhr=12, besucher=0.6, sichtfeld=60, unscharf_ab=0, dunst=0.004)),
    "13": dict(titel="Zeitraffer Sonnenuntergang über dem Zelt",
               punkte=[(-30, 16, 48), (-29, 16.5, 47), (-28, 17, 46)], blick=(0, 4, 0),
               werte=dict(dauer=8, uhr=17, uhr_ende=22, besucher=0.6, sichtfeld=55, unscharf_ab=0, dunst=0.01)),
    "14": dict(titel="Zelt innen von oben: volles Haus, Band, Tanz",
               punkte=[(8, 3.8, 10), (4, 3.8, 10.5), (-4, 3.8, 10.5)], blick=(0, 1.2, -4),
               werte=dict(dauer=7, uhr=21, besucher=0, sichtfeld=65, unscharf_ab=22, dunst=0.004),
               zelt=dict(tanzen=0.5)),
    "15": dict(titel="Lieferwagen rast durch die Gasse, Besucher fliegen (von der Seite)",
               punkte=[(1.8, 7.5, 60), (1.8, 7.5, 53), (1.8, 7.5, 46)], blick=(-0.5, 1.0, 62),
               werte=dict(dauer=7, uhr=15, besucher=0.3, sichtfeld=62, unscharf_ab=45, dunst=0.006),
               ereignis=dict(art="lieferwagen", anzahl=30, verzug=0.3, tempo=11,
                             fahrt=[(-0.5, 0, 92), (-0.5, 0, 60), (-0.5, 0, 30)])),
    "16": dict(titel="Lieferwagen frontal: Besucher fliegen auf die Kamera zu",
               punkte=[(2.6, 1.3, 30), (2.6, 1.4, 29.5), (2.6, 1.5, 29)], blick=(-0.5, 1.5, 60),
               werte=dict(dauer=6, uhr=16, besucher=0.2, sichtfeld=70, unscharf_ab=0, dunst=0.006),
               ereignis=dict(art="lieferwagen", anzahl=28, verzug=0.2, tempo=12,
                             fahrt=[(-0.5, 0, 88), (-0.5, 0, 60), (-0.5, 0, 38)])),
    "17": dict(titel="Massenschlägerei im Zelt, Kamera kreist darüber",
               punkte=kreis((-2.8, 1.7), 6.5, 3.6, 200, 290), blick=(-2.8, 0.8, 1.7),
               werte=dict(dauer=7, uhr=21, besucher=0, sichtfeld=62, unscharf_ab=18, dunst=0.004),
               zelt=dict(tanzen=0.0), ereignis=dict(art="schlaegerei", anzahl=18, verzug=0.2, ort=(-2.8, 0, 1.7))),
    "18": dict(titel="Massenschlägerei weit: das ganze Zelt schaut zu",
               punkte=[(9, 3.7, 11), (6, 3.7, 11.2), (3, 3.7, 11.4)], blick=(2.6, 0.8, -1.3),
               werte=dict(dauer=7, uhr=21, besucher=0, sichtfeld=68, unscharf_ab=25, dunst=0.004),
               zelt=dict(tanzen=0.0), ereignis=dict(art="schlaegerei", anzahl=24, verzug=0.2, ort=(2.6, 0, -1.3))),
    "19": dict(titel="Bierleichen: eine Tischreihe kotzt nacheinander",
               punkte=[(-6.4, 3.2, 6.5), (-6.4, 3.2, 3), (-6.4, 3.2, -0.5)], blick=(-4.6, 0.8, -1),
               werte=dict(dauer=7, uhr=22, besucher=0, sichtfeld=60, unscharf_ab=14, dunst=0.004),
               zelt=dict(tanzen=0.0), ereignis=dict(art="kotzen", anzahl=10, verzug=0.3, takt=0.6, ort=(-4.6, 0, 1.7))),
    "20": dict(titel="Tanz auf allen Tischen, Orbit",
               punkte=kreis((-1, 0.5), 7, 3.6, 150, 250), blick=(-1, 1.6, 0.5),
               werte=dict(dauer=7, uhr=21.5, besucher=0, sichtfeld=62, unscharf_ab=18, dunst=0.004),
               zelt=dict(tanzen=1.0)),
    "21": dict(titel="Finale: nachts steil nach oben, ganze Kirmes im Bild",
               punkte=[(0, 4, 30), (0, 20, 45), (0, 55, 70)], blick=(0, 0, 0),
               werte=dict(dauer=8, uhr=22, besucher=0.6, sichtfeld=60, unscharf_ab=0, dunst=0.01)),
}


def kurve(punkte):
    """Weiche Kurve durch die Punkte (Griffe wie Catmull-Rom)."""
    daten = []
    n = len(punkte)
    for i, p in enumerate(punkte):
        vor = punkte[max(i - 1, 0)]
        nach = punkte[min(i + 1, n - 1)]
        g = [(nach[k] - vor[k]) / 6.0 for k in range(3)]
        rein = (0, 0, 0) if i == 0 else tuple(-x for x in g)
        raus = (0, 0, 0) if i == n - 1 else tuple(g)
        daten += list(rein) + list(raus) + list(p)
    return ", ".join("%g" % round(v, 3) for v in daten), n


def tscn(nr, s, hoeher=0.0):
    punkte = [(p[0], p[1] + hoeher, p[2]) for p in s["punkte"]]
    daten, n = kurve(punkte)
    w = s["werte"]
    erw = ['[ext_resource type="Script" path="res://tools/trailer/trailer_szene.gd" id="1_szene"]',
           '[ext_resource type="Script" path="res://tools/trailer/trailer_kamera.gd" id="2_kamera"]',
           '[ext_resource type="Script" path="res://tools/trailer/trailer_vorschau.gd" id="3_vorschau"]']
    if "ansturm" in s:
        erw.append('[ext_resource type="Script" path="res://tools/trailer/ansturm.gd" id="4_ansturm"]')
    if "zelt" in s:
        erw.append('[ext_resource type="Script" path="res://tools/trailer/zelt_voll.gd" id="5_zelt"]')
    if "ereignis" in s:
        erw.append('[ext_resource type="Script" path="res://tools/trailer/ereignis.gd" id="6_ereignis"]')
    werte = "\n".join("%s = %s" % (k, ("%.3f" % v).rstrip("0").rstrip(".") if isinstance(v, float) else v) for k, v in w.items())
    p0 = punkte[0]
    teile = ['[gd_scene format=3]', '', "\n".join(erw), '',
             '[sub_resource type="Curve3D" id="fahrt"]',
             '_data = {\n"points": PackedVector3Array(%s),\n"tilts": PackedFloat32Array(%s)\n}' % (daten, ", ".join(["0"] * n)),
             'point_count = %d' % n, '',
             '[node name="Szene%s" type="Node3D"]' % nr,
             '; %s' % s["titel"],
             'script = ExtResource("1_szene")', werte, '',
             '[node name="Kamerafahrt" type="Path3D" parent="."]', 'curve = SubResource("fahrt")', '',
             '[node name="Wagen" type="PathFollow3D" parent="Kamerafahrt"]',
             'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)' % p0,
             'rotation_mode = 0', 'loop = false', '',
             '[node name="Kamera" type="Camera3D" parent="Kamerafahrt/Wagen" node_paths=PackedStringArray("ziel")]',
             'fov = %g' % w.get("sichtfeld", 55), 'script = ExtResource("2_kamera")', 'ziel = NodePath("../../../Blickziel")', '',
             '[node name="Blickziel" type="Marker3D" parent="."]',
             'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)' % s["blick"], 'gizmo_extents = 2.0', '']
    if "ansturm" in s:
        a = s["ansturm"]
        teile += ['[node name="Zelttor" type="Marker3D" parent="."]',
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 11)', '',
                  '[node name="Ansturm" type="Node3D" parent="." node_paths=PackedStringArray("ziel"%s)]' % (', "blickziel"' if s.get("blick_folgt") else ""),
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, %g)' % a["z"],
                  'script = ExtResource("4_ansturm")',
                  'anzahl = %d' % a["anzahl"], 'tempo_min = %g' % a["tempo_min"], 'tempo_max = %g' % a["tempo_max"],
                  'ziel = NodePath("../Zelttor")'] + (['blickziel = NodePath("../Blickziel")'] if s.get("blick_folgt") else []) + ['']
    if "zelt" in s:
        teile += ['[node name="ZeltVoll" type="Node" parent="."]', 'script = ExtResource("5_zelt")',
                  'tanzen = %g' % s["zelt"].get("tanzen", 0.0), '']
    if "ereignis" in s:
        e = s["ereignis"]
        ort = e.get("ort", (0, 0, 0))
        teile += ['[node name="Ereignis" type="Node3D" parent="."]',
                  'transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, %g, %g, %g)' % tuple(ort),
                  'script = ExtResource("6_ereignis")', 'art = "%s"' % e["art"],
                  'anzahl = %d' % e.get("anzahl", 14), 'verzug = %g' % e.get("verzug", 0.5),
                  'takt = %g' % e.get("takt", 0.8), 'tempo = %g' % e.get("tempo", 11), '']
        if "fahrt" in e:
            fd, fn = kurve([(p[0] - ort[0], p[1] - ort[1], p[2] - ort[2]) for p in e["fahrt"]])
            teile.insert(teile.index('[node name="Szene%s" type="Node3D"]' % nr) - 1,
                         '[sub_resource type="Curve3D" id="wagenfahrt"]\n_data = {\n"points": PackedVector3Array(%s),\n'
                         '"tilts": PackedFloat32Array(%s)\n}\npoint_count = %d\n' % (fd, ", ".join(["0"] * fn), fn))
            teile += ['[node name="Fahrt" type="Path3D" parent="Ereignis"]', 'curve = SubResource("wagenfahrt")', '']
    teile += ['[node name="Vorschau" type="Node3D" parent="."]', 'script = ExtResource("3_vorschau")', '']
    # Titel als Kommentar ist in .tscn nicht erlaubt — als Metadaten ablegen
    text = "\n".join(teile).replace('; %s' % s["titel"], 'metadata/titel = "%s"' % s["titel"])
    with open(os.path.join(HIER, "szene_%s.tscn" % nr), "w", encoding="utf-8", newline="\n") as f:
        f.write(text)


if __name__ == "__main__":
    args = sys.argv[1:]
    hoeher = 0.0
    if "--hoeher" in args:
        i = args.index("--hoeher")
        hoeher = float(args[i + 1])
        args = args[:i] + args[i + 2:]
    for nr in (args or sorted(SZENEN)):
        tscn(nr, SZENEN[nr], hoeher)
        print("szene_%s: %s" % (nr, SZENEN[nr]["titel"]))
