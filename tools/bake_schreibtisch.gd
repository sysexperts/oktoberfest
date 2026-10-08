extends SceneTree
## Backt den Schreibtisch fürs Zeltbüro (mit Schubladen, Löschblatt, Monitor, Tastatur)
## und den Ledersessel dazu zu je einem ArrayMesh mit einer Oberfläche pro Material.
## Alle Kanten sind abgerundet (_rbox), das Holz nutzt die Zelt-Texturen.
## Aufruf: godot --headless --path . --script res://tools/bake_schreibtisch.gd
## Maße in Metern, Boden bei y = 0, die Sitzseite zeigt nach +Z.

const ZIEL := "res://assets/moebel/"
const MAT := "res://assets/zelt/materialien/"

var _teile := {}
var _mats := {}
var _rbox_cache := {}

func _init() -> void:
	_schreibtisch()
	_sessel()
	print("Schreibtisch und Sessel gebacken.")
	quit()

# ------------------------------------------------------------ Werkzeug
func _neu() -> void:
	_teile.clear()
	_mats.clear()
	_mats["holz"] = load(MAT + "holz_hell.tres")
	_mats["dunkel"] = load(MAT + "holz_dunkel.tres")
	_farbe("messing", Color(0.86, 0.66, 0.26), 0.28, 0.9)
	_farbe("metall", Color(0.66, 0.67, 0.7), 0.35, 0.85)
	_farbe("schwarz", Color(0.07, 0.07, 0.08), 0.45)
	_farbe("kunststoff", Color(0.8, 0.8, 0.78), 0.5)
	_farbe("filz", Color(0.14, 0.34, 0.2), 0.95)
	_farbe("leder", Color(0.4, 0.11, 0.08), 0.42)
	_farbe("leder_dunkel", Color(0.2, 0.07, 0.05), 0.45)
	_farbe("papier", Color(0.95, 0.93, 0.86), 0.9)
	_farbe("lampenglas", Color(0.1, 0.45, 0.25), 0.2)
	_farbe("stift_rot", Color(0.75, 0.12, 0.1), 0.5)
	_farbe("stift_blau", Color(0.12, 0.25, 0.7), 0.5)
	# Bildschirm: leuchtet blau wie der Laptop im Wohnwagen
	var bild := StandardMaterial3D.new()
	bild.albedo_color = Color(0.25, 0.55, 0.95)
	bild.emission_enabled = true
	bild.emission = Color(0.2, 0.5, 1.0)
	bild.emission_energy_multiplier = 1.6
	_mats["bild"] = bild

func _farbe(name: String, farbe: Color, rauh := 0.8, metall := 0.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
	_mats[name] = m

func _add(mat: String, mesh: Mesh, t: Transform3D) -> void:
	if not _teile.has(mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_teile[mat] = st
	(_teile[mat] as SurfaceTool).append_from(mesh, 0, t)

func _speichern(name: String) -> void:
	var am := ArrayMesh.new()
	for mat: String in _teile.keys():
		var st: SurfaceTool = _teile[mat]
		st.commit(am)
		am.surface_set_material(am.get_surface_count() - 1, _mats[mat])
		am.surface_set_name(am.get_surface_count() - 1, mat)
	ResourceSaver.save(am, ZIEL + name + ".tres")
	print("  ", name, ": ", am.get_surface_count(), " Oberflächen")

func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))

func _zyl(r_oben: float, r_unten: float, h: float, seg := 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_oben
	c.bottom_radius = r_unten
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _kugel(r: float, seg := 12, ringe := 6) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = seg
	s.rings = ringe
	return s

## Achsenpunkte eines abgerundeten Kastens: dicht an den Rundungen, dazwischen nur ein Feld
func _achse(h: float, r: float, s: int) -> Array[float]:
	var a: Array[float] = []
	for k in s + 1:
		a.append(-h + r * (1.0 - cos(float(k) * PI / 2.0 / float(s))))
	for k in range(s, -1, -1):
		a.append(h - r * (1.0 - cos(float(k) * PI / 2.0 / float(s))))
	return a

## Kasten mit abgerundeten Kanten und Ecken (glatte Normalen)
func _rbox(groesse: Vector3, r: float, s := 3) -> ArrayMesh:
	var schluessel := "%s_%s_%d" % [groesse, r, s]
	if _rbox_cache.has(schluessel):
		return _rbox_cache[schluessel]
	var h := groesse / 2.0
	r = minf(r, minf(h.x, minf(h.y, h.z)) * 0.99)
	var achsen := [_achse(h.x, r, s), _achse(h.y, r, s), _achse(h.z, r, s)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for a in 3:
		for vorz in [-1.0, 1.0]:
			var b := (a + 1) % 3
			var c := (a + 2) % 3
			var lb: Array = achsen[b]
			var lc: Array = achsen[c]
			for i in lb.size() - 1:
				for j in lc.size() - 1:
					var ecken: Array[Vector3] = []
					var normalen: Array[Vector3] = []
					for ij in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
						var p := Vector3.ZERO
						p[a] = vorz * h[a]
						p[b] = lb[i + ij.x]
						p[c] = lc[j + ij.y]
						var innen := Vector3(
							clampf(p.x, -h.x + r, h.x - r),
							clampf(p.y, -h.y + r, h.y - r),
							clampf(p.z, -h.z + r, h.z - r))
						var n := (p - innen).normalized()
						ecken.append(innen + n * r)
						normalen.append(n)
					var mitte_n := (normalen[0] + normalen[1] + normalen[2] + normalen[3]).normalized()
					# Godot: Vorderseite = im Uhrzeigersinn
					var reihenfolge := [0, 1, 2, 0, 2, 3]
					var flaeche := (ecken[1] - ecken[0]).cross(ecken[2] - ecken[0])
					if flaeche.dot(mitte_n) > 0.0:
						reihenfolge = [0, 2, 1, 0, 3, 2]
					for k in reihenfolge:
						st.set_normal(normalen[k])
						st.add_vertex(ecken[k])
	var mesh := st.commit()
	_rbox_cache[schluessel] = mesh
	return mesh

func _rb(mat: String, groesse: Vector3, r: float, pos: Vector3, drehung := Basis()) -> void:
	_add(mat, _rbox(groesse, r), Transform3D(drehung, pos))

# ------------------------------------------------------------ Schreibtisch
func _schreibtisch() -> void:
	_neu()
	var H := 0.76
	# Platte mit Zarge darunter
	_rb("holz", Vector3(1.7, 0.04, 0.85), 0.014, Vector3(0, H - 0.02, 0))
	_rb("dunkel", Vector3(1.62, 0.035, 0.77), 0.01, Vector3(0, H - 0.0575, 0))
	# Linker Schubladenblock auf Sockel
	_rb("dunkel", Vector3(0.53, 0.06, 0.77), 0.012, Vector3(-0.56, 0.03, 0))
	_rb("dunkel", Vector3(0.5, 0.64, 0.74), 0.01, Vector3(-0.56, 0.38, 0))
	for i in 3:
		var y := 0.17 + i * 0.21
		# Front, leicht vorstehend; der dunkle Block dahinter ergibt die Fuge
		_rb("holz", Vector3(0.46, 0.185, 0.03), 0.01, Vector3(-0.56, y, 0.375))
		_rb("dunkel", Vector3(0.38, 0.1, 0.006), 0.003, Vector3(-0.56, y + 0.005, 0.392))
		# Messinggriff mit zwei Stegen und Schlüsselschild
		_rb("messing", Vector3(0.15, 0.016, 0.018), 0.007, Vector3(-0.56, y + 0.02, 0.425))
		for sx in [-0.06, 0.06]:
			_rb("messing", Vector3(0.016, 0.016, 0.03), 0.006, Vector3(-0.56 + sx, y + 0.02, 0.405))
		_rb("messing", Vector3(0.034, 0.05, 0.008), 0.003, Vector3(-0.56, y - 0.04, 0.395))
		_add("schwarz", _zyl(0.005, 0.005, 0.01, 8), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(-0.56, y - 0.045, 0.4)))
	# Rechte Seite: Wangen mit Sockel, Rückwand als Blende
	_rb("dunkel", Vector3(0.05, 0.06, 0.77), 0.012, Vector3(0.78, 0.03, 0))
	_rb("dunkel", Vector3(0.04, 0.64, 0.74), 0.008, Vector3(0.78, 0.38, 0))
	_rb("dunkel", Vector3(1.08, 0.42, 0.02), 0.006, Vector3(0.12, 0.47, -0.34))
	_rb("dunkel", Vector3(0.02, 0.05, 0.6), 0.006, Vector3(-0.305, 0.28, 0.0))
	# Löschblatt aus Filz mit Lederecken
	_rb("filz", Vector3(0.7, 0.008, 0.44), 0.003, Vector3(-0.05, H + 0.004, 0.17))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_rb("leder_dunkel", Vector3(0.07, 0.01, 0.07), 0.004, Vector3(-0.05 + sx * 0.335, H + 0.006, 0.17 + sz * 0.205))
	# Papierstapel, schräg
	_rb("papier", Vector3(0.21, 0.035, 0.3), 0.003, Vector3(0.57, H + 0.0175, 0.18), Basis(Vector3.UP, 0.18))
	_rb("papier", Vector3(0.21, 0.012, 0.3), 0.003, Vector3(0.575, H + 0.041, 0.185), Basis(Vector3.UP, 0.3))
	# Stiftebecher
	_add("dunkel", _zyl(0.04, 0.036, 0.1), _at(0.7, H + 0.05, -0.28))
	_add("messing", _zyl(0.042, 0.042, 0.012), _at(0.7, H + 0.1, -0.28))
	_add("stift_rot", _zyl(0.005, 0.005, 0.17, 8), Transform3D(Basis(Vector3.BACK, 0.18), Vector3(0.69, H + 0.14, -0.28)))
	_add("stift_blau", _zyl(0.005, 0.005, 0.16, 8), Transform3D(Basis(Vector3.BACK, -0.14).rotated(Vector3.RIGHT, 0.1), Vector3(0.71, H + 0.135, -0.285)))
	# Messing-Schreibtischlampe mit grünem Glasschirm
	_add("messing", _zyl(0.07, 0.08, 0.022, 20), _at(-0.7, H + 0.011, -0.25))
	_add("messing", _zyl(0.01, 0.012, 0.3, 10), _at(-0.7, H + 0.17, -0.25))
	_add("lampenglas", _zyl(0.045, 0.1, 0.1, 20), Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(-0.7, H + 0.36, -0.22)))
	_add("messing", _kugel(0.016, 10, 6), _at(-0.7, H + 0.325, -0.25))
	# Monitor mit blauem Bild
	_rb("schwarz", Vector3(0.22, 0.016, 0.17), 0.007, Vector3(0.0, H + 0.008, -0.12))
	_rb("schwarz", Vector3(0.05, 0.14, 0.035), 0.012, Vector3(0.0, H + 0.085, -0.16))
	_rb("schwarz", Vector3(0.58, 0.37, 0.04), 0.012, Vector3(0.0, H + 0.36, -0.14))
	_add("bild", _rbox(Vector3(0.52, 0.31, 0.004), 0.001, 1), _at(0.0, H + 0.365, -0.1175))
	_add("metall", _kugel(0.006, 8, 4), _at(0.24, H + 0.195, -0.115))
	# Tastatur mit Tasten und Maus
	_rb("kunststoff", Vector3(0.44, 0.02, 0.15), 0.007, Vector3(-0.02, H + 0.01, 0.24), Basis(Vector3.RIGHT, 0.03))
	for reihe in 4:
		var anzahl := 14 if reihe < 3 else 9
		var x0 := -0.02 - float(anzahl) * 0.0285 / 2.0
		for taste in anzahl:
			var breit := 0.024
			var x := x0 + float(taste) * 0.0285 + 0.013
			if reihe == 3:
				x = -0.02 + (float(taste) - 4.0) * 0.0285
				if taste == 4:
					breit = 0.13
				elif taste > 4:
					x += 0.108
			_rb("kunststoff", Vector3(breit, 0.01, 0.022), 0.003,
				Vector3(x, H + 0.025, 0.2 + float(reihe) * 0.031))
	_rb("kunststoff", Vector3(0.06, 0.028, 0.1), 0.014, Vector3(0.33, H + 0.014, 0.25), Basis(Vector3.UP, -0.1))
	_rb("schwarz", Vector3(0.006, 0.004, 0.03), 0.002, Vector3(0.33, H + 0.029, 0.22), Basis(Vector3.UP, -0.1))
	_speichern("schreibtisch_zelt")

# ------------------------------------------------------------ Sessel
func _sessel() -> void:
	_neu()
	# Fünfsternfuß mit Rollen
	for i in 5:
		var w := float(i) * TAU / 5.0 + 0.3
		var d := Vector3(sin(w), 0, cos(w))
		var basis := Basis(Vector3.UP, w) * Basis(Vector3.RIGHT, 0.07)
		_rb("schwarz", Vector3(0.05, 0.036, 0.32), 0.014, Vector3(0, 0.1, 0) + d * 0.15, basis)
		var ende := d * 0.3
		_rb("schwarz", Vector3(0.03, 0.05, 0.03), 0.01, Vector3(ende.x, 0.075, ende.z))
		_add("metall", _zyl(0.026, 0.026, 0.024, 12), Transform3D(Basis(Vector3.UP, w) * Basis(Vector3.BACK, PI / 2), Vector3(ende.x, 0.03, ende.z)))
	_rb("schwarz", Vector3(0.1, 0.06, 0.1), 0.025, Vector3(0, 0.125, 0))
	# Gasfeder mit Manschette
	_add("metall", _zyl(0.022, 0.022, 0.3, 12), _at(0, 0.3, 0))
	_add("schwarz", _zyl(0.034, 0.045, 0.2, 14), _at(0, 0.24, 0))
	# Mechanik unter dem Sitz
	_rb("schwarz", Vector3(0.3, 0.055, 0.24), 0.02, Vector3(0, 0.43, 0))
	# Sitzpolster: Unterbau und gewölbte Auflage
	_rb("leder_dunkel", Vector3(0.53, 0.06, 0.52), 0.025, Vector3(0, 0.485, 0.01))
	_rb("leder", Vector3(0.5, 0.075, 0.49), 0.035, Vector3(0, 0.535, 0.015))
	_rb("messing", Vector3(0.505, 0.008, 0.495), 0.003, Vector3(0, 0.507, 0.015))
	# Lehne: Holzrahmen, Lederpolster, Knöpfe, leicht nach hinten geneigt
	var lehne := Basis(Vector3.RIGHT, -0.14)
	var mitte := Vector3(0, 0.88, -0.26)
	_add("dunkel", _rbox(Vector3(0.5, 0.56, 0.05), 0.02), Transform3D(lehne, mitte))
	_add("leder", _rbox(Vector3(0.46, 0.52, 0.075), 0.032), Transform3D(lehne, mitte + lehne * Vector3(0, 0, 0.04)))
	for sx in [-0.12, 0.0, 0.12]:
		for sy in [-0.12, 0.08]:
			_add("messing", _kugel(0.011, 8, 4), Transform3D(Basis(), mitte + lehne * Vector3(sx, sy, 0.082)))
	_rb("metall", Vector3(0.05, 0.34, 0.04), 0.012, Vector3(0, 0.62, -0.23), lehne)
	# Armlehnen mit Lederpolster
	for sx in [-1.0, 1.0]:
		_rb("schwarz", Vector3(0.04, 0.22, 0.045), 0.012, Vector3(sx * 0.285, 0.64, -0.05))
		_rb("schwarz", Vector3(0.04, 0.05, 0.22), 0.012, Vector3(sx * 0.285, 0.545, -0.1))
		_rb("leder", Vector3(0.075, 0.045, 0.3), 0.02, Vector3(sx * 0.285, 0.76, 0.02))
	_speichern("sessel_leder")
