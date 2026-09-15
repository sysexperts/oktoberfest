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

const PFLASTER := preload("res://assets/shader/pflaster.tres")
const LATERNE := preload("res://scenes/props/laterne.tscn")
const BANK := preload("res://assets/kirmes/Models/Props/Bench.fbx")
const MUELL := preload("res://assets/kirmes/Models/Props/TrashBin.fbx")
const BAEUME := [preload("res://assets/kirmes/Models/Foliage/Tree_1.fbx"),
	preload("res://assets/kirmes/Models/Foliage/Tree_2.fbx"),
	preload("res://assets/kirmes/Models/Foliage/Tree_4.fbx")]
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
const DEKO_ENTEN := preload("res://scenes/props/enten.tscn")
const DEKO_DREH := preload("res://scenes/props/drehscheibe.tscn")
const DEKO_SUESS := preload("res://scenes/props/suessigkeiten.tscn")
const DEKO_SCHIESS := preload("res://scenes/props/schiessstand.tscn")
const BIERTISCH := preload("res://scenes/zelt/biergarten_tisch.tscn")
const LICHTERKETTE := preload("res://scenes/props/lichterkette.tscn")

var wurzel: Node3D
var rng := RandomNumberGenerator.new()
var _nr := {}
var _haltepunkte: Array[Vector3] = []

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

	# Alleen zu den Toren: Bäume beidseitig, Laternen und Bänke dazwischen
	for richtung: float in [1.0, -1.0]:
		var name := "Nord" if richtung > 0.0 else "Sued"
		var z0 := 46.0 if richtung > 0.0 else -62.0
		var z1 := 90.0 if richtung > 0.0 else -104.0
		var gruppe := _gruppe(deko, name + "allee")
		var i := 0
		var z := z0
		while absf(z - z0) <= absf(z1 - z0):
			for seite: float in [-1.0, 1.0]:
				_setzen(gruppe, BAEUME[rng.randi() % BAEUME.size()], "Baum", Vector3(seite * 6.8, 0, z), rng.randf() * TAU, rng.randf_range(2.2, 2.7))
				if i % 2 == 1:
					_setzen(gruppe, BANK, "Bank", Vector3(seite * 5.4, 0, z + 4.0), (PI * 0.5) * -seite, 1.0)
			if i % 2 == 0:
				var seite_l := 1.0 if i % 4 == 0 else -1.0
				_setzen(gruppe, LATERNE, "Laterne", Vector3(seite_l * 5.2, 0, z + 4.0), 0.0, 1.0)
				_setzen(gruppe, MUELL, "Muell", Vector3(-seite_l * 5.3, 0, z + 2.2), 0.0, 2.0)
			z += 8.0 * richtung
			i += 1
		# Buden am Übergang zum Ring
		for k in 2:
			var seite := -1.0 if k == 0 else 1.0
			var zb := (RING_INNEN - 8.0 + MITTE.z) if richtung > 0.0 else (-RING_INNEN - 4.0 + MITTE.z)
			_setzen(gruppe, BUDEN[(k + (0 if richtung > 0.0 else 2)) % BUDEN.size()], "Bude",
				Vector3(seite * 10.5, 0, zb), PI * 0.5 * seite, 1.0)

	# Laternen und Bäume am Ring (außen), Lücken an den Straßen
	var ring := _gruppe(deko, "Ring")
	var n := 24
	for k in n:
		var a := TAU * k / n + TAU / (n * 2.0)
		var dir := Vector3(sin(a), 0, cos(a))
		var p := MITTE + dir * (RING_AUSSEN + 1.2)
		if _an_strasse(p, 6.0):
			continue
		if k % 2 == 0:
			_setzen(ring, LATERNE, "Laterne", p, 0.0, 1.0)
		else:
			_setzen(ring, BANK, "Bank", MITTE + dir * (RING_AUSSEN + 0.9), atan2(dir.x, dir.z) + PI * 0.5, 1.0)
		_setzen(ring, BAEUME[k % BAEUME.size()], "Baum", MITTE + dir * (RING_AUSSEN + 5.0), rng.randf() * TAU, rng.randf_range(2.4, 2.9))

	# West- und Oststraße: Laternen
	var seiten := _gruppe(deko, "Seitenstrassen")
	for x: float in [-44.0, -58.0]:
		_setzen(seiten, LATERNE, "Laterne", Vector3(x, 0, -8.0 + 4.3), 0.0, 1.0)
		_setzen(seiten, BAEUME[1], "Baum", Vector3(x + 4.0, 0, -8.0 - 6.0), rng.randf() * TAU, 2.5)
	for x: float in [44.0, 58.0]:
		_setzen(seiten, LATERNE, "Laterne", Vector3(x, 0, 30.0 - 4.3), 0.0, 1.0)
		_setzen(seiten, BAEUME[2], "Baum", Vector3(x - 4.0, 0, 30.0 + 6.0), rng.randf() * TAU, 2.5)
	_setzen(seiten, BUDEN[3], "Bude", Vector3(62.0, 0, 36.5), PI, 1.0)
	_setzen(seiten, BUDEN[1], "Bude", Vector3(-62.0, 0, -14.5), 0.0, 1.0)

	# Buden und Minispiele an den Alleen (hinter der Baumreihe, zur Straße gedreht)
	var buden := _gruppe(wurzel, "Buden")
	var nord := [SPIEL_DOSEN, SPIEL_RING, SPIEL_SCHIESS, SPIEL_ENTEN, SPIEL_LUKAS, SPIEL_RAD]
	var i_n := 0
	for z: float in [64.0, 71.5, 79.0]:
		for seite: float in [-1.0, 1.0]:
			_stand(buden, nord[i_n % nord.size()], Vector3(seite * 11.5, 0, z), Vector3(-seite, 0, 0))
			i_n += 1
	var sued := [SPIEL_SCHIESS, SPIEL_RAD, SPIEL_STEMMEN, SPIEL_DOSEN, SPIEL_RING, SPIEL_LUKAS]
	var i_s := 0
	for z: float in [-84.0, -91.5, -99.0]:
		for seite: float in [-1.0, 1.0]:
			_stand(buden, sued[i_s % sued.size()], Vector3(seite * 11.5, 0, z), Vector3(-seite, 0, 0))
			i_s += 1
	# Buden innen am Ring, Front zur Ringstraße
	var ringbuden := [[60.0, SPIEL_DOSEN], [120.0, SPIEL_RING], [150.0, SPIEL_LUKAS], [210.0, SPIEL_ENTEN],
		[240.0, SPIEL_SCHIESS], [300.0, SPIEL_NAGEL], [330.0, SPIEL_STEMMEN]]
	for rb: Array in ringbuden:
		var a := deg_to_rad(float(rb[0]))
		var dir := Vector3(sin(a), 0, cos(a))
		_stand(buden, rb[1], MITTE + dir * 58.5, dir)
	# Weststraße: Stand an der Südseite, Front zur Straße
	_stand(buden, SPIEL_NAGEL, Vector3(-50.0, 0, -17.0), Vector3(0, 0, 1))

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

	var ps := PackedScene.new()
	ps.pack(wurzel)
	ResourceSaver.save(ps, SZENE)
	print("STRASSEN FERTIG")
	quit()

## Stand mit Front in Richtung blick; davor ein Haltepunkt für Besucher.
func _stand(eltern: Node, szene: PackedScene, pos: Vector3, blick: Vector3) -> void:
	var name := String(szene.resource_path.get_file().get_basename()).capitalize().replace(" ", "")
	_setzen(eltern, szene, name, pos, atan2(blick.x, blick.z), 1.0)
	_haltepunkte.append(pos + blick.normalized() * 4.5)

## Biergarten: 3×3 Tische mit Schirmen, Ausschank, zwei Lichterketten, Laternen.
func _biergarten(eltern: Node, name: String, mitte: Vector3) -> void:
	var g := _gruppe(eltern, name)
	for ix in 3:
		for iz in 3:
			var p := mitte + Vector3((ix - 1) * 3.4, 0, (iz - 1) * 3.0)
			_setzen(g, BIERTISCH, "Tisch", p, 0.0, 1.0)
			if iz == 1:
				_haltepunkte.append(p + Vector3(1.7, 0, 0))
	_setzen(g, BUDEN[2], "Ausschank", mitte + Vector3(0, 0, -6.5), 0.0, 1.0)
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
