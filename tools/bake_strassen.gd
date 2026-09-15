extends SceneTree
## Straßen rund um den Festplatz → scenes/kulisse/strassen.tscn (liegt in kirmes.tscn):
##   Ringstraße um den Platz, Nordallee und Südallee zu den Stadttoren (Altstadt-Kulisse),
##   West- und Oststraße bis zum Ring. Kopfsteinpflaster (assets/shader/pflaster.tres),
##   Alleebäume, Laternen, Bänke, Mülleimer, ein paar Verkaufsbuden.
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

var wurzel: Node3D
var rng := RandomNumberGenerator.new()
var _nr := {}

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

	var ps := PackedScene.new()
	ps.pack(wurzel)
	ResourceSaver.save(ps, SZENE)
	print("STRASSEN FERTIG")
	quit()

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
