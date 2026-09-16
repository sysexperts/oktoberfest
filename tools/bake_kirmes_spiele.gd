extends SceneTree
## Baut weitere Kirmes-Spielstände als echte Knoten (Spiel, Anzeige und Budenbesitzer
## liegen jeweils in einer Hüllszene unter scenes/kirmes/):
##   scenes/kirmes/dosenwurf_stand.tscn   achteckiger Pavillon mit Dosenpyramiden
##   scenes/kirmes/lukas_stand.tscn       „Hau den Lukas": Turm mit Glocke + Hütte
##   scenes/kirmes/wurfball.tscn          Ball (RigidBody) zum Dosenwerfen
##   scenes/kirmes/hammer.tscn            Holzhammer
##   scenes/kirmes/ringwurf_stand.tscn    Ringwerfen: Maßkrüge auf Stufen, Preiswand
##   scenes/kirmes/wurfring.tscn          Wurfring
##   scenes/kirmes/entenangeln_stand.tscn Entenangeln: Rundbecken mit Gummienten, Angel
##   scenes/kirmes/gluecksrad_stand.tscn  Glücksrad: großes Rad mit 16 Feldern, Zeiger
##   scenes/kirmes/stemmen_stand.tscn     Maßkrugstemmen: Bühne mit Tafel, Fässer, Arm mit Krug
##   scenes/kirmes/nagelbalken_stand.tscn Nagelbalken: Baumstamm mit Nagel, Hammer an der Kamera
##   scenes/kirmes/kegeln_stand.tscn      Bierfass-Kegeln: kurze Bahn, 9 Fässchen als Kegel
##   scenes/kirmes/kegelkugel.tscn        Holzkugel (RigidBody)
##   scenes/kirmes/pfeilwurf_stand.tscn   Ballonstechen: Korkwand mit 12 Ballons, Pfeile
##   scenes/kirmes/maulwurf_stand.tscn    Hau den Maulwurf: Tisch mit 9 Löchern, Spielhammer
##   scenes/kirmes/krugschieben_stand.tscn Krugschieben: langer Schanktisch mit Punktfeldern
##   scenes/kirmes/essen/*.tscn           Marktbuden (Essen, Süßes, Spielwaren) mit Verkäuferplatz
##   scenes/kulisse/deko/*.tscn           Deko für den Baumodus (Brunnen, Festbogen, Zaun …)
## Front (Spieler) = lokal +Z. Alle passen auf einen Doppelplatz der Kirmes (≤ 6,4 m
## breit, ≤ 3,6 m nach hinten).
##   godot --headless --path . --script tools/bake_kirmes_spiele.gd            (alles)
##   godot --headless --path . --script tools/bake_kirmes_spiele.gd -- ringwurf (nur diese)

const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"

var _own: Node
var _meshes := {}
var m := {}

func _init() -> void:
	for n in ["holz_hell", "holz_dunkel", "streifen", "streifen_fein", "rauten", "rauten_fein", "hopfen", "blau", "weiss",
			"rot", "gold", "metall", "gluehbirne", "stoff", "papier", "lebkuchen", "laternenglas", "messing", "stein", "dielen", "gruen_samt", "teddy", "budenwand",
			"schwarz_lack", "creme_lack", "vorhang_rot", "ente", "orange_lack", "huegel", "rosa_lack", "schindel", "glas", "wasser",
			"streifen_rot", "streifen_fein_rot", "zickzack_rot", "strahlen_rot",
			"streifen_gruen", "streifen_fein_gruen", "zickzack_gruen", "strahlen_gruen",
			"streifen_orange", "streifen_fein_orange", "zickzack_orange", "strahlen_orange",
			"streifen_violett", "streifen_fein_violett", "zickzack_violett", "strahlen_violett",
			"streifen_tuerkis", "streifen_fein_tuerkis", "zickzack_tuerkis", "strahlen_tuerkis"]:
		m[n] = load(MAT + n + ".tres")
	# Mit Namen hinter „--" nur diese Stände backen (Handänderungen an den anderen bleiben)
	var nur := OS.get_cmdline_user_args()
	var soll := func(name: String) -> bool: return nur.is_empty() or nur.has(name)
	if soll.call("dosenwurf"):
		_speichern(_ball(), "res://scenes/kirmes/wurfball.tscn")
		_speichern(_dosenwurf(), "res://scenes/kirmes/dosenwurf_stand.tscn")
	if soll.call("lukas"):
		_speichern(_hammer(), "res://scenes/kirmes/hammer.tscn")
		_speichern(_lukas(), "res://scenes/kirmes/lukas_stand.tscn")
	if soll.call("ringwurf"):
		_speichern(_wurfring(), "res://scenes/kirmes/wurfring.tscn")
		_speichern(_ringwurf(), "res://scenes/kirmes/ringwurf_stand.tscn")
	if soll.call("entenangeln"):
		_speichern(_entenangeln(), "res://scenes/kirmes/entenangeln_stand.tscn")
	if soll.call("gluecksrad"):
		_speichern(_gluecksrad(), "res://scenes/kirmes/gluecksrad_stand.tscn")
	if soll.call("stemmen"):
		_speichern(_stemmen(), "res://scenes/kirmes/stemmen_stand.tscn")
	if soll.call("nagelbalken"):
		_speichern(_nagelbalken(), "res://scenes/kirmes/nagelbalken_stand.tscn")
	if soll.call("essen"):
		for typ: String in MARKTBUDEN:
			_speichern(_marktbude(typ), "res://scenes/kirmes/essen/%s.tscn" % typ)
	if soll.call("pfeilwurf"):
		_speichern(_pfeilwurf(), "res://scenes/kirmes/pfeilwurf_stand.tscn")
	if soll.call("maulwurf"):
		_speichern(_maulwurf(), "res://scenes/kirmes/maulwurf_stand.tscn")
	if soll.call("krugschieben"):
		_speichern(_krugschieben(), "res://scenes/kirmes/krugschieben_stand.tscn")
	if soll.call("deko"):
		for typ: String in DEKO:
			_speichern(_deko(typ), "res://scenes/kulisse/deko/%s.tscn" % typ)
	if soll.call("kegeln"):
		_speichern(_kegelkugel(), "res://scenes/kirmes/kegelkugel.tscn")
		_speichern(_kegeln(), "res://scenes/kirmes/kegeln_stand.tscn")
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
	_zyl(dach, "Kegel", radius + 0.45, 0.35, 1.9, Vector3(0, 1.1, 0), m.streifen_gruen, Vector3(0, 22.5, 0), 8)
	_zyl(dach, "Laterne", 0.45, 0.45, 0.6, Vector3(0, 2.3, 0), m.creme_lack, Vector3(0, 22.5, 0), 8)
	for k in 8:
		var fp: Vector3 = mitte_kante.call(k, 0.42)
		_box(dach, "LaterneFenster%d" % k, Vector3(0.2, 0.35, 0.02), Vector3(fp.x, 2.3, fp.z), m.gluehbirne, Vector3(0, k * 45.0, 0))
	_zyl(dach, "Haube", 0.6, 0.0, 0.8, Vector3(0, 3.0, 0), m.huegel, Vector3(0, 22.5, 0), 8)
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
		_box(t, "Feld", Vector3(kante_breite - 0.6, 0.6, 0.02), Vector3(0, 0.5, 0.185), m.zickzack_gruen)
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

# ------------------------------------------------------------------ Ringwerfen
func _wurfring() -> Node3D:
	var r := _neu("Wurfring")
	_torus(r, "Ring", 0.1, 0.135, Vector3.ZERO, m.rot)
	return r

## Maßkrug aus Grundformen, Ursprung am Boden
func _masskrug(parent: Node3D, name: String, pos: Vector3) -> Node3D:
	var k := _gruppe(parent, name, pos)
	_zyl(k, "Bier", 0.075, 0.07, 0.17, Vector3(0, 0.085, 0), m.orange_lack, Vector3.ZERO, 14)
	_zyl(k, "Boden", 0.078, 0.078, 0.025, Vector3(0, 0.0125, 0), m.glas, Vector3.ZERO, 14)
	for i in 4:
		_box(k, "Rippe%d" % i, Vector3(0.012, 0.15, 0.01), Vector3(sin(i * PI / 2.0) * 0.075, 0.09, cos(i * PI / 2.0) * 0.075), m.glas, Vector3(0, i * 90.0, 0))
	_zyl(k, "Schaum", 0.074, 0.07, 0.045, Vector3(0, 0.19, 0), m.weiss, Vector3.ZERO, 14)
	_kugel(k, "Krone", 0.06, Vector3(0, 0.215, 0), m.weiss, Vector3(1.15, 0.45, 1.15))
	_torus(k, "Henkel", 0.045, 0.062, Vector3(0.1, 0.1, 0), m.glas, Vector3(90, 0, 0))
	return k

## Offene Bude: Theke vorn, dahinter drei Stufen mit 12 Maßkrügen, Preiswand rechts,
## gestreiftes Dach mit Volant und Krone. Ziele = Marken „Krugziele/ZielN“ (Krugoberkante).
func _ringwurf() -> Node3D:
	var r := _neu("Ringwurf")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.4
	var hoehe := 2.9
	var zm := -1.3
	# Sechseckiges Rundzelt in Rot-Creme mit Kegeldach
	var radius := 3.3
	var ecke := func(k: int, rad: float) -> Vector3:
		var a := deg_to_rad(k * 60.0)
		return Vector3(sin(a) * rad, 0, zm + cos(a) * rad)
	_zyl(r, "Podest", radius + 0.15, radius + 0.15, boden, Vector3(0, boden / 2.0, zm), m.holz_dunkel, Vector3.ZERO, 6)
	_zyl(r, "Dielen", radius + 0.05, radius + 0.05, 0.02, Vector3(0, boden + 0.01, zm), m.dielen, Vector3.ZERO, 6)
	_zyl(r, "PodestKante", radius + 0.2, radius + 0.2, 0.08, Vector3(0, boden + 0.04, zm), m.gold, Vector3.ZERO, 6)
	var bau := _gruppe(r, "Bau")
	for k in 6:
		var p: Vector3 = ecke.call(k, radius - 0.15)
		_zyl(bau, "Pfosten%d" % k, 0.09, 0.08, hoehe, Vector3(p.x, boden + hoehe / 2.0, p.z), m.creme_lack, Vector3.ZERO, 10)
		for i in 3:
			_torus(bau, "Ring%d_%d" % [k, i], 0.08, 0.13, Vector3(p.x, boden + 0.8 + i * 0.8, p.z), m.rot)
	# Hintere drei Seiten: roter Vorhang, seitlich Zickzack-Schürzen
	for k: int in [2, 3, 4]:
		var a := k * 60.0 + 30.0
		var mp: Vector3 = ecke.call(k, radius * cos(deg_to_rad(30.0)) - 0.05)
		var mp2: Vector3 = ecke.call(k + 1, radius * cos(deg_to_rad(30.0)) - 0.05)
		var mitte := (mp + mp2) * 0.5
		_box(bau, "Wand%d" % k, Vector3(radius + 0.2, hoehe, 0.08), Vector3(mitte.x, boden + hoehe / 2.0, mitte.z), m.vorhang_rot, Vector3(0, a, 0))
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	_zyl(dach, "Traufring", radius + 0.45, radius + 0.45, 0.16, Vector3(0, 0.08, 0), m.holz_dunkel, Vector3.ZERO, 6)
	_zyl(dach, "Kegel", radius + 0.55, 0.3, 1.5, Vector3(0, 0.9, 0), m.streifen_rot, Vector3.ZERO, 6)
	_zyl(dach, "Schuerze", radius + 0.6, radius + 0.45, 0.4, Vector3(0, -0.15, 0), m.zickzack_rot, Vector3.ZERO, 6)
	_kugel(dach, "Knauf", 0.16, Vector3(0, 1.75, 0), m.gold)
	_instanz(dach, SZ + "fahne.tscn", "Fahne", Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(0, 1.9, 0)))
	for k in 6:
		var a: Vector3 = ecke.call(k, radius + 0.5)
		var b: Vector3 = ecke.call(k + 1, radius + 0.5)
		for i in 5:
			var t := (i + 1) / 6.0
			var p := a.lerp(b, t)
			_kugel(dach, "Birne%d_%d" % [k, i], 0.04, Vector3(p.x, -0.32 - 0.22 * (1.0 - pow(2.0 * t - 1.0, 2.0)), p.z - zm), m.gluehbirne, Vector3.ONE, false)
	# Theke vorn
	var theke := _gruppe(r, "Theke", Vector3(0, boden, 0.05))
	_box(theke, "Korpus", Vector3(breite - 0.4, 0.95, 0.4), Vector3(0, 0.475, 0), m.holz_hell)
	_box(theke, "Feld", Vector3(breite - 1.0, 0.55, 0.02), Vector3(0, 0.5, 0.21), m.zickzack_rot)
	_box(theke, "Rahmen", Vector3(breite - 0.9, 0.65, 0.015), Vector3(0, 0.5, 0.205), m.gold)
	_box(theke, "Platte", Vector3(breite - 0.3, 0.06, 0.5), Vector3(0, 0.98, 0), m.gruen_samt)
	for i in 6:
		_torus(theke, "Vorrat%d" % i, 0.1, 0.135, Vector3(1.4 + (i % 3) * 0.06, 1.02 + i * 0.035, 0.02), [m.rot, m.blau, m.gold][i % 3])
	# Stufen mit Maßkrügen
	var stufen := _gruppe(r, "Stufen", Vector3(0, boden, 0))
	var krugziele := _gruppe(r, "Krugziele")
	var koerper_stufen := StaticBody3D.new()
	_haengen(stufen, koerper_stufen, "Kollision")
	var hoehen := [0.7, 1.0, 1.3]
	var nr := 0
	for i in 3:
		var z := -1.3 - i * 0.55
		var sb := 3.6 - i * 0.4
		_box(stufen, "Stufe%d" % i, Vector3(sb, hoehen[i], 0.5), Vector3(0, hoehen[i] / 2.0, z), m.holz_dunkel)
		_box(stufen, "Samt%d" % i, Vector3(sb + 0.02, 0.03, 0.52), Vector3(0, hoehen[i] + 0.015, z), m.gruen_samt)
		_box(stufen, "Kante%d" % i, Vector3(sb + 0.04, 0.05, 0.02), Vector3(0, hoehen[i] - 0.03, z + 0.26), m.gold)
		_kollision(koerper_stufen, "Stufe%d" % i, _boxform(Vector3(sb, hoehen[i], 0.5)), Transform3D(Basis(), Vector3(0, hoehen[i] / 2.0, z)))
		var anzahl := 4 - (1 if i == 2 else 0)
		for k in anzahl:
			var x := (k - (anzahl - 1) / 2.0) * 0.8
			var kp := Vector3(x, hoehen[i] + 0.03, z)
			_masskrug(stufen, "Krug%d" % nr, kp)
			_marke(krugziele, "Ziel%d" % nr, Vector3(x, boden + hoehen[i] + 0.25, z))
			nr += 1
	# Preiswand rechts innen
	var preise := _gruppe(r, "Preise", Vector3(breite / 2.0 - 0.15, boden, zm - 0.2), Vector3(0, -90, 0))
	_box(preise, "Lochwand", Vector3(2.2, 1.4, 0.04), Vector3(0, 1.9, 0), m.budenwand)
	for i in 3:
		_teddy(preise, "Teddy%d" % i, Vector3(-0.6 + i * 0.6, 2.35, 0.15), 0.0, 0.9)
		_instanz(preise, SZ + "lebkuchenherz.tscn", "Herz%d" % i, Transform3D(Basis(), Vector3(-0.6 + i * 0.6, 1.7, 0.05)))
	# Kollision, Licht, Kamera, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	var rundform := CylinderShape3D.new()
	rundform.radius = 3.3
	rundform.height = 1.15
	_kollision(koerper, "Podest", rundform, Transform3D(Basis(), Vector3(0, 0.575, zm)))
	_licht(r, "Licht", Vector3(0, boden + 2.5, -1.4), 1.8, 6.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.3, 0.9), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.85, 1.05)
	kamera.rotation_degrees = Vector3(-17, 0, 0)
	kamera.fov = 60
	_haengen(r, kamera, "SpielKamera")
	_marke(r, "BesitzerMitte", Vector3(-1.9, boden, -0.55))
	_marke(r, "BesitzerSeite", Vector3(-2.2, boden, -2.5))
	return r

# ------------------------------------------------------------------ Entenangeln
## Gummiente mit Öse auf dem Kopf, Ursprung auf der Wasserlinie, Blick +Z
func _gummiente(parent: Node3D, name: String, pos: Vector3, wert: int) -> Node3D:
	var e := _gruppe(parent, name, pos)
	e.set_meta("wert", wert)
	# Farbe verrät den Wert: gelb 1, blau 2, rosa 3
	var koerper: Material = m.rosa_lack if wert == 3 else (m.blau if wert == 2 else m.ente)
	_kugel(e, "Bauch", 0.1, Vector3(0, 0.04, 0), koerper, Vector3(1.0, 0.8, 1.25))
	_kugel(e, "Kopf", 0.065, Vector3(0, 0.15, 0.07), koerper)
	_kugel(e, "Schnabel", 0.035, Vector3(0, 0.14, 0.14), m.orange_lack, Vector3(1.2, 0.5, 1.0))
	_kugel(e, "AugeL", 0.012, Vector3(-0.035, 0.17, 0.12), m.schwarz_lack)
	_kugel(e, "AugeR", 0.012, Vector3(0.035, 0.17, 0.12), m.schwarz_lack)
	_kugel(e, "Schwanz", 0.04, Vector3(0, 0.08, -0.12), koerper, Vector3(0.8, 0.6, 1.0))
	_torus(e, "Oese", 0.022, 0.034, Vector3(0, 0.235, 0.05), m.gold, Vector3(90, 0, 0))
	return e

## Offene Bude mit rundem Wasserbecken (Kanal um eine Insel), 14 Enten ziehen im Kreis.
## Die Angel liegt im Becken-Raum (Becken/Angel): Rute vom Griff zur Spitze, Schnur, Haken.
## Wert einer Ente = Metadaten „wert“ (1–3).
func _entenangeln() -> Node3D:
	var r := _neu("Entenangeln")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.8
	var hoehe := 3.0
	var zm := -1.3
	var bz := -1.5            # Beckenmitte
	var wasser := boden + 0.5
	# Runder Pavillon in Türkis-Creme mit geschwungenem Schirmdach
	var radius := 2.6
	_zyl(r, "Podest", radius + 0.15, radius + 0.15, boden, Vector3(0, boden / 2.0, zm), m.holz_dunkel, Vector3.ZERO, 20)
	_zyl(r, "Dielen", radius + 0.05, radius + 0.05, 0.02, Vector3(0, boden + 0.01, zm), m.dielen, Vector3.ZERO, 20)
	_torus(r, "PodestKante", radius + 0.1, radius + 0.24, Vector3(0, boden + 0.02, zm), m.gold)
	var bau := _gruppe(r, "Bau")
	for k in 8:
		var a := TAU * k / 8.0 + TAU / 16.0
		var p := Vector3(sin(a) * (radius - 0.12), boden, zm + cos(a) * (radius - 0.12))
		_zyl(bau, "Pfosten%d" % k, 0.075, 0.065, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.creme_lack, Vector3.ZERO, 10)
		for i in 3:
			_torus(bau, "Ring%d_%d" % [k, i], 0.07, 0.11, p + Vector3(0, 0.75 + i * 0.75, 0), m.messing)
	# Rückseite: türkise Bahnen zwischen den hinteren Pfosten
	for k: int in [3, 4, 5]:
		var a := TAU * k / 8.0
		var mp := Vector3(sin(a) * (radius - 0.1), boden, zm + cos(a) * (radius - 0.1))
		_box(bau, "Wand%d" % k, Vector3(2.15, hoehe, 0.07), Vector3(mp.x, boden + hoehe / 2.0, mp.z), m.streifen_fein_tuerkis, Vector3(0, rad_to_deg(a), 0))
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	_zyl(dach, "Traufring", radius + 0.35, radius + 0.35, 0.14, Vector3(0, 0.07, 0), m.holz_dunkel, Vector3.ZERO, 20)
	# Schirmdach aus drei Stufen — gibt die geschwungene Silhouette
	_zyl(dach, "Schirm1", radius + 0.55, radius - 0.3, 0.5, Vector3(0, 0.35, 0), m.streifen_tuerkis, Vector3.ZERO, 20)
	_zyl(dach, "Schirm2", radius - 0.3, radius - 1.35, 0.5, Vector3(0, 0.8, 0), m.streifen_tuerkis, Vector3.ZERO, 20)
	_zyl(dach, "Schirm3", radius - 1.35, 0.15, 0.7, Vector3(0, 1.35, 0), m.streifen_tuerkis, Vector3.ZERO, 20)
	_zyl(dach, "Wimpelband", radius + 0.6, radius + 0.5, 0.3, Vector3(0, -0.08, 0), m.zickzack_tuerkis, Vector3.ZERO, 20)
	_kugel(dach, "Knauf", 0.14, Vector3(0, 1.75, 0), m.gold)
	# Große Ente als Aushängeschild auf dem Dach
	var schild := _gruppe(dach, "Schildente", Vector3(0, 1.95, 0))
	schild.scale = Vector3.ONE * 2.6
	_gummiente(schild, "Ente", Vector3.ZERO, 1)
	# Theke vorn
	var theke := _gruppe(r, "Theke", Vector3(0, boden, 0.45))
	_box(theke, "Korpus", Vector3(3.6, 0.95, 0.3), Vector3(0, 0.475, 0), m.holz_hell)
	_box(theke, "Feld", Vector3(3.0, 0.55, 0.02), Vector3(0, 0.5, 0.16), m.zickzack_tuerkis)
	_box(theke, "Rahmen", Vector3(3.1, 0.65, 0.015), Vector3(0, 0.5, 0.155), m.gold)
	_box(theke, "Platte", Vector3(3.7, 0.06, 0.42), Vector3(0, 0.98, 0), m.gruen_samt)
	_marke(r, "Fangkorb", Vector3(-1.3, boden + 1.01, 0.45))
	_zyl(theke, "Korb", 0.26, 0.22, 0.14, Vector3(-1.3, 1.08, 0), m.holz_hell, Vector3.ZERO, 16)
	# Becken: Außenwand, Wasser, Insel mit Leuchtturm-Säule und Teddy
	var becken := _gruppe(r, "Becken", Vector3(0, wasser, bz))
	_zyl(becken, "Wand", 1.75, 1.75, 0.6, Vector3(0, -0.35, 0), m.holz_dunkel, Vector3.ZERO, 32)
	_torus(becken, "Rand", 1.66, 1.8, Vector3(0, 0.1, 0), m.gold)
	_zyl(becken, "Wasser", 1.68, 1.68, 0.02, Vector3(0, -0.02, 0), m.wasser, Vector3.ZERO, 32)
	_zyl(becken, "Insel", 0.75, 0.8, 0.5, Vector3(0, 0.05, 0), m.creme_lack, Vector3.ZERO, 24)
	_torus(becken, "InselRand", 0.74, 0.84, Vector3(0, 0.3, 0), m.rot)
	_zyl(becken, "Saeule", 0.14, 0.1, 1.2, Vector3(0, 0.9, 0), m.weiss, Vector3.ZERO, 12)
	for i in 3:
		_torus(becken, "Streifen%d" % i, 0.1, 0.15, Vector3(0, 0.55 + i * 0.35, 0), m.rot)
	_kugel(becken, "Lampe", 0.16, Vector3(0, 1.6, 0), m.gluehbirne)
	_teddy(becken, "Teddy", Vector3(0.0, 0.47, -0.45), 0.0, 1.0)
	var enten := _gruppe(becken, "Enten")
	for i in 14:
		var a := TAU * i / 14.0
		var rr := 1.2 + (0.12 if i % 2 == 0 else -0.08)
		var wert := 1 if i % 3 != 0 else (3 if i % 6 == 0 else 2)
		var ente := _gummiente(enten, "Ente%d" % i, Vector3(sin(a) * rr, 0, cos(a) * rr), wert)
		ente.rotation.y = a + PI / 2.0
	# Angel (vom Spielskript bewegt): Griff an der Theke, Rute, Schnur, Haken
	var angel := _gruppe(becken, "Angel")
	_marke(angel, "Griff", Vector3(0.55, 0.75, 2.05))
	var rute := _gruppe(angel, "Rute")
	_zyl(rute, "Stab", 0.018, 0.008, 1.0, Vector3(0, 0.5, 0), m.holz_hell, Vector3.ZERO, 8)
	_torus(rute, "Rolle", 0.02, 0.045, Vector3(0, 0.15, 0.03), m.messing, Vector3(0, 0, 90))
	var schnur := _gruppe(angel, "Schnur")
	_zyl(schnur, "Faden", 0.004, 0.004, 1.0, Vector3(0, 0.5, 0), m.weiss, Vector3.ZERO, 5)
	var haken := _gruppe(angel, "Haken")
	_kugel(haken, "Blei", 0.025, Vector3.ZERO, m.rot)
	_torus(haken, "Bogen", 0.02, 0.03, Vector3(0, -0.05, 0.0), m.metall, Vector3(90, 0, 0))
	# Preise an der Rückwand des Rundpavillons
	var preise := _gruppe(r, "Preise", Vector3(0, boden, zm - radius + 0.2))
	for i in 3:
		_teddy(preise, "Teddy%d" % i, Vector3(-1.0 + i * 1.0, 2.35, 0.1), 0.0, 1.0 if i == 1 else 0.85)
		_instanz(preise, SZ + "lebkuchenherz.tscn", "Herz%d" % i, Transform3D(Basis(), Vector3(-0.8 + i * 0.8, 1.8, 0.03)))
	# Kollision, Licht, Kamera, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	var rundform := CylinderShape3D.new()
	rundform.radius = radius
	rundform.height = 1.15
	_kollision(koerper, "Podest", rundform, Transform3D(Basis(), Vector3(0, 0.575, zm)))
	_licht(r, "Licht", Vector3(0, boden + 2.6, bz), 1.9, 6.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.4, 1.0), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 2.75, 1.35)
	kamera.rotation_degrees = Vector3(-47, 0, 0)
	kamera.fov = 62
	_haengen(r, kamera, "SpielKamera")
	_marke(r, "BesitzerMitte", Vector3(-2.1, boden, -0.2))
	_marke(r, "BesitzerSeite", Vector3(-2.25, boden, -2.7))
	return r

# ------------------------------------------------------------------ Glücksrad
## Feldwerte im Uhrzeigersinn ab oben — muss zu scripts/kirmes/gluecksrad.gd (WERTE) passen
const RAD_WERTE := [1, 2, 0, 1, 5, 0, 1, 2, 10, 0, 1, 3, 0, 2, 1, 0]

## Bude mit großem Rad an der Rückwand. Rad = Gruppe „Rad“ (dreht um lokal Z),
## Feld k liegt bei Winkel k·22,5° im Uhrzeigersinn von oben.
func _gluecksrad() -> Node3D:
	var r := _neu("Gluecksrad")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.4
	var hoehe := 3.5
	var zm := -1.3
	var radius := 1.2
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "Dielen", Vector3(breite - 0.2, 0.02, tiefe - 0.2), Vector3(0, boden + 0.01, zm), m.dielen)
	_box(r, "PodestKante", Vector3(breite + 0.1, 0.06, 0.06), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	var bau := _gruppe(r, "Bau")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * (breite / 2.0 - 0.1), boden, zm + sz * (tiefe / 2.0 - 0.1))
			_zyl(bau, "Pfosten%s%s" % [sx, sz], 0.08, 0.07, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.gold, Vector3.ZERO, 12)
	# Rückwand mit Strahlenkranz hinter dem Rad, seitlich violette Bahnen
	_box(bau, "Rueckwand", Vector3(breite - 0.2, hoehe, 0.08), Vector3(0, boden + hoehe / 2.0, zm - tiefe / 2.0 + 0.05), m.strahlen_violett)
	for sx: float in [-1.0, 1.0]:
		_box(bau, "Seitenwand%s" % sx, Vector3(0.08, hoehe * 0.8, tiefe - 0.4), Vector3(sx * (breite / 2.0 - 0.05), boden + hoehe * 0.4, zm - 0.1), m.streifen_fein_violett)
	# Schaustellerfassade: hoher Bogen über der Front, mit Goldrahmen und Lampen
	var front := _gruppe(r, "Front", Vector3(0, boden + hoehe, zm + tiefe / 2.0))
	var bogen := 14
	for i in bogen:
		var t := float(i) / (bogen - 1)
		var x := lerpf(-breite / 2.0 - 0.2, breite / 2.0 + 0.2, t)
		var h := 1.5 * sin(PI * t) + 0.25
		_box(front, "Bogen%d" % i, Vector3((breite + 0.4) / bogen + 0.04, h, 0.12), Vector3(x, h / 2.0, 0), m.strahlen_violett)
		_box(front, "BogenRahmen%d" % i, Vector3((breite + 0.4) / bogen + 0.05, 0.12, 0.16), Vector3(x, h, 0), m.gold)
		_kugel(front, "Lampe%d" % i, 0.055, Vector3(x, h + 0.16, 0.08), m.gluehbirne, Vector3.ONE, false)
	_instanz(front, SZ + "krone.tscn", "Krone", Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(0, 1.85, 0)))
	for s: float in [-1.0, 1.0]:
		_instanz(front, SZ + "fahne.tscn", "Fahne%s" % s, Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(s * (breite / 2.0 + 0.1), 0.4, 0)))
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	_box(dach, "Traufe", Vector3(breite + 0.3, 0.16, tiefe + 0.3), Vector3(0, 0.08, 0), m.gold)
	_box(dach, "Plane", Vector3(breite + 0.3, 0.12, tiefe + 0.3), Vector3(0, 0.2, 0), m.streifen_violett)
	_instanz(dach, SZ + "lambrequin_2.tscn", "Volant", Transform3D(Basis().scaled(Vector3(2.4, 1, 1)), Vector3(0, -0.02, tiefe / 2.0 + 0.16)))
	# Rad an der Rückwand
	var mitte := Vector3(0, boden + 1.85, zm - tiefe / 2.0 + 0.32)
	var halter := _gruppe(r, "Halter", mitte)
	_box(halter, "Platte", Vector3(0.5, 0.5, 0.12), Vector3(0, 0, -0.1), m.holz_dunkel)
	_zyl(halter, "Achse", 0.06, 0.06, 0.25, Vector3(0, 0, 0.02), m.messing, Vector3(90, 0, 0), 12)
	var rad := _gruppe(r, "Rad", mitte + Vector3(0, 0, 0.08))
	_zyl(rad, "Scheibe", radius + 0.05, radius + 0.05, 0.06, Vector3.ZERO, m.holz_dunkel, Vector3(90, 0, 0), 32)
	var farben := {0: m.weiss, 1: m.ente, 2: m.huegel, 3: m.orange_lack, 5: m.rot, 10: m.gold}
	var feld := TAU / 16.0
	for k in 16:
		var a := k * feld
		var d := Vector3(sin(a), cos(a), 0)
		var wert: int = RAD_WERTE[k]
		_prisma(rad, "Feld%d" % k, Vector3(2.0 * radius * tan(feld / 2.0) + 0.01, radius, 0.03), d * radius * 0.5 + Vector3(0, 0, 0.045), farben[wert], Vector3(0, 0, rad_to_deg(PI - a)))
		var l := Label3D.new()
		l.text = str(wert)
		l.font_size = 72
		l.pixel_size = 0.004
		l.outline_size = 14
		l.modulate = Color(0.1, 0.06, 0.02) if wert != 5 and wert != 10 else Color(1, 1, 1)
		l.outline_modulate = Color(1, 1, 1, 0.6) if wert != 5 and wert != 10 else Color(0.2, 0.05, 0.02)
		l.position = d * radius * 0.78 + Vector3(0, 0, 0.07)
		l.rotation.z = -a
		_haengen(rad, l, "Zahl%d" % k)
		var b := a + feld / 2.0
		_zyl(rad, "Stift%d" % k, 0.02, 0.02, 0.12, Vector3(sin(b), cos(b), 0) * (radius - 0.04) + Vector3(0, 0, 0.09), m.messing, Vector3(90, 0, 0), 8)
	_torus(rad, "Reif", radius, radius + 0.1, Vector3(0, 0, 0.04), m.gold, Vector3(90, 0, 0))
	_kugel(rad, "Nabe", 0.14, Vector3(0, 0, 0.08), m.gold, Vector3(1, 1, 0.6))
	for i in 24:
		var a := TAU * i / 24.0
		_kugel(rad, "Birne%d" % i, 0.035, Vector3(sin(a), cos(a), 0) * (radius + 0.05) + Vector3(0, 0, 0.1), m.gluehbirne, Vector3.ONE, false)
	# Zeiger oben (dreht nicht mit)
	var zeiger := _gruppe(r, "Zeiger", mitte + Vector3(0, radius + 0.2, 0.2))
	_prisma(zeiger, "Spitze", Vector3(0.22, 0.32, 0.05), Vector3.ZERO, m.rot, Vector3(0, 0, 180))
	_kugel(zeiger, "Knopf", 0.06, Vector3(0, 0.16, 0), m.gold)
	# Theke vorn
	var theke := _gruppe(r, "Theke", Vector3(0, boden, 0.05))
	_box(theke, "Korpus", Vector3(breite - 0.4, 0.95, 0.4), Vector3(0, 0.475, 0), m.holz_hell)
	_box(theke, "Feld", Vector3(breite - 1.0, 0.55, 0.02), Vector3(0, 0.5, 0.21), m.zickzack_violett)
	_box(theke, "Rahmen", Vector3(breite - 0.9, 0.65, 0.015), Vector3(0, 0.5, 0.205), m.gold)
	_box(theke, "Platte", Vector3(breite - 0.3, 0.06, 0.5), Vector3(0, 0.98, 0), m.gruen_samt)
	# Preisregale an den Seiten
	for s: float in [-1.0, 1.0]:
		var regal := _gruppe(r, "Preise%s" % s, Vector3(s * (breite / 2.0 - 0.4), boden, zm - 0.3), Vector3(0, -90.0 * s, 0))
		for e in 3:
			_box(regal, "Brett%d" % e, Vector3(1.8, 0.04, 0.35), Vector3(0, 1.1 + e * 0.6, 0), m.holz_hell)
			for i in 3:
				if e == 2:
					_teddy(regal, "Teddy%d_%d" % [e, i], Vector3(-0.55 + i * 0.55, 1.1 + e * 0.6 + 0.2, 0), 0.0, 0.8)
				else:
					_instanz(regal, SZ + "lebkuchenherz.tscn", "Herz%d_%d" % [e, i], Transform3D(Basis(), Vector3(-0.55 + i * 0.55, 1.1 + e * 0.6 + 0.3, -0.1)))
	# Kollision, Licht, Kamera, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Podest", _boxform(Vector3(breite, 1.15, tiefe)), Transform3D(Basis(), Vector3(0, 0.575, zm)))
	_licht(r, "Radlicht", mitte + Vector3(0, 0.4, 1.4), 2.2, 5.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.6, 0.9), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.85, 1.6)
	kamera.rotation_degrees = Vector3(1.5, 0, 0)
	kamera.fov = 58
	_haengen(r, kamera, "SpielKamera")
	_marke(r, "BesitzerMitte", Vector3(-1.9, boden, -0.45))
	_marke(r, "BesitzerSeite", Vector3(-2.3, boden, -2.4))
	return r

# ------------------------------------------------------------------ Maßkrugstemmen
func _fass(parent: Node3D, name: String, pos: Vector3, liegend := false) -> void:
	var f := _gruppe(parent, name, pos, Vector3(90, 0, 0) if liegend else Vector3.ZERO)
	_zyl(f, "Bauch", 0.32, 0.32, 0.78, Vector3(0, 0.39, 0), m.holz_hell, Vector3.ZERO, 16)
	_zyl(f, "Mitte", 0.35, 0.35, 0.3, Vector3(0, 0.39, 0), m.holz_hell, Vector3.ZERO, 16)
	for y: float in [0.08, 0.3, 0.48, 0.7]:
		_torus(f, "Reif%.2f" % y, 0.32, 0.36, Vector3(0, y, 0), m.metall)
	_zyl(f, "Deckel", 0.3, 0.3, 0.02, Vector3(0, 0.78, 0), m.holz_dunkel, Vector3.ZERO, 16)

## Bühne mit Tafel. Gespielt wird von der Bühne aus Richtung Straße (Kamera blickt +Z).
## Arm mit Maßkrug hängt an der Kamera (SpielKamera/Arm, dreht um lokal X).
func _stemmen() -> Node3D:
	var r := _neu("Stemmen")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.4
	var hoehe := 3.2
	var zm := -1.3
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "Dielen", Vector3(breite - 0.2, 0.02, tiefe - 0.2), Vector3(0, boden + 0.01, zm), m.dielen)
	_box(r, "PodestKante", Vector3(breite + 0.1, 0.06, 0.06), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	# Offene Holzpergola statt Bude: dicke Rundpfosten, Querbalken, Hopfen und
	# ein grünes Zickzack-Band — von allen Seiten einsehbar
	var bau := _gruppe(r, "Bau")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * (breite / 2.0 - 0.15), boden, zm + sz * (tiefe / 2.0 - 0.15))
			_zyl(bau, "Pfosten%s%s" % [sx, sz], 0.16, 0.13, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.holz_hell, Vector3.ZERO, 10)
			_box(bau, "Stuetze%s%s" % [sx, sz], Vector3(0.12, 0.12, 0.7), p + Vector3(0, hoehe - 0.45, -sz * 0.35), m.holz_dunkel, Vector3(35.0 * sz, 0, 0))
			_torus(bau, "Hopfen%s%s" % [sx, sz], 0.13, 0.24, p + Vector3(0, hoehe - 0.35, 0), m.hopfen)
	for sx: float in [-1.0, 1.0]:
		_box(bau, "Laengsbalken%s" % sx, Vector3(0.16, 0.24, tiefe), Vector3(sx * (breite / 2.0 - 0.15), boden + hoehe - 0.1, zm), m.holz_dunkel)
	# Sparren quer über die Pergola, dazwischen Hopfenranken
	for i in 9:
		var x := -breite / 2.0 + 0.4 + i * (breite - 0.8) / 8.0
		_box(bau, "Sparren%d" % i, Vector3(0.1, 0.16, tiefe + 0.5), Vector3(x, boden + hoehe + 0.1, zm), m.holz_hell)
		_kugel(bau, "Ranke%d" % i, 0.13, Vector3(x, boden + hoehe - 0.05, zm + tiefe / 2.0 + 0.2), m.hopfen, Vector3(1.4, 0.9, 0.9))
	_box(bau, "Firstbalken", Vector3(breite + 0.5, 0.2, 0.2), Vector3(0, boden + hoehe + 0.28, zm), m.holz_dunkel)
	_box(bau, "Zierband", Vector3(breite + 0.5, 0.42, 0.06), Vector3(0, boden + hoehe - 0.35, zm + tiefe / 2.0 + 0.24), m.zickzack_gruen)
	_box(bau, "Rueckwand", Vector3(breite - 0.2, hoehe * 0.62, 0.08), Vector3(0, boden + hoehe * 0.31, zm - tiefe / 2.0 + 0.05), m.streifen_fein_gruen)
	for s: float in [-1.0, 1.0]:
		_instanz(bau, SZ + "fahne.tscn", "Fahne%s" % s, Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(s * (breite / 2.0 - 0.15), boden + hoehe + 0.3, zm)))
	# Tafel mit Aufschrift
	var tafel := _gruppe(r, "Tafel", Vector3(0, boden + hoehe - 0.65, zm + tiefe / 2.0 + 0.22))
	_box(tafel, "Brett", Vector3(3.0, 1.0, 0.06), Vector3.ZERO, m.holz_dunkel)
	_box(tafel, "Rahmen", Vector3(3.1, 1.1, 0.04), Vector3(0, 0, -0.02), m.gold)
	# Die Aufschrift hängt in scenes/kirmes/stemmen.tscn (Label3D mit welt_text.gd,
	# übersetzt beim Start) — hier steckt keine Sprache im gebackenen Stand
	_marke(tafel, "TitelPunkt", Vector3(0, 0.1, 0.05))
	for i in 3:
		_masskrug(tafel, "Krug%d" % i, Vector3(-0.5 + i * 0.5, -0.4, 0.12))
	# Kleine Bühne, Fässer, Stehtisch
	var buehne := _gruppe(r, "Buehne", Vector3(0, boden, -1.1))
	_box(buehne, "Block", Vector3(2.4, 0.35, 1.6), Vector3(0, 0.175, 0), m.holz_hell)
	_box(buehne, "Kante", Vector3(2.45, 0.05, 1.65), Vector3(0, 0.35, 0), m.gold)
	_box(buehne, "Stufe", Vector3(1.0, 0.17, 0.35), Vector3(0, 0.085, 0.95), m.holz_dunkel)
	_fass(r, "FassLinks", Vector3(-2.2, boden, -2.4))
	_fass(r, "FassLinksOben", Vector3(-2.2, boden + 0.78, -2.4))
	_fass(r, "FassRechts", Vector3(2.2, boden, -2.4))
	_fass(r, "FassVorn", Vector3(2.25, boden, -0.3))
	var tisch := _gruppe(r, "Stehtisch", Vector3(1.6, boden, -0.9))
	_zyl(tisch, "Fuss", 0.05, 0.05, 1.05, Vector3(0, 0.525, 0), m.metall, Vector3.ZERO, 10)
	_zyl(tisch, "Platte", 0.35, 0.35, 0.05, Vector3(0, 1.07, 0), m.holz_hell, Vector3.ZERO, 20)
	for i in 2:
		_masskrug(tisch, "Krug%d" % i, Vector3(-0.12 + i * 0.22, 1.1, 0.05))
	# Kamera auf der Bühne, Blick zur Straße; Arm mit Krug
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, boden + 0.35 + 1.62, -1.1)
	kamera.rotation_degrees = Vector3(-4, 180, 0)
	kamera.fov = 66
	_haengen(r, kamera, "SpielKamera")
	var arm := _gruppe(kamera, "Arm", Vector3(0.2, -0.3, -0.05))
	_zyl(arm, "Aermel", 0.06, 0.05, 0.7, Vector3(0, 0, -0.35), m.weiss, Vector3(90, 0, 0), 10)
	_zyl(arm, "Stulpe", 0.058, 0.058, 0.06, Vector3(0, 0, -0.7), m.blau, Vector3(90, 0, 0), 10)
	_kugel(arm, "Hand", 0.05, Vector3(0, 0.0, -0.77), m.creme_lack, Vector3(0.9, 1.0, 1.1))
	var krug := _masskrug(arm, "Krug", Vector3(-0.02, -0.1, -0.84))
	krug.scale = Vector3.ONE * 0.95
	krug.rotation_degrees = Vector3(0, 180, 0)
	# Kollision, Licht, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Podest", _boxform(Vector3(breite, 1.15, tiefe)), Transform3D(Basis(), Vector3(0, 0.575, zm)))
	_licht(r, "Licht", Vector3(0, boden + 2.7, -1.0), 1.8, 6.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.4, 0.9), 0.9, 5.0)
	_marke(r, "BesitzerMitte", Vector3(-1.7, boden, 0.0))
	_marke(r, "BesitzerSeite", Vector3(-1.9, boden, -2.3))
	return r

# ------------------------------------------------------------------ Nagelbalken
## Bude mit Baumstamm vorn (Oberfläche voller alter Nägel), in der Mitte der Spielnagel
## „Stamm/Nagel“ (Ursprung = Stammoberfläche). Kamera blickt schräg von oben auf den
## Nagel, der Hammer hängt an der Kamera (SpielKamera/Hammer).
func _nagelbalken() -> Node3D:
	var r := _neu("Nagelbalken")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.4
	var hoehe := 3.0
	var zm := -1.3
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "Dielen", Vector3(breite - 0.2, 0.02, tiefe - 0.2), Vector3(0, boden + 0.01, zm), m.dielen)
	_box(r, "PodestKante", Vector3(breite + 0.1, 0.06, 0.06), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	# Blockhütte: gestapelte Rundhölzer, vorn zwei Stämme als Stützen, steiles Schindeldach
	var bau := _gruppe(r, "Bau")
	var lagen := 9
	for i in lagen:
		var y := boden + 0.16 + i * 0.29
		_zyl(bau, "Stamm%d" % i, 0.15, 0.15, breite, Vector3(0, y, zm - tiefe / 2.0 + 0.15), m.holz_hell, Vector3(0, 0, 90), 10)
		for sx: float in [-1.0, 1.0]:
			if i < lagen - 3:
				_zyl(bau, "Seite%s_%d" % [sx, i], 0.15, 0.15, tiefe - 0.6, Vector3(sx * (breite / 2.0 - 0.15), y, zm - 0.3), m.holz_hell, Vector3(90, 0, 0), 10)
	for sx: float in [-1.0, 1.0]:
		var p := Vector3(sx * (breite / 2.0 - 0.15), boden, zm + tiefe / 2.0 - 0.15)
		_zyl(bau, "Pfosten%s" % sx, 0.17, 0.14, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.holz_dunkel, Vector3.ZERO, 10)
		_box(bau, "Kopfband%s" % sx, Vector3(0.12, 0.5, 0.12), p + Vector3(0, hoehe - 0.3, -0.25), m.holz_dunkel, Vector3(35.0, 0, 0))
	_box(bau, "Querbalken", Vector3(breite, 0.22, 0.22), Vector3(0, boden + hoehe - 0.1, zm + tiefe / 2.0 - 0.15), m.holz_dunkel)
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	_box(dach, "Traufe", Vector3(breite + 0.4, 0.16, tiefe + 0.4), Vector3(0, 0.08, 0), m.holz_dunkel)
	_prisma(dach, "Giebel", Vector3(breite + 0.5, 1.8, tiefe + 0.5), Vector3(0, 1.05, 0), m.schindel, Vector3(0, 90, 0))
	_zyl(dach, "Rauchfang", 0.16, 0.14, 0.9, Vector3(breite / 2.0 - 0.7, 1.8, -0.6), m.stein, Vector3.ZERO, 8)
	for i in 9:
		var t := (i + 0.5) / 9.0
		_kugel(dach, "Birne%d" % i, 0.045, Vector3(-breite / 2.0 + t * breite, -0.3 - 0.2 * (1.0 - pow(2.0 * t - 1.0, 2.0)), tiefe / 2.0 + 0.12), m.gluehbirne, Vector3.ONE, false)
	# Schild
	var tafel := _gruppe(r, "Tafel", Vector3(0, boden + 2.2, zm - tiefe / 2.0 + 0.14))
	_box(tafel, "Brett", Vector3(2.6, 0.8, 0.06), Vector3.ZERO, m.holz_dunkel)
	_box(tafel, "Rahmen", Vector3(2.7, 0.9, 0.04), Vector3(0, 0, -0.02), m.gold)
	_marke(tafel, "TitelPunkt", Vector3(0, 0, 0.05))   # Aufschrift: scenes/kirmes/nagelbalken.tscn
	# Werkzeugwand und Holzstapel
	for i in 3:
		_instanz(r, "res://scenes/kirmes/hammer.tscn", "WandHammer%d" % i, Transform3D(_rot(Vector3(0, 0, 180 + (i - 1) * 12)), Vector3(-1.9 + i * 0.35, boden + 1.9, zm - tiefe / 2.0 + 0.2)))
	for i in 6:
		_zyl(r, "Scheit%d" % i, 0.12, 0.12, 0.9, Vector3(1.9 + (i % 3) * 0.26 - 0.26, boden + 0.12 + (i / 3) * 0.22, -2.4), m.holz_hell, Vector3(0, 0, 90), 10)
	# Baumstamm mit altem Nagelfeld
	var stamm := _gruppe(r, "Stamm", Vector3(0, boden, -0.9))
	_zyl(stamm, "Rinde", 0.47, 0.5, 0.85, Vector3(0, 0.425, 0), m.holz_dunkel, Vector3.ZERO, 20)
	_zyl(stamm, "Schnitt", 0.44, 0.44, 0.02, Vector3(0, 0.86, 0), m.holz_hell, Vector3.ZERO, 20)
	for i in 3:
		_torus(stamm, "Jahresring%d" % i, 0.1 + i * 0.1, 0.11 + i * 0.1, Vector3(0, 0.871, 0), m.holz_dunkel)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 22:
		var a := rng.randf() * TAU
		var rr := rng.randf_range(0.14, 0.4)
		_zyl(stamm, "AlterNagel%d" % i, 0.012, 0.012, 0.008, Vector3(cos(a) * rr, 0.875, sin(a) * rr), m.metall, _rot(Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8))).get_euler() * 57.3, 8)
	var nagel := _gruppe(stamm, "Nagel", Vector3(0, 0.87, 0))
	_zyl(nagel, "Schaft", 0.007, 0.004, 0.2, Vector3(0, 0.02, 0), m.metall, Vector3.ZERO, 8)
	_zyl(nagel, "Kopf", 0.02, 0.02, 0.012, Vector3(0, 0.125, 0), m.messing, Vector3.ZERO, 12)
	var koerper_stamm := StaticBody3D.new()
	_haengen(stamm, koerper_stamm, "Kollision")
	var zylform := CylinderShape3D.new()
	zylform.radius = 0.5
	zylform.height = 0.85
	_kollision(koerper_stamm, "Form", zylform, Transform3D(Basis(), Vector3(0, 0.425, 0)))
	# Kollision, Licht, Kamera mit Hammer, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Rueckbereich", _boxform(Vector3(breite, 1.15, 1.6)), Transform3D(Basis(), Vector3(0, 0.575, -2.2)))
	_licht(r, "Licht", Vector3(0, boden + 2.4, -0.9), 1.8, 5.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.4, 0.9), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, boden + 1.6, -0.25)
	kamera.rotation_degrees = Vector3(-52, 0, 0)
	kamera.fov = 58
	_haengen(r, kamera, "SpielKamera")
	# Griff unten rechts im Bild, Kopf zeigt nach vorn über den Nagel
	_instanz(kamera, "res://scenes/kirmes/hammer.tscn", "Hammer", Transform3D(_rot(Vector3(-72, 0, 18)).scaled(Vector3.ONE * 0.55), Vector3(0.2, -0.26, -0.3)))
	_marke(r, "BesitzerMitte", Vector3(-1.9, boden, -0.3))
	_marke(r, "BesitzerSeite", Vector3(-2.3, boden, -2.5))
	return r

# ------------------------------------------------------------------ Bierfass-Kegeln
func _kegelkugel() -> Node3D:
	var r := _neu("Kegelkugel", "RigidBody3D")
	var rb := r as RigidBody3D
	rb.mass = 2.5
	rb.continuous_cd = true
	_kugel(r, "Holz", 0.095, Vector3.ZERO, m.holz_dunkel)
	_torus(r, "Band", 0.088, 0.1, Vector3.ZERO, m.gold, Vector3(0, 0, 90))
	var f := SphereShape3D.new()
	f.radius = 0.095
	_kollision(r, "Form", f, Transform3D())
	return r

## Bude mit kurzer Kegelbahn (Start lokal z 0,3, Kegel hinten bei z −2,6), Fangraum mit
## Polsterwand, Seitenbanden. Kegel = RigidBody-Fässchen unter „Kegel“.
func _kegeln() -> Node3D:
	var r := _neu("Kegeln")
	var boden := 0.2
	var breite := 5.6
	var tiefe := 3.6
	var hoehe := 3.0
	var zm := -1.3
	var bahn_b := 1.1
	var bahn_y := boden + 0.06
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "PodestKante", Vector3(breite + 0.1, 0.06, 0.06), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	# Tonnendach-Halle in Orange-Creme: gebogene Plane auf Bügeln, offene Front
	var bau := _gruppe(r, "Bau")
	for sx: float in [-1.0, 1.0]:
		var p := Vector3(sx * (breite / 2.0 - 0.1), boden, zm + tiefe / 2.0 - 0.15)
		_zyl(bau, "Pfosten%s" % sx, 0.09, 0.08, hoehe * 0.72, p + Vector3(0, hoehe * 0.36, 0), m.creme_lack, Vector3.ZERO, 10)
		_torus(bau, "Reif%s" % sx, 0.08, 0.13, p + Vector3(0, hoehe * 0.6, 0), m.orange_lack)
	_box(bau, "Rueckwand", Vector3(breite - 0.2, hoehe * 0.8, 0.08), Vector3(0, boden + hoehe * 0.4, zm - tiefe / 2.0 + 0.05), m.streifen_fein_orange)
	for sx: float in [-1.0, 1.0]:
		_box(bau, "Seitenwand%s" % sx, Vector3(0.08, hoehe * 0.55, tiefe - 0.3), Vector3(sx * (breite / 2.0 - 0.05), boden + hoehe * 0.275, zm - 0.1), m.streifen_orange)
	# Tonnendach: schmale Latten entlang eines Halbkreises
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe * 0.72, zm))
	var segmente := 13
	for i in segmente:
		var a := PI * (i + 0.5) / segmente
		var hr := breite / 2.0 + 0.25
		var pos := Vector3(cos(a) * hr, sin(a) * 0.95, 0)
		_box(dach, "Latte%d" % i, Vector3(hr * PI / segmente + 0.04, 0.12, tiefe + 0.4), pos, m.streifen_orange, Vector3(0, 0, rad_to_deg(a) - 90.0))
	for sz: float in [-1.0, 1.0]:
		for i in segmente:
			var a := PI * (i + 0.5) / segmente
			_box(dach, "Bogen%s_%d" % [sz, i], Vector3((breite / 2.0 + 0.3) * PI / segmente + 0.05, 0.1, 0.1),
				Vector3(cos(a) * (breite / 2.0 + 0.3), sin(a) * 1.0, sz * (tiefe / 2.0 + 0.2)), m.gold, Vector3(0, 0, rad_to_deg(a) - 90.0))
	for i in 9:
		var t := (i + 0.5) / 9.0
		_kugel(dach, "Birne%d" % i, 0.045, Vector3(-breite / 2.0 + t * breite, 0.15 + sin(PI * t) * 0.85, tiefe / 2.0 + 0.24), m.gluehbirne, Vector3.ONE, false)
	_instanz(dach, SZ + "fahne.tscn", "Fahne", Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(0, 1.05, tiefe / 2.0)))
	var tafel := _gruppe(r, "Tafel", Vector3(0, boden + 2.25, zm - tiefe / 2.0 + 0.12))
	_box(tafel, "Brett", Vector3(2.6, 0.7, 0.06), Vector3.ZERO, m.holz_dunkel)
	_box(tafel, "Rahmen", Vector3(2.7, 0.8, 0.04), Vector3(0, 0, -0.02), m.gold)
	_marke(tafel, "TitelPunkt", Vector3(0, 0, 0.05))   # Aufschrift: scenes/kirmes/kegeln.tscn
	# Bahn mit Banden, Fangraum und Polsterwand
	var bahn := _gruppe(r, "Bahn")
	_box(bahn, "Belag", Vector3(bahn_b, 0.06, 3.3), Vector3(0, boden + 0.03, -1.25), m.dielen)
	for s: float in [-1.0, 1.0]:
		_box(bahn, "Bande%s" % s, Vector3(0.08, 0.16, 3.3), Vector3(s * (bahn_b / 2.0 + 0.04), bahn_y + 0.08, -1.25), m.holz_dunkel)
		_box(bahn, "BandeGold%s" % s, Vector3(0.09, 0.02, 3.3), Vector3(s * (bahn_b / 2.0 + 0.04), bahn_y + 0.17, -1.25), m.gold)
	_box(bahn, "Fang", Vector3(bahn_b + 0.2, 0.02, 0.4), Vector3(0, boden + 0.01, -3.0), m.schwarz_lack)
	_box(bahn, "Polster", Vector3(bahn_b + 0.4, 0.6, 0.12), Vector3(0, boden + 0.3, -3.2), m.vorhang_rot)
	_box(bahn, "Startlinie", Vector3(bahn_b, 0.005, 0.04), Vector3(0, bahn_y + 0.003, 0.1), m.weiss)
	var koerper_bahn := StaticBody3D.new()
	_haengen(bahn, koerper_bahn, "Kollision")
	_kollision(koerper_bahn, "Belag", _boxform(Vector3(bahn_b, 0.06, 3.3)), Transform3D(Basis(), Vector3(0, boden + 0.03, -1.25)))
	for s: float in [-1.0, 1.0]:
		_kollision(koerper_bahn, "Bande%s" % s, _boxform(Vector3(0.08, 0.4, 3.3)), Transform3D(Basis(), Vector3(s * (bahn_b / 2.0 + 0.04), bahn_y + 0.2, -1.25)))
	_kollision(koerper_bahn, "Fang", _boxform(Vector3(bahn_b + 0.2, 0.02, 0.4)), Transform3D(Basis(), Vector3(0, boden + 0.01, -3.0)))
	_kollision(koerper_bahn, "Polster", _boxform(Vector3(bahn_b + 0.4, 0.6, 0.12)), Transform3D(Basis(), Vector3(0, boden + 0.3, -3.2)))
	# 9 Fässchen als Kegel in Rautenform
	var kegel := _gruppe(r, "Kegel")
	var reihen := [1, 2, 3, 2, 1]
	var form := CylinderShape3D.new()
	form.radius = 0.055
	form.height = 0.26
	var nr := 0
	for ri in reihen.size():
		for k in int(reihen[ri]):
			var x := (k - (int(reihen[ri]) - 1) / 2.0) * 0.19
			var z := -2.0 - ri * 0.16
			var kg := RigidBody3D.new()
			kg.mass = 0.45
			kg.position = Vector3(x, bahn_y + 0.13, z)
			kg.can_sleep = true
			kg.sleeping = true
			_haengen(kegel, kg, "Kegel%d" % nr)
			_zyl(kg, "Fass", 0.05, 0.05, 0.26, Vector3.ZERO, m.holz_hell, Vector3.ZERO, 12)
			_zyl(kg, "Bauch", 0.058, 0.058, 0.1, Vector3.ZERO, m.holz_hell, Vector3.ZERO, 12)
			for y: float in [-0.09, 0.09]:
				_torus(kg, "Reif%.2f" % y, 0.05, 0.062, Vector3(0, y, 0), m.metall)
			_zyl(kg, "Deckel", 0.046, 0.046, 0.01, Vector3(0, 0.131, 0), m.rot if nr == 4 else m.holz_dunkel, Vector3.ZERO, 12)
			_kollision(kg, "Form", form, Transform3D())
			nr += 1
	# Kugelablage und Fässer an den Seiten
	var ablage := _gruppe(r, "Kugelablage", Vector3(0.95, boden, 0.2))
	_box(ablage, "Bock", Vector3(0.5, 0.6, 0.3), Vector3(0, 0.3, 0), m.holz_dunkel)
	for i in 3:
		_kugel(ablage, "Kugel%d" % i, 0.095, Vector3(-0.15 + i * 0.15, 0.7, 0), m.holz_dunkel)
	_fass(r, "FassLinks", Vector3(-2.1, boden, -2.5))
	_fass(r, "FassLinks2", Vector3(-2.1, boden, -1.7))
	_fass(r, "FassRechts", Vector3(2.1, boden, -2.5))
	_fass(r, "FassRechtsOben", Vector3(2.1, boden + 0.78, -2.5))
	# Kollision (ohne Bahn), Licht, Kamera, Marken
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	for s: float in [-1.0, 1.0]:
		_kollision(koerper, "Seite%s" % s, _boxform(Vector3(2.0, 1.15, tiefe)), Transform3D(Basis(), Vector3(s * 1.8, 0.575, zm)))
	_kollision(koerper, "Hinten", _boxform(Vector3(breite, 1.15, 0.4)), Transform3D(Basis(), Vector3(0, 0.575, zm - tiefe / 2.0 + 0.2)))
	_licht(r, "Licht", Vector3(0, boden + 2.5, -2.2), 2.0, 5.0)
	_licht(r, "Frontlicht", Vector3(0, boden + 2.4, 0.9), 0.9, 5.0)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, boden + 0.85, 0.95)
	kamera.rotation_degrees = Vector3(-13, 0, 0)
	kamera.fov = 55
	_haengen(r, kamera, "SpielKamera")
	_marke(r, "Wurfpunkt", Vector3(0, bahn_y + 0.1, 0.2))
	_marke(r, "BesitzerMitte", Vector3(-1.5, boden, 0.2))
	_marke(r, "BesitzerSeite", Vector3(-2.2, boden, -0.9))
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
		_zyl(turm, "Pfosten%s" % s, 0.06, 0.05, turm_h + 0.3, Vector3(s * 0.55, 0.5 + (turm_h + 0.3) / 2.0, 0), m.orange_lack, Vector3.ZERO, 10)
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
	_box(huette, "WandLinks", Vector3(0.1, 2.4, 2.4), Vector3(-1.1, 1.2, 0), m.streifen_fein_orange)
	_box(huette, "Theke", Vector3(1.9, 1.0, 0.45), Vector3(-0.1, 0.5, 1.0), m.holz_hell)
	_box(huette, "ThekeFeld", Vector3(1.6, 0.6, 0.02), Vector3(-0.1, 0.5, 1.235), m.zickzack_orange)
	_box(huette, "ThekePlatte", Vector3(2.0, 0.05, 0.55), Vector3(-0.1, 1.02, 1.0), m.gruen_samt)
	_box(huette, "Dach", Vector3(2.6, 0.08, 2.9), Vector3(0, 2.6, 0.1), m.streifen_orange, Vector3(-10, 0, 0))
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
		_prisma(wimpel, "Wimpel%d" % i, Vector3(0.22, 0.28, 0.01), p - Vector3(0, 0.14, 0), m.orange_lack if i % 2 == 0 else m.weiss, Vector3(0, 60, 180))
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

# ------------------------------------------------------------------ Markt- und Essensbuden
## Deko-Buden ohne Spiel: typische Kirmesstände. Je Typ Farbschema und Dachform.
## Dachformen: pult (mit Markise), giebel, rund (kleines Kegelzelt), grill (Pult mit Rauchfang)
const MARKTBUDEN := {
	"bratwurst": ["rot", "grill"],
	"hendl": ["orange", "grill"],
	"steckerlfisch": ["tuerkis", "grill"],
	"brezn": ["gruen", "giebel"],
	"mandeln": ["violett", "pult"],
	"zuckerwatte": ["rot", "rund"],
	"lebkuchen": ["rot", "giebel"],
	"losbude": ["gruen", "pult"],
	"hutstand": ["orange", "pult"],
	"ausschank": ["tuerkis", "rund"],
	"softeis": ["tuerkis", "spitz"],
	"crepes": ["violett", "giebel"],
	"magenbrot": ["orange", "spitz"],
	"schokofruechte": ["rot", "doppel"],
	"fischbroetchen": ["tuerkis", "pult"],
	"luftballons": ["gruen", "spitz"],
	"schmalzkuchen": ["orange", "doppel"],
}

func _marktbude(typ: String) -> Node3D:
	var art: Array = MARKTBUDEN[typ]
	var schema: String = art[0]
	var dachform: String = art[1]
	var streifen: Material = m["streifen_" + schema]
	var streifen_fein: Material = m["streifen_fein_" + schema]
	var zickzack: Material = m["zickzack_" + schema]
	var r := _neu(typ.capitalize())
	var boden := 0.18
	var breite := 4.6
	var tiefe := 2.6
	var hoehe := 2.5
	var zm := -0.9
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "Dielen", Vector3(breite - 0.16, 0.02, tiefe - 0.16), Vector3(0, boden + 0.01, zm), m.dielen)
	_box(r, "PodestKante", Vector3(breite + 0.08, 0.05, 0.05), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	var bau := _gruppe(r, "Bau")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * (breite / 2.0 - 0.08), boden, zm + sz * (tiefe / 2.0 - 0.08))
			_zyl(bau, "Pfosten%s%s" % [sx, sz], 0.07, 0.06, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.creme_lack, Vector3.ZERO, 8)
	_box(bau, "Rueckwand", Vector3(breite - 0.16, hoehe, 0.07), Vector3(0, boden + hoehe / 2.0, zm - tiefe / 2.0 + 0.05), streifen_fein)
	for sx: float in [-1.0, 1.0]:
		_box(bau, "Seitenwand%s" % sx, Vector3(0.07, hoehe * 0.6, tiefe - 0.3), Vector3(sx * (breite / 2.0 - 0.04), boden + hoehe * 0.3, zm - 0.05), streifen_fein)
	var theke := _gruppe(r, "Theke", Vector3(0, boden, zm + tiefe / 2.0 - 0.3))
	_box(theke, "Korpus", Vector3(breite - 0.3, 0.92, 0.45), Vector3(0, 0.46, 0), m.holz_hell)
	_box(theke, "Feld", Vector3(breite - 0.8, 0.5, 0.02), Vector3(0, 0.48, 0.235), zickzack)
	_box(theke, "Platte", Vector3(breite - 0.1, 0.06, 0.55), Vector3(0, 0.95, 0), m.gruen_samt)
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	match dachform:
		"giebel":
			_box(dach, "Traufe", Vector3(breite + 0.3, 0.12, tiefe + 0.3), Vector3(0, 0.06, 0), m.holz_dunkel)
			_prisma(dach, "Giebel", Vector3(tiefe + 0.4, 0.85, breite + 0.4), Vector3(0, 0.55, 0), streifen, Vector3(0, 90, 0))
		"spitz":
			# Zeltdach: vierseitige Spitze mit Wimpel
			_box(dach, "Traufe", Vector3(breite + 0.3, 0.12, tiefe + 0.3), Vector3(0, 0.06, 0), m.holz_dunkel)
			var zelt := _gruppe(dach, "Zeltdach")
			zelt.scale = Vector3(1.0, 1.0, (tiefe + 0.5) / (breite + 0.5))
			_zyl(zelt, "Spitze", (breite + 0.5) * 0.72, 0.05, 1.6, Vector3(0, 0.92, 0), streifen, Vector3(0, 45, 0), 4)
			_zyl(dach, "Mast", 0.03, 0.03, 0.8, Vector3(0, 2.0, 0), m.gold, Vector3.ZERO, 6)
			_prisma(dach, "Wimpel", Vector3(0.5, 0.3, 0.02), Vector3(0.26, 2.22, 0), m.rot, Vector3(0, 0, -90))
		"doppel":
			# zweistufiges Dach mit Zierfries dazwischen
			_box(dach, "Traufe", Vector3(breite + 0.3, 0.12, tiefe + 0.3), Vector3(0, 0.06, 0), m.holz_dunkel)
			_prisma(dach, "Unten", Vector3(tiefe + 0.4, 0.5, breite + 0.4), Vector3(0, 0.37, 0), streifen, Vector3(0, 90, 0))
			_box(dach, "Fries", Vector3(breite * 0.62, 0.36, tiefe * 0.5), Vector3(0, 0.66, 0), zickzack)
			_prisma(dach, "Oben", Vector3(tiefe * 0.6, 0.55, breite * 0.7), Vector3(0, 1.11, 0), streifen, Vector3(0, 90, 0))
			for sx: float in [-1.0, 1.0]:
				_kugel(dach, "Knauf%s" % sx, 0.09, Vector3(sx * breite * 0.34, 1.42, 0), m.gold)
		"rund":
			_zyl(dach, "Traufring", breite * 0.62, breite * 0.62, 0.12, Vector3(0, 0.06, 0), m.holz_dunkel, Vector3.ZERO, 12)
			_zyl(dach, "Kegel", breite * 0.66, 0.16, 1.2, Vector3(0, 0.7, 0), streifen, Vector3.ZERO, 12)
			_kugel(dach, "Knauf", 0.12, Vector3(0, 1.35, 0), m.gold)
		_:
			_box(dach, "Pult", Vector3(breite + 0.4, 0.12, tiefe + 0.7), Vector3(0, 0.22, 0.1), streifen, Vector3(-12, 0, 0))
			if dachform == "grill":
				_zyl(dach, "Rauchfang", 0.14, 0.12, 1.0, Vector3(breite / 2.0 - 0.6, 0.7, -0.6), m.metall, Vector3.ZERO, 8)
				_torus(dach, "Kappe", 0.13, 0.19, Vector3(breite / 2.0 - 0.6, 1.2, -0.6), m.schwarz_lack)
	_box(dach, "Markise", Vector3(breite + 0.3, 0.4, 0.05), Vector3(0, -0.12, tiefe / 2.0 + 0.22), zickzack)
	for i in 7:
		var t := (i + 0.5) / 7.0
		_kugel(dach, "Birne%d" % i, 0.035, Vector3(-breite / 2.0 + t * breite, -0.3, tiefe / 2.0 + 0.24), m.gluehbirne, Vector3.ONE, false)
	_marktauslage(r, typ, boden, tiefe, zm)
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Bude", _boxform(Vector3(breite, 1.1, tiefe)), Transform3D(Basis(), Vector3(0, 0.55, zm)))
	_licht(r, "Licht", Vector3(0, boden + 2.1, zm + 0.2), 1.2, 4.5)
	_marke(r, "Verkaeufer", Vector3(0, boden, zm - 0.35))
	return r

## Auslage und Aufbauten je Budentyp (lokal zur Bude, y ab Podestoberkante)
func _marktauslage(r: Node3D, typ: String, boden: float, tiefe: float, zm: float) -> void:
	var a := _gruppe(r, "Auslage", Vector3(0, boden, zm))
	var t_y := 0.95
	var t_z := tiefe / 2.0 - 0.3
	var schild_z := tiefe / 2.0 + 0.32   # vor der Dachtraufe, damit das Schild nicht im Dach steckt
	match typ:
		"bratwurst":
			_box(a, "Grill", Vector3(2.0, 0.22, 0.7), Vector3(-0.5, 0.85, -0.2), m.metall)
			_box(a, "Glut", Vector3(1.85, 0.04, 0.6), Vector3(-0.5, 0.97, -0.2), m.rot)
			for i in 9:
				_zyl(a, "Wurst%d" % i, 0.045, 0.045, 0.26, Vector3(-1.35 + i * 0.21, 1.04, -0.2 + (i % 2) * 0.12), m.orange_lack, Vector3(90, 8.0 * i, 0), 8)
			_zyl(a, "Senf", 0.06, 0.05, 0.22, Vector3(1.4, t_y + 0.11, t_z), m.ente, Vector3.ZERO, 8)
			_zyl(a, "Ketchup", 0.06, 0.05, 0.22, Vector3(1.6, t_y + 0.11, t_z), m.rot, Vector3.ZERO, 8)
			var w := _gruppe(a, "Schildwurst", Vector3(0, 2.75, schild_z), Vector3(0, 0, 20))
			_zyl(w, "Wurst", 0.16, 0.16, 1.1, Vector3.ZERO, m.orange_lack, Vector3(0, 0, 90), 12)
			_kugel(w, "EndeL", 0.16, Vector3(-0.55, 0, 0), m.orange_lack)
			_kugel(w, "EndeR", 0.16, Vector3(0.55, 0, 0), m.orange_lack)
		"hendl":
			for reihe in 2:
				var y := 1.05 + reihe * 0.42
				_zyl(a, "Spiess%d" % reihe, 0.02, 0.02, 2.4, Vector3(0, y, -0.3), m.metall, Vector3(0, 0, 90), 6)
				for i in 5:
					_kugel(a, "Hendl%d_%d" % [reihe, i], 0.14, Vector3(-1.0 + i * 0.5, y, -0.3), m.orange_lack, Vector3(1.4, 1.0, 1.0))
			_box(a, "Tropfblech", Vector3(2.4, 0.05, 0.5), Vector3(0, 0.85, -0.3), m.metall)
			_kugel(a, "Schildhendl", 0.4, Vector3(0, 2.8, schild_z), m.orange_lack, Vector3(1.5, 1.0, 1.0))
		"steckerlfisch":
			_box(a, "Glutbett", Vector3(2.2, 0.16, 0.6), Vector3(0, 0.85, -0.25), m.schwarz_lack)
			for i in 7:
				var g := _gruppe(a, "Stecken%d" % i, Vector3(-1.1 + i * 0.36, 0.95, -0.25), Vector3(-35, 0, 0))
				_zyl(g, "Stab", 0.02, 0.015, 1.1, Vector3(0, 0.55, 0), m.holz_hell, Vector3.ZERO, 6)
				_kugel(g, "Fisch", 0.11, Vector3(0, 0.85, 0), m.creme_lack, Vector3(0.7, 0.55, 2.0))
			_kugel(a, "Schildfisch", 0.38, Vector3(0, 2.8, schild_z), m.glas, Vector3(0.6, 0.5, 2.0))
		"brezn":
			_zyl(a, "Stange", 0.05, 0.05, 1.5, Vector3(-1.1, 1.6, -0.4), m.holz_dunkel, Vector3.ZERO, 8)
			_zyl(a, "Querstange", 0.04, 0.04, 2.6, Vector3(0, 2.25, -0.4), m.holz_dunkel, Vector3(0, 0, 90), 8)
			for i in 6:
				_instanz(a, "res://scenes/einrichtung/riesenbrezel.tscn", "Brezn%d" % i,
					Transform3D(Basis().scaled(Vector3.ONE * 0.32), Vector3(-1.1 + i * 0.44, 1.95, -0.4)))
			for i in 4:
				_instanz(a, "res://scenes/einrichtung/riesenbrezel.tscn", "Theke%d" % i,
					Transform3D(_rot(Vector3(80, 0, 0)).scaled(Vector3.ONE * 0.22), Vector3(-0.9 + i * 0.6, t_y + 0.1, t_z)))
			_instanz(a, "res://scenes/einrichtung/riesenbrezel.tscn", "Schild",
				Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(0, 2.85, schild_z)))
		"mandeln":
			_zyl(a, "Kessel", 0.42, 0.36, 0.4, Vector3(-0.9, 1.1, -0.2), m.messing, Vector3.ZERO, 16)
			_torus(a, "Kesselrand", 0.42, 0.5, Vector3(-0.9, 1.3, -0.2), m.gold)
			_zyl(a, "Ruehrer", 0.03, 0.03, 0.8, Vector3(-0.9, 1.55, -0.2), m.holz_hell, Vector3(20, 0, 0), 6)
			for i in 8:
				_kugel(a, "Mandel%d" % i, 0.05, Vector3(-1.05 + (i % 4) * 0.1, 1.32, -0.3 + (i / 4) * 0.12), m.holz_dunkel)
			for i in 5:
				_prisma(a, "Tuete%d" % i, Vector3(0.18, 0.3, 0.12), Vector3(0.4 + i * 0.28, t_y + 0.15, t_z), m.creme_lack, Vector3(0, 0, 180))
			_zyl(a, "Schildtuete", 0.3, 0.05, 0.7, Vector3(0, 2.85, schild_z), m.creme_lack, Vector3(180, 0, 0), 10)
		"zuckerwatte":
			_zyl(a, "Maschine", 0.35, 0.35, 0.4, Vector3(-0.9, 1.1, -0.2), m.metall, Vector3.ZERO, 14)
			_zyl(a, "Trommel", 0.22, 0.22, 0.2, Vector3(-0.9, 1.4, -0.2), m.rosa_lack, Vector3.ZERO, 12)
			for i in 6:
				var g := _gruppe(a, "Watte%d" % i, Vector3(0.1 + i * 0.36, 0.95, t_z - 0.05))
				_zyl(g, "Stab", 0.015, 0.015, 0.5, Vector3(0, 0.25, 0), m.weiss, Vector3.ZERO, 6)
				_kugel(g, "Wolke", 0.17, Vector3(0, 0.6, 0), m.rosa_lack if i % 2 == 0 else m.blau, Vector3(1.0, 0.9, 1.0))
			for i in 4:
				_kugel(a, "Popcorn%d" % i, 0.12, Vector3(-1.6 + i * 0.22, t_y + 0.12, t_z), m.creme_lack)
			_kugel(a, "Schildwatte", 0.42, Vector3(0, 2.8, schild_z), m.rosa_lack)
		"lebkuchen":
			for reihe in 3:
				var y := 1.05 + reihe * 0.5
				_zyl(a, "Leine%d" % reihe, 0.015, 0.015, 3.6, Vector3(0, y + 0.25, -0.5), m.holz_dunkel, Vector3(0, 0, 90), 6)
				for i in 5:
					_instanz(a, SZ + "lebkuchenherz.tscn", "Herz%d_%d" % [reihe, i],
						Transform3D(Basis().scaled(Vector3.ONE * 0.9), Vector3(-1.5 + i * 0.75, y, -0.5)))
			_instanz(a, SZ + "lebkuchenherz.tscn", "Schildherz",
				Transform3D(Basis().scaled(Vector3.ONE * 2.2), Vector3(0, 2.9, schild_z)))
		"losbude":
			_zyl(a, "Trommel", 0.35, 0.35, 0.5, Vector3(-1.1, 1.25, -0.1), m.gold, Vector3(0, 0, 90), 12)
			_zyl(a, "Kurbel", 0.03, 0.03, 0.3, Vector3(-1.45, 1.25, -0.1), m.metall, Vector3(0, 0, 90), 6)
			_box(a, "Gestell", Vector3(0.1, 0.9, 0.1), Vector3(-1.1, 0.8, -0.1), m.holz_dunkel)
			for reihe in 2:
				_box(a, "Regal%d" % reihe, Vector3(2.2, 0.05, 0.3), Vector3(0.7, 1.15 + reihe * 0.55, -0.6), m.holz_hell)
				for i in 3:
					_teddy(a, "Teddy%d_%d" % [reihe, i], Vector3(0.0 + i * 0.7, 1.35 + reihe * 0.55, -0.6), 0.0, 0.8)
			for i in 12:
				_box(a, "Los%d" % i, Vector3(0.12, 0.16, 0.01), Vector3(-1.9 + (i % 6) * 0.18, 0.95 + (i / 6) * 0.2, t_z), m.creme_lack)
			_kugel(a, "Schildstern", 0.32, Vector3(0, 2.8, schild_z), m.gold, Vector3(1.0, 1.0, 0.4))
		"hutstand":
			for i in 6:
				var g := _gruppe(a, "Hut%d" % i, Vector3(-1.5 + (i % 3) * 0.9, 0.9 + (i / 3) * 0.55, -0.35))
				_zyl(g, "Staender", 0.03, 0.03, 0.3, Vector3(0, 0.15, 0), m.metall, Vector3.ZERO, 6)
				_zyl(g, "Kopf", 0.16, 0.15, 0.2, Vector3(0, 0.4, 0), m.huegel if i % 2 == 0 else m.holz_dunkel, Vector3.ZERO, 12)
				_torus(g, "Krempe", 0.15, 0.28, Vector3(0, 0.32, 0), m.huegel if i % 2 == 0 else m.holz_dunkel)
				_zyl(g, "Band", 0.162, 0.162, 0.06, Vector3(0, 0.34, 0), m.rot, Vector3.ZERO, 12)
			for i in 5:
				_kugel(a, "Ballon%d" % i, 0.16, Vector3(1.3 + (i % 2) * 0.3, 2.2 + i * 0.12, t_z - 0.2), [m.rot, m.blau, m.ente, m.huegel, m.rosa_lack][i])
			_zyl(a, "Schildhut", 0.34, 0.32, 0.26, Vector3(0, 2.85, schild_z), m.huegel, Vector3.ZERO, 12)
			_torus(a, "Schildkrempe", 0.32, 0.55, Vector3(0, 2.72, schild_z), m.huegel)
		"softeis":
			# Eismaschine mit zwei Zapfhähnen, Waffeltüten, Eisbecher
			_box(a, "Maschine", Vector3(0.7, 0.9, 0.55), Vector3(-1.2, 1.4, -0.35), m.weiss)
			_box(a, "Blende", Vector3(0.72, 0.25, 0.57), Vector3(-1.2, 1.95, -0.35), m.blau)
			for i in 2:
				_zyl(a, "Hahn%d" % i, 0.04, 0.03, 0.22, Vector3(-1.35 + i * 0.3, 1.0, -0.02), m.metall, Vector3.ZERO, 8)
			for i in 6:
				var g := _gruppe(a, "Eis%d" % i, Vector3(-0.3 + i * 0.32, t_y, t_z))
				var sorte: Material = [m.weiss, m.rosa_lack, m.holz_dunkel][i % 3]
				_zyl(g, "Waffel", 0.05, 0.012, 0.2, Vector3(0, 0.12, 0), m.lebkuchen, Vector3(180, 0, 0), 8)
				_kugel(g, "Kugel", 0.07, Vector3(0, 0.25, 0), sorte)
				_kugel(g, "Spitze", 0.045, Vector3(0, 0.33, 0), sorte)
			var s := _gruppe(a, "Schildeis", Vector3(0, 2.5, schild_z))
			_zyl(s, "Waffel", 0.3, 0.04, 0.9, Vector3.ZERO, m.lebkuchen, Vector3(180, 0, 0), 12)
			_kugel(s, "Kugel", 0.34, Vector3(0, 0.55, 0), m.rosa_lack)
			_kugel(s, "Haube", 0.22, Vector3(0, 0.88, 0), m.weiss)
		"crepes":
			# zwei runde Crêpe-Platten, Teigschüssel, Gläser mit Aufstrich
			for i in 2:
				_zyl(a, "Platte%d" % i, 0.3, 0.3, 0.12, Vector3(-1.3 + i * 0.75, 1.0, -0.25), m.schwarz_lack, Vector3.ZERO, 20)
				_zyl(a, "Crepe%d" % i, 0.26, 0.26, 0.01, Vector3(-1.3 + i * 0.75, 1.065, -0.25), m.creme_lack, Vector3.ZERO, 20)
			_zyl(a, "Schuessel", 0.2, 0.14, 0.16, Vector3(0.4, 1.0, -0.3), m.metall, Vector3.ZERO, 12)
			_zyl(a, "Schieber", 0.015, 0.015, 0.35, Vector3(0.4, 1.12, -0.3), m.holz_hell, Vector3(0, 0, 70), 6)
			for i in 5:
				_zyl(a, "Glas%d" % i, 0.06, 0.06, 0.14, Vector3(0.9 + i * 0.18, t_y + 0.07, t_z), m.holz_dunkel if i % 2 == 0 else m.rot, Vector3.ZERO, 10)
				_zyl(a, "Deckel%d" % i, 0.062, 0.062, 0.03, Vector3(0.9 + i * 0.18, t_y + 0.155, t_z), m.gold, Vector3.ZERO, 10)
			for i in 3:
				_prisma(a, "Tasche%d" % i, Vector3(0.26, 0.2, 0.04), Vector3(-1.2 + i * 0.4, t_y + 0.1, t_z), m.creme_lack, Vector3(0, 0, 180))
			var s := _gruppe(a, "Schildcrepe", Vector3(0, 2.8, schild_z))
			_prisma(s, "Dreieck", Vector3(0.9, 0.7, 0.08), Vector3.ZERO, m.creme_lack, Vector3(0, 0, 180))
			_box(s, "Schoko", Vector3(0.6, 0.08, 0.09), Vector3(0, 0.22, 0), m.holz_dunkel)
		"magenbrot":
			# offene Säcke mit Magenbrot, Schütten, Waage
			for i in 3:
				var x := -1.3 + i * 0.6
				_zyl(a, "Sack%d" % i, 0.24, 0.2, 0.45, Vector3(x, 0.99, -0.4), m.stoff, Vector3.ZERO, 10)
				_torus(a, "Saum%d" % i, 0.18, 0.24, Vector3(x, 1.22, -0.4), m.stoff)
				for k in 5:
					_box(a, "Stueck%d_%d" % [i, k], Vector3(0.07, 0.035, 0.05), Vector3(x - 0.1 + k * 0.05, 1.23, -0.4 + (k % 2) * 0.05), m.holz_dunkel, Vector3(0, k * 37.0, 0))
			for i in 2:
				_box(a, "Schuette%d" % i, Vector3(0.55, 0.12, 0.35), Vector3(0.5 + i * 0.7, t_y + 0.06, t_z), m.holz_hell)
				_box(a, "Haufen%d" % i, Vector3(0.45, 0.07, 0.25), Vector3(0.5 + i * 0.7, t_y + 0.15, t_z), m.holz_dunkel)
			_zyl(a, "Waage", 0.14, 0.14, 0.03, Vector3(-0.5, t_y + 0.2, t_z), m.messing, Vector3.ZERO, 12)
			_zyl(a, "Waagfuss", 0.03, 0.06, 0.18, Vector3(-0.5, t_y + 0.09, t_z), m.messing, Vector3.ZERO, 8)
			for i in 6:
				_box(a, "Magen%d" % i, Vector3(0.22, 0.1, 0.16), Vector3(-0.35 + (i % 3) * 0.35, 2.55 + (i / 3) * 0.14, schild_z), m.holz_dunkel, Vector3(0, 0, -10.0 + i * 5.0))
		"schokofruechte":
			# Schokobrunnen, Spieße mit Erdbeeren und Trauben, Schokoäpfel
			_zyl(a, "Brunnenfuss", 0.22, 0.28, 0.1, Vector3(-1.2, 1.0, -0.3), m.metall, Vector3.ZERO, 14)
			for k in 3:
				_zyl(a, "Stufe%d" % k, 0.28 - k * 0.08, 0.26 - k * 0.08, 0.08, Vector3(-1.2, 1.15 + k * 0.22, -0.3), m.holz_dunkel, Vector3.ZERO, 14)
			_zyl(a, "Saeule", 0.04, 0.04, 0.7, Vector3(-1.2, 1.35, -0.3), m.metall, Vector3.ZERO, 8)
			for i in 7:
				var g := _gruppe(a, "Spiess%d" % i, Vector3(-0.2 + i * 0.28, t_y, t_z), Vector3(0, 0, -6.0 + i * 2.0))
				_zyl(g, "Stab", 0.01, 0.01, 0.55, Vector3(0, 0.27, 0), m.holz_hell, Vector3.ZERO, 5)
				for k in 3:
					var frucht: Material = m.rot if (i + k) % 3 != 0 else m.hopfen
					_kugel(g, "Frucht%d" % k, 0.045, Vector3(0, 0.36 + k * 0.08, 0), frucht, Vector3(1.0, 1.2, 1.0))
					_kugel(g, "Schoko%d" % k, 0.047, Vector3(0, 0.33 + k * 0.08, 0), m.holz_dunkel, Vector3(1.0, 0.6, 1.0))
			for i in 4:
				_kugel(a, "Apfel%d" % i, 0.08, Vector3(-0.9 + i * 0.22, t_y + 0.08, t_z - 0.05), m.rot)
				_zyl(a, "Apfelstab%d" % i, 0.01, 0.01, 0.25, Vector3(-0.9 + i * 0.22, t_y + 0.25, t_z - 0.05), m.holz_hell, Vector3.ZERO, 5)
			var s := _gruppe(a, "Schildbeere", Vector3(0, 2.95, schild_z))
			_kugel(s, "Beere", 0.36, Vector3.ZERO, m.rot, Vector3(1.0, 1.25, 0.6))
			_kugel(s, "Schoko", 0.37, Vector3(0, -0.12, 0), m.holz_dunkel, Vector3(1.0, 0.7, 0.62))
			_prisma(s, "Blatt", Vector3(0.4, 0.14, 0.1), Vector3(0, 0.46, 0), m.hopfen)
		"fischbroetchen":
			# Kühlvitrine mit Fisch, Brötchenkörbe, Fischernetz, Rettungsring als Schild
			_box(a, "Vitrine", Vector3(2.4, 0.3, 0.45), Vector3(-0.3, t_y + 0.15, t_z - 0.05), m.glas)
			for i in 6:
				_kugel(a, "Fisch%d" % i, 0.07, Vector3(-1.3 + i * 0.4, t_y + 0.07, t_z - 0.05), m.creme_lack if i % 2 == 0 else m.orange_lack, Vector3(2.6, 0.5, 1.0))
			for i in 2:
				_zyl(a, "Korb%d" % i, 0.22, 0.18, 0.14, Vector3(1.3, 1.02, -0.1 - i * 0.5), m.holz_hell, Vector3.ZERO, 12)
				for k in 4:
					_kugel(a, "Broetchen%d_%d" % [i, k], 0.07, Vector3(1.22 + (k % 2) * 0.15, 1.13, -0.16 - i * 0.5 + (k / 2) * 0.12), m.lebkuchen, Vector3(1.3, 0.8, 1.0))
			for k in 5:
				_zyl(a, "Netz%d" % k, 0.008, 0.008, 3.2, Vector3(0, 1.9 + k * 0.12, -0.78), m.stoff, Vector3(0, 0, 90), 4)
			_torus(a, "Schildring", 0.28, 0.45, Vector3(0, 2.85, schild_z), m.weiss, Vector3(90, 0, 0))
			for k in 4:
				_box(a, "Ringband%d" % k, Vector3(0.18, 0.12, 0.2), Vector3(cos(k * PI / 2.0) * 0.37, 2.85 + sin(k * PI / 2.0) * 0.37, schild_z), m.rot, Vector3(0, 0, k * 90.0))
		"luftballons":
			# großer Ballonstrauß, Windräder und Plüschtiere
			var halter := Vector3(-2.95, 1.9, 0.7)
			_zyl(a, "Halter", 0.04, 0.04, 2.1, Vector3(-2.95, 0.87, 0.7), m.metall, Vector3.ZERO, 8)
			_zyl(a, "HalterFuss", 0.25, 0.3, 0.12, Vector3(-2.95, -0.12, 0.7), m.schwarz_lack, Vector3.ZERO, 10)
			for i in 14:
				var winkel := i * 2.4
				var rad := 0.2 + (i % 4) * 0.13
				var farbe: Material = [m.rot, m.blau, m.ente, m.hopfen, m.rosa_lack, m.orange_lack, m.weiss][i % 7]
				var p := Vector3(-2.95 + cos(winkel) * rad, 2.55 + (i % 5) * 0.17, 0.7 + sin(winkel) * rad)
				_kugel(a, "Ballon%d" % i, 0.16, p, farbe, Vector3(1.0, 1.2, 1.0))
				var schnur: MeshInstance3D = _zyl(a, "Schnur%d" % i, 0.004, 0.004, 1.0, Vector3.ZERO, m.weiss, Vector3.ZERO, 3)
				var unten := p - Vector3(0, 0.18, 0)
				var achse := (unten - halter)
				schnur.transform = Transform3D(Basis(Quaternion(Vector3.UP, achse.normalized())).scaled(Vector3(1, achse.length(), 1)), (unten + halter) * 0.5)
			for i in 5:
				var g := _gruppe(a, "Windrad%d" % i, Vector3(0.3 + i * 0.3, t_y, t_z))
				_zyl(g, "Stab", 0.008, 0.008, 0.5, Vector3(0, 0.25, 0), m.weiss, Vector3.ZERO, 4)
				for k in 4:
					_prisma(g, "Fluegel%d" % k, Vector3(0.1, 0.1, 0.01), Vector3(cos(k * PI / 2.0) * 0.05, 0.5 + sin(k * PI / 2.0) * 0.05, 0), [m.rot, m.ente, m.blau, m.hopfen][(i + k) % 4], Vector3(0, 0, k * 90.0))
			_box(a, "Regal", Vector3(1.8, 0.05, 0.3), Vector3(1.1, 1.3, -0.65), m.holz_hell)
			for i in 3:
				_teddy(a, "Pluesch%d" % i, Vector3(0.6 + i * 0.5, 1.33, -0.65), 0.0, 0.7)
			for i in 3:
				_kugel(a, "Schildballon%d" % i, 0.26, Vector3(-0.35 + i * 0.35, 2.85 + (i % 2) * 0.15, schild_z), [m.rot, m.ente, m.blau][i], Vector3(1.0, 1.2, 0.8))
		"schmalzkuchen":
			# Fritteuse mit Schmalzkuchen, Puderzucker, Tütenstapel
			_box(a, "Fritteuse", Vector3(1.2, 0.35, 0.55), Vector3(-0.9, 1.0, -0.3), m.metall)
			_box(a, "Fett", Vector3(1.05, 0.02, 0.42), Vector3(-0.9, 1.18, -0.3), m.orange_lack)
			for i in 10:
				_kugel(a, "Kuechlein%d" % i, 0.05, Vector3(-1.3 + (i % 5) * 0.2, 1.21, -0.42 + (i / 5) * 0.22), m.lebkuchen, Vector3(1.0, 0.65, 1.0))
			_zyl(a, "Korb", 0.012, 0.012, 0.6, Vector3(-0.2, 1.35, -0.3), m.metall, Vector3(0, 0, 60), 5)
			_box(a, "Schale", Vector3(0.8, 0.1, 0.35), Vector3(0.6, t_y + 0.05, t_z), m.weiss)
			for i in 12:
				_kugel(a, "Puder%d" % i, 0.045, Vector3(0.3 + (i % 6) * 0.12, t_y + 0.13, t_z - 0.08 + (i / 6) * 0.14), m.creme_lack, Vector3(1.0, 0.7, 1.0))
			_zyl(a, "Streuer", 0.05, 0.05, 0.18, Vector3(1.25, t_y + 0.09, t_z), m.weiss, Vector3.ZERO, 8)
			for i in 6:
				_box(a, "Tuete%d" % i, Vector3(0.2, 0.03, 0.14), Vector3(-1.6, t_y + 0.02 + i * 0.03, t_z), m.papier)
			for i in 5:
				_kugel(a, "Schildkuchen%d" % i, 0.16, Vector3(-0.3 + (i % 3) * 0.3, 2.75 + (i / 3) * 0.24, schild_z), m.lebkuchen, Vector3(1.0, 0.8, 0.8))
		"ausschank":
			for i in 3:
				_instanz(a, SZ + "fass.tscn", "Fass%d" % i, Transform3D(_rot(Vector3(90, 0, 0)), Vector3(-1.3 + i * 0.75, 0.45, -0.55)))
			_zyl(a, "Zapfsaeule", 0.07, 0.07, 0.5, Vector3(0.9, 1.1, -0.1), m.messing, Vector3.ZERO, 8)
			_zyl(a, "Hahn", 0.03, 0.03, 0.25, Vector3(0.9, 1.25, 0.05), m.gold, Vector3(70, 0, 0), 6)
			for i in 5:
				_masskrug(a, "Krug%d" % i, Vector3(-1.4 + i * 0.5, t_y, t_z))
			var s := _masskrug(a, "Schildkrug", Vector3(0, 2.5, schild_z))
			s.scale = Vector3.ONE * 2.6

# ------------------------------------------------------------------ Deko für den Baumodus
# Alle Teile stehen auf y = 0, Front = +Z. Einfache Kollision, damit man nicht durchläuft.
const DEKO := ["blumenkuebel", "fassstapel", "heuballen", "wegweiser", "jaegerzaun",
	"brunnen", "eingangsbogen", "blumenampel", "sonnenschirm", "wimpelmast"]

func _deko(typ: String) -> Node3D:
	var r := _neu(typ.capitalize())
	var koerper: Node = _haengen(r, StaticBody3D.new(), "Kollision")
	match typ:
		"blumenkuebel":
			_zyl(r, "Kuebel", 0.42, 0.36, 0.5, Vector3(0, 0.25, 0), m.holz_hell, Vector3.ZERO, 14)
			for y: float in [0.08, 0.42]:
				_torus(r, "Reif%.2f" % y, 0.37 + y * 0.12, 0.42 + y * 0.12, Vector3(0, y, 0), m.metall)
			_zyl(r, "Erde", 0.4, 0.4, 0.04, Vector3(0, 0.49, 0), m.holz_dunkel, Vector3.ZERO, 14)
			for i in 7:
				var a := TAU * i / 7.0
				_kugel(r, "Gruen%d" % i, 0.16, Vector3(sin(a) * 0.24, 0.6, cos(a) * 0.24), m.hopfen, Vector3(1.0, 0.8, 1.0))
			_kugel(r, "GruenMitte", 0.22, Vector3(0, 0.72, 0), m.hopfen)
			var farben: Array = [m.rot, m.rosa_lack, m.ente, m.weiss, m.blau]
			for i in 16:
				var a := i * 2.39
				var rad := 0.1 + (i % 4) * 0.08
				_kugel(r, "Bluete%d" % i, 0.055, Vector3(sin(a) * rad, 0.74 + (3 - i % 4) * 0.05, cos(a) * rad), farben[i % farben.size()], Vector3.ONE, false)
			_kollision(koerper, "Form", _boxform(Vector3(0.8, 0.8, 0.8)), Transform3D(Basis(), Vector3(0, 0.4, 0)))
		"fassstapel":
			_box(r, "Palette", Vector3(2.4, 0.14, 1.0), Vector3(0, 0.07, 0), m.holz_dunkel)
			for i in 3:
				_fass(r, "Unten%d" % i, Vector3(-0.72 + i * 0.72, 0.5, -0.39), true)
			for i in 2:
				_fass(r, "Mitte%d" % i, Vector3(-0.36 + i * 0.72, 1.12, -0.39), true)
			_fass(r, "Oben", Vector3(0, 1.74, -0.39), true)
			for sx: float in [-1.0, 1.0]:
				_box(r, "Keil%s" % sx, Vector3(0.12, 0.12, 0.9), Vector3(sx * 1.1, 0.2, 0), m.holz_dunkel, Vector3(0, 0, 45))
			_kollision(koerper, "Form", _boxform(Vector3(2.4, 2.0, 1.0)), Transform3D(Basis(), Vector3(0, 1.0, 0)))
		"heuballen":
			var heu: Material = m.huegel
			for i in 2:
				_zyl(r, "Ballen%d" % i, 0.6, 0.6, 1.1, Vector3(-0.7 + i * 1.4, 0.6, 0), heu, Vector3(0, 0, 90), 16)
				_zyl(r, "Stirn%d" % i, 0.5, 0.5, 1.12, Vector3(-0.7 + i * 1.4, 0.6, 0), m.lebkuchen, Vector3(0, 0, 90), 16)
			_zyl(r, "BallenOben", 0.55, 0.55, 1.0, Vector3(0, 1.55, 0), heu, Vector3(0, 0, 90), 16)
			for i in 3:
				_kugel(r, "Kuerbis%d" % i, 0.22 - i * 0.03, Vector3(-0.9 + i * 0.5, 0.2 - i * 0.02, 0.85), m.orange_lack, Vector3(1.2, 0.85, 1.2))
				_zyl(r, "Stiel%d" % i, 0.03, 0.02, 0.1, Vector3(-0.9 + i * 0.5, 0.4 - i * 0.05, 0.85), m.hopfen, Vector3.ZERO, 5)
			var gabel := _gruppe(r, "Heugabel", Vector3(1.35, 0, 0.4), Vector3(0, 0, -15))
			_zyl(gabel, "Stiel", 0.025, 0.025, 1.6, Vector3(0, 0.8, 0), m.holz_hell, Vector3.ZERO, 6)
			for k in 3:
				_zyl(gabel, "Zinke%d" % k, 0.012, 0.008, 0.35, Vector3(-0.08 + k * 0.08, 1.75, 0), m.metall, Vector3.ZERO, 4)
			_box(gabel, "Querstueck", Vector3(0.2, 0.03, 0.03), Vector3(0, 1.6, 0), m.metall)
			_kollision(koerper, "Form", _boxform(Vector3(2.6, 2.1, 1.2)), Transform3D(Basis(), Vector3(0, 1.05, 0)))
		"wegweiser":
			_zyl(r, "Pfahl", 0.09, 0.08, 3.2, Vector3(0, 1.6, 0), m.holz_dunkel, Vector3.ZERO, 8)
			_zyl(r, "Kappe", 0.16, 0.0, 0.25, Vector3(0, 3.32, 0), m.schindel, Vector3.ZERO, 8)
			_kugel(r, "Knauf", 0.05, Vector3(0, 3.48, 0), m.gold)
			var farben: Array = [m.blau, m.rot, m.hopfen, m.orange_lack]
			for i in 4:
				var s := _gruppe(r, "Schild%d" % i, Vector3(0, 2.7 - i * 0.42, 0), Vector3(0, i * 67.0 - 40.0, 0))
				var seite := 1.0 if i % 2 == 0 else -1.0
				_box(s, "Brett", Vector3(1.0, 0.26, 0.05), Vector3(seite * 0.55, 0, 0), m.holz_hell)
				_prisma(s, "Pfeil", Vector3(0.26, 0.22, 0.05), Vector3(seite * 1.18, 0, 0), m.holz_hell, Vector3(0, 0, -90 * seite))
				_box(s, "Streifen", Vector3(0.85, 0.08, 0.06), Vector3(seite * 0.55, 0, 0), farben[i])
			_zyl(r, "Sockel", 0.3, 0.35, 0.15, Vector3(0, 0.075, 0), m.stein, Vector3.ZERO, 8)
			_kollision(koerper, "Form", _boxform(Vector3(0.3, 3.2, 0.3)), Transform3D(Basis(), Vector3(0, 1.6, 0)))
		"jaegerzaun":
			# 3 m Jägerzaun: zwei Pfosten, gekreuzte Latten, Deckleiste
			for sx: float in [-1.5, 1.5]:
				_box(r, "Pfosten%s" % sx, Vector3(0.1, 1.05, 0.1), Vector3(sx, 0.52, 0), m.holz_dunkel)
				_prisma(r, "Spitze%s" % sx, Vector3(0.1, 0.1, 0.1), Vector3(sx, 1.1, 0), m.holz_dunkel)
			for i in 12:
				var x := -1.375 + i * 0.25
				_box(r, "LatteA%d" % i, Vector3(0.05, 1.15, 0.02), Vector3(x, 0.55, 0.03), m.holz_hell, Vector3(0, 0, 32))
				_box(r, "LatteB%d" % i, Vector3(0.05, 1.15, 0.02), Vector3(x, 0.55, -0.03), m.holz_hell, Vector3(0, 0, -32))
			_box(r, "Deckleiste", Vector3(3.1, 0.06, 0.08), Vector3(0, 0.98, 0), m.holz_dunkel)
			_box(r, "Unterleiste", Vector3(3.0, 0.05, 0.08), Vector3(0, 0.15, 0), m.holz_dunkel)
			for i in 3:
				_kugel(r, "Busch%d" % i, 0.22, Vector3(-1.0 + i * 1.0, 0.16, 0.25), m.hopfen, Vector3(1.3, 0.7, 1.0))
			_kollision(koerper, "Form", _boxform(Vector3(3.1, 1.1, 0.2)), Transform3D(Basis(), Vector3(0, 0.55, 0)))
		"brunnen":
			# achteckiges Steinbecken, Säule mit Schale und Wasserspeiern, Blumen am Rand
			_zyl(r, "Sockel", 2.2, 2.3, 0.2, Vector3(0, 0.1, 0), m.stein, Vector3.ZERO, 8)
			for k in 8:
				var a := TAU * k / 8.0 + PI / 8.0
				_box(r, "Wand%d" % k, Vector3(1.75, 0.6, 0.25), Vector3(sin(a) * 1.85, 0.5, cos(a) * 1.85), m.stein, Vector3(0, rad_to_deg(a), 0))
				_box(r, "Sims%d" % k, Vector3(1.85, 0.08, 0.38), Vector3(sin(a) * 1.85, 0.83, cos(a) * 1.85), m.creme_lack, Vector3(0, rad_to_deg(a), 0))
				_zyl(r, "Blumen%d" % k, 0.14, 0.14, 0.14, Vector3(sin(a + PI / 8.0) * 1.95, 0.93, cos(a + PI / 8.0) * 1.95), m.holz_hell, Vector3.ZERO, 8)
				_kugel(r, "Bluete%d" % k, 0.13, Vector3(sin(a + PI / 8.0) * 1.95, 1.06, cos(a + PI / 8.0) * 1.95), [m.rot, m.rosa_lack, m.ente][k % 3], Vector3(1.0, 0.7, 1.0))
			_zyl(r, "Wasser", 1.75, 1.75, 0.04, Vector3(0, 0.62, 0), m.wasser, Vector3.ZERO, 16)
			_zyl(r, "Saeule", 0.28, 0.22, 1.9, Vector3(0, 1.1, 0), m.stein, Vector3.ZERO, 8)
			_zyl(r, "Schale", 0.85, 0.3, 0.3, Vector3(0, 1.75, 0), m.stein, Vector3.ZERO, 12)
			_zyl(r, "SchaleWasser", 0.78, 0.78, 0.03, Vector3(0, 1.88, 0), m.wasser, Vector3.ZERO, 12)
			_zyl(r, "Aufsatz", 0.12, 0.16, 0.7, Vector3(0, 2.25, 0), m.creme_lack, Vector3.ZERO, 8)
			_kugel(r, "Kugel", 0.18, Vector3(0, 2.7, 0), m.gold)
			for k in 4:
				var a := TAU * k / 4.0
				_zyl(r, "Speier%d" % k, 0.035, 0.035, 0.3, Vector3(sin(a) * 0.3, 1.0, cos(a) * 0.3), m.messing, Vector3(rad_to_deg(cos(a)) * 1.3, 0, -rad_to_deg(sin(a)) * 1.3), 6)
				var strahl: MeshInstance3D = _zyl(r, "Strahl%d" % k, 0.02, 0.03, 0.55, Vector3(sin(a) * 0.62, 0.8, cos(a) * 0.62), m.wasser, Vector3(rad_to_deg(cos(a)) * 0.6, 0, -rad_to_deg(sin(a)) * 0.6), 6)
				strahl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var form := CylinderShape3D.new()
			form.radius = 2.2
			form.height = 1.0
			_kollision(koerper, "Form", form, Transform3D(Basis(), Vector3(0, 0.5, 0)))
		"eingangsbogen":
			# Festbogen über den Weg: zwei bemalte Säulen, Bogen mit Girlande, Lichtern und Wimpeln
			var weite := 3.2
			for sx: float in [-1.0, 1.0]:
				var x := sx * weite
				_box(r, "Fuss%s" % sx, Vector3(0.7, 0.4, 0.7), Vector3(x, 0.2, 0), m.stein)
				_zyl(r, "Saeule%s" % sx, 0.22, 0.2, 4.4, Vector3(x, 2.6, 0), m.weiss, Vector3.ZERO, 12)
				for k in 5:
					_torus(r, "Band%s_%d" % [sx, k], 0.2, 0.25, Vector3(x, 1.0 + k * 0.8, 0), m.blau, Vector3(12, 0, 0))
				_kugel(r, "Kugel%s" % sx, 0.3, Vector3(x, 5.1, 0), m.gold)
				_prisma(r, "Fahne%s" % sx, Vector3(0.6, 0.9, 0.02), Vector3(x + sx * 0.35, 5.4, 0), m.rauten, Vector3(0, 0, sx * 90))
				_zyl(r, "Fahnenstab%s" % sx, 0.02, 0.02, 1.0, Vector3(x, 5.8, 0), m.gold, Vector3.ZERO, 5)
			var segmente := 14
			for k in segmente:
				var a0 := PI * k / segmente
				var a1 := PI * (k + 1) / segmente
				var p0 := Vector3(-cos(a0) * weite, 4.8 + sin(a0) * 1.4, 0)
				var p1 := Vector3(-cos(a1) * weite, 4.8 + sin(a1) * 1.4, 0)
				var mitte := (p0 + p1) * 0.5
				var achse := p1 - p0
				var seg: MeshInstance3D = _box(r, "Bogen%d" % k, Vector3(achse.length() + 0.05, 0.4, 0.3), mitte, m.streifen)
				seg.transform = Transform3D(Basis(Vector3.BACK, atan2(achse.y, achse.x)), mitte)
				_kugel(r, "Kranz%d" % k, 0.2, mitte + Vector3(0, -0.25, 0.12), m.hopfen, Vector3(1.4, 0.8, 1.0))
				_kugel(r, "Birne%d" % k, 0.05, mitte + Vector3(0, -0.4, 0.2), m.gluehbirne, Vector3.ONE, false)
				_prisma(r, "Wimpel%d" % k, Vector3(0.25, 0.35, 0.01), mitte + Vector3(0, -0.62, 0), [m.blau, m.weiss, m.rot][k % 3], Vector3(0, 0, 180))
			_box(r, "Tafel", Vector3(2.6, 0.7, 0.1), Vector3(0, 5.3, 0.2), m.holz_dunkel)
			_box(r, "TafelRand", Vector3(2.7, 0.8, 0.08), Vector3(0, 5.3, 0.16), m.gold)
			_instanz(r, "res://scenes/einrichtung/riesenbrezel.tscn", "Brezn", Transform3D(Basis().scaled(Vector3.ONE * 0.6), Vector3(0, 5.3, 0.3)))
			_licht(r, "Licht", Vector3(0, 4.8, 0.6), 1.4, 7.0)
			for sx: float in [-1.0, 1.0]:
				_kollision(koerper, "Form%s" % sx, _boxform(Vector3(0.7, 5.0, 0.7)), Transform3D(Basis(), Vector3(sx * weite, 2.5, 0)))
		"blumenampel":
			# gusseiserner Laternenmast mit zwei hängenden Blumenkörben
			_zyl(r, "Fuss", 0.25, 0.3, 0.3, Vector3(0, 0.15, 0), m.schwarz_lack, Vector3.ZERO, 8)
			_zyl(r, "Mast", 0.07, 0.06, 3.8, Vector3(0, 2.1, 0), m.schwarz_lack, Vector3.ZERO, 8)
			_box(r, "Ausleger", Vector3(1.8, 0.06, 0.06), Vector3(0, 3.6, 0), m.schwarz_lack)
			for sx: float in [-1.0, 1.0]:
				_zyl(r, "Kette%s" % sx, 0.01, 0.01, 0.5, Vector3(sx * 0.8, 3.33, 0), m.metall, Vector3.ZERO, 4)
				_zyl(r, "Korb%s" % sx, 0.3, 0.16, 0.26, Vector3(sx * 0.8, 2.95, 0), m.holz_hell, Vector3.ZERO, 12)
				for i in 10:
					var a := i * 2.39
					_kugel(r, "Bluete%s_%d" % [sx, i], 0.08, Vector3(sx * 0.8 + sin(a) * 0.24, 3.1 - (i % 3) * 0.12, cos(a) * 0.24), [m.rot, m.rosa_lack, m.weiss, m.hopfen][i % 4], Vector3.ONE, false)
				for i in 4:
					var a := TAU * i / 4.0
					_zyl(r, "Ranke%s_%d" % [sx, i], 0.03, 0.01, 0.5, Vector3(sx * 0.8 + sin(a) * 0.28, 2.7, cos(a) * 0.28), m.hopfen, Vector3.ZERO, 4)
			_zyl(r, "Laterne", 0.16, 0.2, 0.45, Vector3(0, 4.25, 0), m.laternenglas, Vector3.ZERO, 6)
			_zyl(r, "LaternenDach", 0.26, 0.02, 0.25, Vector3(0, 4.6, 0), m.schwarz_lack, Vector3.ZERO, 6)
			_licht(r, "Licht", Vector3(0, 4.2, 0), 1.0, 6.0)
			_kollision(koerper, "Form", _boxform(Vector3(0.3, 3.8, 0.3)), Transform3D(Basis(), Vector3(0, 1.9, 0)))
		"sonnenschirm":
			# großer Biergarten-Schirm in Rauten mit Volant
			_zyl(r, "Fuss", 0.35, 0.4, 0.12, Vector3(0, 0.06, 0), m.stein, Vector3.ZERO, 12)
			_zyl(r, "Stange", 0.05, 0.05, 2.9, Vector3(0, 1.5, 0), m.holz_hell, Vector3.ZERO, 8)
			_zyl(r, "Dach", 2.1, 0.08, 0.8, Vector3(0, 2.95, 0), m.rauten, Vector3.ZERO, 12)
			_zyl(r, "Volant", 2.1, 2.1, 0.22, Vector3(0, 2.44, 0), m.rauten_fein, Vector3.ZERO, 12)
			_kugel(r, "Spitze", 0.08, Vector3(0, 3.4, 0), m.gold)
			for i in 12:
				var a := TAU * i / 12.0
				_kugel(r, "Birne%d" % i, 0.04, Vector3(sin(a) * 2.05, 2.28, cos(a) * 2.05), m.gluehbirne, Vector3.ONE, false)
			_kollision(koerper, "Form", _boxform(Vector3(0.3, 2.5, 0.3)), Transform3D(Basis(), Vector3(0, 1.25, 0)))
		"wimpelmast":
			# weiß-blauer Mast mit Wimpelketten zu drei Bodenankern
			_zyl(r, "Mast", 0.1, 0.06, 7.0, Vector3(0, 3.5, 0), m.weiss, Vector3.ZERO, 10)
			for k in 6:
				_torus(r, "Band%d" % k, 0.07, 0.1, Vector3(0, 0.8 + k * 1.1, 0), m.blau, Vector3(15, 0, 0))
			_kugel(r, "Spitze", 0.14, Vector3(0, 7.1, 0), m.gold)
			for k in 3:
				var a := TAU * k / 3.0
				var anker := Vector3(sin(a) * 3.5, 0.3, cos(a) * 3.5)
				_zyl(r, "Anker%d" % k, 0.05, 0.05, 0.6, anker, m.holz_dunkel, Vector3.ZERO, 6)
				var oben := Vector3(0, 6.8, 0)
				for i in 10:
					var t0 := i / 10.0
					var t1 := (i + 1) / 10.0
					var q0 := oben.lerp(anker + Vector3(0, 0.3, 0), t0) - Vector3(0, sin(t0 * PI) * 0.4, 0)
					var q1 := oben.lerp(anker + Vector3(0, 0.3, 0), t1) - Vector3(0, sin(t1 * PI) * 0.4, 0)
					var achse := q1 - q0
					var seil: MeshInstance3D = _zyl(r, "Seil%d_%d" % [k, i], 0.012, 0.012, 1.0, Vector3.ZERO, m.weiss, Vector3.ZERO, 4)
					seil.transform = Transform3D(Basis(Quaternion(Vector3.UP, achse.normalized())).scaled(Vector3(1, achse.length(), 1)), (q0 + q1) * 0.5)
				for i in 10:
					var t := (i + 0.5) / 10.0
					var p := oben.lerp(anker + Vector3(0, 0.3, 0), t) - Vector3(0, sin(t * PI) * 0.4, 0)
					_prisma(r, "Wimpel%d_%d" % [k, i], Vector3(0.28, 0.36, 0.01), p - Vector3(0, 0.18, 0), [m.blau, m.weiss][i % 2], Vector3(0, rad_to_deg(a) + 90.0, 180))
			_kollision(koerper, "Form", _boxform(Vector3(0.3, 7.0, 0.3)), Transform3D(Basis(), Vector3(0, 3.5, 0)))
	return r

# ------------------------------------------------------------------ Gemeinsame Spielbude
## Podest, Eckpfosten, Rück- und Seitenwände, Satteldach mit Markise, Lichterreihe und
## Tafel vorn oben (Aufschrift als Label3D in der Hüllszene). Front = +Z.
func _spielbude(r: Node3D, schema: String, breite: float, tiefe: float, hoehe: float, zm: float, boden: float) -> void:
	var streifen: Material = m["streifen_" + schema]
	var fein: Material = m["streifen_fein_" + schema]
	var zickzack: Material = m["zickzack_" + schema]
	_box(r, "Podest", Vector3(breite, boden, tiefe), Vector3(0, boden / 2.0, zm), m.holz_dunkel)
	_box(r, "Dielen", Vector3(breite - 0.16, 0.02, tiefe - 0.16), Vector3(0, boden + 0.01, zm), m.dielen)
	_box(r, "PodestKante", Vector3(breite + 0.08, 0.05, 0.05), Vector3(0, boden, zm + tiefe / 2.0), m.gold)
	var bau := _gruppe(r, "Bau")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * (breite / 2.0 - 0.1), boden, zm + sz * (tiefe / 2.0 - 0.1))
			_zyl(bau, "Pfosten%s%s" % [sx, sz], 0.09, 0.08, hoehe, p + Vector3(0, hoehe / 2.0, 0), m.creme_lack, Vector3.ZERO, 10)
			_kugel(bau, "Knauf%s%s" % [sx, sz], 0.1, p + Vector3(0, hoehe + 0.05, 0), m.gold)
	_box(bau, "Rueckwand", Vector3(breite - 0.2, hoehe, 0.08), Vector3(0, boden + hoehe / 2.0, zm - tiefe / 2.0 + 0.05), fein)
	for sx: float in [-1.0, 1.0]:
		_box(bau, "Seitenwand%s" % sx, Vector3(0.08, hoehe * 0.75, tiefe - 0.3), Vector3(sx * (breite / 2.0 - 0.05), boden + hoehe * 0.375, zm - 0.1), fein)
	var dach := _gruppe(r, "Dach", Vector3(0, boden + hoehe, zm))
	_box(dach, "Traufe", Vector3(breite + 0.3, 0.12, tiefe + 0.3), Vector3(0, 0.06, 0), m.holz_dunkel)
	_prisma(dach, "Giebel", Vector3(tiefe + 0.5, 1.0, breite + 0.4), Vector3(0, 0.62, 0), streifen, Vector3(0, 90, 0))
	for sx: float in [-1.0, 1.0]:
		_prisma(dach, "Stirn%s" % sx, Vector3(tiefe + 0.3, 0.95, 0.04), Vector3(sx * (breite / 2.0 + 0.22), 0.6, 0), zickzack, Vector3(0, 90, 0))
	_box(dach, "Markise", Vector3(breite + 0.3, 0.45, 0.05), Vector3(0, -0.14, tiefe / 2.0 + 0.2), zickzack)
	for i in 9:
		var t := (i + 0.5) / 9.0
		_kugel(dach, "Birne%d" % i, 0.035, Vector3(-breite / 2.0 + t * breite, -0.36, tiefe / 2.0 + 0.24), m.gluehbirne, Vector3.ONE, false)
	var tafel := _gruppe(r, "Tafel", Vector3(0, boden + hoehe + 0.55, zm + tiefe / 2.0 + 0.45))
	_box(tafel, "Brett", Vector3(2.8, 0.6, 0.06), Vector3.ZERO, m.holz_dunkel)
	_box(tafel, "Rahmen", Vector3(2.9, 0.7, 0.04), Vector3(0, 0, -0.02), m.gold)
	_marke(tafel, "TitelPunkt", Vector3(0, 0, 0.05))
	_licht(r, "Licht", Vector3(0, boden + hoehe - 0.3, zm + 0.2), 1.6, 6.0)

func _spielkamera(r: Node3D, pos: Vector3, grad: Vector3, fov: float) -> Camera3D:
	var kamera := Camera3D.new()
	kamera.position = pos
	kamera.rotation_degrees = grad
	kamera.fov = fov
	_haengen(r, kamera, "SpielKamera")
	return kamera

# ------------------------------------------------------------------ Ballonstechen
## Pfeile auf eine Wand voller Luftballons. Spieler steht vor der Theke, blickt -Z.
##   Ballons/Ballon0..11  Ziele (Skript blendet getroffene aus)
##   Zielpunkt            Fadenkreuz auf der Wand (Skript bewegt es)
##   Flugpfeil            Pfeil, der zur Wand fliegt
func _pfeilwurf() -> Node3D:
	var r := _neu("Pfeilwurf")
	var boden := 0.18
	var zm := -1.2
	_spielbude(r, "violett", 5.4, 3.4, 2.9, zm, boden)
	var theke := _gruppe(r, "Theke", Vector3(0, boden, 0.2))
	_box(theke, "Korpus", Vector3(4.8, 0.95, 0.4), Vector3(0, 0.475, 0), m.holz_hell)
	_box(theke, "Feld", Vector3(4.2, 0.5, 0.02), Vector3(0, 0.48, 0.21), m.zickzack_violett)
	_box(theke, "Platte", Vector3(5.0, 0.06, 0.55), Vector3(0, 0.98, 0), m.gruen_samt)
	for i in 5:
		_zyl(theke, "Pfeil%d" % i, 0.012, 0.012, 0.32, Vector3(1.4 + i * 0.1, 1.02, 0.05), m.holz_hell, Vector3(90, 0, 0), 5)
		_prisma(theke, "Feder%d" % i, Vector3(0.05, 0.08, 0.01), Vector3(1.4 + i * 0.1, 1.02, 0.2), [m.rot, m.ente][i % 2], Vector3(90, 0, 0))
	# Korkwand mit Ballons
	var wand_z := zm - 1.7 + 0.14
	_box(r, "Korkwand", Vector3(4.2, 2.0, 0.06), Vector3(0, boden + 1.85, wand_z), m.lebkuchen)
	_box(r, "Korkrahmen", Vector3(4.35, 2.15, 0.04), Vector3(0, boden + 1.85, wand_z - 0.02), m.gold)
	var ballons := _gruppe(r, "Ballons")
	var farben: Array = [m.rot, m.blau, m.ente, m.hopfen, m.rosa_lack, m.orange_lack]
	for i in 12:
		var x := -1.5 + (i % 4) * 1.0
		var y := boden + 1.2 + (i / 4) * 0.65
		var b := _gruppe(ballons, "Ballon%d" % i, Vector3(x, y, wand_z + 0.2))
		_kugel(b, "Huelle", 0.2, Vector3.ZERO, farben[i % farben.size()], Vector3(1.0, 1.2, 0.9))
		_zyl(b, "Knoten", 0.03, 0.01, 0.05, Vector3(0, -0.26, 0), farben[i % farben.size()], Vector3.ZERO, 6)
	# Preise an den Seiten
	for i in 4:
		_teddy(r, "Teddy%d" % i, Vector3(-2.35, boden + 0.6 + (i % 2) * 0.0, zm - 0.9 + i * 0.5), 90.0, 0.8)
	for i in 3:
		_kugel(r, "Deko%d" % i, 0.18, Vector3(2.3, boden + 2.4 + i * 0.1, zm - 0.6 + i * 0.5), farben[i], Vector3(1.0, 1.2, 1.0))
	# Fadenkreuz und Flugpfeil
	var ziel := _gruppe(r, "Zielpunkt", Vector3(0, boden + 1.85, wand_z + 0.45))
	_torus(ziel, "Ring", 0.07, 0.09, Vector3.ZERO, m.gluehbirne, Vector3(90, 0, 0))
	_kugel(ziel, "Punkt", 0.015, Vector3.ZERO, m.gluehbirne, Vector3.ONE, false)
	var pfeil := _gruppe(r, "Flugpfeil", Vector3(0, 1.5, 1.2))
	_zyl(pfeil, "Schaft", 0.012, 0.012, 0.34, Vector3(0, 0, 0), m.holz_hell, Vector3(90, 0, 0), 5)
	_zyl(pfeil, "Spitze", 0.012, 0.0, 0.08, Vector3(0, 0, -0.21), m.metall, Vector3(-90, 0, 0), 5)
	for k in 2:
		_prisma(pfeil, "Feder%d" % k, Vector3(0.06, 0.1, 0.01), Vector3(0, 0, 0.14), m.rot, Vector3(90, 0, k * 90.0))
	_spielkamera(r, Vector3(0, boden + 1.62, 1.1), Vector3(-3, 0, 0), 60)
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Bude", _boxform(Vector3(5.4, 1.2, 3.4)), Transform3D(Basis(), Vector3(0, 0.6, zm)))
	_marke(r, "BesitzerMitte", Vector3(-1.9, boden, -0.4))
	_marke(r, "BesitzerSeite", Vector3(-2.0, boden, -2.2))
	return r

# ------------------------------------------------------------------ Hau den Maulwurf
## Tisch mit 3×3 Löchern, aus denen Maulwürfe schauen. Kamera schräg von oben.
##   Maulwuerfe/Maulwurf0..8  (lokal y = 0 versteckt, Skript hebt sie an)
##   Hammer                   Spielhammer (Skript schwingt ihn zum Loch)
func _maulwurf() -> Node3D:
	var r := _neu("Maulwurf")
	var boden := 0.18
	var zm := -1.2
	_spielbude(r, "orange", 5.4, 3.4, 2.9, zm, boden)
	var tisch := _gruppe(r, "Tisch", Vector3(0, boden, -0.4))
	var top := 0.9
	_box(tisch, "Korpus", Vector3(2.6, top - 0.06, 1.8), Vector3(0, (top - 0.06) / 2.0, 0), m.holz_hell)
	_box(tisch, "Front", Vector3(2.3, 0.55, 0.02), Vector3(0, 0.45, 0.91), m.zickzack_orange)
	_box(tisch, "Rand", Vector3(2.7, 0.08, 1.9), Vector3(0, top - 0.02, 0), m.holz_dunkel)
	_box(tisch, "Platte", Vector3(2.5, 0.02, 1.7), Vector3(0, top + 0.03, 0), m.huegel)
	var maeuse := _gruppe(r, "Maulwuerfe")
	for i in 9:
		var p := Vector3(-0.8 + (i % 3) * 0.8, boden + top, -0.4 - 0.5 + (i / 3) * 0.5)
		_zyl(r, "Loch%d" % i, 0.2, 0.2, 0.02, p + Vector3(0, 0.045, 0), m.holz_dunkel, Vector3.ZERO, 16)
		_torus(r, "Erdwall%d" % i, 0.19, 0.26, p + Vector3(0, 0.05, 0), m.holz_dunkel)
		var mw := _gruppe(maeuse, "Maulwurf%d" % i, p)
		var koerper_mw := _gruppe(mw, "Koerper", Vector3(0, -0.3, 0))
		_kugel(koerper_mw, "Leib", 0.15, Vector3(0, 0.1, 0), m.holz_dunkel, Vector3(1.0, 1.3, 1.0))
		_kugel(koerper_mw, "Nase", 0.04, Vector3(0, 0.18, 0.14), m.rosa_lack)
		for sx: float in [-1.0, 1.0]:
			_kugel(koerper_mw, "Auge%s" % sx, 0.022, Vector3(sx * 0.06, 0.25, 0.115), m.weiss, Vector3.ONE, false)
			_kugel(koerper_mw, "Pupille%s" % sx, 0.012, Vector3(sx * 0.06, 0.25, 0.135), m.schwarz_lack, Vector3.ONE, false)
			_kugel(koerper_mw, "Pfote%s" % sx, 0.045, Vector3(sx * 0.12, 0.08, 0.1), m.rosa_lack, Vector3(1.2, 0.6, 1.0))
		_zyl(koerper_mw, "Helm", 0.1, 0.12, 0.06, Vector3(0, 0.3, 0), m.ente, Vector3(-10, 0, 0), 12)
	# Anzeigetafel mit Glühbirnen hinten, Preise
	_box(r, "Punktetafel", Vector3(2.4, 1.0, 0.06), Vector3(0, boden + 2.0, zm - 1.5), m.schwarz_lack)
	for i in 10:
		_kugel(r, "Lampe%d" % i, 0.07, Vector3(-1.0 + i * 0.222, boden + 2.0, zm - 1.45), m.gluehbirne, Vector3.ONE, false)
	for i in 3:
		_teddy(r, "Teddy%d" % i, Vector3(-1.6 + i * 1.6, boden + 1.0, zm - 1.3), 0.0, 0.9)
	# Spielhammer: Stiel + Gummikopf, hängt vor der Kamera
	var hammer := _gruppe(r, "Hammer", Vector3(0.6, boden + 1.5, 0.3))
	_zyl(hammer, "Stiel", 0.025, 0.025, 0.6, Vector3(0, 0.3, 0), m.holz_hell, Vector3.ZERO, 8)
	_zyl(hammer, "Kopf", 0.09, 0.09, 0.26, Vector3(0, 0.62, 0), m.rot, Vector3(0, 0, 90), 14)
	for sx: float in [-1.0, 1.0]:
		_zyl(hammer, "Gummi%s" % sx, 0.095, 0.095, 0.04, Vector3(sx * 0.13, 0.62, 0), m.schwarz_lack, Vector3(0, 0, 90), 14)
	_spielkamera(r, Vector3(0, boden + 2.2, 0.75), Vector3(-52, 0, 0), 62)
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Bude", _boxform(Vector3(5.4, 1.2, 3.4)), Transform3D(Basis(), Vector3(0, 0.6, zm)))
	_marke(r, "BesitzerMitte", Vector3(-1.9, boden, -0.2))
	_marke(r, "BesitzerSeite", Vector3(-2.0, boden, -2.2))
	return r

# ------------------------------------------------------------------ Krugschieben
## Langer Schanktisch in die Bude hinein, am Ende drei Punktfelder. Spieler steht vorn.
##   Krug        Schiebekrug (Skript bewegt ihn entlang -Z)
##   KrugStart   Startpunkt auf dem Tisch
##   Tischende   Kante: darüber hinaus fällt der Krug
func _krugschieben() -> Node3D:
	var r := _neu("Krugschieben")
	var boden := 0.18
	var zm := -1.3
	var tiefe := 3.6
	_spielbude(r, "tuerkis", 5.0, tiefe, 2.9, zm, boden)
	var top := 1.0
	var tisch := _gruppe(r, "Tisch", Vector3(0, boden, 0))
	var laenge := 3.5
	var mitte_z := 0.55 - laenge / 2.0
	_box(tisch, "Platte", Vector3(0.9, 0.08, laenge), Vector3(0, top, mitte_z), m.holz_hell)
	_box(tisch, "Belag", Vector3(0.8, 0.01, laenge - 0.05), Vector3(0, top + 0.045, mitte_z), m.dielen)
	for sx: float in [-1.0, 1.0]:
		_box(tisch, "Bande%s" % sx, Vector3(0.05, 0.06, laenge), Vector3(sx * 0.45, top + 0.07, mitte_z), m.messing)
		for k in 4:
			_box(tisch, "Bein%s_%d" % [sx, k], Vector3(0.08, top, 0.08), Vector3(sx * 0.38, top / 2.0, 0.4 - k * 1.05), m.holz_dunkel)
	# Punktfelder am Ende: 1, 2, 3 (3 ganz hinten, schmal)
	var felder := [[-1.85, 0.6, m.hopfen], [-2.375, 0.45, m.ente], [-2.75, 0.3, m.rot]]
	for f: Array in felder:
		_box(tisch, "Feld%.2f" % f[0], Vector3(0.8, 0.012, f[1]), Vector3(0, top + 0.052, f[0]), f[2])
		_box(tisch, "Linie%.2f" % f[0], Vector3(0.8, 0.014, 0.02), Vector3(0, top + 0.053, f[0] + f[1] / 2.0), m.weiss)
	_marke(r, "Tischende", Vector3(0, boden + top, 0.55 - laenge))
	_marke(r, "KrugStart", Vector3(0, boden + top + 0.05, 0.3))
	# Auffangkorb hinter dem Tisch
	_zyl(r, "Korb", 0.45, 0.35, 0.5, Vector3(0, boden + 0.25, 0.55 - laenge - 0.35), m.holz_dunkel, Vector3.ZERO, 12)
	# Fässer und Krüge als Deko
	_fass(r, "FassL", Vector3(-1.9, boden, -2.5))
	_fass(r, "FassR", Vector3(1.9, boden, -2.5))
	_fass(r, "FassROben", Vector3(1.9, boden + 0.78, -2.5))
	var regal := _gruppe(r, "Regal", Vector3(-1.9, boden + 1.3, -1.0))
	_box(regal, "Brett", Vector3(0.4, 0.04, 1.6), Vector3.ZERO, m.holz_dunkel)
	for i in 4:
		_masskrug(regal, "Krug%d" % i, Vector3(0, 0.02, -0.6 + i * 0.4))
	var krug := _masskrug(r, "Krug", Vector3(0, boden + top + 0.05, 0.3))
	krug.rotation_degrees = Vector3(0, 90, 0)
	_spielkamera(r, Vector3(0, boden + 1.85, 1.35), Vector3(-17, 0, 0), 58)
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Bude", _boxform(Vector3(5.0, 1.2, tiefe)), Transform3D(Basis(), Vector3(0, 0.6, zm)))
	_marke(r, "BesitzerMitte", Vector3(-1.95, boden, -0.5))
	_marke(r, "BesitzerSeite", Vector3(-1.95, boden, -1.7))
	return r
