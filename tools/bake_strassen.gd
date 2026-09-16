extends SceneTree
## Straßen rund um den Festplatz → scenes/kulisse/strassen.tscn (liegt in kirmes.tscn):
##   Ringstraße um den Platz, Nordallee und Südallee zu den Stadttoren (Altstadt-Kulisse),
##   West- und Oststraße bis zum Ring. Kopfsteinpflaster (assets/shader/pflaster.tres),
##   Alleebäume, Laternen, Bänke, Mülleimer, Verkaufsbuden, Minispiel-Buden an Alleen und Ring,
##   drei Biergärten, Besucher-Wegpunkte (Gruppe „besucher_punkt“, crowd.gd) und die
##   Spielgrenze entlang der Stadtmauer (Stadtgrenze).
## Alles echte Knoten (Instanzen) — Feinschliff danach im Editor.
## ACHTUNG: überschreibt scenes/kulisse/strassen.tscn und assets/altstadt/meshes/ringstrasse.res.
##   godot --headless --path . --script tools/bake_strassen.gd

const SZENE := "res://scenes/kulisse/strassen.tscn"
const MITTE := Vector3(0, 0, -8)        # wie tools/bake_altstadt.gd
const RING_INNEN := 64.0
const RING_AUSSEN := 70.0
const OBEN := 0.05                      # Oberkante Pflaster

## false: nur Pflaster, Besucherwege und Stadtgrenze (Rest baut man im Baumodus)
const MIT_AUSSTATTUNG := false
const PFLASTER := preload("res://assets/shader/pflaster.tres")
const LATERNE := preload("res://scenes/props/laterne.tscn")
const BANK := preload("res://assets/kirmes/Models/Props/Bench.fbx")
const MUELL := preload("res://assets/kirmes/Models/Props/TrashBin.fbx")
const BAEUME := [preload("res://scenes/kulisse/baum_kastanie.tscn"),
	preload("res://scenes/kulisse/baum_linde.tscn"),
	preload("res://scenes/kulisse/baum_ahorn.tscn")]
const BUDEN := [preload("res://assets/kirmes/Models/Shops/HotDogs_Shop.fbx"),
	preload("res://assets/kirmes/Models/Shops/PopCorn_Shop.fbx"),
	preload("res://assets/kirmes/Models/Shops/Soda_Shop.fbx"),
	preload("res://assets/kirmes/Models/Shops/Gift_Shop.fbx")]

const SPIEL_DOSEN := preload("res://scenes/kirmes/dosenwurf.tscn")
const SPIEL_LUKAS := preload("res://scenes/kirmes/hau_den_lukas.tscn")
const SPIEL_SCHIESS := preload("res://scenes/kirmes/schiessstand.tscn")
const SPIEL_RING := preload("res://scenes/kirmes/ringwurf.tscn")
const SPIEL_ENTEN := preload("res://scenes/kirmes/entenangeln.tscn")
const SPIEL_RAD := preload("res://scenes/kirmes/gluecksrad.tscn")
const SPIEL_STEMMEN := preload("res://scenes/kirmes/stemmen.tscn")
const SPIEL_NAGEL := preload("res://scenes/kirmes/nagelbalken.tscn")
const SPIEL_KEGELN := preload("res://scenes/kirmes/kegeln.tscn")
const DEKO_ENTEN := preload("res://scenes/props/enten.tscn")
const DEKO_DREH := preload("res://scenes/props/drehscheibe.tscn")
const DEKO_SUESS := preload("res://scenes/props/suessigkeiten.tscn")
const DEKO_SCHIESS := preload("res://scenes/props/schiessstand.tscn")
const BIERTISCH := preload("res://scenes/zelt/biergarten_tisch.tscn")
const LICHTERKETTE := preload("res://scenes/props/lichterkette.tscn")

## Essens- und Marktbuden (tools/bake_kirmes_spiele.gd -- essen)
const MARKT := {
	"bratwurst": preload("res://scenes/kirmes/essen/bratwurst.tscn"),
	"hendl": preload("res://scenes/kirmes/essen/hendl.tscn"),
	"steckerlfisch": preload("res://scenes/kirmes/essen/steckerlfisch.tscn"),
	"brezn": preload("res://scenes/kirmes/essen/brezn.tscn"),
	"mandeln": preload("res://scenes/kirmes/essen/mandeln.tscn"),
	"zuckerwatte": preload("res://scenes/kirmes/essen/zuckerwatte.tscn"),
	"lebkuchen": preload("res://scenes/kirmes/essen/lebkuchen.tscn"),
	"losbude": preload("res://scenes/kirmes/essen/losbude.tscn"),
	"hutstand": preload("res://scenes/kirmes/essen/hutstand.tscn"),
	"ausschank": preload("res://scenes/kirmes/essen/ausschank.tscn"),
}

## Feste Dinge aus kirmes.tscn (Fahrgeschäfte, Häuser, Parkplatz) — Mitte und Radius.
## Damit stellt das Werkzeug weder Buden noch Deko hinein.
const HINDERNISSE := [
	[Vector2(43, -11), 22.0],    # Riesenrad (Gondeln ragen weit)
	[Vector2(7.8, 36.8), 7.0],   # Schiffschaukel
	[Vector2(-41, -27), 11.0],   # TopSpin
	[Vector2(-41, -27), 12.0],   # Ground2
	[Vector2(-38, 28), 8.0],     # Rockets
	[Vector2(29, -27), 8.0],     # Karussell
	[Vector2(23.3, -29.3), 5.0], # Gift_Shop2
	[Vector2(5.9, 29.6), 9.0],   # Parkplatz
	[Vector2(6.8, 26.8), 6.0],   # Park_Entrance
	[Vector2(41.5, 18.4), 8.0],  # Wiesenbüro
	[Vector2(22.8, 21.9), 5.0],  # Bäckerei
	[Vector2(20.9, 37.9), 6.0],  # Café
	[Vector2(14, 43.6), 5.0],    # Gift_Shop
	[Vector2(-14, 41), 5.0],     # HotDogs
	[Vector2(29.8, 21.7), 4.0],  # PopCorn
	[Vector2(35, 25), 4.5],      # Soda
	[Vector2(31.3, 43.2), 4.0],  # Auto
	[Vector2(25.8, 43.3), 4.0],  # Van
	[Vector2(-4, -50), 14.0],    # Wohnwagenplatz
	[Vector2(3, -39), 4.0],      # WC2
]

var wurzel: Node3D
var rng := RandomNumberGenerator.new()
var _nr := {}
var _haltepunkte: Array[Vector3] = []
var _belegt_kreise: Array = []

func _init() -> void:
	rng.seed = 77
	wurzel = Node3D.new()
	wurzel.name = "Strassen"
	var belag := _gruppe(wurzel, "Pflaster")
	var deko := _gruppe(wurzel, "Ausstattung")

	# Ringstraße
	var mi := MeshInstance3D.new()
	mi.name = "Ringstrasse"
	mi.mesh = _ring_mesh()
	_haengen(belag, mi)

	# Gerade Straßen: [Name, Mitte x/z, Länge, Breite, entlang x?]
	var strassen := [
		["Nordallee", Vector2(0, 68.0), 48.0, 9.0, false],
		["Suedallee", Vector2(0, -84.0), 48.0, 9.0, false],
		["Weststrasse", Vector2(-53.0, -8.0), 26.0, 7.0, true],
		["Oststrasse", Vector2(54.0, 30.0), 32.0, 7.0, true],
	]
	for s: Array in strassen:
		var m2: Vector2 = s[1]
		var laenge: float = s[2]
		var breite: float = s[3]
		var quer: bool = s[4]
		var box := BoxMesh.new()
		box.size = Vector3(laenge, 0.14, breite) if quer else Vector3(breite, 0.14, laenge)
		box.material = PFLASTER
		var b := MeshInstance3D.new()
		b.name = s[0]
		b.mesh = box
		b.position = Vector3(m2.x, OBEN - 0.07, m2.y)
		_haengen(belag, b)

	# Biergaerten zuerst als belegt merken, damit keine Deko hineinfaellt
	for h: Array in HINDERNISSE:
		_belegt_kreise.append([h[0], h[1]])
	for bg: Vector3 in [Vector3(-50, 0, 6), Vector3(53, 0, 2), Vector3(30, 0, -45)]:
		_belegen(bg, 9.5)
	# ---------------------------------------------------------------- Buden
	# Erst alle Buden setzen (sie belegen Platz), danach Deko nur auf freie Flächen.
	var buden := _gruppe(wurzel, "Buden")
	var markt := _gruppe(wurzel, "Marktbuden")
	var spiele := [SPIEL_DOSEN, SPIEL_RING, SPIEL_SCHIESS, SPIEL_ENTEN, SPIEL_LUKAS,
		SPIEL_RAD, SPIEL_STEMMEN, SPIEL_NAGEL, SPIEL_KEGELN]
	var essen := ["bratwurst", "hendl", "steckerlfisch", "brezn", "mandeln",
		"zuckerwatte", "lebkuchen", "losbude", "hutstand", "ausschank"]
	var nr_spiel := 0
	var nr_essen := 0

	# Zeltstraßen (Nord- und Südallee): Buden beidseitig, dicht an dicht
	for richtung: float in [1.0, -1.0]:
		var gruppe := _gruppe(deko, ("Nord" if richtung > 0.0 else "Sued") + "allee")
		var z := 52.0 if richtung > 0.0 else -68.0
		var schritt := 11.0
		var ende := 88.0 if richtung > 0.0 else -104.0
		while (z <= ende) if richtung > 0.0 else (z >= ende):
			for seite: float in [-1.0, 1.0]:
				var p := Vector3(seite * 13.5, 0, z)
				var spiel := int(absf(z)) % 2 == 0
				if spiel and _frei(p, 5.2):
					_stand(buden, spiele[nr_spiel % spiele.size()], p, Vector3(-seite, 0, 0), 5.6)
					nr_spiel += 1
				elif not spiel and _frei(p, 4.0):
					_stand(markt, MARKT[essen[nr_essen % essen.size()]], p, Vector3(-seite, 0, 0), 4.6)
					nr_essen += 1
			z += schritt * richtung

	# Seitenstraßen
	_stand(buden, SPIEL_NAGEL, Vector3(-50.0, 0, -17.0), Vector3(0, 0, 1))
	_stand(buden, SPIEL_KEGELN, Vector3(-60.0, 0, -17.5), Vector3(0, 0, 1))
	_stand(buden, SPIEL_KEGELN, Vector3(60.0, 0, 38.0), Vector3(0, 0, -1))
	_stand(markt, MARKT["ausschank"], Vector3(-50.0, 0, 1.0), Vector3(0, 0, -1), 4.0)
	_stand(markt, MARKT["hutstand"], Vector3(-62.0, 0, 1.0), Vector3(0, 0, -1), 4.0)
	_stand(markt, MARKT["bratwurst"], Vector3(47.0, 0, 27.0), Vector3(0, 0, 1), 4.0)
	_stand(markt, MARKT["zuckerwatte"], Vector3(60.0, 0, 21.5), Vector3(0, 0, 1), 4.0)
	# Ringstraße innen: Buden im Kreis, Front zur Straße
	for k in 30:
		var a := TAU * k / 30.0 + 0.05
		var dir := Vector3(sin(a), 0, cos(a))
		var p := MITTE + dir * 58.0
		if _an_strasse(p, 7.0) or not _frei(p, 5.4):
			continue
		if k % 3 == 0:
			_stand(buden, spiele[nr_spiel % spiele.size()], p, dir, 5.6)
			nr_spiel += 1
		else:
			_stand(markt, MARKT[essen[nr_essen % essen.size()]], p, dir, 4.6)
			nr_essen += 1
	# Ringstraße außen: Buden mit Front zur Straße (Rücken zur Wiese)
	for k in 26:
		var a := TAU * k / 26.0 + 0.14
		var dir := Vector3(sin(a), 0, cos(a))
		var p := MITTE + dir * 77.0
		if _an_strasse(p, 8.0) or not _frei(p, 5.4):
			continue
		if k % 4 == 0:
			_stand(buden, spiele[nr_spiel % spiele.size()], p, -dir, 5.6)
			nr_spiel += 1
		else:
			_stand(markt, MARKT[essen[nr_essen % essen.size()]], p, -dir, 4.6)
			nr_essen += 1

	# ---------------------------------------------------------------- Deko
	# Bäume, Laternen, Bänke und Mülleimer füllen die Lücken — nur wo Platz frei ist.
	for richtung: float in [1.0, -1.0]:
		var gruppe := _gruppe(deko, ("Nord" if richtung > 0.0 else "Sued") + "alleeDeko")
		var z := 48.0 if richtung > 0.0 else -64.0
		var ende := 90.0 if richtung > 0.0 else -106.0
		var i := 0
		while (z <= ende) if richtung > 0.0 else (z >= ende):
			for seite: float in [-1.0, 1.0]:
				_deko_baum(gruppe, Vector3(seite * 6.3, 0, z), 1.0)
				if i % 2 == 0:
					_deko_setzen(gruppe, LATERNE, "Laterne", Vector3(seite * 5.0, 0, z + 3.0), 0.0, 1.0)
				else:
					_deko_setzen(gruppe, BANK, "Bank", Vector3(seite * 5.2, 0, z + 3.0), (PI * 0.5) * -seite, 1.0)
				if i % 3 == 0:
					_deko_setzen(gruppe, MUELL, "Muell", Vector3(seite * 5.4, 0, z + 5.5), 0.0, 2.0)
			z += 6.0 * richtung
			i += 1

	# Ring: Baumreihen innen und außen, Laternen und Bänke am Straßenrand
	var ring := _gruppe(deko, "Ring")
	for k in 60:
		var a := TAU * k / 60.0
		var dir := Vector3(sin(a), 0, cos(a))
		if not _an_strasse(MITTE + dir * 63.0, 5.0):
			_deko_setzen(ring, LATERNE, "Laterne", MITTE + dir * 62.8, 0.0, 1.0)
		if k % 2 == 1:
			_deko_baum(ring, MITTE + dir * 48.0, 1.15)
		if k % 2 == 0:
			_deko_baum(ring, MITTE + dir * 91.0, 1.1)
		if k % 4 == 2:
			_deko_setzen(ring, BANK, "Bank", MITTE + dir * 71.8, atan2(dir.x, dir.z) + PI * 0.5, 1.0)
			_deko_setzen(ring, MUELL, "Muell", MITTE + dir * 71.8 + Vector3(1.2, 0, 0), 0.0, 2.0)
		if k % 6 == 3:
			_deko_baum(ring, MITTE + dir * 90.0, 1.3)

	# Lichterketten über der Ringstraße — gleichmäßig im Kreis wie das Zifferblatt einer Uhr
	var ketten := _gruppe(wurzel, "Lichterketten")
	for k in 24:
		var a := TAU * k / 24.0
		var dir := Vector3(sin(a), 0, cos(a))
		var p := MITTE + dir * 67.0
		if _an_strasse(p, 5.0):
			continue
		var kette := LICHTERKETTE.instantiate() as Node3D
		kette.name = "Kette%02d" % k
		# lokal +X quer über die Straße (Masten außerhalb der Fahrbahn), Spannweite 14 → 8 m
		kette.transform = Transform3D(Basis(Vector3.UP, a - PI * 0.5).scaled(Vector3(0.58, 1.0, 1.0)), p)
		_haengen(ketten, kette)

	# Wiese zwischen Platz und Ring: lockere Baumgruppen, wo nichts steht
	var wiese := _gruppe(deko, "Wiese")
	for k in 90:
		var a := rng.randf() * TAU
		var r_w := rng.randf_range(44.0, 56.0) if k % 2 == 0 else rng.randf_range(90.0, 96.0)
		var p := MITTE + Vector3(sin(a), 0, cos(a)) * r_w
		if absf(p.x) < 38.0 and p.z > -42.0 and p.z < 48.0:
			continue
		_deko_baum(wiese, p, rng.randf_range(0.9, 1.35))

	# Biergärten auf der Wiese
	_biergarten(wurzel, "BiergartenWest", Vector3(-50.0, 0, 6.0))
	_biergarten(wurzel, "BiergartenOst", Vector3(53.0, 0, 2.0))
	_biergarten(wurzel, "BiergartenSued", Vector3(30.0, 0, -45.0))

	# Wegpunkte für die Besucher (crowd.gd sammelt die Gruppe „besucher_punkt“)
	var punkte := _gruppe(wurzel, "Besucherwege")
	for k in 36:
		var a := TAU * k / 36.0
		_punkt(punkte, MITTE + Vector3(sin(a), 0, cos(a)) * 67.0)
	var z_n := 46.0
	while z_n <= 88.0:
		_punkt(punkte, Vector3(0, 0, z_n))
		z_n += 7.0
	var z_s := -60.0
	while z_s >= -102.0:
		_punkt(punkte, Vector3(0, 0, z_s))
		z_s -= 7.0
	for x: float in [-40.0, -47.0, -54.0, -61.0]:
		_punkt(punkte, Vector3(x, 0, -8.0))
	for x: float in [40.0, 47.0, 54.0, 61.0]:
		_punkt(punkte, Vector3(x, 0, 30.0))
	# Zwischenpunkte über die Wiese, damit sie vom Platz zum Ring finden
	for x: float in [-40.0, 40.0]:
		for z: float in [-30.0, 10.0, 40.0]:
			_punkt(punkte, Vector3(x, 0, z))
	for p: Vector3 in _haltepunkte:
		_punkt(punkte, p)

	# Grenze entlang der Stadtmauer (ersetzt die alten unsichtbaren Wände um den Platz)
	var grenze := StaticBody3D.new()
	grenze.name = "Stadtgrenze"
	_haengen(wurzel, grenze)
	var teile := 56
	var r_grenze := 98.2
	for k in teile:
		var a := TAU * (k + 0.5) / teile
		var form := CollisionShape3D.new()
		form.name = "Wand%02d" % k
		var box := BoxShape3D.new()
		box.size = Vector3(2.0 * r_grenze * sin(PI / teile) + 0.6, 8.0, 1.0)
		form.shape = box
		form.transform = Transform3D(Basis(Vector3.UP, a), MITTE + Vector3(sin(a), 0, cos(a)) * r_grenze + Vector3(0, 3.0, 0))
		_haengen(grenze, form)

	# Buden, Bäume und Deko stellt man seit dem Baumodus (F8) selbst auf — die
	# alte Aufstellung liegt als res://daten/karte_vorlage.json bei.
	if not MIT_AUSSTATTUNG:
		for g in ["Ausstattung", "Buden", "Marktbuden", "Lichterketten", "BiergartenWest", "BiergartenOst", "BiergartenSued"]:
			var weg := wurzel.get_node(g)
			wurzel.remove_child(weg)
			weg.free()
	var ps := PackedScene.new()
	ps.pack(wurzel)
	ResourceSaver.save(ps, SZENE)
	print("STRASSEN FERTIG")
	quit()

## Stand mit Front in Richtung blick; davor ein Haltepunkt für Besucher.
func _stand(eltern: Node, szene: PackedScene, pos: Vector3, blick: Vector3, radius := 5.5) -> void:
	var name := String(szene.resource_path.get_file().get_basename()).capitalize().replace(" ", "")
	_setzen(eltern, szene, name, pos, atan2(blick.x, blick.z), 1.0)
	_haltepunkte.append(pos + blick.normalized() * 4.5)
	_belegen(pos, radius)


## Belegte Flächen (Mitte, Radius) — Deko kommt nur dorthin, wo nichts steht
func _belegen(p: Vector3, radius: float) -> void:
	_belegt_kreise.append([Vector2(p.x, p.z), radius])

func _frei(p: Vector3, radius: float) -> bool:
	var q := Vector2(p.x, p.z)
	for b: Array in _belegt_kreise:
		if q.distance_to(b[0]) < float(b[1]) + radius:
			return false
	return true

## Innerhalb des Festplatzes (dort steht schon alles aus kirmes.tscn)
func _auf_dem_platz(p: Vector3) -> bool:
	return absf(p.x) < 38.0 and p.z > -42.0 and p.z < 48.0

## Deko nur setzen, wenn der Platz frei ist
func _deko_setzen(eltern: Node, szene: PackedScene, name: String, pos: Vector3, drehung: float, groesse: float) -> void:
	if _auf_dem_platz(pos) or not _frei(pos, 1.2):
		return
	_setzen(eltern, szene, name, pos, drehung, groesse)
	_belegen(pos, 0.8)

## Laubbaum aus scenes/kulisse/baum_*.tscn — Größe zuerst würfeln, dann prüfen
func _deko_baum(eltern: Node, pos: Vector3, groesse: float) -> void:
	var g := groesse * rng.randf_range(0.9, 1.15)
	if _auf_dem_platz(pos) or not _frei(pos, 4.9 * g):
		return
	_setzen(eltern, BAEUME[rng.randi() % BAEUME.size()], "Baum", pos, rng.randf() * TAU, g)
	_belegen(pos, 3.8 * g)
## Biergarten: 3×3 Tische mit Schirmen, Ausschank, zwei Lichterketten, Laternen.
func _biergarten(eltern: Node, name: String, mitte: Vector3) -> void:
	var g := _gruppe(eltern, name)
	for ix in 3:
		for iz in 3:
			var p := mitte + Vector3((ix - 1) * 3.4, 0, (iz - 1) * 3.0)
			_setzen(g, BIERTISCH, "Tisch", p, 0.0, 1.0)
			if iz == 1:
				_haltepunkte.append(p + Vector3(1.7, 0, 0))
	_setzen(g, MARKT["ausschank"], "Ausschank", mitte + Vector3(0, 0, -6.5), 0.0, 1.0)
	_setzen(g, LICHTERKETTE, "Lichterkette", mitte, 0.0, 1.0)
	_setzen(g, LICHTERKETTE, "Lichterkette", mitte, PI * 0.5, 1.0)
	for s: float in [-1.0, 1.0]:
		_setzen(g, LATERNE, "Laterne", mitte + Vector3(s * 6.2, 0, 5.2), 0.0, 1.0)
		_setzen(g, BAEUME[0], "Baum", mitte + Vector3(s * 7.5, 0, -4.5), rng.randf() * TAU, 2.6)

func _punkt(eltern: Node, p: Vector3) -> void:
	var m := Marker3D.new()
	_nr["Punkt"] = int(_nr.get("Punkt", 0)) + 1
	m.name = "Punkt%d" % _nr["Punkt"]
	m.position = Vector3(p.x, 0.1, p.z)
	m.add_to_group("besucher_punkt", true)
	_haengen(eltern, m)

func _an_strasse(p: Vector3, abstand: float) -> bool:
	if absf(p.x) < 4.5 + abstand and (p.z > 40.0 or p.z < -56.0):
		return true
	if absf(p.z + 8.0) < 3.5 + abstand and p.x < -38.0:
		return true
	if absf(p.z - 30.0) < 3.5 + abstand and p.x > 38.0:
		return true
	return false

func _gruppe(eltern: Node, name: String) -> Node3D:
	var g := Node3D.new()
	g.name = name
	_haengen(eltern, g)
	return g

func _haengen(eltern: Node, n: Node) -> void:
	eltern.add_child(n)
	n.owner = wurzel

func _setzen(eltern: Node, szene: PackedScene, name: String, pos: Vector3, drehung: float, groesse: float) -> void:
	var n := szene.instantiate() as Node3D
	_nr[name] = int(_nr.get(name, 0)) + 1
	n.name = "%s%d" % [name, _nr[name]]
	n.transform = Transform3D(Basis(Vector3.UP, drehung).scaled(Vector3.ONE * groesse), pos)
	_haengen(eltern, n)

func _ring_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var seg := 128
	for j in seg:
		var a0 := TAU * j / seg
		var a1 := TAU * (j + 1) / seg
		var d0 := Vector3(sin(a0), 0, cos(a0))
		var d1 := Vector3(sin(a1), 0, cos(a1))
		var i0 := MITTE + d0 * RING_INNEN + Vector3(0, OBEN, 0)
		var i1 := MITTE + d1 * RING_INNEN + Vector3(0, OBEN, 0)
		var o0 := MITTE + d0 * RING_AUSSEN + Vector3(0, OBEN, 0)
		var o1 := MITTE + d1 * RING_AUSSEN + Vector3(0, OBEN, 0)
		_viereck(st, i0, i1, o1, o0, Vector3.UP)
		var u := Vector3(0, -0.2, 0)
		_viereck(st, o0, o1, o1 + u, o0 + u, d0)
		_viereck(st, i1, i0, i0 + u, i1 + u, -d0)
	st.index()
	var m := st.commit()
	m.surface_set_material(0, PFLASTER)
	var pfad := "res://assets/altstadt/meshes/ringstrasse.res"
	ResourceSaver.save(m, pfad, ResourceSaver.FLAG_COMPRESS)
	m.take_over_path(pfad)
	return m

## Viereck mit Vorderseite in Richtung n (Godot: Uhrzeigersinn von vorn)
func _viereck(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
	var tris := [[a, b, c], [a, c, d]]
	for t: Array in tris:
		var p0: Vector3 = t[0]
		var p1: Vector3 = t[1]
		var p2: Vector3 = t[2]
		if (p1 - p0).cross(p2 - p0).dot(n) > 0.0:
			var tmp := p1
			p1 = p2
			p2 = tmp
		for p: Vector3 in [p0, p1, p2]:
			st.set_normal(n.normalized())
			st.add_vertex(p)
