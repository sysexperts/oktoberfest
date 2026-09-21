extends SceneTree
## Backt die große Mülltonne vor dem Zelt zu zwei ArrayMeshes: Korpus und
## Deckel (getrennt, damit der Deckel beim Einwerfen aufklappen kann).
## Szene: scenes/muellplatz.tscn.
## Aufruf: godot --headless --script res://tools/bake_muelltonne.gd
## Vorn (Einwurfseite) = +Z, Boden bei y = 0. Der Deckel dreht um seine
## Hinterkante bei z = -0.53, y = 1.17 — dort sitzt in der Szene das Gelenk.

const ZIEL := "res://assets/dreck/"
## Außenmaß oben; unten läuft die Tonne etwas schmaler zu
const BREITE := 1.42
const TIEFE := 1.02
const KORPUS_H := 1.05
const BODEN := 0.12       # Höhe der Rollen
const RAND_Y := BODEN + KORPUS_H

var _teile := {}
var _mats := {}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
	_korpus()
	_deckel()
	print("Mülltonne gebacken.")
	quit()

func _mat(name: String, farbe: Color, rauh := 0.6, metall := 0.0) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = farbe
	m.roughness = rauh
	m.metallic = metall
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

## Nach unten zulaufender Kasten: ein Vierkant-Kegelstumpf, um 45° gedreht und
## in der Tiefe gestaucht. So bekommt die Tonne ihre echte Wannenform.
func _wanne(mat: String, y: float, h: float, breite_oben: float, breite_unten: float, tiefe_oben: float) -> void:
	var r_oben := breite_oben * 0.5 / cos(PI / 4.0)
	var r_unten := breite_unten * 0.5 / cos(PI / 4.0)
	var basis := Basis.from_scale(Vector3(1, 1, tiefe_oben / breite_oben)) * Basis(Vector3.UP, PI / 4.0)
	_add(mat, _zyl(r_oben, h, 4, r_unten), Transform3D(basis, Vector3(0, y + h * 0.5, 0)))

func _korpus() -> void:
	_mat("kunststoff", Color(0.16, 0.27, 0.2), 0.75)
	_mat("dunkel", Color(0.1, 0.16, 0.12), 0.8)
	_mat("gummi", Color(0.06, 0.06, 0.07), 0.9)
	_mat("stahl", Color(0.45, 0.46, 0.48), 0.4, 0.8)
	# Wanne, unten 12 cm schmaler als oben
	_wanne("kunststoff", BODEN, KORPUS_H, BREITE, BREITE - 0.18, TIEFE)
	# Umlaufender Rand oben, auf dem der Deckel aufliegt
	_wanne("dunkel", RAND_Y - 0.06, 0.1, BREITE + 0.06, BREITE + 0.06, TIEFE + 0.06)
	# Griffleisten an den Seiten
	for sx in [-1.0, 1.0]:
		_add("dunkel", _zyl(0.045, TIEFE * 0.78, 8),
			Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(sx * (BREITE * 0.5 - 0.02), RAND_Y - 0.3, 0)))
	# Waagerechte Rippen vorn — gibt der Fläche Halt fürs Auge
	for i in 3:
		_add("dunkel", _box(Vector3(BREITE - 0.26, 0.045, 0.035)), _at(0, BODEN + 0.26 + i * 0.24, TIEFE * 0.5 - 0.04))
	# Tritt-/Anfahrschutz unten
	_add("dunkel", _box(Vector3(BREITE - 0.3, 0.07, 0.05)), _at(0, BODEN + 0.06, TIEFE * 0.5 - 0.03))
	# Vier Lenkrollen mit Gabel
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var p := Vector3(sx * (BREITE * 0.5 - 0.22), BODEN * 0.5, sz * (TIEFE * 0.5 - 0.18))
			_add("stahl", _box(Vector3(0.1, 0.1, 0.06)), _at(p.x, BODEN + 0.02, p.z))
			_add("gummi", _zyl(0.062, 0.05, 12), Transform3D(Basis(Vector3.FORWARD, PI / 2.0), p))
			_add("stahl", _zyl(0.018, 0.06, 8), Transform3D(Basis(Vector3.FORWARD, PI / 2.0), p))
	_speichern("muelltonne")

func _deckel() -> void:
	_mat("deckel", Color(0.13, 0.22, 0.16), 0.7)
	_mat("deckel_dunkel", Color(0.09, 0.15, 0.11), 0.8)
	# Der Deckel liegt vor dem Gelenk: Hinterkante bei z = 0, Vorderkante bei +Tiefe
	var t := TIEFE + 0.1
	_add("deckel", _box(Vector3(BREITE + 0.1, 0.07, t)), _at(0, 0.035, t * 0.5))
	# Leichte Wölbung: ein flacher Streifen in der Mitte
	_add("deckel", _box(Vector3(BREITE - 0.2, 0.05, t - 0.2)), _at(0, 0.08, t * 0.5))
	# Abgesetzte Vorderkante statt einer Griffstange
	_add("deckel_dunkel", _box(Vector3(BREITE + 0.1, 0.05, 0.08)), _at(0, 0.03, t - 0.04))
	_speichern("muelltonne_deckel")
