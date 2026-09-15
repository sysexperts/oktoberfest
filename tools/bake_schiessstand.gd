extends SceneTree
## Baut die große Schießbude (scenes/kirmes/schiessstand_spiel.tscn) und das
## Luftgewehr (scenes/kirmes/luftgewehr.tscn) als echte Knoten. Spiel, Anzeige und
## Budenbesitzer liegen in der Hüllszene scenes/kirmes/schiessstand.tscn.
##
## Maße: 6,4 m breit, Front (Theke, Schütze) = lokal +Z, Tiefe nach −Z 3,4 m —
## nimmt den Platz von zwei Kirmesständen ein und passt vor die Kirmesmauer.
## Oben kein Schriftzug: Schützenscheiben-Wappen mit Gewehren und Geweih.
##   godot --headless --path . --script tools/bake_schiessstand.gd

const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"
const BUDE := "res://scenes/kirmes/schiessstand_spiel.tscn"
const GEWEHR := "res://scenes/kirmes/luftgewehr.tscn"

## Zielbereich (für scripts/kirmes/schiessstand.gd)
const BREITE := 6.4
const TIEFE := 3.4
const BODEN := 0.3

var _own: Node
var _meshes := {}
var m := {}
var s_gewehr: PackedScene

func _init() -> void:
	for n in ["holz_hell", "holz_dunkel", "streifen", "streifen_fein", "rauten", "rauten_fein", "hopfen", "blau", "weiss",
			"rot", "gold", "metall", "gluehbirne", "messing", "stein", "lebkuchen", "himmel", "dielen", "gruen_samt", "teddy", "budenwand"]:
		m[n] = load(MAT + n + ".tres")
	m.schwarz = _mat("schwarz_lack", Color(0.06, 0.06, 0.07), 0.35)
	m.creme = _mat("creme_lack", Color(0.93, 0.87, 0.72), 0.5)
	m.huegel = _mat("huegel", Color(0.32, 0.55, 0.25), 0.95)
	m.huegel_dunkel = _mat("huegel_dunkel", Color(0.2, 0.4, 0.18), 0.95)
	m.welle = _mat("welle", Color(0.16, 0.42, 0.78), 0.6)
	m.welle_hell = _mat("welle_hell", Color(0.45, 0.7, 0.95), 0.6)
	m.ente = _mat("ente", Color(1.0, 0.82, 0.18), 0.4)
	m.orange = _mat("orange_lack", Color(0.95, 0.45, 0.1), 0.5)
	m.geweih = _mat("geweih", Color(0.86, 0.8, 0.68), 0.7)
	m.rosa = _mat("rosa_lack", Color(0.95, 0.55, 0.7), 0.6)
	m.vorhang = _mat("vorhang_rot", Color(0.55, 0.08, 0.1), 0.9)
	# Kulissenhimmel: gedämpft und ohne Leuchten — der Zelthimmel strahlte zu hell
	var kh := StandardMaterial3D.new()
	kh.albedo_texture = load("res://assets/zelt/texturen/himmel.png")
	kh.albedo_color = Color(0.5, 0.56, 0.72)
	kh.uv1_triplanar = true
	kh.uv1_world_triplanar = true
	kh.uv1_scale = Vector3.ONE / 6.0
	kh.roughness = 1.0
	ResourceSaver.save(kh, MAT + "kulisse_himmel.tres")
	m.kulisse_himmel = ResourceLoader.load(MAT + "kulisse_himmel.tres", "", ResourceLoader.CACHE_MODE_REPLACE)
	s_gewehr = _speichern(_gewehr(), GEWEHR)
	_speichern(_bude(), BUDE)
	print("SCHIESSSTAND FERTIG")
	quit()

func _mat(name: String, c: Color, r: float) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	mt.roughness = r
	ResourceSaver.save(mt, MAT + name + ".tres")
	return ResourceLoader.load(MAT + name + ".tres", "", ResourceLoader.CACHE_MODE_REPLACE)

# ------------------------------------------------------------------ Helfer
func _neu(name: String) -> Node3D:
	var r := Node3D.new()
	r.name = name
	_own = r
	_meshes = {}
	return r

func _haengen(parent: Node, n: Node, name: String) -> Node:
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _gruppe(parent: Node, name: String, pos := Vector3.ZERO, grad := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	g.rotation_degrees = grad
	return _haengen(parent, g, name)

func _rot(g: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z)))

func _mesh(key: String, erzeuge: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = erzeuge.call()
	return _meshes[key]

func _mi(parent: Node, name: String, mesh: Mesh, xf: Transform3D, mat: Material, schatten := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.material_override = mat
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return _haengen(parent, mi, name)

func _box(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("b%.3f_%.3f_%.3f" % [g.x, g.y, g.z], func() -> Mesh:
		var b := BoxMesh.new()
		b.size = g
		return b)
	return _mi(parent, name, mesh, Transform3D(_rot(grad), pos), mat)

func _zyl(parent: Node, name: String, unten: float, oben: float, h: float, pos: Vector3, mat: Material, grad := Vector3.ZERO, seg := 16) -> MeshInstance3D:
	var mesh := _mesh("z%.3f_%.3f_%.3f_%d" % [unten, oben, h, seg], func() -> Mesh:
		var c := CylinderMesh.new()
		c.bottom_radius = unten
		c.top_radius = oben
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		return c)
	return _mi(parent, name, mesh, Transform3D(_rot(grad), pos), mat)

func _kugel(parent: Node, name: String, r: float, pos: Vector3, mat: Material, skal := Vector3.ONE, schatten := true) -> MeshInstance3D:
	var mesh := _mesh("k%.3f" % r, func() -> Mesh:
		var k := SphereMesh.new()
		k.radius = r
		k.height = r * 2.0
		k.radial_segments = 14
		k.rings = 7
		return k)
	return _mi(parent, name, mesh, Transform3D(Basis().scaled(skal), pos), mat, schatten)

func _torus(parent: Node, name: String, i: float, a: float, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("t%.3f_%.3f" % [i, a], func() -> Mesh:
		var t := TorusMesh.new()
		t.inner_radius = i
		t.outer_radius = a
		t.rings = 28
		t.ring_segments = 8
		return t)
	return _mi(parent, name, mesh, Transform3D(_rot(grad), pos), mat)

func _prisma(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("p%.3f_%.3f_%.3f" % [g.x, g.y, g.z], func() -> Mesh:
		var p := PrismMesh.new()
		p.size = g
		return p)
	return _mi(parent, name, mesh, Transform3D(_rot(grad), pos), mat)

func _balken(parent: Node, name: String, a: Vector3, b: Vector3, r: float, mat: Material) -> MeshInstance3D:
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	var l := a.distance_to(b)
	var mesh := _mesh("s%.3f_%.3f" % [r, l], func() -> Mesh:
		var c := CylinderMesh.new()
		c.bottom_radius = r
		c.top_radius = r
		c.height = l
		c.radial_segments = 8
		c.rings = 1
		return c)
	return _mi(parent, name, mesh, Transform3D(Basis(x, y, z), (a + b) * 0.5), mat)

func _instanz(parent: Node, szene: PackedScene, name: String, xf: Transform3D) -> Node3D:
	var n := szene.instantiate() as Node3D
	n.transform = xf
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _speichern(root: Node, pfad: String) -> PackedScene:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pfad.get_base_dir()))
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, pfad)
	root.free()
	print("  ", pfad)
	return ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_REPLACE)

# ------------------------------------------------------------------ Luftgewehr
## Ursprung am Abzug, Lauf zeigt nach −Z. Länge etwa 1 m.
func _gewehr() -> Node3D:
	var r := _neu("Luftgewehr")
	var schaft := _gruppe(r, "Schaft")
	_box(schaft, "Kolben", Vector3(0.05, 0.13, 0.3), Vector3(0, -0.03, 0.3), m.holz_hell, Vector3(-6, 0, 0))
	_box(schaft, "Kolbenkappe", Vector3(0.055, 0.15, 0.02), Vector3(0, -0.045, 0.455), m.schwarz, Vector3(-6, 0, 0))
	_prisma(schaft, "Backe", Vector3(0.052, 0.05, 0.22), Vector3(0, 0.055, 0.28), m.holz_hell, Vector3(90, 0, 0))
	_box(schaft, "Hals", Vector3(0.045, 0.07, 0.12), Vector3(0, -0.005, 0.1), m.holz_hell, Vector3(-14, 0, 0))
	_box(schaft, "Pistolengriff", Vector3(0.042, 0.1, 0.05), Vector3(0, -0.065, 0.09), m.holz_hell, Vector3(22, 0, 0))
	_box(schaft, "Vorderschaft", Vector3(0.05, 0.055, 0.34), Vector3(0, -0.005, -0.2), m.holz_hell)
	_box(schaft, "Schaftende", Vector3(0.052, 0.057, 0.03), Vector3(0, -0.005, -0.38), m.holz_dunkel)
	_box(schaft, "Plakette", Vector3(0.002, 0.03, 0.07), Vector3(0.027, -0.02, 0.3), m.messing, Vector3(-6, 0, 0))
	var system := _gruppe(r, "System")
	_box(system, "Gehaeuse", Vector3(0.04, 0.045, 0.24), Vector3(0, 0.04, -0.02), m.schwarz)
	_zyl(system, "Lauf", 0.011, 0.011, 0.6, Vector3(0, 0.048, -0.44), m.schwarz, Vector3(90, 0, 0), 12)
	_zyl(system, "Muendung", 0.016, 0.016, 0.035, Vector3(0, 0.048, -0.73), m.messing, Vector3(90, 0, 0), 12)
	_zyl(system, "Spannhebel", 0.007, 0.007, 0.32, Vector3(0, 0.022, -0.4), m.metall, Vector3(90, 0, 0), 8)
	_box(system, "Korn", Vector3(0.006, 0.03, 0.012), Vector3(0, 0.074, -0.7), m.messing)
	_box(system, "KornTunnel", Vector3(0.03, 0.03, 0.03), Vector3(0, 0.072, -0.7), m.schwarz)
	_box(system, "Kimme", Vector3(0.036, 0.024, 0.012), Vector3(0, 0.075, -0.1), m.schwarz)
	_box(system, "Kimmenschlitz", Vector3(0.008, 0.012, 0.014), Vector3(0, 0.083, -0.1), m.messing)
	_zyl(system, "Ladeknopf", 0.009, 0.009, 0.025, Vector3(0.028, 0.045, 0.06), m.messing, Vector3(0, 0, 90), 10)
	var abzug := _gruppe(r, "Abzug")
	_torus(abzug, "Buegel", 0.026, 0.032, Vector3(0, -0.045, 0.02), m.messing, Vector3(0, 90, 90))
	_box(abzug, "Zunge", Vector3(0.006, 0.028, 0.008), Vector3(0, -0.035, 0.018), m.metall, Vector3(-15, 0, 0))
	# Riemen
	_balken(r, "RiemenVorn", Vector3(0.027, -0.03, -0.3), Vector3(0.03, -0.12, -0.05), 0.004, m.holz_dunkel)
	_balken(r, "RiemenHinten", Vector3(0.03, -0.12, -0.05), Vector3(0.028, -0.09, 0.4), 0.004, m.holz_dunkel)
	return r

# ------------------------------------------------------------------ Bude
func _bude() -> Node3D:
	var r := _neu("Schiessbude")
	var hb := BREITE / 2.0
	var hoehe := 3.3
	_boden_und_waende(r, hb, hoehe)
	_kulisse(r, hb)
	_preise(r, hb)
	_theke(r, hb)
	_kasse(r, hb)
	_fassade(r, hb, hoehe)
	_licht_und_marken(r, hb, hoehe)
	return r

func _boden_und_waende(r: Node3D, hb: float, hoehe: float) -> void:
	var g := _gruppe(r, "Bau")
	_box(g, "Podest", Vector3(BREITE + 0.2, BODEN, TIEFE + 0.1), Vector3(0, BODEN / 2.0, -TIEFE / 2.0 + 0.05), m.holz_dunkel)
	_box(g, "Dielen", Vector3(BREITE - 0.2, 0.02, TIEFE - 0.1), Vector3(0, BODEN + 0.01, -TIEFE / 2.0), m.dielen)
	_box(g, "Sockelblende", Vector3(BREITE + 0.24, BODEN - 0.06, 0.04), Vector3(0, BODEN / 2.0, 0.1), m.rauten_fein)
	_box(g, "Rueckwand", Vector3(BREITE, hoehe, 0.12), Vector3(0, BODEN + hoehe / 2.0, -TIEFE), m.kulisse_himmel)
	for s: float in [-1.0, 1.0]:
		var seite := "Links" if s < 0 else "Rechts"
		_box(g, "Wand" + seite, Vector3(0.14, hoehe, TIEFE), Vector3(s * hb, BODEN + hoehe / 2.0, -TIEFE / 2.0), m.budenwand)
		# Außen bemalte Felder mit Goldrahmen
		for k in 2:
			var z := -0.85 - k * 1.6
			_box(g, "Feld%s%d" % [seite, k], Vector3(0.02, 1.8, 1.2), Vector3(s * (hb + 0.08), BODEN + 1.6, z), m.rauten)
			_box(g, "FeldRahmenO%s%d" % [seite, k], Vector3(0.03, 0.06, 1.3), Vector3(s * (hb + 0.09), BODEN + 2.53, z), m.gold)
			_box(g, "FeldRahmenU%s%d" % [seite, k], Vector3(0.03, 0.06, 1.3), Vector3(s * (hb + 0.09), BODEN + 0.67, z), m.gold)
		_box(g, "Sockel" + seite, Vector3(0.18, 0.5, TIEFE), Vector3(s * (hb + 0.02), BODEN + 0.25, -TIEFE / 2.0), m.holz_dunkel)
	# Dach: gestreift, nach hinten geneigt, Volant an den Seiten
	var dach := _gruppe(r, "Dach")
	_box(dach, "Plane", Vector3(BREITE + 0.5, 0.08, TIEFE + 0.6), Vector3(0, BODEN + hoehe + 0.45, -TIEFE / 2.0 + 0.1), m.streifen, Vector3(-9, 0, 0))
	_box(dach, "Decke", Vector3(BREITE - 0.1, 0.05, TIEFE), Vector3(0, BODEN + hoehe - 0.02, -TIEFE / 2.0), m.budenwand)
	for s: float in [-1.0, 1.0]:
		for i in 2:
			var z := -0.6 - i * 1.8
			_instanz(dach, load(SZ + "lambrequin_2.tscn"), "Volant%s%d" % ["L" if s < 0 else "R", i], Transform3D(_rot(Vector3(0, 90, 0)).scaled(Vector3(0.9, 1, 1)), Vector3(s * (hb + 0.26), BODEN + hoehe + 0.2 + i * 0.28, z)))

## Kulisse: Hügel, Wellen, Enten und Scheiben (vom Spielskript bewegt), Glocke
func _kulisse(r: Node3D, hb: float) -> void:
	var k := _gruppe(r, "Kulisse")
	# Wolken vor dem Himmel und Hügel
	for i in 5:
		var x := -2.4 + i * 1.2
		_kugel(k, "Wolke%d" % i, 0.28, Vector3(x, BODEN + 2.95 - (i % 2) * 0.2, -TIEFE + 0.1), m.creme, Vector3(1.8, 0.7, 0.2))
	for i in 3:
		_kugel(k, "Huegel%d" % i, 1.2, Vector3(-2.2 + i * 2.2, BODEN + 0.6, -TIEFE + 0.25), m.huegel if i % 2 == 0 else m.huegel_dunkel, Vector3(1.4, 0.8, 0.15))
	# Tannen
	for i in 4:
		var x := -2.6 + i * 1.75
		_zyl(k, "Tanne%d" % i, 0.28, 0.0, 0.8, Vector3(x, BODEN + 1.55, -TIEFE + 0.3), m.huegel_dunkel, Vector3.ZERO, 8)
	# Obere Bahn: Scheiben
	var b := _gruppe(k, "Zielbahnen")
	_box(b, "SchieneOben", Vector3(BREITE - 0.9, 0.05, 0.1), Vector3(0, BODEN + 2.05, -TIEFE + 0.55), m.messing)
	var oben := _gruppe(b, "Reihe1", Vector3(0, BODEN + 2.1, -TIEFE + 0.55))
	for i in 6:
		var z := _gruppe(oben, "Ziel%d" % i, Vector3(-2.5 + i * 1.0, 0, 0))
		_zyl(z, "Scheibe", 0.17, 0.17, 0.03, Vector3(0, 0.17, 0), m.weiss, Vector3(90, 0, 0), 24)
		_zyl(z, "Ring1", 0.13, 0.13, 0.034, Vector3(0, 0.17, 0.002), m.schwarz, Vector3(90, 0, 0), 24)
		_zyl(z, "Ring2", 0.09, 0.09, 0.038, Vector3(0, 0.17, 0.004), m.weiss, Vector3(90, 0, 0), 24)
		_zyl(z, "Mitte", 0.045, 0.045, 0.042, Vector3(0, 0.17, 0.006), m.rot, Vector3(90, 0, 0), 16)
		_box(z, "Stiel", Vector3(0.03, 0.06, 0.02), Vector3(0, 0.0, 0), m.metall)
	# Wellen mit Enten dazwischen
	for w in 3:
		var y := BODEN + 1.05 - w * 0.2
		var zw := -TIEFE + 0.9 + w * 0.3
		var welle := _gruppe(k, "Welle%d" % w, Vector3(0, y, zw))
		_box(welle, "Brett", Vector3(BREITE - 0.6, 0.3, 0.03), Vector3(0, -0.15, 0), m.welle if w % 2 == 0 else m.welle_hell)
		for i in 15:
			_zyl(welle, "Kamm%d" % i, 0.14, 0.14, 0.03, Vector3(-2.8 + i * 0.4 + w * 0.13, 0.0, 0), m.welle if w % 2 == 0 else m.welle_hell, Vector3(90, 0, 0), 12)
	var unten := _gruppe(b, "Reihe0", Vector3(0, BODEN + 1.02, -TIEFE + 1.05))
	for i in 6:
		var e := _gruppe(unten, "Ziel%d" % i, Vector3(-2.5 + i * 1.0, 0, 0))
		_kugel(e, "Koerper", 0.13, Vector3(0, 0.1, 0), m.ente, Vector3(1.3, 0.75, 0.35))
		_kugel(e, "Kopf", 0.075, Vector3(0.12, 0.25, 0), m.ente, Vector3(1, 1, 0.5))
		_prisma(e, "Schnabel", Vector3(0.09, 0.04, 0.03), Vector3(0.21, 0.24, 0), m.orange, Vector3(0, 0, -90))
		_kugel(e, "Auge", 0.015, Vector3(0.14, 0.28, 0.035), m.schwarz)
		_prisma(e, "Fluegel", Vector3(0.14, 0.08, 0.02), Vector3(-0.03, 0.13, 0.04), m.orange, Vector3(0, 0, 180))
		_zyl(e, "Mitte", 0.035, 0.035, 0.02, Vector3(-0.02, 0.12, 0.05), m.rot, Vector3(90, 0, 0), 12)
	# Glocke (Bonusziel) mit Scheibe darunter
	var glocke := _gruppe(b, "Glocke", Vector3(0, BODEN + 2.75, -TIEFE + 0.2))
	_box(glocke, "Galgen", Vector3(0.7, 0.05, 0.05), Vector3(0, 0.3, 0), m.messing)
	_zyl(glocke, "Kelch", 0.18, 0.08, 0.22, Vector3(0, 0.12, 0), m.gold, Vector3.ZERO, 18)
	_kugel(glocke, "Kloeppel", 0.035, Vector3(0, 0.0, 0), m.messing)
	_zyl(glocke, "Ziel", 0.07, 0.07, 0.02, Vector3(0, -0.14, 0.05), m.rot, Vector3(90, 0, 0), 16)
	_torus(glocke, "ZielRing", 0.07, 0.09, Vector3(0, -0.14, 0.055), m.weiss, Vector3(90, 0, 0))

## Preiswände an den Innenseiten: große Teddys, Herzen, Rosensträuße, Luftballons
func _preise(r: Node3D, hb: float) -> void:
	var p := _gruppe(r, "Preise")
	for s: float in [-1.0, 1.0]:
		var seite := "Links" if s < 0 else "Rechts"
		var wand := _gruppe(p, seite, Vector3(s * (hb - 0.09), BODEN, 0))
		_box(wand, "Lochwand", Vector3(0.03, 1.9, 1.6), Vector3(0, 1.95, -1.2), m.creme)
		_box(wand, "Rahmen", Vector3(0.035, 2.0, 1.7), Vector3(-s * 0.005, 1.95, -1.2), m.gold)
		for i in 3:
			var z := -0.65 - i * 0.55
			_teddy(wand, "Teddy%d" % i, Vector3(-s * 0.2, 2.25, z), s)
			_instanz(wand, load(SZ + "lebkuchenherz.tscn"), "Herz%d" % i, Transform3D(_rot(Vector3(0, -s * 90, 0)), Vector3(-s * 0.04, 1.65, z)))
		for i in 2:
			var z := -0.9 - i * 0.6
			var strauss := _gruppe(wand, "Rosen%d" % i, Vector3(-s * 0.12, 1.1, z))
			_zyl(strauss, "Tuete", 0.09, 0.02, 0.3, Vector3(0, 0.0, 0), m.weiss, Vector3(0, 0, -s * 15), 10)
			for k in 3:
				_kugel(strauss, "Bluete%d" % k, 0.05, Vector3(-s * 0.05 + (k - 1) * 0.04, 0.2, (k - 1) * 0.04), m.rot)
		var ballons := _gruppe(wand, "Ballons", Vector3(-s * 0.3, 2.9, -2.6))
		var farben := [m.rot, m.blau, m.ente, m.rosa]
		for k in 4:
			var bp := Vector3((k % 2) * 0.18 - 0.09, 0.1 + k * 0.08, (k - 1.5) * 0.18)
			_kugel(ballons, "Ballon%d" % k, 0.13, bp, farben[k], Vector3(1, 1.2, 1))
			_balken(ballons, "Schnur%d" % k, bp - Vector3(0, 0.15, 0), Vector3(0, -0.6, 0), 0.003, m.weiss)

func _teddy(parent: Node3D, name: String, pos: Vector3, s: float) -> void:
	var t := _gruppe(parent, name, pos, Vector3(0, -s * 90, 0))
	_kugel(t, "Bauch", 0.16, Vector3(0, 0, 0), m.teddy, Vector3(1, 1.1, 0.9))
	_kugel(t, "Bauchfleck", 0.1, Vector3(0, -0.02, 0.1), m.creme, Vector3(1, 1.1, 0.4))
	_kugel(t, "Kopf", 0.12, Vector3(0, 0.25, 0.02), m.teddy)
	_kugel(t, "Schnauze", 0.05, Vector3(0, 0.22, 0.12), m.creme, Vector3(1.2, 0.9, 0.8))
	_kugel(t, "Nase", 0.018, Vector3(0, 0.24, 0.165), m.schwarz)
	_kugel(t, "AugeL", 0.014, Vector3(-0.045, 0.29, 0.11), m.schwarz)
	_kugel(t, "AugeR", 0.014, Vector3(0.045, 0.29, 0.11), m.schwarz)
	_kugel(t, "OhrL", 0.045, Vector3(-0.09, 0.35, 0.0), m.teddy, Vector3(1, 1, 0.6))
	_kugel(t, "OhrR", 0.045, Vector3(0.09, 0.35, 0.0), m.teddy, Vector3(1, 1, 0.6))
	_kugel(t, "ArmL", 0.055, Vector3(-0.17, 0.02, 0.04), m.teddy, Vector3(0.8, 1.4, 0.8))
	_kugel(t, "ArmR", 0.055, Vector3(0.17, 0.02, 0.04), m.teddy, Vector3(0.8, 1.4, 0.8))
	_kugel(t, "BeinL", 0.065, Vector3(-0.09, -0.17, 0.07), m.teddy, Vector3(0.9, 0.8, 1.2))
	_kugel(t, "BeinR", 0.065, Vector3(0.09, -0.17, 0.07), m.teddy, Vector3(0.9, 0.8, 1.2))
	_prisma(t, "Schleife", Vector3(0.12, 0.05, 0.03), Vector3(0, 0.13, 0.12), m.rot)

## Theke mit Polsterkante, Messinggeländer, Gewehrablagen und Munitionsdosen
func _theke(r: Node3D, hb: float) -> void:
	var t := _gruppe(r, "Theke")
	var tb := BREITE - 0.6
	_box(t, "Korpus", Vector3(tb, 1.2, 0.55), Vector3(0, 0.6, 0.1), m.holz_dunkel)
	for i in 5:
		var x := -tb / 2.0 + 0.58 + i * (tb - 1.16) / 4.0
		_box(t, "Feld%d" % i, Vector3(0.95, 0.7, 0.02), Vector3(x, 0.62, 0.385), m.rauten_fein)
		_box(t, "FeldRahmen%d" % i, Vector3(1.05, 0.8, 0.015), Vector3(x, 0.62, 0.38), m.gold)
	_box(t, "Platte", Vector3(tb + 0.2, 0.07, 0.7), Vector3(0, 1.235, 0.12), m.gruen_samt)
	_zyl(t, "Polster", 0.05, 0.05, tb + 0.2, Vector3(0, 1.24, 0.47), m.vorhang, Vector3(0, 0, 90), 12)
	_zyl(t, "Fussstange", 0.03, 0.03, tb, Vector3(0, 0.22, 0.6), m.messing, Vector3(0, 0, 90), 12)
	for i in 5:
		_box(t, "Stangenhalter%d" % i, Vector3(0.04, 0.04, 0.25), Vector3(-tb / 2.0 + 0.3 + i * (tb - 0.6) / 4.0, 0.22, 0.49), m.messing)
	# Ablagen mit Gewehren, die nicht benutzt werden
	for i in 2:
		# Nur links und rechts — in der Mitte läge das Gewehr beim Schießen im Bild
		var x := -2.2 + i * 4.4
		var ab := _gruppe(t, "Ablage%d" % i, Vector3(x, 1.27, 0.15))
		for dz in [-0.28, 0.2]:
			_box(ab, "Gabel_%s" % String.num(dz), Vector3(0.05, 0.08, 0.03), Vector3(0, 0.04, dz), m.messing)
		_instanz(ab, s_gewehr, "Gewehr", Transform3D(_rot(Vector3(0, 90 + i * 8, 90)), Vector3(0, 0.1, 0)))
	# Munitionsdosen, Service-Glocke
	for i in 4:
		var x := -2.7 + i * 0.25 + (i / 2) * 3.8
		_zyl(t, "Dose%d" % i, 0.04, 0.04, 0.05, Vector3(x, 1.3, 0.3), m.rot if i % 2 == 0 else m.blau, Vector3.ZERO, 14)
		_zyl(t, "Deckel%d" % i, 0.041, 0.041, 0.008, Vector3(x, 1.33, 0.3), m.messing, Vector3.ZERO, 14)
	_zyl(t, "Klingelfuss", 0.05, 0.05, 0.02, Vector3(1.0, 1.28, 0.32), m.schwarz)
	_kugel(t, "Klingel", 0.045, Vector3(1.0, 1.31, 0.32), m.messing, Vector3(1, 0.7, 1))

## Kasse mit Vorhang in der rechten Ecke — dorthin geht der Budenbesitzer beim Schießen
func _kasse(r: Node3D, hb: float) -> void:
	var k := _gruppe(r, "Kasse", Vector3(hb - 0.55, BODEN, -0.9))
	_box(k, "Pult", Vector3(0.7, 1.0, 0.45), Vector3(0, 0.5, 0.25), m.holz_hell)
	_box(k, "Pultplatte", Vector3(0.76, 0.05, 0.5), Vector3(0, 1.02, 0.25), m.holz_dunkel)
	_box(k, "Kassenkasten", Vector3(0.34, 0.2, 0.26), Vector3(0, 1.15, 0.25), m.messing)
	_box(k, "Kassentasten", Vector3(0.28, 0.02, 0.16), Vector3(0, 1.26, 0.31), m.schwarz, Vector3(-20, 0, 0))
	# Niedrige Schutzwand — höher würde sie beim Schießen die Ziele rechts verdecken
	_box(k, "Schutzwand", Vector3(0.08, 1.1, 1.0), Vector3(-0.42, 0.55, -0.25), m.holz_dunkel)
	_box(k, "SchutzwandKante", Vector3(0.1, 0.05, 1.02), Vector3(-0.42, 1.12, -0.25), m.gold)
	_box(k, "Vorhangstange", Vector3(0.04, 0.04, 1.4), Vector3(0.5, 2.6, -1.1), m.messing)
	for i in 6:
		_box(k, "Vorhang%d" % i, Vector3(0.05, 2.4, 0.22), Vector3(0.5 + (i % 2) * 0.04, 1.4, -0.5 - i * 0.22), m.vorhang)

## Fassade: Säulen, Glühbirnenbogen, Gesims, Wappen mit Schützenscheibe, Gewehren, Geweih
func _fassade(r: Node3D, hb: float, hoehe: float) -> void:
	var f := _gruppe(r, "Fassade")
	var oben := BODEN + hoehe
	for s: float in [-1.0, 1.0]:
		var seite := "Links" if s < 0 else "Rechts"
		var saeule := _gruppe(f, "Saeule" + seite, Vector3(s * (hb + 0.05), 0, 0.3))
		_box(saeule, "Fuss", Vector3(0.5, 0.5, 0.5), Vector3(0, 0.25, 0), m.holz_dunkel)
		_box(saeule, "FussGold", Vector3(0.54, 0.06, 0.54), Vector3(0, 0.52, 0), m.gold)
		_zyl(saeule, "Schaft", 0.17, 0.15, oben - 0.7, Vector3(0, 0.55 + (oben - 0.7) / 2.0, 0), m.creme, Vector3.ZERO, 16)
		for k in 5:
			_torus(saeule, "Ring%d" % k, 0.15, 0.2, Vector3(0, 0.9 + k * (oben - 1.4) / 4.0, 0), m.gold)
		for k in 4:
			var w := k * 90.0 + 45.0
			_box(saeule, "Kannelur%d" % k, Vector3(0.03, oben - 1.0, 0.03), Vector3(sin(deg_to_rad(w)) * 0.16, 0.55 + (oben - 0.7) / 2.0, cos(deg_to_rad(w)) * 0.16), m.rot)
		_box(saeule, "Kapitell", Vector3(0.5, 0.25, 0.5), Vector3(0, oben - 0.02, 0), m.gold)
		_kugel(saeule, "Knauf", 0.14, Vector3(0, oben + 0.2, 0), m.gold)
		# Laterne an der Säule
		_instanz(saeule, load(SZ + "wandlaterne.tscn"), "Laterne", Transform3D(Basis(), Vector3(0, 1.9, 0.18)))
	# Gesims mit Rautenfries und Volant
	_box(f, "Gesims", Vector3(BREITE + 0.7, 0.35, 0.4), Vector3(0, oben + 0.1, 0.3), m.holz_dunkel)
	_box(f, "Fries", Vector3(BREITE + 0.4, 0.22, 0.02), Vector3(0, oben + 0.1, 0.51), m.rauten_fein)
	_box(f, "GesimsKanteO", Vector3(BREITE + 0.8, 0.05, 0.45), Vector3(0, oben + 0.3, 0.3), m.gold)
	_box(f, "GesimsKanteU", Vector3(BREITE + 0.8, 0.05, 0.45), Vector3(0, oben - 0.1, 0.3), m.gold)
	for i in 3:
		_instanz(f, load(SZ + "lambrequin_2.tscn"), "Volant%d" % i, Transform3D(Basis(), Vector3(-2.0 + i * 2.0, oben - 0.16, 0.5)))
	# Glühbirnenbogen über der Öffnung
	var bogen := _gruppe(f, "Birnenbogen")
	var anzahl := 25
	for i in anzahl:
		var t := float(i) / (anzahl - 1)
		var x := lerpf(-hb + 0.2, hb - 0.2, t)
		var y := oben - 0.35 - 0.55 * pow(2.0 * t - 1.0, 2.0) + 0.0
		_kugel(bogen, "Birne%d" % i, 0.045, Vector3(x, y - 0.3, 0.52), m.gluehbirne, Vector3.ONE, false)
	for s: float in [-1.0, 1.0]:
		for i in 7:
			_kugel(bogen, "Saeulenbirne%s%d" % ["L" if s < 0 else "R", i], 0.045, Vector3(s * (hb + 0.05), 0.8 + i * 0.4, 0.52), m.gluehbirne, Vector3.ONE, false)
	# Wappen: Schützenscheibe, gekreuzte Gewehre, Geweih, Schnörkel, Fahnen
	var w := _gruppe(f, "Wappen", Vector3(0, oben + 1.05, 0.4))
	_box(w, "Schildbrett", Vector3(3.2, 1.2, 0.08), Vector3(0, 0, -0.1), m.holz_dunkel)
	_prisma(w, "Giebel", Vector3(3.4, 0.5, 0.1), Vector3(0, 0.84, -0.1), m.holz_dunkel)
	_box(w, "SchildKanteU", Vector3(3.3, 0.06, 0.12), Vector3(0, -0.6, -0.08), m.gold)
	for s: float in [-1.0, 1.0]:
		_prisma(w, "SchildSchraege%s" % ["L" if s < 0 else "R"], Vector3(0.06, 0.5, 1.9), Vector3(s * 0.85, 0.84, -0.06), m.gold, Vector3(90, 0, s * -17))
		_torus(w, "Schnoerkel%s" % ["L" if s < 0 else "R"], 0.16, 0.22, Vector3(s * 1.45, -0.35, -0.02), m.gold, Vector3(90, 0, 0))
		_torus(w, "Schnoerkel2%s" % ["L" if s < 0 else "R"], 0.08, 0.12, Vector3(s * 1.2, 0.2, -0.02), m.gold, Vector3(90, 0, 0))
		_instanz(w, s_gewehr, "Gewehr%s" % ["L" if s < 0 else "R"], Transform3D(_rot(Vector3(0, 0, s * 35)).scaled(Vector3.ONE * 1.8), Vector3(0, 0.05, 0.05)) \
			* Transform3D(_rot(Vector3(90, 0, 0)), Vector3.ZERO))
		_instanz(w, load(SZ + "fahne.tscn"), "Fahne%s" % ["L" if s < 0 else "R"], Transform3D(_rot(Vector3(0, 90 - s * 90, 0)), Vector3(s * 1.7, -0.5, -0.05)))
	var scheibe := _gruppe(w, "Scheibe", Vector3(0, 0.1, 0.1))
	var ringe := [[0.62, m.gold], [0.56, m.weiss], [0.44, m.schwarz], [0.32, m.weiss], [0.2, m.schwarz], [0.1, m.rot]]
	for i in ringe.size():
		_zyl(scheibe, "Ring%d" % i, ringe[i][0], ringe[i][0], 0.03 + i * 0.006, Vector3(0, 0, i * 0.004), ringe[i][1], Vector3(90, 0, 0), 32)
	_torus(scheibe, "Kranz", 0.6, 0.74, Vector3(0, 0, -0.01), m.hopfen, Vector3(90, 0, 0))
	# Hirschgeweih über der Scheibe
	var geweih := _gruppe(w, "Geweih", Vector3(0, 0.78, 0.08))
	_kugel(geweih, "Stirn", 0.1, Vector3(0, 0, 0), m.holz_dunkel, Vector3(1.4, 0.7, 0.7))
	for s: float in [-1.0, 1.0]:
		var a := Vector3(s * 0.08, 0.02, 0)
		var b := Vector3(s * 0.45, 0.45, 0)
		var c := Vector3(s * 0.62, 0.95, 0)
		_balken(geweih, "Stange%s" % s, a, b, 0.03, m.geweih)
		_balken(geweih, "Stange2%s" % s, b, c, 0.025, m.geweih)
		_balken(geweih, "Spross1%s" % s, a.lerp(b, 0.5), Vector3(s * 0.12, 0.45, 0.05), 0.018, m.geweih)
		_balken(geweih, "Spross2%s" % s, b, Vector3(s * 0.32, 0.8, 0.03), 0.018, m.geweih)
		_balken(geweih, "Spross3%s" % s, b.lerp(c, 0.6), Vector3(s * 0.85, 0.95, 0.02), 0.016, m.geweih)
	# Birnen am Wappenrand
	for i in 11:
		var t := float(i) / 10.0
		_kugel(w, "WappenBirne%d" % i, 0.04, Vector3(lerpf(-1.55, 1.55, t), -0.66, 0.0), m.gluehbirne, Vector3.ONE, false)
	_kugel(w, "Spitze", 0.12, Vector3(0, 1.15, -0.1), m.gold)

func _licht_und_marken(r: Node3D, hb: float, hoehe: float) -> void:
	for x in [-1.6, 1.6]:
		var l := OmniLight3D.new()
		l.position = Vector3(x, BODEN + hoehe - 0.4, -1.4)
		l.light_color = Color(1, 0.84, 0.6)
		l.light_energy = 1.4
		l.omni_range = 5.0
		_haengen(r, l, "Budenlicht_%s" % String.num(x))
	var aussen := OmniLight3D.new()
	aussen.position = Vector3(0, BODEN + hoehe - 0.2, 1.3)
	aussen.light_color = Color(1, 0.8, 0.5)
	aussen.light_energy = 1.0
	aussen.omni_range = 6.0
	_haengen(r, aussen, "Frontlicht")
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.72, 1.3)
	kamera.fov = 52
	_haengen(r, kamera, "SpielKamera")
	_instanz(kamera, s_gewehr, "Gewehr", Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(0.22, -0.3, -0.62)))
	for name_pos: Array in [["Spielerplatz", Vector3(0, 0, 1.4)], ["BesitzerMitte", Vector3(0, BODEN, -0.45)], ["BesitzerSeite", Vector3(hb - 0.55, BODEN, -0.35)]]:
		var mk := Marker3D.new()
		mk.position = name_pos[1]
		_haengen(r, mk, name_pos[0])
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	var teile := [
		["Theke", Vector3(BREITE - 0.6, 1.25, 0.7), Vector3(0, 0.62, 0.12)],
		["Rueckwand", Vector3(BREITE, hoehe + BODEN, 0.2), Vector3(0, (hoehe + BODEN) / 2.0, -TIEFE)],
		["Links", Vector3(0.6, hoehe + BODEN, TIEFE + 0.4), Vector3(-hb, (hoehe + BODEN) / 2.0, -TIEFE / 2.0 + 0.2)],
		["Rechts", Vector3(0.6, hoehe + BODEN, TIEFE + 0.4), Vector3(hb, (hoehe + BODEN) / 2.0, -TIEFE / 2.0 + 0.2)],
	]
	for teil: Array in teile:
		var cs := CollisionShape3D.new()
		var form := BoxShape3D.new()
		form.size = teil[1]
		cs.shape = form
		cs.position = teil[2]
		_haengen(koerper, cs, teil[0])
