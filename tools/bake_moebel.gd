extends SceneTree
## Backt Büromöbel (Wiesenbüro, später auch fürs Zeltbüro zu kaufen) zu je einem
## ArrayMesh mit einer Oberfläche pro Material — viele Einzelteile, wenige
## Zeichenaufrufe. Szenen dazu: scenes/moebel/*.tscn (Mesh + Kollision).
## Aufruf: godot --headless --script res://tools/bake_moebel.gd
## Maße in Metern, Boden bei y = 0, Vorderseite zeigt nach -Z.

const ZIEL := "res://assets/moebel/"

var _teile := {}
var _mats := {}
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_aktenschrank()
	_ordnerregal()
	_buerostuhl()
	_pflanze()
	_wanduhr()
	_plakat()
	_stehlampe()
	_deckenlampe()
	_teppich()
	_wartebank()
	_garderobe()
	_kaffeeecke()
	print("Möbel gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _mat(name: String, farbe: Color, rauh := 0.8, metall := 0.0, leuchten := 0.0) -> void:
	if _mats.has(name):
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
	if leuchten > 0.0:
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = leuchten
	_mats[name] = m

func _neu() -> void:
	_teile.clear()
	_mats.clear()

func _add(mat: String, mesh: PrimitiveMesh, t: Transform3D) -> void:
	if not _teile.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_teile[mat] = st
	(_teile[mat] as SurfaceTool).append_from(mesh, 0, t)

func _speichern(name: String) -> void:
	var am := ArrayMesh.new()
	for mat: String in _teile.keys():
		var st: SurfaceTool = _teile[mat]
		st.generate_normals()
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, _mats[mat])
		am.surface_set_name(am.get_surface_count() - 1, mat)
	ResourceSaver.save(am, ZIEL + name + ".tres")
	print("  ", name, ": ", am.get_surface_count(), " Oberflächen")

func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

func _zyl(r_oben: float, r_unten: float, h: float, seg := 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_oben
	c.bottom_radius = r_unten
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _kugel(r: float, seg := 10, ringe := 6) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = ringe
	return s

func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))

func _holz_mats() -> void:
	_mat("holz", Color(0.55, 0.36, 0.2), 0.7)
	_mat("holz_dunkel", Color(0.32, 0.2, 0.11), 0.7)
	_mat("metall", Color(0.62, 0.63, 0.66), 0.35, 0.85)
	_mat("messing", Color(0.8, 0.62, 0.25), 0.3, 0.9)

# ------------------------------------------------------------ Möbel
## Aktenschrank aus Holz mit vier Schubladen, Griffen und Namensschildchen
func _aktenschrank() -> void:
	_neu()
	_holz_mats()
	_mat("papier", Color(0.95, 0.93, 0.85), 0.9)
	_add("holz_dunkel", _box(Vector3(0.7, 1.4, 0.6)), _at(0, 0.7, 0))
	_add("holz", _box(Vector3(0.74, 0.04, 0.64)), _at(0, 1.42, 0))
	_add("holz_dunkel", _box(Vector3(0.66, 0.06, 0.56)), _at(0, 0.03, 0))
	for i in 4:
		var y := 0.2 + i * 0.33
		_add("holz", _box(Vector3(0.62, 0.3, 0.03)), _at(0, y, -0.3))
		_add("messing", _box(Vector3(0.16, 0.025, 0.035)), _at(0, y + 0.06, -0.33))
		_add("messing", _box(Vector3(0.1, 0.05, 0.01)), _at(0, y - 0.05, -0.318))
		_add("papier", _box(Vector3(0.08, 0.035, 0.012)), _at(0, y - 0.05, -0.322))
	# Ablage oben: Stapel Papier und ein Stempelkasten
	_add("papier", _box(Vector3(0.3, 0.05, 0.22)), Transform3D(Basis(Vector3.UP, 0.2), Vector3(-0.12, 1.47, 0.02)))
	_add("holz", _box(Vector3(0.18, 0.08, 0.12)), _at(0.2, 1.48, 0.05))
	_speichern("aktenschrank")

## Wandregal mit bunten Aktenordnern und Kisten
func _ordnerregal() -> void:
	_neu()
	_holz_mats()
	var ordner := ["ordner_rot", "ordner_blau", "ordner_gruen", "ordner_gelb", "ordner_grau"]
	_mat("ordner_rot", Color(0.7, 0.15, 0.12), 0.6)
	_mat("ordner_blau", Color(0.15, 0.3, 0.65), 0.6)
	_mat("ordner_gruen", Color(0.2, 0.5, 0.25), 0.6)
	_mat("ordner_gelb", Color(0.85, 0.7, 0.2), 0.6)
	_mat("ordner_grau", Color(0.45, 0.45, 0.48), 0.6)
	_mat("etikett", Color(0.96, 0.95, 0.9), 0.9)
	_rng.seed = 7
	for s in [-0.6, 0.6]:
		_add("holz_dunkel", _box(Vector3(0.04, 1.9, 0.35)), _at(s, 0.95, 0))
	_add("holz_dunkel", _box(Vector3(1.24, 1.9, 0.02)), _at(0, 0.95, 0.17))
	for i in 5:
		var y := 0.05 + i * 0.44
		_add("holz", _box(Vector3(1.2, 0.035, 0.34)), _at(0, y, 0))
		if i == 4:
			continue
		var x := -0.55
		while x < 0.5:
			var b := _rng.randf_range(0.055, 0.075)
			var h := _rng.randf_range(0.3, 0.34)
			var m: String = ordner[_rng.randi() % ordner.size()]
			var neigung := _rng.randf_range(-0.05, 0.05)
			_add(m, _box(Vector3(b, h, 0.28)), Transform3D(Basis(Vector3.BACK, neigung), Vector3(x + b / 2, y + 0.02 + h / 2, 0.0)))
			_add("etikett", _box(Vector3(b * 0.6, 0.08, 0.005)), Transform3D(Basis(Vector3.BACK, neigung), Vector3(x + b / 2, y + 0.02 + h * 0.62, -0.142)))
			x += b + 0.004
			if _rng.randf() < 0.08:
				x += 0.12   # Lücke
	_speichern("ordnerregal")

## Bürostuhl mit Polster, Armlehnen und Fünfsternfuß
func _buerostuhl() -> void:
	_neu()
	_holz_mats()
	_mat("polster", Color(0.45, 0.14, 0.12), 0.9)
	_mat("schwarz", Color(0.08, 0.08, 0.09), 0.5)
	for i in 5:
		var w := i * TAU / 5.0
		var d := Vector3(sin(w), 0, cos(w))
		_add("schwarz", _box(Vector3(0.05, 0.04, 0.32)), Transform3D(Basis(Vector3.UP, w), Vector3(0, 0.07, 0) + d * 0.16))
		_add("schwarz", _kugel(0.03, 8, 4), _at(d.x * 0.3, 0.03, d.z * 0.3))
	_add("metall", _zyl(0.025, 0.025, 0.36), _at(0, 0.27, 0))
	_add("polster", _box(Vector3(0.48, 0.09, 0.46)), _at(0, 0.49, 0))
	_add("polster", _box(Vector3(0.46, 0.5, 0.08)), Transform3D(Basis(Vector3.RIGHT, -0.12), Vector3(0, 0.82, 0.24)))
	_add("schwarz", _box(Vector3(0.05, 0.3, 0.05)), _at(0, 0.62, 0.24))
	for s in [-0.26, 0.26]:
		_add("schwarz", _box(Vector3(0.04, 0.2, 0.04)), _at(s, 0.6, 0.02))
		_add("schwarz", _box(Vector3(0.06, 0.03, 0.3)), _at(s, 0.71, 0.0))
	_speichern("buerostuhl")

## Gummibaum im Terrakottatopf
func _pflanze() -> void:
	_neu()
	_mat("topf", Color(0.72, 0.36, 0.2), 0.85)
	_mat("erde", Color(0.2, 0.13, 0.08), 1.0)
	_mat("stamm", Color(0.35, 0.25, 0.15), 0.9)
	_mat("blatt", Color(0.16, 0.42, 0.18), 0.45)
	_mat("blatt_hell", Color(0.25, 0.55, 0.22), 0.45)
	_rng.seed = 9
	_add("topf", _zyl(0.22, 0.16, 0.38, 16), _at(0, 0.19, 0))
	_add("topf", _zyl(0.245, 0.245, 0.05, 16), _at(0, 0.38, 0))
	_add("erde", _zyl(0.21, 0.21, 0.02, 14), _at(0, 0.37, 0))
	_add("stamm", _zyl(0.02, 0.03, 1.0, 8), _at(0, 0.88, 0))
	for i in 34:
		var h := _rng.randf_range(0.6, 1.45)
		var w := _rng.randf() * TAU
		var r := (1.5 - h) * 0.35 + 0.08
		var p := Vector3(sin(w) * r, h, cos(w) * r)
		var b := Basis(Vector3.UP, w).rotated(Vector3(cos(w), 0, -sin(w)), _rng.randf_range(0.3, 0.9))
		_add("blatt" if i % 3 else "blatt_hell", _kugel(0.07, 8, 4), Transform3D(b.scaled_local(Vector3(0.6, 0.06, 1.5)), p))
	_speichern("pflanze")

## Wanduhr mit Pendel (Rückseite an der Wand, Zifferblatt nach -Z)
func _wanduhr() -> void:
	_neu()
	_holz_mats()
	_mat("ziffer", Color(0.96, 0.94, 0.86), 0.7)
	_mat("zeiger", Color(0.05, 0.05, 0.05), 0.5)
	_add("holz_dunkel", _box(Vector3(0.36, 0.9, 0.12)), _at(0, 0, 0))
	_add("holz", _box(Vector3(0.4, 0.06, 0.14)), _at(0, 0.47, 0))
	_add("holz", _box(Vector3(0.4, 0.06, 0.14)), _at(0, -0.47, 0))
	var vorn := Basis(Vector3.RIGHT, PI / 2)
	_add("ziffer", _zyl(0.14, 0.14, 0.01, 24), Transform3D(vorn, Vector3(0, 0.22, -0.065)))
	_add("messing", _zyl(0.155, 0.155, 0.008, 24), Transform3D(vorn, Vector3(0, 0.22, -0.061)))
	for i in 12:
		var w := i * TAU / 12.0
		_add("zeiger", _box(Vector3(0.012, 0.03, 0.004)), Transform3D(Basis(Vector3.BACK, w), Vector3(sin(w) * 0.115, 0.22 + cos(w) * 0.115, -0.072)))
	_add("zeiger", _box(Vector3(0.012, 0.09, 0.004)), Transform3D(Basis(Vector3.BACK, 0.9), Vector3(-0.035, 0.245, -0.076)))
	_add("zeiger", _box(Vector3(0.008, 0.12, 0.004)), Transform3D(Basis(Vector3.BACK, -2.4), Vector3(-0.04, 0.18, -0.078)))
	_add("messing", _box(Vector3(0.01, 0.3, 0.01)), _at(0, -0.12, -0.05))
	_add("messing", _zyl(0.045, 0.045, 0.012, 16), Transform3D(vorn, Vector3(0, -0.3, -0.05)))
	_speichern("wanduhr")

## Gerahmtes Wiesn-Plakat (Rahmen, Passepartout, Motiv aus Farbflächen)
func _plakat() -> void:
	_neu()
	_holz_mats()
	_mat("passe", Color(0.95, 0.92, 0.84), 0.9)
	_mat("himmel", Color(0.35, 0.6, 0.9), 0.8)
	_mat("wiese", Color(0.3, 0.6, 0.25), 0.8)
	_mat("zelt_blau", Color(0.15, 0.35, 0.75), 0.8)
	_mat("zelt_weiss", Color(0.96, 0.96, 0.96), 0.8)
	_mat("rad", Color(0.85, 0.25, 0.2), 0.7)
	_add("holz_dunkel", _box(Vector3(0.72, 0.96, 0.04)), _at(0, 0, 0))
	_add("passe", _box(Vector3(0.62, 0.86, 0.01)), _at(0, 0, -0.022))
	_add("himmel", _box(Vector3(0.52, 0.45, 0.01)), _at(0, 0.12, -0.027))
	_add("wiese", _box(Vector3(0.52, 0.2, 0.01)), _at(0, -0.2, -0.027))
	for i in 4:
		_add("zelt_blau" if i % 2 == 0 else "zelt_weiss", _box(Vector3(0.05, 0.16, 0.01)), _at(-0.14 + i * 0.05, -0.04, -0.032))
	var dach := PrismMesh.new()
	dach.size = Vector3(0.24, 0.08, 0.01)
	_add("zelt_blau", dach, _at(-0.065, 0.08, -0.032))
	_add("rad", _zyl(0.09, 0.09, 0.008, 20), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0.14, 0.05, -0.033)))
	_add("zelt_weiss", _zyl(0.07, 0.07, 0.009, 20), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0.14, 0.05, -0.034)))
	_add("rad", _box(Vector3(0.44, 0.06, 0.008)), _at(0, 0.33, -0.034))
	_speichern("plakat")

## Stehlampe mit Stoffschirm (Licht in der Szene)
func _stehlampe() -> void:
	_neu()
	_holz_mats()
	_mat("schirm", Color(0.95, 0.85, 0.6), 0.9, 0.0, 0.6)
	_add("messing", _zyl(0.16, 0.18, 0.04, 20), _at(0, 0.02, 0))
	_add("messing", _zyl(0.015, 0.015, 1.4, 10), _at(0, 0.72, 0))
	_add("schirm", _zyl(0.14, 0.24, 0.3, 20), _at(0, 1.5, 0))
	_speichern("stehlampe")

## Deckenleuchte: Kranz aus Holz mit vier Glaskugeln (Licht in der Szene)
func _deckenlampe() -> void:
	_neu()
	_holz_mats()
	_mat("kugel", Color(1.0, 0.9, 0.7), 0.3, 0.0, 2.5)
	_add("metall", _zyl(0.008, 0.008, 0.6, 6), _at(0, -0.3, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34
	ring.outer_radius = 0.4
	ring.rings = 24
	ring.ring_segments = 8
	_add("holz_dunkel", ring, _at(0, -0.62, 0))
	for i in 4:
		var w := i * TAU / 4.0
		_add("messing", _zyl(0.03, 0.02, 0.06, 10), _at(sin(w) * 0.37, -0.57, cos(w) * 0.37))
		_add("kugel", _kugel(0.06, 12, 8), _at(sin(w) * 0.37, -0.5, cos(w) * 0.37))
	_speichern("deckenlampe")

## Teppich mit Rand und Rautenmuster
func _teppich() -> void:
	_neu()
	_mat("rot", Color(0.55, 0.12, 0.1), 1.0)
	_mat("creme", Color(0.9, 0.82, 0.62), 1.0)
	_mat("blau", Color(0.15, 0.25, 0.5), 1.0)
	_add("rot", _box(Vector3(3.0, 0.012, 2.0)), _at(0, 0.006, 0))
	_add("creme", _box(Vector3(2.7, 0.014, 1.7)), _at(0, 0.007, 0))
	_add("rot", _box(Vector3(2.5, 0.016, 1.5)), _at(0, 0.008, 0))
	for x in 5:
		for z in 3:
			_add("blau", _box(Vector3(0.22, 0.018, 0.22)), Transform3D(Basis(Vector3.UP, PI / 4), Vector3(-1.0 + x * 0.5, 0.009, -0.5 + z * 0.5)))
	for x in 16:
		for s in [-1.0, 1.0]:
			_add("creme", _box(Vector3(0.03, 0.006, 0.08)), _at(-1.4 + x * 0.187, 0.003, s * 1.03))
	_speichern("teppich")

## Wartebank aus Holz mit Lehne
func _wartebank() -> void:
	_neu()
	_holz_mats()
	for x in [-0.7, 0.7]:
		for z in [-0.18, 0.18]:
			_add("holz_dunkel", _box(Vector3(0.06, 0.45, 0.06)), _at(x, 0.225, z))
		_add("holz_dunkel", _box(Vector3(0.06, 0.5, 0.06)), Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(x, 0.7, 0.22)))
	for i in 4:
		_add("holz", _box(Vector3(1.6, 0.03, 0.1)), _at(0, 0.46, -0.16 + i * 0.105))
	for i in 3:
		_add("holz", _box(Vector3(1.6, 0.08, 0.025)), Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(0, 0.62 + i * 0.13, 0.24 + i * 0.016)))
	_speichern("wartebank")

## Garderobenständer mit Hut und Janker
func _garderobe() -> void:
	_neu()
	_holz_mats()
	_mat("hut", Color(0.2, 0.25, 0.18), 0.9)
	_mat("feder", Color(0.9, 0.88, 0.8), 0.8)
	_mat("janker", Color(0.3, 0.38, 0.22), 0.95)
	_add("holz_dunkel", _zyl(0.025, 0.03, 1.75, 10), _at(0, 0.875, 0))
	for i in 4:
		var w := i * TAU / 4.0
		_add("holz_dunkel", _box(Vector3(0.04, 0.03, 0.34)), Transform3D(Basis(Vector3.UP, w).rotated(Vector3.UP, 0), Vector3(sin(w) * 0.15, 0.03, cos(w) * 0.15)))
		_add("holz", _zyl(0.012, 0.012, 0.16, 8), Transform3D(Basis(Vector3(cos(w), 0, -sin(w)), 0.9), Vector3(sin(w) * 0.07, 1.65, cos(w) * 0.07)))
	# Hut
	_add("hut", _zyl(0.11, 0.12, 0.12, 16), _at(0.12, 1.78, 0))
	_add("hut", _zyl(0.17, 0.17, 0.015, 18), _at(0.12, 1.72, 0))
	_add("feder", _box(Vector3(0.01, 0.12, 0.03)), Transform3D(Basis(Vector3.BACK, -0.4), Vector3(0.2, 1.84, 0)))
	# Janker am Haken
	_add("janker", _box(Vector3(0.4, 0.6, 0.12)), _at(-0.02, 1.3, -0.12))
	_add("janker", _box(Vector3(0.1, 0.5, 0.1)), _at(-0.25, 1.32, -0.12))
	_add("janker", _box(Vector3(0.1, 0.5, 0.1)), _at(0.21, 1.32, -0.12))
	for i in 3:
		_add("messing", _kugel(0.012, 6, 4), _at(0.05, 1.45 - i * 0.14, -0.185))
	_speichern("garderobe")

## Anrichte mit Kaffeemaschine, Tassen und Zuckerdose
func _kaffeeecke() -> void:
	_neu()
	_holz_mats()
	_mat("maschine", Color(0.12, 0.12, 0.13), 0.4, 0.3)
	_mat("kanne", Color(0.6, 0.75, 0.8), 0.1)
	_mat("kaffee", Color(0.2, 0.1, 0.05), 0.2)
	_mat("tasse", Color(0.96, 0.96, 0.94), 0.3)
	_mat("rot", Color(0.75, 0.15, 0.12), 0.5)
	_add("holz", _box(Vector3(1.2, 0.85, 0.45)), _at(0, 0.425, 0))
	_add("holz_dunkel", _box(Vector3(1.24, 0.04, 0.49)), _at(0, 0.87, 0))
	for x in [-0.3, 0.3]:
		_add("holz_dunkel", _box(Vector3(0.56, 0.7, 0.02)), _at(x, 0.43, -0.23))
		_add("messing", _kugel(0.018, 8, 5), _at(x * 0.2, 0.55, -0.25))
	# Kaffeemaschine
	_add("maschine", _box(Vector3(0.22, 0.34, 0.24)), _at(-0.35, 1.06, 0.03))
	_add("maschine", _box(Vector3(0.22, 0.05, 0.3)), _at(-0.35, 1.24, 0.0))
	_add("kanne", _zyl(0.065, 0.075, 0.14, 14), _at(-0.35, 0.96, -0.08))
	_add("kaffee", _zyl(0.066, 0.074, 0.06, 14), _at(-0.35, 0.93, -0.08))
	_add("rot", _box(Vector3(0.02, 0.02, 0.01)), _at(-0.28, 1.18, -0.095))
	# Tassen
	for i in 4:
		var p := Vector3(0.05 + (i % 2) * 0.12, 0.93, -0.05 + (i / 2) * 0.12)
		_add("tasse", _zyl(0.035, 0.03, 0.08, 12), Transform3D(Basis(), p))
		_add("tasse", _box(Vector3(0.012, 0.04, 0.03)), Transform3D(Basis(), p + Vector3(0.042, 0, 0)))
	_add("tasse", _zyl(0.05, 0.05, 0.09, 14), _at(0.42, 0.94, 0.02))
	_add("rot", _zyl(0.052, 0.052, 0.02, 14), _at(0.42, 1.0, 0.02))
	_speichern("kaffeeecke")
