extends SceneTree
## Baut das Festzelt „Himmel“ als echte Knoten:
##   assets/zelt/texturen/*.png   erzeugte Texturen (Dielen, Holz, Stoff, Himmel, Rauten …)
##   assets/zelt/materialien/*.tres
##   scenes/zelt/*.tscn            Bauteile (Kranzleuchter, Laterne, Fenster, Girlande …)
##   scenes/tent.tscn              das Zelt selbst (Boden, Wände, Emporen, Dach, Fassade)
## Vorbild: Wiesn-Festhallen — Holzdielen, begehbare Emporen mit Rautenbrüstung,
## hellblaue Wolkendecke („Himmel der Bayern“), Hopfenkränze als Leuchter, Krone
## auf dem Giebel, Maibaum vor dem Eingang.
## Maße passen zu main.tscn (Kollision innen x ±12, z -14 … 11, Tür x ±3) und zu den
## Emporen-Konstanten im GameManager (EMPORE_Y, EMPORE_KANTE, TREPPE).
##
## ACHTUNG: überschreibt Handänderungen an diesen Dateien. Nur neu backen, wenn sich
## das Grunddesign ändert — Feinschliff danach im Editor.
##   1) godot --headless --path . --script tools/bake_zelt.gd -- texturen
##   2) godot --headless --path . --import
##   3) godot --headless --path . --script tools/bake_zelt.gd

const TEX := "res://assets/zelt/texturen/"
const MAT := "res://assets/zelt/materialien/"
const SZ := "res://scenes/zelt/"
const ZELT := "res://scenes/tent.tscn"

## Innenmaße (Kollision in main.tscn)
const XI := 12.0
const ZB := -14.0
const ZF := 11.0
const TRAUFE := 7.0
const WAND_H := 7.05
const FIRST := 11.5
const K := 4.5 / 12.3          # Dachneigung (Höhe je Meter)
## Binder/Hauptpfosten entlang der Zeltlänge
const BINDER := [-11.5, -6.5, -1.5, 3.5, 8.5]
## Emporen (GameManager: EMPORE_Y, EMPORE_KANTE)
const EMPORE_Y := 3.6
const EMPORE_KANTE := 7.8
const TREPPE_INNEN := 10.7     # |x| der Treppen-Innenseite, Treppe liegt an der Wand
## Stützen unter der Emporenkante — nicht in Bühne, Büro, Klo
const STUETZEN_WEST := [-11.5, -6.5, -1.5, 3.5]
const STUETZEN_OST := [-11.5, -6.5, 8.5]

var _own: Node
var _meshes := {}
var _formen := {}
var m := {}   # Materialien

func _init() -> void:
	if "texturen" in OS.get_cmdline_user_args():
		_texturen()
	else:
		_materialien()
		_bauteile()
		_zelt()
	print("BAKE FERTIG")
	quit()

## Treppe je Seite: unten (z), oben (z), Treppenloch im Emporenboden von la bis lb (z)
func _treppe(s: float) -> Dictionary:
	if s < 0.0:
		return {"zu": 0.0, "zo": 6.5, "la": 2.5, "lb": 6.5}
	return {"zu": -10.0, "zo": -3.5, "la": -7.5, "lb": -3.5}

# ------------------------------------------------------------------ Texturen

func _png(img: Image, name: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEX))
	img.save_png(TEX + name + ".png")
	print("  Textur ", name)

func _rauschen(groesse: int, freq: float, typ := FastNoiseLite.TYPE_SIMPLEX_SMOOTH, oktaven := 4, seed_ := 1) -> Image:
	var n := FastNoiseLite.new()
	n.noise_type = typ
	n.frequency = freq
	n.fractal_octaves = oktaven
	n.seed = seed_
	return n.get_seamless_image(groesse, groesse)

func _texturen() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7

	# Dielen: 8 Bretter je Kachel, versetzte Stöße, Maserung, dunkle Fugen
	var s := 512
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var ni := _rauschen(s, 0.02, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 3, 3)
	var farben := []
	var stoss := []
	for i in 8:
		farben.append(Color(0.60, 0.40, 0.23).lerp(Color(0.76, 0.54, 0.32), rng.randf()))
		stoss.append(rng.randf())
	for y in s:
		var v := float(y) / s
		for x in s:
			var i := x / 64
			var lx := x % 64
			var nv := ni.get_pixel(x, y).r
			var c: Color = farben[i]
			var maser := 0.5 + 0.5 * sin(TAU * (v * 6.0 + nv * 1.6 + i * 0.37))
			c = c.darkened(0.14 * maser).lightened(0.06 * nv)
			if lx < 2 or lx >= 63:
				c = c.darkened(0.6)
			elif fposmod(v - float(stoss[i]), 1.0) < 0.005:
				c = c.darkened(0.5)
			img.set_pixel(x, y, c)
	_png(img, "dielen")

	# Holz für Balken und Galerie
	s = 256
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	ni = _rauschen(s, 0.03, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 3, 5)
	for y in s:
		for x in s:
			var u := float(x) / s
			var nv := ni.get_pixel(x, y).r
			var c := Color(0.62, 0.41, 0.23)
			c = c.darkened(0.16 * (0.5 + 0.5 * sin(TAU * (u * 12.0 + nv * 0.5)))).lightened(0.05 * nv)
			img.set_pixel(x, y, c)
	_png(img, "holz")

	# Zeltstoff: cremeweiß, feine Webung, eine Naht je Kachel
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	ni = _rauschen(s, 0.05, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 3, 9)
	for y in s:
		for x in s:
			var c := Color(0.95, 0.92, 0.84).darkened(0.05 * ni.get_pixel(x, y).r)
			if (x % 4 < 2) != (y % 4 < 2):
				c = c.darkened(0.02)
			if x < 3:
				c = c.darkened(0.1)
			img.set_pixel(x, y, c)
	_png(img, "stoff")

	# Himmel der Bayern: hellblau mit weißen Wolken
	s = 1024
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	ni = _rauschen(s, 0.0035, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 5, 21)
	var blau := Color(0.50, 0.72, 0.93)
	for y in s:
		for x in s:
			var n := ni.get_pixel(x, y).r
			var t := smoothstep(0.5, 0.78, n)
			var c := blau.lerp(Color(0.99, 0.99, 1.0), t)
			c = c.darkened(0.25 * t * (1.0 - t))
			img.set_pixel(x, y, c)
	_png(img, "himmel")

	# Blau-weiße Streifen (Dachplane, Maibaum)
	s = 256
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var c := Color(0.96, 0.96, 0.94) if y < s / 2 else Color(0.13, 0.35, 0.70)
			if y % (s / 2) < 2:
				c = c.darkened(0.15)
			img.set_pixel(x, y, c)
	_png(img, "streifen")

	# Bayerische Rauten
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var u := float(x) / s
			var v := float(y) / s
			var a := floori((u + v) * 4.0)
			var b := floori((u - v) * 4.0)
			var c := Color(0.12, 0.40, 0.78) if posmod(a + b, 2) == 0 else Color(0.97, 0.97, 0.97)
			img.set_pixel(x, y, c)
	_png(img, "rauten")

	# Hopfen: zelliges Grün
	img = Image.create(s, s, false, Image.FORMAT_RGB8)
	var nz := FastNoiseLite.new()
	nz.noise_type = FastNoiseLite.TYPE_CELLULAR
	nz.frequency = 0.07
	nz.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	ni = nz.get_seamless_image(s, s)
	var n2 := _rauschen(s, 0.04, FastNoiseLite.TYPE_SIMPLEX_SMOOTH, 3, 13)
	for y in s:
		for x in s:
			var n := ni.get_pixel(x, y).r
			var c := Color(0.55, 0.72, 0.28).lerp(Color(0.16, 0.32, 0.10), n)
			c = c.lerp(Color(0.72, 0.78, 0.36), 0.25 * n2.get_pixel(x, y).r)
			img.set_pixel(x, y, c)
	_png(img, "hopfen")

# ---------------------------------------------------------------- Materialien

func _mat_tex(name: String, tex: String, kachel: Vector3, farbe := Color.WHITE, rauheit := 0.85) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_texture = load(TEX + tex + ".png")
	mt.albedo_color = farbe
	mt.uv1_triplanar = true
	mt.uv1_world_triplanar = true
	mt.uv1_scale = Vector3(1.0 / kachel.x, 1.0 / kachel.y, 1.0 / kachel.z)
	mt.roughness = rauheit
	return _mat_speichern(name, mt)

func _mat_farbe(name: String, farbe: Color, rauheit := 0.8, glut := 0.0, glut_farbe := Color.WHITE) -> StandardMaterial3D:
	var mt := StandardMaterial3D.new()
	mt.albedo_color = farbe
	mt.roughness = rauheit
	if glut > 0.0:
		mt.emission_enabled = true
		mt.emission = glut_farbe
		mt.emission_energy_multiplier = glut
	return _mat_speichern(name, mt)

func _mat_speichern(name: String, mt: StandardMaterial3D) -> StandardMaterial3D:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(MAT))
	var pfad := MAT + name + ".tres"
	ResourceSaver.save(mt, pfad)
	m[name] = ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_REPLACE)
	return m[name]

func _materialien() -> void:
	_mat_tex("dielen", "dielen", Vector3(1.6, 1.6, 1.6), Color.WHITE, 0.8)
	_mat_tex("holz_hell", "holz", Vector3(1.2, 1.2, 1.2), Color(1, 1, 1), 0.75)
	_mat_tex("vertaefelung", "dielen", Vector3(1.6, 1.2, 1.6), Color(0.8, 0.72, 0.68), 0.8)
	_mat_tex("holz_dunkel", "holz", Vector3(1.2, 1.2, 1.2), Color(0.55, 0.5, 0.48), 0.75)
	_mat_tex("stoff", "stoff", Vector3(3.0, 3.0, 3.0), Color.WHITE, 0.95)
	_mat_tex("streifen", "streifen", Vector3(2.4, 2.4, 2.4), Color.WHITE, 0.9)
	_mat_tex("streifen_fein", "streifen", Vector3(0.6, 0.6, 0.6), Color.WHITE, 0.8)
	_mat_tex("rauten", "rauten", Vector3(0.9, 1.3, 0.9), Color.WHITE, 0.8)
	_mat_tex("rauten_fein", "rauten", Vector3(0.45, 0.6, 0.45), Color.WHITE, 0.8)
	_mat_tex("hopfen", "hopfen", Vector3(0.5, 0.5, 0.5), Color.WHITE, 0.9)
	var himmel := StandardMaterial3D.new()
	himmel.albedo_texture = load(TEX + "himmel.png")
	himmel.uv1_triplanar = true
	himmel.uv1_world_triplanar = true
	himmel.uv1_scale = Vector3.ONE / 16.0
	himmel.roughness = 1.0
	himmel.emission_enabled = true
	himmel.emission_texture = himmel.albedo_texture
	himmel.emission = Color.WHITE
	himmel.emission_energy_multiplier = 0.35
	_mat_speichern("himmel", himmel)
	_mat_farbe("blau", Color(0.12, 0.34, 0.72), 0.7)
	_mat_farbe("weiss", Color(0.95, 0.95, 0.93), 0.8)
	_mat_farbe("rot", Color(0.72, 0.1, 0.1), 0.7)
	_mat_farbe("lebkuchen", Color(0.5, 0.27, 0.12), 0.8)
	_mat_farbe("gold", Color(0.95, 0.72, 0.25), 0.35, 0.25, Color(1.0, 0.75, 0.3))
	_mat_farbe("metall", Color(0.13, 0.12, 0.12), 0.5)
	_mat_farbe("glas", Color(0.85, 0.92, 1.0), 0.2, 0.9, Color(0.9, 0.95, 1.0))
	_mat_farbe("laternenglas", Color(1.0, 0.85, 0.6), 0.3, 2.2, Color(1.0, 0.72, 0.4))
	_mat_farbe("gluehbirne", Color(1.0, 0.9, 0.7), 0.3, 3.0, Color(1.0, 0.76, 0.45))

# ------------------------------------------------------------------- Helfer

func _neu(name: String) -> Node3D:
	var r := Node3D.new()
	r.name = name
	_own = r
	_meshes = {}
	_formen = {}
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

func _mi(parent: Node, name: String, mesh: Mesh, xf: Transform3D, mat: Material, schatten := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = xf
	mi.material_override = mat
	if not schatten:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return _haengen(parent, mi, name)

func _cache(key: String, erzeuge: Callable) -> Mesh:
	if not _meshes.has(key):
		_meshes[key] = erzeuge.call()
	return _meshes[key]

func _box_mesh(g: Vector3) -> Mesh:
	return _cache("box%.3f_%.3f_%.3f" % [g.x, g.y, g.z], func() -> Mesh:
		var b := BoxMesh.new()
		b.size = g
		return b)

func _rot(grad: Vector3) -> Basis:
	return Basis.from_euler(Vector3(deg_to_rad(grad.x), deg_to_rad(grad.y), deg_to_rad(grad.z)))

func _box(parent: Node, name: String, g: Vector3, pos: Vector3, mat: Material, grad := Vector3.ZERO, schatten := true) -> MeshInstance3D:
	return _mi(parent, name, _box_mesh(g), Transform3D(_rot(grad), pos), mat, schatten)

## Kollisionsquader unter einem StaticBody3D
func _kollision(koerper: Node, name: String, g: Vector3, xf: Transform3D) -> CollisionShape3D:
	var key := "%.3f_%.3f_%.3f" % [g.x, g.y, g.z]
	if not _formen.has(key):
		var f := BoxShape3D.new()
		f.size = g
		_formen[key] = f
	var cs := CollisionShape3D.new()
	cs.shape = _formen[key]
	cs.transform = xf
	return _haengen(koerper, cs, name)

## Transform, dessen Y-Achse von a nach b zeigt (Mitte zwischen beiden)
func _achse(a: Vector3, b: Vector3) -> Transform3D:
	var y := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Transform3D(Basis(x, y, z), (a + b) * 0.5)

func _balken(parent: Node, name: String, a: Vector3, b: Vector3, dicke: float, mat: Material, schatten := true) -> MeshInstance3D:
	return _mi(parent, name, _box_mesh(Vector3(dicke, a.distance_to(b), dicke)), _achse(a, b), mat, schatten)

func _stange(parent: Node, name: String, a: Vector3, b: Vector3, radius: float, mat: Material, schatten := true) -> MeshInstance3D:
	var l := a.distance_to(b)
	var mesh := _cache("zyl%.3f_%.3f" % [radius, l], func() -> Mesh:
		var c := CylinderMesh.new()
		c.top_radius = radius
		c.bottom_radius = radius
		c.height = l
		c.radial_segments = 8
		c.rings = 1
		return c)
	return _mi(parent, name, mesh, _achse(a, b), mat, schatten)

func _kugel(parent: Node, name: String, radius: float, pos: Vector3, mat: Material, schatten := true) -> MeshInstance3D:
	var mesh := _cache("kugel%.3f" % radius, func() -> Mesh:
		var k := SphereMesh.new()
		k.radius = radius
		k.height = radius * 2.0
		k.radial_segments = 12
		k.rings = 6
		return k)
	return _mi(parent, name, mesh, Transform3D(Basis(), pos), mat, schatten)

func _kegel(parent: Node, name: String, unten: float, oben: float, hoehe: float, segmente: int, xf: Transform3D, mat: Material) -> MeshInstance3D:
	var mesh := _cache("kegel%.3f_%.3f_%.3f_%d" % [unten, oben, hoehe, segmente], func() -> Mesh:
		var c := CylinderMesh.new()
		c.top_radius = oben
		c.bottom_radius = unten
		c.height = hoehe
		c.radial_segments = segmente
		c.rings = 1
		return c)
	return _mi(parent, name, mesh, xf, mat)

func _pyramide(parent: Node, name: String, breite: float, hoehe: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	return _kegel(parent, name, breite * 0.7071, 0.0, hoehe, 4, Transform3D(_rot(Vector3(0, 45, 0)), pos), mat)

func _torus(parent: Node, name: String, innen: float, aussen: float, xf: Transform3D, mat: Material, schatten := true) -> MeshInstance3D:
	var mesh := _cache("torus%.3f_%.3f" % [innen, aussen], func() -> Mesh:
		var t := TorusMesh.new()
		t.inner_radius = innen
		t.outer_radius = aussen
		t.rings = 28
		t.ring_segments = 8
		return t)
	return _mi(parent, name, mesh, xf, mat, schatten)

func _prisma(parent: Node, name: String, g: Vector3, xf: Transform3D, mat: Material, schatten := true) -> MeshInstance3D:
	var mesh := _cache("prisma%.3f_%.3f_%.3f" % [g.x, g.y, g.z], func() -> Mesh:
		var p := PrismMesh.new()
		p.size = g
		return p)
	return _mi(parent, name, mesh, xf, mat, schatten)

func _licht(parent: Node, name: String, pos: Vector3, energie: float, reichweite: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1.0, 0.74, 0.44)
	l.light_energy = energie
	l.omni_range = reichweite
	l.omni_attenuation = 1.4
	l.shadow_enabled = false
	return _haengen(parent, l, name)

func _instanz(parent: Node, szene: PackedScene, name: String, xf: Transform3D) -> Node3D:
	var n := szene.instantiate() as Node3D
	n.transform = xf
	n.name = name
	parent.add_child(n)
	n.owner = _own
	return n

func _speichern(root: Node, pfad: String) -> PackedScene:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pfad.get_base_dir()))
	var alte_uid := ""
	if FileAccess.file_exists(pfad):
		var kopf := FileAccess.get_file_as_string(pfad).get_slice("\n", 0)
		var treffer := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(kopf)
		if treffer:
			alte_uid = treffer.get_string(1)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack %s: %d" % [pfad, err])
	ResourceSaver.save(ps, pfad)
	root.free()
	# UID behalten, damit main.tscn & Co. die Szene weiter über die UID finden
	if alte_uid != "":
		var text := FileAccess.get_file_as_string(pfad)
		var erste := text.get_slice("\n", 0)
		var neu := RegEx.create_from_string(" uid=\"uid://[a-z0-9]+\"").sub(erste, "")
		neu = neu.replace("]", " uid=\"%s\"]" % alte_uid)
		var f := FileAccess.open(pfad, FileAccess.WRITE)
		f.store_string(neu + text.substr(erste.length()))
		f.close()
	print("  Szene ", pfad)
	return ResourceLoader.load(pfad, "", ResourceLoader.CACHE_MODE_REPLACE)

# ------------------------------------------------------------------ Bauteile

var s_leuchter: PackedScene
var s_laterne: PackedScene
var s_fenster: PackedScene
var s_fahne: PackedScene
var s_krone: PackedScene
var s_wappen: PackedScene
var s_blumen: PackedScene
var s_girlande := {}
var s_wimpel: PackedScene
var s_herz: PackedScene
var s_lichterkette: PackedScene
var s_maibaum: PackedScene
var s_fass: PackedScene

func _bauteile() -> void:
	s_leuchter = _speichern(_bau_leuchter(), SZ + "kranzleuchter.tscn")
	s_laterne = _speichern(_bau_laterne(), SZ + "wandlaterne.tscn")
	s_fenster = _speichern(_bau_fenster(), SZ + "fenster.tscn")
	s_fahne = _speichern(_bau_fahne(), SZ + "fahne.tscn")
	s_krone = _speichern(_bau_krone(), SZ + "krone.tscn")
	s_wappen = _speichern(_bau_wappen(), SZ + "wappen.tscn")
	s_blumen = _speichern(_bau_blumenkasten(), SZ + "blumenkasten.tscn")
	for l in [2.5, 5.0, 6.0]:
		s_girlande[l] = _speichern(_bau_girlande(l), SZ + "girlande_%s.tscn" % String.num(l).replace(".", "_"))
	s_wimpel = _speichern(_bau_wimpel(5.0), SZ + "wimpelkette_5.tscn")
	s_herz = _speichern(_bau_herz(), SZ + "lebkuchenherz.tscn")
	s_lichterkette = _speichern(_bau_lichterkette(13.6), SZ + "lichterkette_giebel.tscn")
	s_maibaum = _speichern(_bau_maibaum(), SZ + "maibaum.tscn")
	s_fass = _speichern(_bau_fass(), SZ + "fass.tscn")

## Hopfenkranz mit Glühbirnen und Bändern — hängt an einer Kette (Oberkante y 1.65)
func _bau_leuchter() -> Node3D:
	var r := _neu("Kranzleuchter")
	_torus(r, "Hopfenkranz", 0.78, 1.06, Transform3D(), m.hopfen)
	_torus(r, "Goldreif", 0.9, 0.96, Transform3D(Basis(), Vector3(0, 0.1, 0)), m.gold)
	var birnen := _gruppe(r, "Gluehbirnen")
	for i in 10:
		var w := TAU * i / 10.0
		_kugel(birnen, "Birne%d" % (i + 1), 0.075, Vector3(cos(w) * 0.93, 0.17, sin(w) * 0.93), m.gluehbirne, false)
	for i in 3:
		var w := TAU * i / 3.0 + 0.5
		_stange(r, "Kette%d" % (i + 1), Vector3(cos(w) * 0.92, 0.12, sin(w) * 0.92), Vector3(0, 1.2, 0), 0.015, m.metall, false)
	_stange(r, "Hauptkette", Vector3(0, 1.2, 0), Vector3(0, 1.65, 0), 0.02, m.metall, false)
	var baender := _gruppe(r, "Baender")
	for i in 8:
		var w := TAU * (i + 0.5) / 8.0
		_box(baender, "Band%d" % (i + 1), Vector3(0.08, 0.7, 0.01), Vector3(cos(w) * 1.0, -0.36, sin(w) * 1.0),
			m.blau if i % 2 == 0 else m.weiss, Vector3(0, -rad_to_deg(w) + 90.0, 0), false)
	_licht(r, "Licht", Vector3(0, -0.1, 0), 1.7, 9.5)
	return r

## Wandlaterne: Ursprung an der Wand, ragt nach +Z
func _bau_laterne() -> Node3D:
	var r := _neu("Wandlaterne")
	_box(r, "Wandplatte", Vector3(0.14, 0.4, 0.03), Vector3(0, 0.22, 0.015), m.metall)
	_box(r, "Arm", Vector3(0.04, 0.04, 0.42), Vector3(0, 0.36, 0.21), m.metall)
	_stange(r, "Haken", Vector3(0, 0.36, 0.38), Vector3(0, 0.27, 0.38), 0.012, m.metall, false)
	_box(r, "Glas", Vector3(0.2, 0.3, 0.2), Vector3(0, 0.1, 0.38), m.laternenglas, Vector3.ZERO, false)
	for i in 4:
		var dx := 0.1 if i % 2 == 0 else -0.1
		var dz := 0.1 if i < 2 else -0.1
		_box(r, "Strebe%d" % (i + 1), Vector3(0.03, 0.34, 0.03), Vector3(dx, 0.1, 0.38 + dz), m.metall)
	_box(r, "Boden", Vector3(0.25, 0.03, 0.25), Vector3(0, -0.06, 0.38), m.metall)
	_pyramide(r, "Dach", 0.3, 0.14, Vector3(0, 0.32, 0.38), m.metall)
	_licht(r, "Licht", Vector3(0, 0.1, 0.5), 1.0, 5.5)
	return r

## Sprossenfenster mit Läden, Tiefe 0.42 — sitzt mittig in einer 0.3 m dicken Wand
func _bau_fenster() -> Node3D:
	var r := _neu("Fenster")
	_box(r, "Glas", Vector3(1.16, 0.86, 0.34), Vector3.ZERO, m.glas, Vector3.ZERO, false)
	_box(r, "RahmenOben", Vector3(1.36, 0.1, 0.42), Vector3(0, 0.48, 0), m.holz_dunkel)
	_box(r, "RahmenUnten", Vector3(1.36, 0.1, 0.42), Vector3(0, -0.48, 0), m.holz_dunkel)
	_box(r, "RahmenLinks", Vector3(0.1, 1.06, 0.42), Vector3(-0.63, 0, 0), m.holz_dunkel)
	_box(r, "RahmenRechts", Vector3(0.1, 1.06, 0.42), Vector3(0.63, 0, 0), m.holz_dunkel)
	_box(r, "SprosseSenkrecht", Vector3(0.05, 0.86, 0.38), Vector3.ZERO, m.holz_dunkel)
	_box(r, "SprosseWaagrecht", Vector3(1.16, 0.05, 0.38), Vector3(0, 0.12, 0), m.holz_dunkel)
	_box(r, "Fensterbank", Vector3(1.46, 0.06, 0.52), Vector3(0, -0.55, 0), m.holz_hell)
	_prisma(r, "Giebel", Vector3(1.5, 0.28, 0.44), Transform3D(Basis(), Vector3(0, 0.67, 0)), m.holz_dunkel)
	# Läden nur außen (+Z) — die Fenster werden so gedreht, dass +Z nach draußen zeigt
	_box(r, "LadenLinks", Vector3(0.5, 1.0, 0.04), Vector3(-0.95, 0, 0.23), m.blau)
	_box(r, "LadenRechts", Vector3(0.5, 1.0, 0.04), Vector3(0.95, 0, 0.23), m.blau)
	return r

func _bau_fahne() -> Node3D:
	var r := _neu("Fahne")
	_stange(r, "Mast", Vector3.ZERO, Vector3(0, 2.4, 0), 0.04, m.weiss)
	_kugel(r, "Spitze", 0.09, Vector3(0, 2.46, 0), m.gold)
	_box(r, "Tuch", Vector3(1.3, 0.85, 0.02), Vector3(0.69, 1.95, 0), m.rauten_fein)
	return r

func _bau_krone() -> Node3D:
	var r := _neu("Krone")
	_torus(r, "Reif", 0.56, 0.72, Transform3D(Basis(), Vector3(0, 0.08, 0)), m.gold)
	_kegel(r, "Band", 0.62, 0.7, 0.45, 16, Transform3D(Basis(), Vector3(0, 0.3, 0)), m.gold)
	var polster := _kugel(r, "Polster", 0.6, Vector3(0, 0.62, 0), m.rot)
	polster.scale = Vector3(1, 0.75, 1)
	var zacken := _gruppe(r, "Zacken")
	for i in 5:
		var w := TAU * i / 5.0
		var p := Vector3(sin(w) * 0.66, 0.78, cos(w) * 0.66)
		_prisma(zacken, "Zacke%d" % (i + 1), Vector3(0.34, 0.62, 0.08), Transform3D(_rot(Vector3(0, rad_to_deg(w), 0)), p), m.gold)
		_kugel(zacken, "Perle%d" % (i + 1), 0.08, p + Vector3(0, 0.36, 0), m.weiss)
	_kugel(r, "Reichsapfel", 0.17, Vector3(0, 1.22, 0), m.gold)
	_box(r, "KreuzSenkrecht", Vector3(0.07, 0.4, 0.07), Vector3(0, 1.55, 0), m.gold)
	_box(r, "KreuzWaagrecht", Vector3(0.26, 0.07, 0.07), Vector3(0, 1.6, 0), m.gold)
	return r

## Rautenwappen im Hopfenkranz mit Krone — steht senkrecht, schaut nach +Z
func _bau_wappen() -> Node3D:
	var r := _neu("Wappen")
	var steh := Basis.from_euler(Vector3(PI / 2, 0, 0))
	_torus(r, "Hopfenkranz", 1.0, 1.38, Transform3D(steh, Vector3.ZERO), m.hopfen)
	_kegel(r, "Rautenschild", 1.02, 1.02, 0.06, 32, Transform3D(steh, Vector3(0, 0, -0.02)), m.rauten_fein)
	_torus(r, "Goldrand", 0.98, 1.07, Transform3D(steh, Vector3(0, 0, 0.05)), m.gold)
	_instanz(r, s_krone, "Krone", Transform3D(Basis().scaled(Vector3.ONE * 0.7), Vector3(0, 1.25, 0.1)))
	_box(r, "BandBlau", Vector3(0.22, 1.1, 0.02), Vector3(-0.55, -1.55, 0.1), m.blau, Vector3(0, 0, -18))
	_box(r, "BandWeiss", Vector3(0.22, 1.1, 0.02), Vector3(0.55, -1.55, 0.1), m.weiss, Vector3(0, 0, 18))
	return r

func _bau_blumenkasten() -> Node3D:
	var r := _neu("Blumenkasten")
	_box(r, "Kasten", Vector3(1.4, 0.26, 0.3), Vector3(0, 0.13, 0), m.holz_dunkel)
	var farben := [m.rot, m.rot, m.weiss, m.rot, m.rot]
	for i in 5:
		var x := -0.56 + i * 0.28
		_kugel(r, "Blatt%d" % (i + 1), 0.15, Vector3(x, 0.3, 0.02), m.hopfen)
		_kugel(r, "Bluete%d" % (i + 1), 0.09, Vector3(x + 0.05, 0.42, 0.08), farben[i])
	_kugel(r, "Ranke1", 0.1, Vector3(-0.5, 0.02, 0.16), m.hopfen)
	_kugel(r, "Ranke2", 0.1, Vector3(0.45, -0.02, 0.16), m.hopfen)
	return r

## Hopfengirlande entlang X, hängt in der Mitte durch
func _bau_girlande(laenge: float) -> Node3D:
	var r := _neu("Girlande")
	var durchhang := laenge * 0.11
	var n := 6
	var punkte := []
	for i in n + 1:
		var t := float(i) / n
		punkte.append(Vector3(-laenge / 2.0 + laenge * t, -durchhang * (1.0 - pow(2.0 * t - 1.0, 2.0)), 0))
	for i in n:
		_stange(r, "Stueck%d" % (i + 1), punkte[i], punkte[i + 1], 0.045, m.hopfen)
	for i in range(1, n):
		_kugel(r, "Dolde%d" % i, 0.08, punkte[i], m.hopfen)
	_box(r, "SchleifeLinks", Vector3(0.18, 0.28, 0.04), punkte[0] + Vector3(0, -0.12, 0.06), m.blau)
	_box(r, "SchleifeRechts", Vector3(0.18, 0.28, 0.04), punkte[n] + Vector3(0, -0.12, 0.06), m.blau)
	return r

## Blau-weiße Wimpelkette entlang X
func _bau_wimpel(laenge: float) -> Node3D:
	var r := _neu("Wimpelkette")
	var durchhang := laenge * 0.07
	var n := 4
	var punkte := []
	for i in n + 1:
		var t := float(i) / n
		punkte.append(Vector3(-laenge / 2.0 + laenge * t, -durchhang * (1.0 - pow(2.0 * t - 1.0, 2.0)), 0))
	for i in n:
		_stange(r, "Schnur%d" % (i + 1), punkte[i], punkte[i + 1], 0.01, m.weiss, false)
	var wimpel := _gruppe(r, "Wimpel")
	var zahl := int(laenge / 0.42)
	for i in zahl:
		var t := (i + 0.5) / zahl
		var y := -durchhang * (1.0 - pow(2.0 * t - 1.0, 2.0))
		_prisma(wimpel, "Wimpel%d" % (i + 1), Vector3(0.28, 0.36, 0.01),
			Transform3D(_rot(Vector3(0, 0, 180)), Vector3(-laenge / 2.0 + laenge * t, y - 0.18, 0)),
			m.blau if i % 2 == 0 else m.weiss, false)
	return r

## Lebkuchenherz an einer Schnur, schaut nach +Z (Ursprung = Aufhängung)
func _bau_herz() -> Node3D:
	var r := _neu("Lebkuchenherz")
	var steh := Basis.from_euler(Vector3(PI / 2, 0, 0))
	_kegel(r, "BogenLinks", 0.17, 0.17, 0.05, 16, Transform3D(steh, Vector3(-0.12, -0.42, 0)), m.lebkuchen)
	_kegel(r, "BogenRechts", 0.17, 0.17, 0.05, 16, Transform3D(steh, Vector3(0.12, -0.42, 0)), m.lebkuchen)
	_prisma(r, "Spitze", Vector3(0.58, 0.4, 0.05), Transform3D(_rot(Vector3(0, 0, 180)), Vector3(0, -0.66, 0)), m.lebkuchen)
	_torus(r, "Zuckerguss", 0.1, 0.125, Transform3D(steh, Vector3(0, -0.52, 0.03)), m.weiss, false)
	_box(r, "Schrift", Vector3(0.22, 0.04, 0.01), Vector3(0, -0.52, 0.035), m.rot, Vector3.ZERO, false)
	_stange(r, "Schnur", Vector3.ZERO, Vector3(0, -0.3, 0), 0.008, m.blau, false)
	return r

## Lichterkette entlang X (Glühbirnen ohne eigenes Licht)
func _bau_lichterkette(laenge: float) -> Node3D:
	var r := _neu("Lichterkette")
	_stange(r, "Kabel", Vector3(-laenge / 2.0, 0, 0), Vector3(laenge / 2.0, 0, 0), 0.012, m.metall, false)
	var birnen := _gruppe(r, "Birnen")
	var zahl := int(laenge / 0.5)
	for i in zahl:
		_kugel(birnen, "Birne%d" % (i + 1), 0.07, Vector3(-laenge / 2.0 + (i + 0.5) * laenge / zahl, -0.08, 0), m.gluehbirne, false)
	return r

## Maibaum: blau-weißer Stamm, Kränze, Zunftzeichen, Tannenspitze
func _bau_maibaum() -> Node3D:
	var r := _neu("Maibaum")
	_box(r, "Sockel", Vector3(1.2, 0.4, 1.2), Vector3(0, 0.2, 0), m.holz_dunkel)
	_kegel(r, "Stamm", 0.24, 0.12, 15.0, 12, Transform3D(Basis(), Vector3(0, 7.9, 0)), m.streifen_fein)
	for y in [9.0, 12.6]:
		_torus(r, "Kranz_%s" % String.num(y), 0.2, 0.5, Transform3D(Basis(), Vector3(0, y, 0)), m.hopfen)
	var schilder := _gruppe(r, "Zunftzeichen")
	var farben := [m.blau, m.rot, m.gold, m.weiss]
	var nr := 0
	for ebene in 3:
		var y := 4.0 + ebene * 1.6
		var drehung := ebene * 60.0
		_box(schilder, "Querholz%d" % (ebene + 1), Vector3(2.6, 0.08, 0.08), Vector3(0, y, 0), m.holz_dunkel, Vector3(0, drehung, 0))
		for seite: float in [-1.0, 1.0]:
			nr += 1
			var aussen := Basis.from_euler(Vector3(0, deg_to_rad(drehung), 0)) * Vector3(seite * 1.15, 0, 0)
			_box(schilder, "Schild%d" % nr, Vector3(0.55, 0.55, 0.04), Vector3(aussen.x, y - 0.4, aussen.z), farben[nr % farben.size()], Vector3(0, drehung, 0))
			_kugel(schilder, "Figur%d" % nr, 0.12, Vector3(aussen.x, y + 0.16, aussen.z), m.gold)
	_kegel(r, "Tannenspitze", 0.7, 0.0, 1.8, 8, Transform3D(Basis(), Vector3(0, 16.2, 0)), m.hopfen)
	var koerper := StaticBody3D.new()
	_haengen(r, koerper, "Kollision")
	_kollision(koerper, "Form", Vector3(0.6, 3.0, 0.6), Transform3D(Basis(), Vector3(0, 1.5, 0)))
	return r

## Bierfass (stehend) mit zwei Eisenreifen
func _bau_fass() -> Node3D:
	var r := _neu("Fass")
	_kegel(r, "Dauben", 0.36, 0.36, 0.9, 16, Transform3D(Basis(), Vector3(0, 0.45, 0)), m.holz_hell)
	_kegel(r, "Bauch", 0.4, 0.4, 0.4, 16, Transform3D(Basis(), Vector3(0, 0.45, 0)), m.holz_hell)
	for y in [0.12, 0.78]:
		_torus(r, "Reif_%s" % String.num(y), 0.36, 0.395, Transform3D(Basis(), Vector3(0, y, 0)), m.metall)
	_kegel(r, "Deckel", 0.33, 0.33, 0.02, 16, Transform3D(Basis(), Vector3(0, 0.91, 0)), m.holz_dunkel)
	return r

# ---------------------------------------------------------------------- Zelt

func _dach_y(s: float, x: float) -> float:
	return FIRST - s * x * K

func _zelt() -> void:
	var r := _neu("Tent")
	_boden(_gruppe(r, "Boden"))
	_waende(_gruppe(r, "Waende"))
	_galerie(_gruppe(r, "Galerie"))
	_dach(_gruppe(r, "Dach"))
	_beleuchtung(_gruppe(r, "Beleuchtung"))
	_deko(_gruppe(r, "Deko"))
	_fassade(_gruppe(r, "Fassade"))
	_speichern(r, ZELT)

func _boden(g: Node3D) -> void:
	# Oberkante 0.07 — knapp über dem Kirmes-Gelände (Terrain y 0.056)
	_box(g, "Dielen", Vector3(24.0, 0.1, 25.0), Vector3(0, 0.02, -1.5), m.dielen, Vector3.ZERO, false)
	_box(g, "Schwelle", Vector3(6.6, 0.1, 1.4), Vector3(0, 0.02, 11.7), m.dielen, Vector3.ZERO, false)
	_box(g, "SockelWest", Vector3(0.05, 0.12, 25.0), Vector3(-11.95, 0.12, -1.5), m.holz_dunkel, Vector3.ZERO, false)
	_box(g, "SockelOst", Vector3(0.05, 0.12, 25.0), Vector3(11.95, 0.12, -1.5), m.holz_dunkel, Vector3.ZERO, false)
	_box(g, "SockelHinten", Vector3(24.0, 0.12, 0.05), Vector3(0, 0.12, -13.95), m.holz_dunkel, Vector3.ZERO, false)

func _waende(g: Node3D) -> void:
	var h := WAND_H
	var stoff := _gruppe(g, "Stoffwaende")
	_box(stoff, "WandWest", Vector3(0.3, h, 25.6), Vector3(-XI - 0.15, h / 2, -1.5), m.stoff)
	_box(stoff, "WandOst", Vector3(0.3, h, 25.6), Vector3(XI + 0.15, h / 2, -1.5), m.stoff)
	_box(stoff, "WandHinten", Vector3(24.6, h, 0.3), Vector3(0, h / 2, ZB - 0.15), m.stoff)
	_box(stoff, "WandVorneLinks", Vector3(9.3, h, 0.3), Vector3(-7.65, h / 2, ZF + 0.15), m.stoff)
	_box(stoff, "WandVorneRechts", Vector3(9.3, h, 0.3), Vector3(7.65, h / 2, ZF + 0.15), m.stoff)
	_box(stoff, "WandUeberTor", Vector3(6.0, h - 3.3, 0.3), Vector3(0, 3.3 + (h - 3.3) / 2, ZF + 0.15), m.stoff)

	# Holzvertäfelung unten, innen und außen
	var vt := _gruppe(g, "Vertaefelung")
	for s: float in [-1.0, 1.0]:
		var seite := "West" if s < 0 else "Ost"
		_box(vt, "Innen" + seite, Vector3(0.06, 1.2, 25.0), Vector3(s * (XI - 0.03), 0.6, -1.5), m.vertaefelung)
		_box(vt, "Aussen" + seite, Vector3(0.06, 1.2, 25.7), Vector3(s * (XI + 0.33), 0.6, -1.5), m.holz_dunkel)
		_box(vt, "Handleiste" + seite, Vector3(0.1, 0.07, 25.0), Vector3(s * (XI - 0.05), 1.22, -1.5), m.holz_dunkel)
		_box(vt, "InnenVorne" + seite, Vector3(9.0, 1.2, 0.06), Vector3(s * 7.5, 0.6, ZF - 0.03), m.vertaefelung)
		_box(vt, "AussenVorne" + seite, Vector3(9.36, 1.2, 0.06), Vector3(s * 7.68, 0.6, ZF + 0.33), m.holz_dunkel)
	_box(vt, "InnenHinten", Vector3(24.0, 1.2, 0.06), Vector3(0, 0.6, ZB + 0.03), m.vertaefelung)
	_box(vt, "AussenHinten", Vector3(24.7, 1.2, 0.06), Vector3(0, 0.6, ZB - 0.33), m.holz_dunkel)
	_box(vt, "HandleisteHinten", Vector3(24.0, 0.07, 0.1), Vector3(0, 1.22, ZB + 0.05), m.holz_dunkel)

	# Pfosten und Rähm
	var pf := _gruppe(g, "Pfosten")
	for s: float in [-1.0, 1.0]:
		var seite := "West" if s < 0 else "Ost"
		for z: float in BINDER + [ZB + 0.15, ZF - 0.15]:
			_box(pf, "Pfosten%s_%s" % [seite, String.num(z)], Vector3(0.3, h, 0.3), Vector3(s * (XI - 0.15), h / 2, z), m.holz_dunkel)
		_box(pf, "Raehm" + seite, Vector3(0.24, 0.3, 25.0), Vector3(s * (XI - 0.12), TRAUFE - 0.2, -1.5), m.holz_dunkel)
		_box(pf, "PfostenVorne" + seite, Vector3(0.3, h, 0.12), Vector3(s * 7.5, h / 2, ZF - 0.06), m.holz_dunkel)
		_box(pf, "TorPfosten" + seite, Vector3(0.3, 3.3, 0.5), Vector3(s * 3.15, 1.65, ZF + 0.15), m.holz_dunkel)
	for x in [-10.0, -2.5, 2.5, 10.0]:
		_box(pf, "PfostenHinten_%s" % String.num(x), Vector3(0.3, h, 0.12), Vector3(x, h / 2, ZB + 0.06), m.holz_dunkel)
	_box(pf, "RaehmHinten", Vector3(24.0, 0.3, 0.24), Vector3(0, TRAUFE - 0.2, ZB + 0.12), m.holz_dunkel)
	_box(pf, "RaehmVorne", Vector3(24.0, 0.3, 0.24), Vector3(0, TRAUFE - 0.2, ZF - 0.12), m.holz_dunkel)
	_box(pf, "TorSturz", Vector3(6.6, 0.36, 0.5), Vector3(0, 3.48, ZF + 0.15), m.holz_dunkel)

	# Fenster unten und über der Empore, auch Vorder- und Rückwand
	var fe := _gruppe(g, "Fenster")
	var nr := 0
	var pfosten_z: Array = [ZB] + BINDER + [ZF]
	for s: float in [-1.0, 1.0]:
		var t := _treppe(s)
		for i in pfosten_z.size() - 1:
			var a: float = pfosten_z[i]
			var b: float = pfosten_z[i + 1]
			var mitte := (a + b) / 2.0
			var plaetze := [mitte] if b - a < 4.0 else [mitte - 1.2, mitte + 1.2]
			for z: float in plaetze:
				for y in [2.1, 5.35]:
					# Unten nicht hinter der Treppe
					if y < 3.0 and z > float(t.zu) - 0.8 and z < float(t.zo) + 0.8:
						continue
					nr += 1
					_instanz(fe, s_fenster, "Fenster%d" % nr, Transform3D(_rot(Vector3(0, s * 90, 0)), Vector3(s * (XI + 0.15), y, z)))
	for x in [-9.9, 9.9]:
		for y in [2.1, 5.35]:
			nr += 1
			_instanz(fe, s_fenster, "Fenster%d" % nr, Transform3D(Basis(), Vector3(x, y, ZF + 0.15)))
	for x in [-9.8, -6.3, 6.3, 9.8]:
		nr += 1
		_instanz(fe, s_fenster, "Fenster%d" % nr, Transform3D(_rot(Vector3(0, 180, 0)), Vector3(x, 5.35, ZB - 0.15)))

## Begehbare Emporen links und rechts: Boden mit Treppenloch, Brüstung, Stützen,
## Treppe an der Wand — alles mit Kollision (StaticBody „Kollision“ je Seite).
func _galerie(g: Node3D) -> void:
	var laenge := 24.7
	var mz := -1.5
	var ey := EMPORE_Y
	var dicke := 0.22
	for s: float in [-1.0, 1.0]:
		var seite := "West" if s < 0 else "Ost"
		var t := _treppe(s)
		var la: float = t.la
		var lb: float = t.lb
		var e := _gruppe(g, "Empore" + seite)
		var koerper := StaticBody3D.new()
		_haengen(e, koerper, "Kollision")

		# Boden: Innenstreifen + zwei Wandstücke vor und hinter dem Treppenloch
		var innen_b := TREPPE_INNEN - EMPORE_KANTE
		var wand_b := XI - TREPPE_INNEN
		var hinten := ZB + 0.15
		var vorne := ZF - 0.15
		var stuecke := [
			["BodenInnen", Vector3(innen_b, dicke, laenge), Vector3(s * (EMPORE_KANTE + innen_b / 2.0), ey - dicke / 2.0, mz)],
			["BodenHinten", Vector3(wand_b, dicke, la - hinten), Vector3(s * (TREPPE_INNEN + XI) / 2.0, ey - dicke / 2.0, (la + hinten) / 2.0)],
			["BodenVorne", Vector3(wand_b, dicke, vorne - lb), Vector3(s * (TREPPE_INNEN + XI) / 2.0, ey - dicke / 2.0, (lb + vorne) / 2.0)],
		]
		for st: Array in stuecke:
			_box(e, st[0], st[1], st[2], m.dielen)
			_kollision(koerper, st[0], st[1], Transform3D(Basis(), st[2]))
		_box(e, "Unterzug", Vector3(0.3, 0.4, laenge), Vector3(s * (EMPORE_KANTE + 0.15), ey - dicke - 0.2, mz), m.holz_dunkel)
		_box(e, "Stirnbrett", Vector3(0.05, 0.3, laenge), Vector3(s * (EMPORE_KANTE - 0.02), ey - 0.12, mz), m.blau)

		# Brüstung an der Kante
		var kx := s * (EMPORE_KANTE + 0.06)
		_box(e, "Rautenbruestung", Vector3(0.05, 0.62, laenge), Vector3(kx, ey + 0.45, mz), m.rauten)
		_box(e, "Handlauf", Vector3(0.16, 0.1, laenge + 0.1), Vector3(kx, ey + 0.82, mz), m.holz_dunkel)
		_box(e, "Fussleiste", Vector3(0.1, 0.08, laenge), Vector3(kx, ey + 0.15, mz), m.holz_dunkel)
		for i in 11:
			var z := mz - laenge / 2.0 + 0.1 + (laenge - 0.2) * i / 10.0
			_box(e, "Docke%d" % (i + 1), Vector3(0.12, 0.8, 0.12), Vector3(kx, ey + 0.42, z), m.holz_dunkel)
		_kollision(koerper, "Bruestung", Vector3(0.12, 1.1, laenge), Transform3D(Basis(), Vector3(kx, ey + 0.55, mz)))

		# Geländer ums Treppenloch (längs zur Halle, quer am unteren Ende)
		var lx := s * (TREPPE_INNEN - 0.06)
		var qx := s * (TREPPE_INNEN + XI) / 2.0
		_box(e, "LochBruestung", Vector3(0.05, 0.62, lb - la), Vector3(lx, ey + 0.45, (la + lb) / 2.0), m.rauten)
		_box(e, "LochHandlauf", Vector3(0.14, 0.1, lb - la), Vector3(lx, ey + 0.82, (la + lb) / 2.0), m.holz_dunkel)
		_box(e, "LochQuerBruestung", Vector3(wand_b + 0.06, 0.62, 0.05), Vector3(qx, ey + 0.45, la), m.rauten)
		_box(e, "LochQuerHandlauf", Vector3(wand_b + 0.06, 0.1, 0.14), Vector3(qx, ey + 0.82, la), m.holz_dunkel)
		_box(e, "LochEckpfosten", Vector3(0.14, 0.95, 0.14), Vector3(lx, ey + 0.42, la), m.holz_dunkel)
		_kollision(koerper, "LochBruestung", Vector3(0.12, 1.1, lb - la), Transform3D(Basis(), Vector3(lx, ey + 0.55, (la + lb) / 2.0)))
		_kollision(koerper, "LochQuer", Vector3(wand_b, 1.1, 0.12), Transform3D(Basis(), Vector3(qx, ey + 0.55, la)))

		# Stützen unter der Kante mit Kopfbändern
		var hs := ey - dicke - 0.4
		var sx := s * (EMPORE_KANTE + 0.15)
		for z: float in (STUETZEN_WEST if s < 0 else STUETZEN_OST):
			_box(e, "Stuetze_%s" % String.num(z), Vector3(0.28, hs, 0.28), Vector3(sx, hs / 2.0, z), m.holz_dunkel)
			_balken(e, "KopfbandA_%s" % String.num(z), Vector3(sx, hs - 0.7, z), Vector3(sx, hs, z - 0.7), 0.12, m.holz_dunkel)
			_balken(e, "KopfbandB_%s" % String.num(z), Vector3(sx, hs - 0.7, z), Vector3(sx, hs, z + 0.7), 0.12, m.holz_dunkel)
			_kollision(koerper, "Stuetze_%s" % String.num(z), Vector3(0.28, hs, 0.28), Transform3D(Basis(), Vector3(sx, hs / 2.0, z)))

		# Hopfengirlanden, Lebkuchenherzen und Blumenkästen an der Brüstung
		var pz: Array = [ZB + 0.2] + BINDER + [ZF - 0.2]
		for i in pz.size() - 1:
			var a: float = pz[i]
			var b: float = pz[i + 1]
			var szene: PackedScene = s_girlande[2.5] if b - a < 4.0 else s_girlande[5.0]
			_instanz(e, szene, "Girlande%d" % (i + 1), Transform3D(_rot(Vector3(0, 90, 0)), Vector3(s * (EMPORE_KANTE - 0.08), ey + 0.78, (a + b) / 2.0)))
			if b - a >= 4.0:
				_instanz(e, s_herz, "Herz%d" % (i + 1), Transform3D(_rot(Vector3(0, -s * 90, 0)), Vector3(s * (EMPORE_KANTE - 0.1), ey + 0.8, (a + b) / 2.0)))
		for i in 4:
			var z := -11.0 + i * 6.5
			_instanz(e, s_blumen, "Blumenkasten%d" % (i + 1), Transform3D(_rot(Vector3(0, -s * 90, 0)), Vector3(s * (EMPORE_KANTE - 0.25), ey + 0.02, z)))

		# Treppe an der Wand: Stufen, Wangen, Handlauf; Rampe als Kollision
		var tr := _gruppe(e, "Treppe")
		var zu: float = t.zu
		var zo: float = t.zo
		var lauf := zo - zu
		var n := 18
		var steigung := ey / n
		var tritt := lauf / n
		for i in n:
			_box(tr, "Stufe%d" % (i + 1), Vector3(wand_b - 0.06, 0.07, tritt + 0.04),
				Vector3(qx, steigung * (i + 1) - 0.035, zu + tritt * (i + 0.5)), m.dielen)
		var winkel := atan2(ey, lauf)
		var schraeg := sqrt(ey * ey + lauf * lauf)
		var neigung := Vector3(-rad_to_deg(winkel), 0, 0)
		var mitte := Vector3(qx, ey / 2.0, (zu + zo) / 2.0)
		for wx: float in [TREPPE_INNEN + 0.03, XI - 0.03]:
			_box(tr, "Wange_%s" % String.num(wx), Vector3(0.06, 0.34, schraeg), Vector3(s * wx, ey / 2.0 - 0.06, mitte.z), m.holz_dunkel, neigung)
		_box(tr, "Handlauf", Vector3(0.07, 0.07, schraeg), Vector3(s * (TREPPE_INNEN + 0.03), ey / 2.0 + 0.95, mitte.z), m.holz_dunkel, neigung)
		for i in range(0, n, 4):
			var z := zu + tritt * (i + 0.5)
			var y := steigung * (i + 1)
			_box(tr, "Gelaenderpfosten%d" % (i / 4 + 1), Vector3(0.06, 0.95, 0.06), Vector3(s * (TREPPE_INNEN + 0.03), y + 0.47, z), m.holz_dunkel)
		var normale := Vector3(0, cos(winkel), -sin(winkel))
		var rampe := Basis(Vector3.RIGHT, -winkel)
		_kollision(koerper, "Rampe", Vector3(wand_b, 0.12, schraeg + 0.2), Transform3D(rampe, mitte - normale * 0.06))
		_kollision(koerper, "TreppenGelaender", Vector3(0.08, 1.0, schraeg), Transform3D(rampe, Vector3(s * (TREPPE_INNEN + 0.03), ey / 2.0 + 0.5, mitte.z)))

func _dach(g: Node3D) -> void:
	var winkel := atan(K)
	var cw := cos(winkel)
	var plane := _gruppe(g, "Plane")
	var himmel := _gruppe(g, "Himmel")
	for s: float in [-1.0, 1.0]:
		var seite := "West" if s < 0 else "Ost"
		var nrm := Vector2(s * sin(winkel), cos(winkel))
		var p0 := Vector2(-s * 0.15, _dach_y(s, -s * 0.15))
		var p1 := Vector2(s * 13.0, _dach_y(s, s * 13.0))
		var mitte := (p0 + p1) / 2.0 + nrm * 0.06
		_box(plane, "Plane" + seite, Vector3(p0.distance_to(p1), 0.12, 27.4), Vector3(mitte.x, mitte.y, -1.5), m.streifen, Vector3(0, 0, -s * rad_to_deg(winkel)))
		_box(plane, "Traufbrett" + seite, Vector3(0.08, 0.4, 27.4), Vector3(s * 13.02, _dach_y(s, s * 13.0) - 0.12, -1.5), m.blau)
		var q0 := Vector2(-s * 0.25, _dach_y(s, -s * 0.25))
		var q1 := Vector2(s * XI, _dach_y(s, s * XI))
		var qm := (q0 + q1) / 2.0 - nrm * 0.22
		_box(himmel, "Himmel" + seite, Vector3(q0.distance_to(q1), 0.04, 25.0), Vector3(qm.x, qm.y, -1.5), m.himmel, Vector3(0, 0, -s * rad_to_deg(winkel)), false)
	_box(plane, "Firstkappe", Vector3(0.5, 0.18, 27.4), Vector3(0, FIRST + 0.13, -1.5), m.holz_dunkel)
	var gh := FIRST - TRAUFE
	_prisma(plane, "GiebelHinten", Vector3(24.6, gh, 0.3), Transform3D(Basis(), Vector3(0, TRAUFE + gh / 2.0, ZB - 0.15)), m.stoff)
	_prisma(plane, "GiebelVorne", Vector3(24.6, gh, 0.3), Transform3D(Basis(), Vector3(0, TRAUFE + gh / 2.0, ZF + 0.15)), m.rauten)
	for s: float in [-1.0, 1.0]:
		var seite := "West" if s < 0 else "Ost"
		for z in [ZF + 0.38, ZB - 0.38]:
			_balken(plane, "Ortgang%s_%s" % [seite, "Vorne" if z > 0 else "Hinten"],
				Vector3(s * 13.1, _dach_y(s, s * 13.1) + 0.05, z), Vector3(0, FIRST + 0.12, z), 0.3, m.holz_dunkel)

	var stuhl := _gruppe(g, "Dachstuhl")
	var unter := 0.38 / cw
	var zug := TRAUFE - 0.2
	for z: float in BINDER:
		var b := _gruppe(stuhl, "Binder_%s" % String.num(z))
		_box(b, "Zugbalken", Vector3(24.0, 0.32, 0.26), Vector3(0, zug, z), m.holz_dunkel)
		for s: float in [-1.0, 1.0]:
			var seite := "West" if s < 0 else "Ost"
			_balken(b, "Sparren" + seite, Vector3(s * 11.9, _dach_y(s, s * 11.9) - unter, z), Vector3(0, FIRST - unter, z), 0.22, m.holz_dunkel)
			_balken(b, "Strebe" + seite, Vector3(s * 4.6, zug + 0.16, z), Vector3(0, zug + 2.9, z), 0.16, m.holz_dunkel)
		var sh := FIRST - unter - (zug + 0.16)
		_box(b, "Haengesaeule", Vector3(0.24, sh, 0.24), Vector3(0, zug + 0.16 + sh / 2.0, z), m.holz_dunkel)
	for z in [ZB + 0.12, ZF - 0.12]:
		for s: float in [-1.0, 1.0]:
			_balken(stuhl, "GiebelSparren%s_%s" % ["West" if s < 0 else "Ost", "Vorne" if z > 0 else "Hinten"],
				Vector3(s * 11.9, _dach_y(s, s * 11.9) - unter, z), Vector3(0, FIRST - unter, z), 0.22, m.holz_dunkel)
	_box(stuhl, "Firstpfette", Vector3(0.26, 0.3, 25.0), Vector3(0, FIRST - unter - 0.05, -1.5), m.holz_dunkel)
	for s: float in [-1.0, 1.0]:
		var x := s * 6.0
		_box(stuhl, "Pfette" + ("West" if s < 0 else "Ost"), Vector3(0.2, 0.2, 25.0), Vector3(x, _dach_y(s, x) - unter - 0.04, -1.5), m.holz_dunkel, Vector3(0, 0, -s * rad_to_deg(winkel)))

func _beleuchtung(g: Node3D) -> void:
	var kl := _gruppe(g, "Kranzleuchter")
	var haken := TRAUFE - 0.36 - 1.65
	for z: float in BINDER:
		for x in [-6.0, 0.0, 6.0]:
			_instanz(kl, s_leuchter, "Leuchter_%s_%s" % [String.num(x), String.num(z)], Transform3D(Basis(), Vector3(x, haken, z)))
	var la := _gruppe(g, "Wandlaternen")
	# Unten: an den Emporenstützen zur Halle hin, an den Seitenwänden hinten, an der Rückwand
	for z: float in STUETZEN_WEST:
		_instanz(la, s_laterne, "StuetzeWest_%s" % String.num(z), Transform3D(_rot(Vector3(0, 90, 0)), Vector3(-EMPORE_KANTE - 0.01, 2.3, z)))
	for z: float in STUETZEN_OST:
		_instanz(la, s_laterne, "StuetzeOst_%s" % String.num(z), Transform3D(_rot(Vector3(0, -90, 0)), Vector3(EMPORE_KANTE + 0.01, 2.3, z)))
	_instanz(la, s_laterne, "WestHinten", Transform3D(_rot(Vector3(0, 90, 0)), Vector3(-XI + 0.3, 2.6, -11.5)))
	_instanz(la, s_laterne, "OstHinten", Transform3D(_rot(Vector3(0, -90, 0)), Vector3(XI - 0.3, 2.6, -11.5)))
	for x in [-10.0, -2.5, 2.5, 10.0]:
		_instanz(la, s_laterne, "Hinten_%s" % String.num(x), Transform3D(Basis(), Vector3(x, 2.85, ZB + 0.12)))
	# Oben auf den Emporen an den Wandpfosten
	for z: float in BINDER:
		_instanz(la, s_laterne, "EmporeWest_%s" % String.num(z), Transform3D(_rot(Vector3(0, 90, 0)), Vector3(-XI + 0.3, EMPORE_Y + 1.95, z)))
		_instanz(la, s_laterne, "EmporeOst_%s" % String.num(z), Transform3D(_rot(Vector3(0, -90, 0)), Vector3(XI - 0.3, EMPORE_Y + 1.95, z)))

func _deko(g: Node3D) -> void:
	var gi := _gruppe(g, "Girlanden")
	var gy := TRAUFE - 0.38
	for z: float in BINDER:
		for x in [-9.0, -3.0, 3.0, 9.0]:
			_instanz(gi, s_girlande[6.0], "Binder_%s_%s" % [String.num(z), String.num(x)], Transform3D(Basis(), Vector3(x, gy, z + 0.17)))
	var pz: Array = [ZB] + BINDER + [ZF]
	for s: float in [-1.0, 1.0]:
		for i in pz.size() - 1:
			var a: float = pz[i]
			var b: float = pz[i + 1]
			var szene: PackedScene = s_girlande[2.5] if b - a < 4.0 else s_girlande[5.0]
			_instanz(gi, szene, "Raehm%s%d" % ["West" if s < 0 else "Ost", i + 1], Transform3D(_rot(Vector3(0, 90, 0)), Vector3(s * (XI - 0.3), gy, (a + b) / 2.0)))
	_instanz(gi, s_girlande[6.0], "TorInnen", Transform3D(Basis(), Vector3(0, 3.62, ZF - 0.15)))
	var wi := _gruppe(g, "Wimpelketten")
	for x in [-9.0, -3.0, 3.0, 9.0]:
		for i in BINDER.size() - 1:
			var z := (float(BINDER[i]) + float(BINDER[i + 1])) / 2.0
			_instanz(wi, s_wimpel, "Wimpel_%s_%d" % [String.num(x), i + 1], Transform3D(_rot(Vector3(0, 90, 0)), Vector3(x, TRAUFE - 0.45, z)))
	# Rückwand über der Theke: Wappen und Rautenbanner
	_instanz(g, s_wappen, "Wappen", Transform3D(Basis(), Vector3(0, 5.2, ZB + 0.2)))
	for x in [-3.3, 3.3]:
		var bn := _gruppe(g, "Banner_%s" % String.num(x), Vector3(x, 0, ZB + 0.14))
		_box(bn, "Tuch", Vector3(1.0, 2.2, 0.03), Vector3(0, 5.2, 0), m.rauten_fein)
		_stange(bn, "Stange", Vector3(-0.62, 6.33, 0.02), Vector3(0.62, 6.33, 0.02), 0.03, m.gold)
		_prisma(bn, "Spitze", Vector3(1.0, 0.3, 0.03), Transform3D(_rot(Vector3(0, 0, 180)), Vector3(0, 3.95, 0)), m.rauten_fein)

func _fassade(g: Node3D) -> void:
	var zf := ZF + 0.3
	var sch := _gruppe(g, "Namensschild")
	_box(sch, "Tafel", Vector3(13.2, 2.1, 0.1), Vector3(0, 4.4, zf + 0.12), m.holz_dunkel)
	_box(sch, "RahmenOben", Vector3(13.44, 0.12, 0.16), Vector3(0, 5.5, zf + 0.15), m.gold)
	_box(sch, "RahmenUnten", Vector3(13.44, 0.12, 0.16), Vector3(0, 3.3, zf + 0.15), m.gold)
	_box(sch, "RahmenLinks", Vector3(0.12, 2.32, 0.16), Vector3(-6.66, 4.4, zf + 0.15), m.gold)
	_box(sch, "RahmenRechts", Vector3(0.12, 2.32, 0.16), Vector3(6.66, 4.4, zf + 0.15), m.gold)
	_instanz(g, s_girlande[6.0], "TorGirlande", Transform3D(Basis(), Vector3(0, 3.22, zf + 0.25)))
	_instanz(g, s_wappen, "GiebelWappen", Transform3D(Basis().scaled(Vector3.ONE * 0.8), Vector3(0, TRAUFE + 1.6, zf + 0.1)))

	var th := 9.2
	var winkel := atan(K)
	for s: float in [-1.0, 1.0]:
		var name_s := "Links" if s < 0 else "Rechts"
		var t := _gruppe(g, "Turm" + name_s, Vector3(s * 7.35, 0, zf + 0.55))
		_box(t, "Koerper", Vector3(1.4, th, 1.4), Vector3(0, th / 2.0, 0), m.stoff)
		_box(t, "Sockel", Vector3(1.48, 1.2, 1.48), Vector3(0, 0.6, 0), m.holz_dunkel)
		for i in 4:
			var dx := 0.68 if i % 2 == 0 else -0.68
			var dz := 0.68 if i < 2 else -0.68
			_box(t, "Eckbalken%d" % (i + 1), Vector3(0.16, th, 0.16), Vector3(dx, th / 2.0, dz), m.holz_dunkel)
		_box(t, "Gesims", Vector3(1.6, 0.18, 1.6), Vector3(0, th + 0.05, 0), m.holz_dunkel)
		_pyramide(t, "Turmdach", 1.75, 1.9, Vector3(0, th + 1.1, 0), m.blau)
		_kugel(t, "Kugel", 0.16, Vector3(0, th + 2.1, 0), m.gold)
		_instanz(t, s_fahne, "Fahne", Transform3D(Basis() if s > 0 else _rot(Vector3(0, 180, 0)), Vector3(0, th + 2.15, 0)))
		_instanz(t, s_fenster, "FensterOben", Transform3D(Basis().scaled(Vector3(0.75, 0.9, 0.75)), Vector3(0, 7.2, 0.62)))
		_instanz(t, s_fenster, "FensterUnten", Transform3D(Basis().scaled(Vector3(0.75, 0.9, 0.75)), Vector3(0, 2.4, 0.62)))
		var koerper := StaticBody3D.new()
		_haengen(t, koerper, "Kollision")
		_kollision(koerper, "Form", Vector3(1.4, th, 1.4), Transform3D(Basis(), Vector3(0, th / 2.0, 0)))
		_instanz(t, s_laterne, "Laterne", Transform3D(_rot(Vector3(0, -s * 90, 0)), Vector3(-s * 0.7, 2.9, 0)))
		_instanz(g, s_blumen, "Blumenkasten%sUnten" % name_s, Transform3D(Basis(), Vector3(s * 9.9, 1.26, zf + 0.2)))
		_instanz(g, s_blumen, "Blumenkasten%sOben" % name_s, Transform3D(Basis(), Vector3(s * 9.9, 4.5, zf + 0.2)))
		# Lichterkette am Giebelrand
		var mx := s * 6.55
		_instanz(g, s_lichterkette, "Lichterkette" + name_s,
			Transform3D(_rot(Vector3(0, 0, -s * rad_to_deg(winkel))), Vector3(mx, _dach_y(s, mx) - 0.1, zf + 0.3)))
		# Bierfässer neben dem Tor
		var fg := _gruppe(g, "Faesser" + name_s, Vector3(s * 4.7, 0, zf + 0.75))
		_instanz(fg, s_fass, "Fass1", Transform3D(Basis(), Vector3(-0.42, 0, 0)))
		_instanz(fg, s_fass, "Fass2", Transform3D(Basis(), Vector3(0.42, 0, 0)))
		_instanz(fg, s_fass, "Fass3", Transform3D(_rot(Vector3(0, 30, 0)), Vector3(0, 0.92, 0)))
		var fk := StaticBody3D.new()
		_haengen(fg, fk, "Kollision")
		_kollision(fk, "Form", Vector3(1.7, 1.8, 0.8), Transform3D(Basis(), Vector3(0, 0.9, 0)))

	_instanz(g, s_krone, "Krone", Transform3D(Basis().scaled(Vector3.ONE * 1.5), Vector3(0, FIRST + 0.2, zf + 0.1)))
	_instanz(g, s_fahne, "FahneHinten", Transform3D(Basis(), Vector3(0, FIRST + 0.2, ZB - 0.4)))
	_instanz(g, s_maibaum, "Maibaum", Transform3D(Basis(), Vector3(-10.6, 0, zf + 2.6)))
