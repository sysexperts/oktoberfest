extends SceneTree
## Backt die Dreck-Modelle fürs verdreckte Zelt (Tutorial „Putze das Zelt") und
## den Besen zu je einem ArrayMesh mit wenigen Oberflächen (eine je Material) —
## viele Einzelteile, aber nur 2–5 Zeichenaufrufe pro Modell.
## Aufruf: godot --headless --script res://tools/bake_dreck.gd
## Ergebnis: assets/dreck/<name>.tres (von scenes/dreck/*.tscn und player.tscn benutzt)

const ZIEL := "res://assets/dreck/"

var _teile := {}      # Materialname -> SurfaceTool
var _mats := {}       # Materialname -> Material
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_laub()
	_scherben()
	_papier()
	_stroh()
	_staub()
	_besen()
	_plane()
	_muellsack()
	print("Dreck gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _mat(name: String, farbe: Color, rauh := 0.85, metall := 0.0, alpha := false) -> void:
	if _mats.has(name):
		return
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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

func _zyl(r_oben: float, r_unten: float, h: float, seg := 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_oben
	c.bottom_radius = r_unten
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _kugel(r: float, seg := 8, ringe := 5) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = ringe
	return s

func _dreh() -> Basis:
	return Basis.from_euler(Vector3(_rng.randf_range(-PI, PI), _rng.randf_range(-PI, PI), _rng.randf_range(-PI, PI)))

## Punkt auf einem flachen Hügel (Radius r, Höhe h)
func _huegel(r: float, h: float) -> Vector3:
	var a := _rng.randf() * TAU
	var d := sqrt(_rng.randf()) * r
	return Vector3(cos(a) * d, h * (1.0 - (d / r) * (d / r)), sin(a) * d)

# ------------------------------------------------------------ Modelle
## Laubhaufen mit Zweigen und Kastanien
func _laub() -> void:
	_neu()
	_rng.seed = 11
	var farben := {"laub_orange": Color(0.86, 0.45, 0.12), "laub_braun": Color(0.48, 0.27, 0.12),
		"laub_gelb": Color(0.9, 0.72, 0.2), "laub_rot": Color(0.62, 0.16, 0.1)}
	for k: String in farben:
		_mat(k, farben[k], 0.9)
	_mat("holz", Color(0.33, 0.22, 0.13), 0.95)
	_mat("kastanie", Color(0.36, 0.17, 0.08), 0.35)
	var namen := farben.keys()
	# Grundhügel aus dunklem Laub
	_add("laub_braun", _kugel(0.42, 10, 5), Transform3D(Basis().scaled(Vector3(1.0, 0.22, 0.85)), Vector3(0, 0.0, 0)))
	for i in 70:
		var blatt := _kugel(0.05, 8, 4)
		var gross := Vector3(_rng.randf_range(1.2, 1.9), 0.08, _rng.randf_range(0.7, 1.1))
		var p := _huegel(0.5, 0.13)
		var b := Basis.from_euler(Vector3(_rng.randf_range(-0.6, 0.6), _rng.randf() * TAU, _rng.randf_range(-0.6, 0.6)))
		_add(namen[i % namen.size()], blatt, Transform3D(b.scaled_local(gross), p + Vector3(0, 0.02, 0)))
	for i in 6:
		var p := _huegel(0.45, 0.1)
		var zweig := _zyl(0.006, 0.009, _rng.randf_range(0.2, 0.38), 5)
		_add("holz", zweig, Transform3D(Basis.from_euler(Vector3(PI / 2 + _rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, 0)), p + Vector3(0, 0.03, 0)))
	for i in 4:
		_add("kastanie", _kugel(0.025, 8, 5), Transform3D(Basis(), _huegel(0.55, 0.05) + Vector3(0, 0.02, 0)))
	_speichern("laub")

## Zerbrochener Maßkrug mit Bierlache und Scherben
func _scherben() -> void:
	_neu()
	_rng.seed = 22
	_mat("glas", Color(0.8, 0.9, 0.95, 0.8), 0.05, 0.3, true)
	_mat("bier", Color(0.78, 0.5, 0.08, 0.85), 0.05, 0.0, true)
	_mat("schaum", Color(0.98, 0.96, 0.88), 0.6)
	# Lache
	_add("bier", _zyl(0.42, 0.42, 0.006, 18), Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.7)), Vector3(0.05, 0.003, 0)))
	_add("bier", _zyl(0.2, 0.2, 0.006, 14), Transform3D(Basis(), Vector3(-0.32, 0.003, 0.16)))
	for i in 7:
		_add("schaum", _kugel(_rng.randf_range(0.015, 0.03), 6, 4), Transform3D(Basis().scaled(Vector3(1, 0.4, 1)), _huegel(0.35, 0.0) + Vector3(0, 0.008, 0)))
	# Boden des Krugs (liegt schräg), dicker Glasboden
	var boden := Transform3D(Basis.from_euler(Vector3(0.4, 0.3, 1.2)), Vector3(0.08, 0.07, -0.02))
	_add("glas", _zyl(0.075, 0.08, 0.1, 20), boden)
	_add("glas", _zyl(0.082, 0.082, 0.02, 14), boden * Transform3D(Basis(), Vector3(0, -0.05, 0)))
	# Henkel: vier Stücke im Bogen
	for i in 4:
		var w := -0.9 + i * 0.6
		var t := Transform3D(Basis.from_euler(Vector3(0, 0, w)), Vector3(-0.2 + sin(w) * 0.05, 0.02 + cos(w) * 0.05 * 0.3, 0.2))
		_add("glas", _box(Vector3(0.022, 0.06, 0.03)), t)
	# Scherben
	for i in 22:
		var p := PrismMesh.new()
		p.size = Vector3(_rng.randf_range(0.05, 0.12), _rng.randf_range(0.04, 0.1), 0.008)
		var pos := _huegel(0.45, 0.0) + Vector3(0, 0.01, 0)
		_add("glas", p, Transform3D(Basis.from_euler(Vector3(PI / 2 + _rng.randf_range(-0.3, 0.3), _rng.randf() * TAU, 0)), pos))
	_speichern("scherben")

## Papiermüll: zerknüllte Servietten, Pappbecher, Brezelrest, Konfetti
func _papier() -> void:
	_neu()
	_rng.seed = 33
	_mat("papier", Color(0.95, 0.94, 0.9), 0.95)
	_mat("becher_rot", Color(0.78, 0.12, 0.12), 0.7)
	_mat("becher_weiss", Color(0.97, 0.97, 0.97), 0.7)
	_mat("brezn", Color(0.55, 0.3, 0.1), 0.55)
	_mat("salz", Color(1, 1, 1), 0.9)
	_mat("konfetti_blau", Color(0.15, 0.4, 0.85), 0.8)
	_mat("konfetti_gelb", Color(0.95, 0.8, 0.15), 0.8)
	for i in 7:
		var r := _rng.randf_range(0.04, 0.07)
		var k := _kugel(r, 6, 4)
		var s := Vector3(_rng.randf_range(0.8, 1.3), _rng.randf_range(0.6, 0.9), _rng.randf_range(0.8, 1.3))
		_add("papier", k, Transform3D(_dreh().scaled(s), _huegel(0.45, 0.0) + Vector3(0, r * 0.6, 0)))
	# flache Serviette
	_add("papier", _box(Vector3(0.18, 0.004, 0.18)), Transform3D(Basis.from_euler(Vector3(0.05, 0.6, 0.04)), Vector3(-0.25, 0.004, -0.2)))
	# zwei umgefallene Pappbecher (Streifen)
	for i in 2:
		var b := Transform3D(Basis.from_euler(Vector3(PI / 2, _rng.randf() * TAU, 0)), _huegel(0.35, 0.0) + Vector3(0, 0.045, 0))
		_add("becher_weiss", _zyl(0.045, 0.034, 0.11, 12), b)
		_add("becher_rot", _zyl(0.0465, 0.043, 0.03, 12), b * Transform3D(Basis(), Vector3(0, 0.03, 0)))
	# Brezelrest (halber Bogen)
	for i in 5:
		var w := i * 0.55
		_add("brezn", _zyl(0.022, 0.022, 0.07, 8), Transform3D(Basis.from_euler(Vector3(PI / 2, w, 0)), Vector3(0.2 + cos(w) * 0.08, 0.02, 0.18 + sin(w) * 0.08)))
	for i in 6:
		_add("salz", _box(Vector3(0.008, 0.006, 0.008)), Transform3D(Basis(), Vector3(0.2, 0.04, 0.18) + _huegel(0.09, 0.0)))
	for i in 24:
		_add("konfetti_blau" if i % 2 == 0 else "konfetti_gelb", _box(Vector3(0.018, 0.002, 0.012)),
			Transform3D(Basis.from_euler(Vector3(0, _rng.randf() * TAU, 0)), _huegel(0.6, 0.0) + Vector3(0, 0.002, 0)))
	_speichern("papier")

## Strohhaufen aus einzelnen Halmen
func _stroh() -> void:
	_neu()
	_rng.seed = 44
	_mat("stroh", Color(0.86, 0.72, 0.36), 0.9)
	_mat("stroh_dunkel", Color(0.68, 0.53, 0.24), 0.95)
	_add("stroh_dunkel", _kugel(0.36, 10, 5), Transform3D(Basis().scaled(Vector3(1.1, 0.3, 0.9)), Vector3.ZERO))
	for i in 110:
		var halm := _zyl(0.004, 0.005, _rng.randf_range(0.15, 0.32), 4)
		var p := _huegel(0.5, 0.12) + Vector3(0, 0.02, 0)
		var b := Basis.from_euler(Vector3(PI / 2 + _rng.randf_range(-0.5, 0.5), _rng.randf() * TAU, _rng.randf_range(-0.3, 0.3)))
		_add("stroh" if i % 3 else "stroh_dunkel", halm, Transform3D(b, p))
	_speichern("stroh")

## Staubhaufen mit Kronkorken, Kippen und einer Flasche
func _staub() -> void:
	_neu()
	_rng.seed = 55
	_mat("staub", Color(0.42, 0.37, 0.31), 1.0)
	_mat("staub_hell", Color(0.58, 0.53, 0.45), 1.0)
	_mat("kronkorken", Color(0.75, 0.72, 0.65), 0.35, 0.8)
	_mat("kippe", Color(0.95, 0.93, 0.88), 0.9)
	_mat("filter", Color(0.85, 0.55, 0.25), 0.9)
	_mat("flasche", Color(0.18, 0.35, 0.12, 0.85), 0.1, 0.0, true)
	_add("staub", _zyl(0.03, 0.34, 0.1, 14), Transform3D(Basis().scaled(Vector3(1.0, 1.0, 0.8)), Vector3(0, 0.05, 0)))
	for i in 18:
		_add("staub_hell" if i % 2 else "staub", _kugel(_rng.randf_range(0.02, 0.05), 6, 4),
			Transform3D(Basis().scaled(Vector3(1, 0.5, 1)), _huegel(0.45, 0.07) + Vector3(0, 0.01, 0)))
	for i in 5:
		var t := Transform3D(Basis.from_euler(Vector3(_rng.randf_range(-0.4, 0.4), _rng.randf() * TAU, 0)), _huegel(0.5, 0.0) + Vector3(0, 0.004, 0))
		_add("kronkorken", _zyl(0.016, 0.014, 0.006, 12), t)
	for i in 4:
		var t := Transform3D(Basis.from_euler(Vector3(PI / 2, _rng.randf() * TAU, 0)), _huegel(0.5, 0.0) + Vector3(0, 0.005, 0))
		_add("kippe", _zyl(0.004, 0.004, 0.035, 6), t)
		_add("filter", _zyl(0.0045, 0.0045, 0.015, 6), t * Transform3D(Basis(), Vector3(0, -0.024, 0)))
	var f := Transform3D(Basis.from_euler(Vector3(PI / 2, 0.7, 0)), Vector3(0.28, 0.035, 0.1))
	_add("flasche", _zyl(0.033, 0.033, 0.16, 12), f)
	_add("flasche", _zyl(0.012, 0.03, 0.05, 12), f * Transform3D(Basis(), Vector3(0, 0.105, 0)))
	_add("flasche", _zyl(0.012, 0.012, 0.04, 10), f * Transform3D(Basis(), Vector3(0, 0.15, 0)))
	_speichern("staub")

## Stubenbesen: Holzstiel, Metallhülse, Bürstenkopf mit Borsten. Stiel entlang +Y,
## Kopf unten bei y = 0.
func _besen() -> void:
	_neu()
	_rng.seed = 66
	_mat("holz", Color(0.62, 0.43, 0.24), 0.7)
	_mat("holz_dunkel", Color(0.42, 0.27, 0.14), 0.7)
	_mat("metall", Color(0.7, 0.7, 0.72), 0.3, 0.9)
	_mat("borsten", Color(0.2, 0.15, 0.1), 0.95)
	_add("holz", _zyl(0.016, 0.016, 1.25, 10), Transform3D(Basis.from_euler(Vector3(0.35, 0, 0)), Vector3(0, 0.69, 0.25)))
	_add("holz_dunkel", _kugel(0.022, 8, 5), Transform3D(Basis(), Vector3(0, 1.28, 0.46)))
	_add("metall", _zyl(0.02, 0.02, 0.08, 10), Transform3D(Basis.from_euler(Vector3(0.35, 0, 0)), Vector3(0, 0.13, 0.012)))
	# Kopf
	_add("holz_dunkel", _box(Vector3(0.36, 0.045, 0.07)), Transform3D(Basis(), Vector3(0, 0.07, 0)))
	_add("holz", _box(Vector3(0.34, 0.012, 0.06)), Transform3D(Basis(), Vector3(0, 0.098, 0)))
	for x in 13:
		for z in 3:
			var p := Vector3(-0.162 + x * 0.027, 0.025, -0.022 + z * 0.022)
			var b := Basis.from_euler(Vector3(_rng.randf_range(-0.08, 0.08), 0, _rng.randf_range(-0.08, 0.08)))
			_add("borsten", _zyl(0.005, 0.006, 0.055, 5), Transform3D(b, p))
	_speichern("besen")

## Staubige Abdeckplane über einem Möbelstück. Einheitsgröße 1 × 1 × 1 (Boden
## bei y = 0) — die Szene skaliert sie auf das Möbel. Oben leicht durchhängend,
## rundum Falten, unten ausgestellter Saum, Staubflecken obenauf.
func _plane() -> void:
	_neu()
	_rng.seed = 77
	_mat("plane", Color(0.72, 0.68, 0.58), 0.95)
	_mat("plane_dunkel", Color(0.6, 0.56, 0.47), 0.95)
	_mat("staub", Color(0.5, 0.46, 0.4), 1.0)
	# Oberseite: leicht gewölbt
	_add("plane", _box(Vector3(1.04, 0.03, 1.04)), _at_y(0.985))
	_add("plane", _kugel(0.5, 16, 6), Transform3D(Basis().scaled(Vector3(1.0, 0.05, 1.0)), Vector3(0, 0.985, 0)))
	# Seiten mit Falten: je Seite eine Wand plus Faltenstreifen
	for seite in 4:
		var w := seite * PI / 2.0
		var b := Basis(Vector3.UP, w)
		var raus := b * Vector3(0, 0, 0.52)
		_add("plane", _box(Vector3(1.04, 0.98, 0.02)), Transform3D(b, raus + Vector3(0, 0.49, 0)))
		for i in 7:
			var x := -0.45 + i * 0.15 + _rng.randf_range(-0.03, 0.03)
			var tief := _rng.randf_range(0.015, 0.035)
			var falte := _zyl(tief, tief * 1.8, 0.95, 6)
			_add("plane_dunkel" if i % 2 else "plane", falte, Transform3D(b, raus + b * Vector3(x, 0.0, 0.0) + Vector3(0, 0.475, 0)))
		# Saum: unten leicht ausgestellt
		_add("plane", _box(Vector3(1.1, 0.06, 0.05)), Transform3D(b.rotated(b * Vector3.RIGHT, 0.25), raus * 1.03 + Vector3(0, 0.03, 0)))
	# Staubflecken
	for i in 9:
		_add("staub", _kugel(_rng.randf_range(0.06, 0.12), 8, 4), Transform3D(Basis().scaled(Vector3(1, 0.08, 1)), Vector3(_rng.randf_range(-0.4, 0.4), 1.005, _rng.randf_range(-0.4, 0.4))))
	_speichern("plane")

func _at_y(y: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(0, y, 0))

## Voller Müllsack aus dunkelgrauem Kunststoff als Drehkörper: flacher Boden,
## praller Bauch mit leichten Beulen vom Inhalt, nach oben Falten, die zum
## zusammengerafften Hals laufen; rotes Zugband mit Schleife, zwei kurze Zipfel.
func _muellsack() -> void:
	_neu()
	_mat("sack", Color(0.12, 0.13, 0.16), 0.32, 0.05)
	_mat("band", Color(0.78, 0.1, 0.08), 0.5)
	(_mats["sack"] as StandardMaterial3D).clearcoat_enabled = true
	(_mats["sack"] as StandardMaterial3D).clearcoat = 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_teile["sack"] = st
	# Profil: [Höhe, Radius]
	var profil := [[0.0, 0.0], [0.0, 0.22], [0.03, 0.27], [0.12, 0.305], [0.25, 0.315], [0.38, 0.3],
		[0.5, 0.26], [0.6, 0.2], [0.68, 0.13], [0.74, 0.07], [0.78, 0.045], [0.84, 0.04], [0.86, 0.0]]
	var seg := 40
	var punkte := []
	for i in profil.size():
		var y: float = profil[i][0]
		var r0: float = profil[i][1]
		var ring := []
		for j in seg + 1:
			var w := float(j) / seg * TAU
			var r := r0
			if r0 > 0.0:
				# Falten: werden zum Hals hin tiefer
				var falte := clampf((y - 0.35) / 0.4, 0.0, 1.0)
				r *= 1.0 + 0.09 * falte * sin(w * 9.0 + y * 6.0)
				# Beulen vom Inhalt (Karton, Flasche) im Bauch
				var bauch := clampf(1.0 - absf(y - 0.28) / 0.25, 0.0, 1.0)
				r *= 1.0 + bauch * (0.07 * sin(w * 2.0 + 0.7) + 0.05 * sin(w * 3.0 + 2.1) + 0.03 * sin(w * 5.0))
			ring.append(Vector3(sin(w) * r, y + (0.015 * sin(w * 3.0) if y > 0.05 and y < 0.7 else 0.0), cos(w) * r))
		punkte.append(ring)
	for i in punkte.size() - 1:
		for j in seg:
			var a: Vector3 = punkte[i][j]
			var b: Vector3 = punkte[i][j + 1]
			var c: Vector3 = punkte[i + 1][j]
			var d: Vector3 = punkte[i + 1][j + 1]
			for v in [a, c, b, b, c, d]:
				st.add_vertex(v)
	# Zugband: Wicklung um den Hals, Schleife, Zipfel
	_add("band", _zyl(0.05, 0.05, 0.03, 16), _at_y(0.79))
	var schlaufe := TorusMesh.new()
	schlaufe.inner_radius = 0.022
	schlaufe.outer_radius = 0.034
	schlaufe.rings = 16
	schlaufe.ring_segments = 6
	for s in [-1.0, 1.0]:
		_add("band", schlaufe, Transform3D(Basis(Vector3.RIGHT, PI / 2).rotated(Vector3.BACK, s * 0.5), Vector3(s * 0.05, 0.81, 0.03)))
	_speichern("muellsack")

func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))
