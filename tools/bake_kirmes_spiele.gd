extends SceneTree
## Baut weitere Kirmes-Spielstände als echte Knoten (Spiel, Anzeige und Budenbesitzer
## liegen jeweils in einer Hüllszene unter scenes/kirmes/):
##   scenes/kirmes/dosenwurf_stand.tscn   achteckiger Pavillon mit Dosenpyramiden
##   scenes/kirmes/lukas_stand.tscn       „Hau den Lukas": Turm mit Glocke + Hütte
##   scenes/kirmes/wurfball.tscn          Ball (RigidBody) zum Dosenwerfen
##   scenes/kirmes/hammer.tscn            Holzhammer
## Front (Spieler) = lokal +Z. Beide passen auf einen Doppelplatz der Kirmes (≤ 6,4 m
## breit, ≤ 3,6 m nach hinten).
##   godot --headless --path . --script tools/bake_kirmes_spiele.gd

const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"

var _own: Node
var _meshes := {}
var m := {}

func _init() -> void:
	for n in ["holz_hell", "holz_dunkel", "streifen", "streifen_fein", "rauten", "rauten_fein", "hopfen", "blau", "weiss",
			"rot", "gold", "metall", "gluehbirne", "messing", "stein", "dielen", "gruen_samt", "teddy", "budenwand",
			"schwarz_lack", "creme_lack", "vorhang_rot", "ente", "orange_lack", "huegel", "rosa_lack", "schindel"]:
		m[n] = load(MAT + n + ".tres")
	_speichern(_ball(), "res://scenes/kirmes/wurfball.tscn")
	_speichern(_hammer(), "res://scenes/kirmes/hammer.tscn")
	_speichern(_dosenwurf(), "res://scenes/kirmes/dosenwurf_stand.tscn")
	_speichern(_lukas(), "res://scenes/kirmes/lukas_stand.tscn")
	print("KIRMES-SPIELE FERTIG")
	quit()

# ------------------------------------------------------------------ Helfer
func _neu(name: String, typ := "Node3D") -> Node3D:
	var r: Node3D = RigidBody3D.new() if typ == "RigidBody3D" else Node3D.new()
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

func _instanz(parent: Node, pfad: String, name: String, xf: Transform3D) -> Node3D:
	var n := (load(pfad) as PackedScene).instantiate() as Node3D
	n.transform = xf
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _kollision(koerper: Node, name: String, form: Shape3D, xf: Transform3D) -> void:
	var cs := CollisionShape3D.new()
	cs.shape = form
	cs.transform = xf
	_haengen(koerper, cs, name)

func _boxform(g: Vector3) -> BoxShape3D:
	var f := BoxShape3D.new()
	f.size = g
	return f

func _licht(parent: Node, name: String, pos: Vector3, energie: float, reichweite: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1, 0.84, 0.6)
	l.light_energy = energie
	l.omni_range = reichweite
	_haengen(parent, l, name)

func _marke(parent: Node, name: String, pos: Vector3) -> void:
	var mk := Marker3D.new()
	mk.position = pos
	_haengen(parent, mk, name)

func _speichern(root: Node, pfad: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pfad.get_base_dir()))
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, pfad)
	root.free()
	print("  ", pfad)

func _teddy(parent: Node3D, name: String, pos: Vector3, grad: float, groesse := 1.0) -> void:
	var t := _gruppe(parent, name, pos, Vector3(0, grad, 0))
	t.scale = Vector3.ONE * groesse
	_kugel(t, "Bauch", 0.16, Vector3.ZERO, m.teddy, Vector3(1, 1.1, 0.9))
	_kugel(t, "Bauchfleck", 0.1, Vector3(0, -0.02, 0.1), m.creme_lack, Vector3(1, 1.1, 0.4))
	_kugel(t, "Kopf", 0.12, Vector3(0, 0.25, 0.02), m.teddy)
	_kugel(t, "Schnauze", 0.05, Vector3(0, 0.22, 0.12), m.creme_lack, Vector3(1.2, 0.9, 0.8))
	_kugel(t, "Nase", 0.018, Vector3(0, 0.24, 0.165), m.schwarz_lack)
	_kugel(t, "AugeL", 0.014, Vector3(-0.045, 0.29, 0.11), m.schwarz_lack)
	_kugel(t, "AugeR", 0.014, Vector3(0.045, 0.29, 0.11), m.schwarz_lack)
	_kugel(t, "OhrL", 0.045, Vector3(-0.09, 0.35, 0.0), m.teddy, Vector3(1, 1, 0.6))
	_kugel(t, "OhrR", 0.045, Vector3(0.09, 0.35, 0.0), m.teddy, Vector3(1, 1, 0.6))
	_kugel(t, "ArmL", 0.055, Vector3(-0.17, 0.02, 0.04), m.teddy, Vector3(0.8, 1.4, 0.8))
	_kugel(t, "ArmR", 0.055, Vector3(0.17, 0.02, 0.04), m.teddy, Vector3(0.8, 1.4, 0.8))
	_kugel(t, "BeinL", 0.065, Vector3(-0.09, -0.17, 0.07), m.teddy, Vector3(0.9, 0.8, 1.2))
	_kugel(t, "BeinR", 0.065, Vector3(0.09, -0.17, 0.07), m.teddy, Vector3(0.9, 0.8, 1.2))
	_prisma(t, "Schleife", Vector3(0.12, 0.05, 0.03), Vector3(0, 0.13, 0.12), m.blau)

# ------------------------------------------------------------------ Kleinteile
func _ball() -> Node3D:
	var r := _neu("Wurfball", "RigidBody3D")
	var rb := r as RigidBody3D
	rb.mass = 0.3
	rb.continuous_cd = true
	_kugel(r, "Leder", 0.065, Vector3.ZERO, m.weiss)
	_torus(r, "Naht", 0.058, 0.068, Vector3.ZERO, m.rot, Vector3(0, 0, 90))
	var f := SphereShape3D.new()
	f.radius = 0.065
	_kollision(r, "Form", f, Transform3D())
	return r

## Holzhammer: Ursprung am Griffende, Kopf oben (+Y)
func _hammer() -> Node3D:
	var r := _neu("Hammer")
	_zyl(r, "Stiel", 0.025, 0.02, 0.95, Vector3(0, 0.475, 0), m.holz_hell, Vector3.ZERO, 10)
	_box(r, "Griffband", Vector3(0.06, 0.2, 0.06), Vector3(0, 0.12, 0), m.schwarz_lack)
	_zyl(r, "Kopf", 0.085, 0.085, 0.34, Vector3(0, 0.98, 0), m.holz_dunkel, Vector3(0, 0, 90), 16)
	for s: float in [-1.0, 1.0]:
		_zyl(r, "Ring%s" % s, 0.09, 0.09, 0.035, Vector3(s * 0.14, 0.98, 0), m.metall, Vector3(0, 0, 90), 16)
		_zyl(r, "Kappe%s" % s, 0.07, 0.07, 0.02, Vector3(s * 0.18, 0.98, 0), m.rot, Vector3(0, 0, 90), 16)
	return r

# ------------------------------------------------------------------ Dosenwerfen
## Achteckiger Pavillon, Radius 2,9 m. Vorne drei Theken, hinten Dosenpyramiden auf
## Samtstufen vor einem Vorhang, an den Seiten Preise.
func _dosenwurf() -> Node3D:
	var r := _neu("Dosenwurf")
	var radius := 2.9
	var boden := 0.25
	var saeule_h := 3.0
	var ecke := func(k: int, rad: float) -> Vector3:
		var a := deg_to_rad(k * 45.0 + 22.5)
		return Vector3(sin(a) * rad, 0, cos(a) * rad)
	var mitte_kante := func(k: int, rad: float) -> Vector3:
		var a := deg_to_rad(k * 45.0)
		return Vector3(sin(a) * rad, 0, cos(a) * rad)
	var bau := _gruppe(r, "Bau")
	_zyl(bau, "Podest", radius + 0.15, radius + 0.15, boden, Vector3(0, boden / 2.0, 0), m.holz_dunkel, Vector3(0, 22.5, 0), 8)
	_zyl(bau, "Dielen", radius + 0.05, radius + 0.05, 0.02, Vector3(0, boden + 0.01, 0), m.dielen, Vector3(0, 22.5, 0), 8)
	_zyl(bau, "Sockelring", radius + 0.18, radius + 0.18, 0.08, Vector3(0, 0.04, 0), m.gold, Vector3(0, 22.5, 0), 8)
	# Acht gedrechselte Säulen mit Goldringen und Glühbirnen
	for k in 8:
		var p: Vector3 = ecke.call(k, radius)
		var s := _gruppe(bau, "Saeule%d" % k, Vector3(p.x, boden, p.z))
		_box(s, "Fuss", Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), m.holz_dunkel)
		_zyl(s, "Schaft", 0.09, 0.08, saeule_h - 0.5, Vector3(0, 0.3 + (saeule_h - 0.5) / 2.0, 0), m.creme_lack, Vector3.ZERO, 12)
		for i in 4:
			_torus(s, "Ring%d" % i, 0.08, 0.12, Vector3(0, 0.7 + i * 0.6, 0), m.gold)
		_box(s, "Kapitell", Vector3(0.3, 0.2, 0.3), Vector3(0, saeule_h - 0.1, 0), m.gold)
		for i in 5:
			_kugel(s, "Birne%d" % i, 0.04, Vector3(0, 0.6 + i * 0.5, 0) + Vector3(p.x, 0, p.z).normalized() * 0.12, m.gluehbirne, Vector3.ONE, false)
	# Kegeldach mit Laternenturm, Krone und Fahne
	var dach := _gruppe(r, "Dach", Vector3(0, boden + saeule_h, 0))
	_zyl(dach, "Traufring", radius + 0.35, radius + 0.35, 0.18, Vector3(0, 0.09, 0), m.holz_dunkel, Vector3(0, 22.5, 0), 8)
	_zyl(dach, "Kegel", radius + 0.45, 0.35, 1.9, Vector3(0, 1.1, 0), m.streifen, Vector3(0, 22.5, 0), 8)
	_zyl(dach, "Laterne", 0.45, 0.45, 0.6, Vector3(0, 2.3, 0), m.creme_lack, Vector3(0, 22.5, 0), 8)
	for k in 8:
		var fp: Vector3 = mitte_kante.call(k, 0.42)
		_box(dach, "LaterneFenster%d" % k, Vector3(0.2, 0.35, 0.02), Vector3(fp.x, 2.3, fp.z), m.gluehbirne, Vector3(0, k * 45.0, 0))
	_zyl(dach, "Haube", 0.6, 0.0, 0.8, Vector3(0, 3.0, 0), m.blau, Vector3(0, 22.5, 0), 8)
	_kugel(dach, "Knauf", 0.12, Vector3(0, 3.45, 0), m.gold)
	_instanz(dach, SZ + "krone.tscn", "Krone", Transform3D(Basis().scaled(Vector3.ONE * 0.45), Vector3(0, 3.5, 0)))
	_instanz(dach, SZ + "fahne.tscn", "Fahne", Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(0, 4.2, 0)))
	# Volant und Birnenketten an allen acht Kanten
	for k in 8:
		var mp: Vector3 = mitte_kante.call(k, radius + 0.37)
		_instanz(dach, SZ + "lambrequin_2.tscn", "Volant%d" % k, Transform3D(_rot(Vector3(0, k * 45.0, 0)).scaled(Vector3(1.2, 1, 1)), Vector3(mp.x, -0.02, mp.z)))
		var a: Vector3 = ecke.call(k, radius)
		var b: Vector3 = ecke.call(k + 1, radius)
		for i in 7:
			var t := (i + 1) / 8.0
			var p := a.lerp(b, t)
			_kugel(dach, "Kette%d_%d" % [k, i], 0.035, Vector3(p.x, -0.45 - 0.25 * (1.0 - pow(2.0 * t - 1.0, 2.0)), p.z), m.gluehbirne, Vector3.ONE, false)
	# Vorne drei Theken (Kanten 7, 0, 1), hinten Vorhang (3, 4, 5), Seiten Preiswände (2, 6)
	var theken := _gruppe(r, "Theken")
	var kante_breite := 2.0 * radius * sin(deg_to_rad(22.5))
	for k: int in [7, 0, 1]:
		var mp: Vector3 = mitte_kante.call(k, radius * cos(deg_to_rad(22.5)) - 0.15)
		var t := _gruppe(theken, "Theke%d" % k, Vector3(mp.x, boden, mp.z), Vector3(0, k * 45.0, 0))
		_box(t, "Korpus", Vector3(kante_breite - 0.25, 0.95, 0.35), Vector3(0, 0.475, 0), m.holz_dunkel)
		_box(t, "Feld", Vector3(kante_breite - 0.6, 0.6, 0.02), Vector3(0, 0.5, 0.185), m.rauten_fein)
		_box(t, "Rahmen", Vector3(kante_breite - 0.5, 0.7, 0.015), Vector3(0, 0.5, 0.18), m.gold)
		_box(t, "Platte", Vector3(kante_breite - 0.15, 0.06, 0.45), Vector3(0, 0.98, 0), m.gruen_samt)
	var korb := _gruppe(theken, "Ballkorb", Vector3(0.7, boden + 1.01, radius * cos(deg_to_rad(22.5)) - 0.2))
	_zyl(korb, "Geflecht", 0.18, 0.14, 0.18, Vector3(0, 0.09, 0), m.holz_hell, Vector3.ZERO, 14)
	_torus(korb, "Rand", 0.17, 0.2, Vector3(0, 0.18, 0), m.holz_dunkel)
	for i in 5:
		_kugel(korb, "Ball%d" % i, 0.065, Vector3(cos(i * 1.3) * 0.08, 0.2 + (i % 2) * 0.06, sin(i * 1.3) * 0.08), m.weiss)
	var hinten := _gruppe(r, "Vorhang")
	for k: int in [3, 4, 5]:
		var mp: Vector3 = mitte_kante.call(k, radius * cos(deg_to_rad(22.5)) - 0.05)
		var v := _gruppe(hinten, "Wand%d" % k, Vector3(mp.x, boden, mp.z), Vector3(0, k * 45.0, 0))
		for i in 7:
			_box(v, "Falte%d" % i, Vector3(kante_breite / 7.0 + 0.02, saeule_h - 0.2, 0.06), Vector3(-kante_breite / 2.0 + (i + 0.5) * kante_breite / 7.0, (saeule_h - 0.2) / 2.0, (i % 2) * 0.05), m.vorhang_rot)
		_box(v, "Stange", Vector3(kante_breite, 0.05, 0.05), Vector3(0, saeule_h - 0.12, 0.05), m.messing)
	# Samtstufen mit Dosenpyramiden (RigidBody — fallen wirklich um)
	var stufen := _gruppe(r, "Stufen", Vector3(0, boden, -1.5))
	var hoehen := [0.55, 0.85, 1.15]
	for i in 3:
		var z := 0.6 - i * 0.5
		_box(stufen, "Stufe%d" % i, Vector3(2.6 - i * 0.3, hoehen[i], 0.5), Vector3(0, hoehen[i] / 2.0, z), m.holz_dunkel)
		_box(stufen, "Samt%d" % i, Vector3(2.62 - i * 0.3, 0.03, 0.52), Vector3(0, hoehen[i] + 0.015, z), m.vorhang_rot)
		_box(stufen, "Kante%d" % i, Vector3(2.64 - i * 0.3, 0.05, 0.02), Vector3(0, hoehen[i] - 0.03, z + 0.26), m.gold)
	var stufen_koerper := StaticBody3D.new()
	_haengen(stufen, stufen_koerper, "Kollision")
	for i in 3:
		_kollision(stufen_koerper, "Stufe%d" % i, _boxform(Vector3(2.6 - i * 0.3, hoehen[i], 0.5)), Transform3D(Basis(), Vector3(0, hoehen[i] / 2.0, 0.6 - i * 0.5)))
	var dosen := _gruppe(r, "Dosen")
	var dosen_farben := [m.rot, m.blau, m.ente, m.huegel, m.orange_lack, m.rosa_lack]
	var pyramiden := [[Vector3(0, 0, 0.6), 0], [Vector3(-0.75, 0, 0.1), 1], [Vector3(0.75, 0, 0.1), 1], [Vector3(0, 0, -0.4), 2]]
	var dosenform := CylinderShape3D.new()
	dosenform.radius = 0.075
	dosenform.height = 0.16
	var nr := 0
	for py: Array in pyramiden:
		var basis: Vector3 = Vector3(0, boden, -1.5) + (py[0] as Vector3) + Vector3(0, hoehen[int(py[1])] + 0.03, 0)
		for lage in 3:
			for spalte in 3 - lage:
				var dp := basis + Vector3((spalte - (2 - lage) / 2.0) * 0.165, 0.08 + lage * 0.162, 0)
				var dose := RigidBody3D.new()
				dose.mass = 0.15
				dose.position = dp
				dose.can_sleep = true
				dose.sleeping = true
				_haengen(dosen, dose, "Dose%d" % nr)
				_zyl(dose, "Blech", 0.075, 0.075, 0.16, Vector3.ZERO, dosen_farben[nr % dosen_farben.size()], Vector3.ZERO, 14)
				_zyl(dose, "Band", 0.077, 0.077, 0.05, Vector3.ZERO, m.weiss, Vector3.ZERO, 14)
				_zyl(dose, "Deckel", 0.07, 0.07, 0.01, Vector3(0, 0.082, 0), m.metall, Vector3.ZERO, 14)
				_kollision(dose, "Form", dosenform, Transform3D())
				nr += 1
	# Preiswände an den Seiten
	var preise := _gruppe(r, "Preise")
	for k: int in [2, 6]:
		var mp: Vector3 = mitte_kante.call(k, radius * cos(deg_to_rad(22.5)) - 0.05)
		var w := _gruppe(preise, "Wand%d" % k, Vector3(mp.x, boden, mp.z), Vector3(0, k * 45.0 + 180.0, 0))
		_box(w, "Lochwand", Vector3(kante_breite - 0.1, 2.3, 0.04), Vector3(0, 1.4, 0), m.budenwand)
		_box(w, "Rahmen", Vector3(kante_breite, 2.4, 0.03), Vector3(0, 1.4, -0.01), m.gold)
		for i in 3:
			_teddy(w, "Teddy%d" % i, Vector3(-0.6 + i * 0.6, 2.05, 0.2), 0.0, 1.1 if i == 1 else 0.9)
			_instanz(w, SZ + "lebkuchenherz.tscn", "Herz%d" % i, Transform3D(Basis(), Vector3(-0.6 + i * 0.6, 1.45, 0.05)))
	# Kollision (Podestrand, Säulen, Theken, Vorhang), Licht, Kamera, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	var zylform := CylinderShape3D.new()
	zylform.radius = radius + 0.15
	zylform.height = 1.2
	_kollision(koerper, "Pavillon", zylform, Transform3D(Basis(), Vector3(0, 0.6, 0)))
	_licht(r, "Licht", Vector3(0, boden + 2.6, 0), 1.8, 6.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.4, radius + 0.6), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.95, radius + 0.55)
	kamera.rotation_degrees = Vector3(-14, 0, 0)
	kamera.fov = 62
	_haengen(r, kamera, "SpielKamera")
	_marke(r, "BesitzerMitte", Vector3(0, boden, radius - 0.95))
	_marke(r, "BesitzerSeite", Vector3(-radius + 0.9, boden, -0.6))
	_marke(r, "Wurfpunkt", Vector3(0, 1.5, radius + 0.5))
	return r

# ------------------------------------------------------------------ Hau den Lukas
## Turm mit Farbskala und Glocke, Schlagpolster davor, Hütte mit Hammerständer links.
func _lukas() -> Node3D:
	var r := _neu("HauDenLukas")
	var boden := 0.2
	var tx := 1.0
	var tz := -2.3
	var turm_h := 6.2
	_box(r, "Podest", Vector3(5.6, boden, 3.2), Vector3(0, boden / 2.0, -1.2), m.holz_dunkel)
	_box(r, "PodestKante", Vector3(5.7, 0.06, 0.06), Vector3(0, boden, 0.42), m.gold)
	_box(r, "Dielen", Vector3(5.4, 0.02, 3.0), Vector3(0, boden + 0.01, -1.2), m.dielen)
	# Turm: Rückbrett, Farbskala mit Sternen, Messingschiene, Schlitten
	var turm := _gruppe(r, "Turm", Vector3(tx, boden, tz))
	_box(turm, "Fuss", Vector3(1.3, 0.5, 0.6), Vector3(0, 0.25, 0), m.holz_dunkel)
	_box(turm, "Brett", Vector3(0.95, turm_h, 0.12), Vector3(0, 0.5 + turm_h / 2.0, -0.08), m.creme_lack)
	var skala := [m.huegel, m.huegel, m.ente, m.ente, m.orange_lack, m.orange_lack, m.rot, m.rot, m.rosa_lack, m.gold]
	for i in 10:
		var y := 0.8 + i * 0.52
		_box(turm, "Skala%d" % i, Vector3(0.7, 0.46, 0.02), Vector3(0, y, 0.0), skala[i])
		_kugel(turm, "Stern%d" % i, 0.05, Vector3(-0.4, y, 0.02), m.gold)
		_kugel(turm, "Stern%db" % i, 0.05, Vector3(0.4, y, 0.02), m.gold)
	for s: float in [-1.0, 1.0]:
		_zyl(turm, "Pfosten%s" % s, 0.06, 0.05, turm_h + 0.3, Vector3(s * 0.55, 0.5 + (turm_h + 0.3) / 2.0, 0), m.blau, Vector3.ZERO, 10)
		_zyl(turm, "Schiene%s" % s, 0.015, 0.015, turm_h - 0.4, Vector3(s * 0.12, 0.55 + (turm_h - 0.4) / 2.0 + 0.2, 0.12), m.messing, Vector3.ZERO, 8)
		for i in 14:
			_kugel(turm, "Birne%s_%d" % [s, i], 0.04, Vector3(s * 0.62, 0.7 + i * 0.44, 0.05), m.gluehbirne, Vector3.ONE, false)
		for i in 5:
			_torus(turm, "Ring%s_%d" % [s, i], 0.055, 0.085, Vector3(s * 0.55, 1.0 + i * 1.2, 0), m.gold)
	var schlitten := _gruppe(turm, "Schlitten", Vector3(0, 0.75, 0.16))
	_box(schlitten, "Block", Vector3(0.34, 0.2, 0.12), Vector3.ZERO, m.rot)
	_box(schlitten, "Streifen", Vector3(0.35, 0.05, 0.13), Vector3(0, 0.0, 0.0), m.gold)
	_kugel(schlitten, "Nase", 0.05, Vector3(0, 0.12, 0), m.messing)
	# Glocke mit Kronrahmen und Birnenkranz
	var kopf := _gruppe(turm, "Kopf", Vector3(0, 0.5 + turm_h, 0))
	_box(kopf, "Querbalken", Vector3(1.4, 0.18, 0.2), Vector3(0, 0.1, 0), m.holz_dunkel)
	_zyl(kopf, "Glocke", 0.26, 0.1, 0.34, Vector3(0, 0.45, 0.12), m.gold, Vector3.ZERO, 20)
	_kugel(kopf, "GlockeOben", 0.1, Vector3(0, 0.62, 0.12), m.gold)
	_torus(kopf, "Kranz", 0.55, 0.64, Vector3(0, 0.5, 0.05), m.gold, Vector3(90, 0, 0))
	for i in 16:
		var a := TAU * i / 16.0
		_kugel(kopf, "KranzBirne%d" % i, 0.045, Vector3(cos(a) * 0.6, 0.5 + sin(a) * 0.6, 0.1), m.gluehbirne, Vector3.ONE, false)
	_instanz(kopf, SZ + "krone.tscn", "Krone", Transform3D(Basis().scaled(Vector3.ONE * 0.5), Vector3(0, 1.1, 0.05)))
	for s: float in [-1.0, 1.0]:
		_instanz(kopf, SZ + "fahne.tscn", "Fahne%s" % s, Transform3D(_rot(Vector3(0, 90 - s * 90, 0)).scaled(Vector3.ONE * 0.6), Vector3(s * 0.7, 0.2, 0)))
	# Schlagpolster auf einem Hebel
	var polster := _gruppe(r, "Polster", Vector3(tx, boden, -1.25))
	_box(polster, "Sockel", Vector3(0.6, 0.35, 0.6), Vector3(0, 0.175, 0), m.metall)
	_zyl(polster, "Kappe", 0.22, 0.22, 0.12, Vector3(0, 0.41, 0), m.rot, Vector3.ZERO, 20)
	_torus(polster, "KappenRing", 0.22, 0.25, Vector3(0, 0.36, 0), m.messing)
	_box(polster, "Hebel", Vector3(0.12, 0.08, 1.05), Vector3(0, 0.12, -0.55), m.holz_dunkel)
	# Hütte mit gestreiftem Dach, Hammerständer, Preisregal
	var huette := _gruppe(r, "Huette", Vector3(-1.55, boden, -1.5))
	_box(huette, "Rueckwand", Vector3(2.2, 2.4, 0.1), Vector3(0, 1.2, -1.2), m.budenwand)
	_box(huette, "WandLinks", Vector3(0.1, 2.4, 2.4), Vector3(-1.1, 1.2, 0), m.streifen_fein)
	_box(huette, "Theke", Vector3(1.9, 1.0, 0.45), Vector3(-0.1, 0.5, 1.0), m.holz_hell)
	_box(huette, "ThekeFeld", Vector3(1.6, 0.6, 0.02), Vector3(-0.1, 0.5, 1.235), m.rauten_fein)
	_box(huette, "ThekePlatte", Vector3(2.0, 0.05, 0.55), Vector3(-0.1, 1.02, 1.0), m.gruen_samt)
	_box(huette, "Dach", Vector3(2.6, 0.08, 2.9), Vector3(0, 2.6, 0.1), m.streifen, Vector3(-10, 0, 0))
	_instanz(huette, SZ + "lambrequin_2.tscn", "Volant", Transform3D(Basis().scaled(Vector3(1.25, 1, 1)), Vector3(0, 2.3, 1.55)))
	for i in 3:
		_teddy(huette, "Teddy%d" % i, Vector3(-0.7 + i * 0.6, 1.75, -1.0), 0.0, 0.9)
	_box(huette, "Regal", Vector3(2.0, 0.04, 0.3), Vector3(0, 1.55, -1.0), m.holz_hell)
	for i in 2:
		_instanz(huette, "res://scenes/kirmes/hammer.tscn", "Hammer%d" % i, Transform3D(_rot(Vector3(12, 0, 10 + i * 8)), Vector3(0.75 + i * 0.25, 0.0, -0.4)))
	# Wimpel vom Turm zur Hütte, Laterne
	var wimpel := _gruppe(r, "Wimpel")
	var von := Vector3(tx - 0.6, boden + turm_h + 0.3, tz)
	var bis := Vector3(-2.65, boden + 2.55, 1.2 - 1.5)
	for i in 14:
		var t := (i + 0.5) / 14.0
		var p := von.lerp(bis, t) - Vector3(0, 0.35 * (1.0 - pow(2.0 * t - 1.0, 2.0)), 0)
		_prisma(wimpel, "Wimpel%d" % i, Vector3(0.22, 0.28, 0.01), p - Vector3(0, 0.14, 0), m.blau if i % 2 == 0 else m.weiss, Vector3(0, 60, 180))
	_instanz(r, SZ + "wandlaterne.tscn", "Laterne", Transform3D(Basis(), Vector3(tx - 0.55, boden + 2.4, tz + 0.1)))
	# Kollision, Licht, Kamera mit Hammer, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Podest", _boxform(Vector3(5.6, 0.9, 3.2)), Transform3D(Basis(), Vector3(0, 0.45, -1.2)))
	_kollision(koerper, "Turm", _boxform(Vector3(1.4, turm_h + 1.0, 0.8)), Transform3D(Basis(), Vector3(tx, (turm_h + 1.0) / 2.0, tz)))
	_licht(r, "Turmlicht", Vector3(tx, boden + 3.5, tz + 1.2), 1.5, 6.0)
	_licht(r, "Huettenlicht", Vector3(-1.55, boden + 2.2, -1.0), 1.0, 4.0)
	var kamera := Camera3D.new()
	# Nah am Polster: Turm bis zur Glocke im Bild, keine Kirmesbäume davor
	kamera.position = Vector3(tx, 1.6, 0.9)
	kamera.rotation_degrees = Vector3(30, 0, 0)
	kamera.fov = 76
	_haengen(r, kamera, "SpielKamera")
	_instanz(kamera, "res://scenes/kirmes/hammer.tscn", "Hammer", Transform3D(_rot(Vector3(-40, 0, 18)).scaled(Vector3.ONE * 0.75), Vector3(0.42, -0.62, -0.8)))
	_marke(r, "BesitzerMitte", Vector3(-1.6, boden, -0.1))
	_marke(r, "BesitzerSeite", Vector3(-2.2, boden, -2.2))
	return r
