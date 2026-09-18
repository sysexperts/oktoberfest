extends SceneTree
## Backt den Brauerei-Lieferwagen (Kastenwagen) und sein Rad zu je einem ArrayMesh
## mit einer Oberfläche pro Material. Szene: scenes/delivery_van.tscn.
## Aufruf: godot --headless --script res://tools/bake_lieferwagen.gd
## Vorn = +Z, Boden bei y = 0, Mitte der Hinterachse bei z = -1.6.

const ZIEL := "res://assets/fahrzeuge/"

var _teile := {}
var _mats := {}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_wagen()
	_rad()
	print("Lieferwagen gebacken.")
	quit()

func _mat(name: String, farbe: Color, rauh := 0.6, metall := 0.0, leuchten := 0.0, alpha := false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
	if leuchten > 0.0:
		m.emission_enabled = true
		m.emission = farbe
		m.emission_energy_multiplier = leuchten
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mats[name] = m

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
	_teile.clear()
	_mats.clear()

func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b

func _zyl(r: float, h: float, seg := 16, r_unten := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r if r_unten < 0.0 else r_unten
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

func _at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis(), Vector3(x, y, z))

## Kiste mit abgerundeten Längskanten (entlang Z): Kern + 4 Kantenzylinder
func _rund_kiste(mat: String, mitte: Vector3, s: Vector3, r: float) -> void:
	_add(mat, _box(Vector3(s.x - 2 * r, s.y, s.z)), _at(mitte.x, mitte.y, mitte.z))
	_add(mat, _box(Vector3(s.x, s.y - 2 * r, s.z)), _at(mitte.x, mitte.y, mitte.z))
	var liegend := Basis(Vector3.RIGHT, PI / 2)
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			_add(mat, _zyl(r, s.z, 12), Transform3D(liegend, mitte + Vector3(sx * (s.x / 2 - r), sy * (s.y / 2 - r), 0)))

func _wagen() -> void:
	_mat("lack", Color(0.93, 0.92, 0.88), 0.35, 0.1)
	_mat("blau", Color(0.13, 0.3, 0.68), 0.4, 0.1)
	_mat("dunkel", Color(0.12, 0.12, 0.13), 0.7)
	_mat("chrom", Color(0.8, 0.8, 0.82), 0.2, 1.0)
	_mat("glas", Color(0.12, 0.18, 0.24, 0.85), 0.05, 0.3, 0.0, true)
	_mat("licht", Color(1.0, 0.95, 0.8), 0.2, 0.0, 1.5)
	_mat("blinker", Color(1.0, 0.55, 0.1), 0.3, 0.0, 0.6)
	_mat("rueck", Color(0.85, 0.08, 0.06), 0.3, 0.0, 0.8)
	_mat("schild", Color(0.96, 0.96, 0.92), 0.6)
	_mat("gummi", Color(0.05, 0.05, 0.05), 0.9)
	# Unterboden und Rahmen
	_add("dunkel", _box(Vector3(1.8, 0.2, 4.9)), _at(0, 0.5, -0.05))
	# Kofferaufbau (hinten)
	_rund_kiste("lack", Vector3(0, 1.56, -1.05), Vector3(2.1, 1.9, 3.3), 0.1)
	# Blau-weißer Rautenstreifen an beiden Seiten
	for sx in [-1.0, 1.0]:
		_add("blau", _box(Vector3(0.012, 0.34, 3.1)), _at(sx * 1.052, 1.1, -1.05))
		for i in 13:
			_add("lack", _box(Vector3(0.014, 0.17, 0.17)), Transform3D(Basis(Vector3.RIGHT, PI / 4), Vector3(sx * 1.053, 1.1, -2.45 + i * 0.235)))
		_add("blau", _box(Vector3(0.012, 0.05, 3.1)), _at(sx * 1.052, 2.25, -1.05))
	# Hecktüren: Fuge, Griffe, Rückleuchten, Nummernschild, Stoßstange, Trittstufe
	_add("dunkel", _box(Vector3(0.02, 1.7, 0.02)), _at(0, 1.5, -2.71))
	for sx in [-1.0, 1.0]:
		_add("chrom", _box(Vector3(0.06, 0.2, 0.04)), _at(sx * 0.12, 1.4, -2.72))
		_add("rueck", _box(Vector3(0.14, 0.3, 0.04)), _at(sx * 0.93, 0.95, -2.72))
		_add("blinker", _box(Vector3(0.14, 0.08, 0.04)), _at(sx * 0.93, 0.76, -2.72))
	_add("schild", _box(Vector3(0.5, 0.12, 0.02)), _at(0, 0.78, -2.72))
	_add("dunkel", _box(Vector3(2.0, 0.16, 0.16)), _at(0, 0.52, -2.72))
	_add("chrom", _box(Vector3(0.6, 0.04, 0.3)), _at(0, 0.36, -2.8))
	# Fahrerhaus
	_rund_kiste("lack", Vector3(0, 1.3, 1.25), Vector3(2.04, 1.4, 1.5), 0.12)
	_rund_kiste("lack", Vector3(0, 2.02, 1.05), Vector3(1.96, 0.3, 1.1), 0.12)
	# Motorhaube, schräg abfallend
	_add("lack", _box(Vector3(1.96, 0.5, 0.75)), _at(0, 1.02, 2.2))
	_add("lack", _box(Vector3(1.96, 0.12, 0.8)), Transform3D(Basis(Vector3.RIGHT, 0.18), Vector3(0, 1.3, 2.15)))
	# Frontscheibe (schräg), Seitenfenster, Türfugen, Griffe, Spiegel
	_add("glas", _box(Vector3(1.8, 0.75, 0.04)), Transform3D(Basis(Vector3.RIGHT, -0.45), Vector3(0, 1.78, 1.83)))
	_add("dunkel", _box(Vector3(1.86, 0.06, 0.06)), Transform3D(Basis(Vector3.RIGHT, -0.45), Vector3(0, 2.13, 1.66)))
	for sx in [-1.0, 1.0]:
		_add("glas", _box(Vector3(0.03, 0.55, 0.9)), _at(sx * 1.025, 1.78, 1.2))
		_add("dunkel", _box(Vector3(0.02, 1.2, 0.02)), _at(sx * 1.03, 1.35, 0.55))
		_add("dunkel", _box(Vector3(0.02, 1.2, 0.02)), _at(sx * 1.03, 1.35, 1.72))
		_add("chrom", _box(Vector3(0.04, 0.05, 0.18)), _at(sx * 1.04, 1.4, 0.75))
		_add("dunkel", _box(Vector3(0.28, 0.04, 0.04)), _at(sx * 1.15, 1.7, 1.7))
		_add("dunkel", _box(Vector3(0.05, 0.28, 0.16)), _at(sx * 1.3, 1.72, 1.7))
		_add("glas", _box(Vector3(0.01, 0.24, 0.12)), _at(sx * 1.3, 1.72, 1.61))
		# Radkästen
		for z in [1.75, -1.6]:
			_add("dunkel", _zyl(0.52, 0.3, 16), Transform3D(Basis(Vector3.BACK, PI / 2), Vector3(sx * 0.92, 0.55, z)))
	# Front: Kühlergrill mit Chromstreben, Scheinwerfer, Blinker, Stoßstange, Kennzeichen
	_add("dunkel", _box(Vector3(1.1, 0.4, 0.05)), _at(0, 1.0, 2.58))
	for i in 5:
		_add("chrom", _box(Vector3(1.05, 0.03, 0.03)), _at(0, 0.85 + i * 0.075, 2.61))
	_add("chrom", _box(Vector3(1.16, 0.46, 0.02)), _at(0, 1.0, 2.565))
	for sx in [-1.0, 1.0]:
		_add("licht", _zyl(0.13, 0.05, 16), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(sx * 0.75, 1.05, 2.59)))
		_add("chrom", _zyl(0.15, 0.04, 16), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(sx * 0.75, 1.05, 2.575)))
		_add("blinker", _box(Vector3(0.18, 0.07, 0.04)), _at(sx * 0.75, 0.84, 2.59))
	_add("dunkel", _box(Vector3(2.06, 0.2, 0.2)), _at(0, 0.62, 2.62))
	_add("schild", _box(Vector3(0.5, 0.12, 0.02)), _at(0, 0.62, 2.73))
	# Auspuff
	_add("chrom", _zyl(0.04, 0.3, 10), Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(0.6, 0.35, -2.7)))
	_speichern("lieferwagen")

## Rad: Reifen, Felge, Nabe, fünf Radmuttern. Achse = X.
func _rad() -> void:
	_mat("gummi", Color(0.06, 0.06, 0.06), 0.9)
	_mat("felge", Color(0.75, 0.75, 0.78), 0.25, 0.9)
	_mat("nabe", Color(0.25, 0.25, 0.27), 0.4, 0.6)
	var achse := Basis(Vector3.BACK, PI / 2)
	_add("gummi", _zyl(0.42, 0.28, 24), Transform3D(achse, Vector3.ZERO))
	for sx in [-1.0, 1.0]:
		_add("felge", _zyl(0.27, 0.02, 20), Transform3D(achse, Vector3(sx * 0.141, 0, 0)))
		_add("nabe", _zyl(0.09, 0.03, 12), Transform3D(achse, Vector3(sx * 0.155, 0, 0)))
		for i in 5:
			var w := i * TAU / 5.0
			_add("nabe", _zyl(0.022, 0.03, 8), Transform3D(achse, Vector3(sx * 0.16, sin(w) * 0.16, cos(w) * 0.16)))
		# Profilblöcke
		for i in 16:
			var w := i * TAU / 16.0
			_add("gummi", _box(Vector3(0.24, 0.05, 0.08)), Transform3D(Basis(Vector3.RIGHT, w), Vector3(0, sin(w) * 0.425, cos(w) * 0.425)))
	_speichern("rad")
