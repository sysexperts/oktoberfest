extends SceneTree
## Schöne Laubbäume als echte Knoten: Stamm mit Wurzelanläufen, geschwungene Äste,
## mehrere Blattballen aus Kugeln. Drei Arten für Alleen, Ring und Wiese.
##   scenes/kulisse/baum_kastanie.tscn  breit, dunkelgrün
##   scenes/kulisse/baum_linde.tscn     hoch, hellgrün
##   scenes/kulisse/baum_ahorn.tscn     schlank, gelbgrün
##   godot --headless --path . --script tools/bake_baeume.gd

const SZENE := "res://scenes/kulisse/"

var _own: Node
var rng := RandomNumberGenerator.new()
var rinde: StandardMaterial3D
var laub: StandardMaterial3D

func _init() -> void:
	rinde = StandardMaterial3D.new()
	rinde.albedo_color = Color(0.32, 0.24, 0.18)
	rinde.roughness = 0.95
	for art: String in ["kastanie", "linde", "ahorn"]:
		rng.seed = hash(art)
		laub = StandardMaterial3D.new()
		laub.roughness = 0.9
		match art:
			"kastanie":
				laub.albedo_color = Color(0.17, 0.35, 0.16)
			"linde":
				laub.albedo_color = Color(0.29, 0.5, 0.2)
			_:
				laub.albedo_color = Color(0.42, 0.55, 0.18)
		_speichern(_baum(art), SZENE + "baum_%s.tscn" % art)
	print("BAEUME FERTIG")
	quit()

func _baum(art: String) -> Node3D:
	var r := Node3D.new()
	r.name = "Baum" + art.capitalize()
	_own = r
	var hoehe := 7.5
	var stamm_r := 0.32
	var ballen := 7
	var breite := 3.4
	match art:
		"kastanie":
			hoehe = 6.8
			stamm_r = 0.38
			breite = 4.0
			ballen = 9
		"linde":
			hoehe = 8.5
			stamm_r = 0.3
			breite = 3.2
			ballen = 8
		_:
			hoehe = 7.2
			stamm_r = 0.26
			breite = 2.6
			ballen = 7
	# Stamm: leicht kegelig, mit drei Wurzelanläufen
	_zyl(r, "Stamm", stamm_r * 1.25, stamm_r * 0.7, hoehe * 0.62, Vector3(0, hoehe * 0.31, 0), rinde, Vector3.ZERO, 10)
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		_zyl(r, "Wurzel%d" % i, stamm_r * 0.5, stamm_r * 0.2, 1.0, Vector3(sin(a) * stamm_r * 0.7, 0.35, cos(a) * stamm_r * 0.7),
			rinde, Vector3(rad_to_deg(cos(a)) * 0.28, 0, -rad_to_deg(sin(a)) * 0.28), 6)
	# Äste
	var krone_y := hoehe * 0.6
	for i in 4:
		var a := TAU * i / 4.0 + 0.6
		var laenge := breite * 0.75
		_zyl(r, "Ast%d" % i, stamm_r * 0.42, stamm_r * 0.16, laenge, Vector3(sin(a) * laenge * 0.32, krone_y + laenge * 0.28, cos(a) * laenge * 0.32),
			rinde, Vector3(rad_to_deg(cos(a)) * 0.45, 0, -rad_to_deg(sin(a)) * 0.45), 6)
	# Blattballen: eine große Mitte, außen kleinere, unregelmäßig versetzt
	_kugel(r, "Krone", breite * 0.62, Vector3(0, krone_y + breite * 0.55, 0), laub, Vector3(1.0, 0.82, 1.0))
	for i in ballen:
		var a := TAU * i / float(ballen) + rng.randf_range(-0.2, 0.2)
		var rad := breite * rng.randf_range(0.42, 0.62)
		var y := krone_y + breite * rng.randf_range(0.18, 0.85)
		_kugel(r, "Ballen%d" % i, breite * rng.randf_range(0.3, 0.42), Vector3(sin(a) * rad, y, cos(a) * rad), laub,
			Vector3(1.0, rng.randf_range(0.75, 0.95), 1.0))
	# Stammkollision
	var koerper := StaticBody3D.new()
	koerper.name = "Kollision"
	r.add_child(koerper)
	koerper.owner = r
	var form := CylinderShape3D.new()
	form.radius = stamm_r
	form.height = hoehe * 0.6
	var cs := CollisionShape3D.new()
	cs.shape = form
	cs.position = Vector3(0, hoehe * 0.3, 0)
	cs.name = "Form"
	koerper.add_child(cs)
	cs.owner = r
	return r

func _zyl(parent: Node, name: String, unten: float, oben: float, h: float, pos: Vector3, mat: Material, grad: Vector3, seg: int) -> void:
	var c := CylinderMesh.new()
	c.bottom_radius = unten
	c.top_radius = oben
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.material_override = mat
	mi.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(grad.x), deg_to_rad(grad.y), deg_to_rad(grad.z))), pos)
	mi.name = name
	parent.add_child(mi)
	mi.owner = _own

func _kugel(parent: Node, name: String, r: float, pos: Vector3, mat: Material, skal: Vector3) -> void:
	var k := SphereMesh.new()
	k.radius = r
	k.height = r * 2.0
	k.radial_segments = 12
	k.rings = 6
	var mi := MeshInstance3D.new()
	mi.mesh = k
	mi.material_override = mat
	mi.transform = Transform3D(Basis().scaled(skal), pos)
	mi.name = name
	parent.add_child(mi)
	mi.owner = _own

func _speichern(root: Node, pfad: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pfad.get_base_dir()))
	var ps := PackedScene.new()
	ps.pack(root)
	ResourceSaver.save(ps, pfad)
	root.free()
	print("  ", pfad)
