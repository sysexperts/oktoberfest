extends SceneTree
## Baut die spielbare Schießbude (scenes/kirmes/schiessstand_spiel.tscn) als echte
## Knoten. Beliebig oft in die Kirmes stellen — jede Bude ist eigenständig.
## Maße: 4,2 m breit, Front (Theke, Spieler) = lokal +Z, Tiefe nach −Z 2,8 m.
## Das Spiel selbst: scripts/kirmes/schiessstand.gd.
##   godot --headless --path . --script tools/bake_schiessstand.gd

const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"
const ZIEL := "res://scenes/kirmes/schiessstand_spiel.tscn"

var _own: Node
var _meshes := {}
var m := {}

func _init() -> void:
	for n in ["holz_hell", "holz_dunkel", "streifen", "streifen_fein", "rauten_fein", "hopfen", "blau", "weiss",
			"rot", "gold", "metall", "gluehbirne", "messing", "stein", "schindel", "lebkuchen"]:
		m[n] = load(MAT + n + ".tres")
	m.gruen = _mat("gruen_samt", Color(0.12, 0.34, 0.18), 0.95)
	m.teddy = _mat("teddy", Color(0.62, 0.42, 0.22), 1.0)
	m.blech = _mat("blech", Color(0.78, 0.78, 0.8), 0.35)
	m.nacht = _mat("budenwand", Color(0.1, 0.12, 0.2), 0.9)
	_speichern(_bude(), ZIEL)
	print("SCHIESSSTAND FERTIG")
	quit()

func _mat(name: String, c: Color, r: float) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = c
	mt.roughness = r
	ResourceSaver.save(mt, MAT + name + ".tres")
	return ResourceLoader.load(MAT + name + ".tres", "", ResourceLoader.CACHE_MODE_REPLACE)

func _neu(name: String) -> Node3D:
	var r := Node3D.new()
	r.name = name
	_own = r
	return r

func _haengen(parent: Node, n: Node, name: String) -> Node:
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _gruppe(parent: Node, name: String, pos := Vector3.ZERO) -> Node3D:
	var g := Node3D.new()
	g.position = pos
	return _haengen(parent, g, name)

func _rot(g: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(g.x), deg_to_rad(g.y), deg_to_rad(g.z)))

func _mesh(key: String, erzeuge: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = erzeuge.call()
	return _meshes[key]

func _mi(parent: Node, name: String, mesh: Mesh, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.material_override = mat
	return _haengen(parent, mi, name)

func _box(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO) -> MeshInstance3D:
	var mesh := _mesh("b%s" % g, func() -> Mesh:
		var b := BoxMesh.new()
		b.size = g
		return b)
	return _mi(parent, name, mesh, Transform3D(_rot(grad), pos), mat)

func _zyl(parent: Node, name: String, unten: float, oben: float, h: float, xf: Transform3D, mat: Material, seg := 16) -> MeshInstance3D:
	var mesh := _mesh("z%s_%s_%s_%d" % [unten, oben, h, seg], func() -> Mesh:
		var c := CylinderMesh.new()
		c.bottom_radius = unten
		c.top_radius = oben
		c.height = h
		c.radial_segments = seg
		c.rings = 1
		return c)
	return _mi(parent, name, mesh, xf, mat)

func _kugel(parent: Node, name: String, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := _mesh("k%s" % r, func() -> Mesh:
		var k := SphereMesh.new()
		k.radius = r
		k.height = r * 2.0
		k.radial_segments = 12
		k.rings = 6
		return k)
	return _mi(parent, name, mesh, Transform3D(Basis(), pos), mat)

func _instanz(parent: Node, pfad: String, name: String, xf: Transform3D) -> Node3D:
	var n := (load(pfad) as PackedScene).instantiate() as Node3D
	n.transform = xf
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _speichern(root: Node, pfad: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pfad.get_base_dir()))
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, pfad)
	root.free()
	print("  ", pfad)

# ------------------------------------------------------------------ Bude
func _bude() -> Node3D:
	var r := _neu("Schiessstand")
	var breite := 4.2
	var hb := breite / 2.0
	var tiefe := 2.8
	var hoehe := 2.9
	# Boden, Rückwand (dunkel, damit die Figuren leuchten), Seitenwände
	_box(r, "Podest", Vector3(breite, 0.2, tiefe + 0.4), Vector3(0, 0.1, -tiefe / 2.0 + 0.2), m.holz_dunkel)
	_box(r, "Rueckwand", Vector3(breite, hoehe, 0.12), Vector3(0, hoehe / 2.0 + 0.2, -tiefe), m.nacht)
	for s: float in [-1.0, 1.0]:
		var seite := "Links" if s < 0 else "Rechts"
		_box(r, "Wand" + seite, Vector3(0.12, hoehe, tiefe), Vector3(s * hb, hoehe / 2.0 + 0.2, -tiefe / 2.0), m.streifen_fein)
		_box(r, "Pfeiler" + seite, Vector3(0.22, hoehe + 0.5, 0.22), Vector3(s * hb, (hoehe + 0.5) / 2.0, 0.1), m.holz_dunkel)
		# Preisregal an der Seitenwand: Teddys, Herzen, Rosen
		var regal := _gruppe(r, "Preise" + seite, Vector3(s * (hb - 0.25), 0, -1.0))
		for k in 3:
			_box(regal, "Brett%d" % k, Vector3(0.35, 0.04, 1.6), Vector3(0, 1.3 + k * 0.5, 0), m.holz_hell)
		for k in 3:
			var z := -0.5 + k * 0.5
			var teddy := _gruppe(regal, "Teddy%d" % k, Vector3(0, 2.34, z))
			_kugel(teddy, "Bauch", 0.14, Vector3(0, 0.14, 0), m.teddy)
			_kugel(teddy, "Kopf", 0.1, Vector3(0, 0.34, 0), m.teddy)
			_kugel(teddy, "OhrL", 0.04, Vector3(0, 0.43, -0.07), m.teddy)
			_kugel(teddy, "OhrR", 0.04, Vector3(0, 0.43, 0.07), m.teddy)
			_instanz(regal, SZ + "lebkuchenherz.tscn", "Herz%d" % k, Transform3D(_rot(Vector3(0, -s * 90, 0)).scaled(Vector3.ONE * 0.8), Vector3(-s * 0.02, 2.1, z)))
			var rose := _gruppe(regal, "Rose%d" % k, Vector3(0, 1.34, z))
			_zyl(rose, "Stiel", 0.01, 0.01, 0.35, Transform3D(Basis(), Vector3(0, 0.17, 0)), m.hopfen, 6)
			_kugel(rose, "Bluete", 0.06, Vector3(0, 0.37, 0), m.rot)
	# Dach mit gestreifter Markise, Volant, Glühbirnenrahmen
	_box(r, "Dach", Vector3(breite + 0.3, 0.12, tiefe + 0.5), Vector3(0, hoehe + 0.3, -tiefe / 2.0 + 0.1), m.holz_dunkel)
	_box(r, "Markise", Vector3(breite + 0.4, 0.05, 1.2), Vector3(0, hoehe + 0.15, 0.6), m.streifen, Vector3(-22, 0, 0))
	for i in 2:
		_instanz(r, SZ + "lambrequin_2.tscn", "Volant%d" % (i + 1), Transform3D(Basis().scaled(Vector3(1.1, 1, 1)), Vector3(-1.1 + i * 2.2, hoehe - 0.12, 1.15)))
	var birnen := _gruppe(r, "Gluehbirnen")
	var nr := 0
	for i in 11:
		nr += 1
		_kugel(birnen, "Birne%d" % nr, 0.05, Vector3(-hb + 0.1 + i * (breite - 0.2) / 10.0, hoehe + 0.42, 0.22), m.gluehbirne)
	for s: float in [-1.0, 1.0]:
		for i in 6:
			nr += 1
			_kugel(birnen, "Birne%d" % nr, 0.05, Vector3(s * (hb + 0.13), 0.6 + i * 0.45, 0.22), m.gluehbirne)
	# Schild über der Front (Text aus dem Übersetzungsschlüssel)
	var schild := _gruppe(r, "Schild", Vector3(0, hoehe + 0.85, 0.2))
	_box(schild, "Tafel", Vector3(3.2, 0.6, 0.08), Vector3.ZERO, m.rot)
	_box(schild, "Rahmen", Vector3(3.34, 0.72, 0.05), Vector3(0, 0, -0.03), m.gold)
	var text := Label3D.new()
	text.text = "WORLD_SCHIESSSTAND"
	text.position = Vector3(0, 0, 0.06)
	text.pixel_size = 0.007
	text.font_size = 72
	text.outline_size = 14
	text.modulate = Color(1, 0.92, 0.6)
	text.double_sided = false
	_haengen(schild, text, "Text")
	# Theke mit Gewehren
	_box(r, "Theke", Vector3(breite - 0.3, 1.0, 0.5), Vector3(0, 0.5 + 0.2, 0.55), m.holz_hell)
	_box(r, "ThekePlatte", Vector3(breite - 0.2, 0.06, 0.62), Vector3(0, 1.22, 0.55), m.gruen)
	_box(r, "ThekeFries", Vector3(breite - 0.3, 0.18, 0.02), Vector3(0, 1.05, 0.81), m.rauten_fein)
	for i in 3:
		var g := _gruppe(r, "Gewehr%d" % (i + 1), Vector3(-1.2 + i * 1.2, 1.28, 0.55))
		_box(g, "Schaft", Vector3(0.08, 0.06, 0.45), Vector3(0, 0, 0.15), m.holz_dunkel, Vector3(0, 12, 0))
		_zyl(g, "Lauf", 0.015, 0.015, 0.6, Transform3D(_rot(Vector3(90, 12, 0)), Vector3(0.05, 0.02, -0.3)), m.metall, 8)
	# Zielbahnen: zwei Schienen, die Figuren bewegt das Spielskript
	var bahnen := _gruppe(r, "Zielbahnen")
	for reihe in 2:
		var y := 1.55 + reihe * 0.6
		var z := -tiefe + 0.35 + reihe * 0.05
		_box(bahnen, "Schiene%d" % reihe, Vector3(breite - 0.3, 0.05, 0.1), Vector3(0, y - 0.05, z), m.messing)
		var reihe_knoten := _gruppe(bahnen, "Reihe%d" % reihe, Vector3(0, y, z))
		for k in 5:
			var ziel := _gruppe(reihe_knoten, "Ziel%d" % k, Vector3(-1.6 + k * 0.8, 0, 0))
			if reihe == 0:
				# Blechente
				_box(ziel, "Koerper", Vector3(0.3, 0.16, 0.04), Vector3(0, 0.08, 0), m.gold)
				_kugel(ziel, "Kopf", 0.07, Vector3(0.12, 0.22, 0), m.gold)
				_box(ziel, "Schnabel", Vector3(0.08, 0.03, 0.03), Vector3(0.21, 0.21, 0), m.rot)
			else:
				# Scheibe mit rotem Punkt
				_zyl(ziel, "Scheibe", 0.15, 0.15, 0.03, Transform3D(_rot(Vector3(90, 0, 0)), Vector3(0, 0.15, 0)), m.weiss, 20)
				_zyl(ziel, "Ring", 0.1, 0.1, 0.035, Transform3D(_rot(Vector3(90, 0, 0)), Vector3(0, 0.15, 0.002)), m.rot, 20)
				_zyl(ziel, "Punkt", 0.045, 0.045, 0.04, Transform3D(_rot(Vector3(90, 0, 0)), Vector3(0, 0.15, 0.004)), m.weiss, 12)
	# Licht, Spielkamera, Stehplatz, Kollision
	var licht := OmniLight3D.new()
	licht.position = Vector3(0, hoehe - 0.2, -0.8)
	licht.light_color = Color(1, 0.85, 0.6)
	licht.light_energy = 1.6
	licht.omni_range = 5.0
	_haengen(r, licht, "Budenlicht")
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.62, 1.35)
	kamera.rotation_degrees = Vector3(-4, 0, 0)
	kamera.fov = 55
	_haengen(r, kamera, "SpielKamera")
	var platz := Marker3D.new()
	platz.position = Vector3(0, 0, 1.5)
	_haengen(r, platz, "Spielerplatz")
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	for teil: Array in [[Vector3(breite, 1.2, 0.7), Vector3(0, 0.6, 0.5)], [Vector3(breite, hoehe, 0.2), Vector3(0, hoehe / 2.0, -tiefe)],
			[Vector3(0.3, hoehe, tiefe), Vector3(-hb, hoehe / 2.0, -tiefe / 2.0)], [Vector3(0.3, hoehe, tiefe), Vector3(hb, hoehe / 2.0, -tiefe / 2.0)]]:
		var cs := CollisionShape3D.new()
		var f := BoxShape3D.new()
		f.size = teil[0]
		cs.shape = f
		cs.position = teil[1]
		_haengen(koerper, cs, "Form%d" % koerper.get_child_count())
	return r
