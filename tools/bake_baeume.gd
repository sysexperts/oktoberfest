extends SceneTree
## Schöne Laubbäume als echte Knoten: Stamm mit Wurzelanläufen, geschwungene Äste,
## mehrere Blattballen aus Kugeln. Drei Arten für Alleen, Ring und Wiese.
##   scenes/kulisse/baum_kastanie.tscn  breit, dunkelgrün
##   scenes/kulisse/baum_linde.tscn     hoch, hellgrün
##   scenes/kulisse/baum_ahorn.tscn     schlank, gelbgrün
##   scenes/kulisse/baum_birke.tscn     weißer Stamm mit dunklen Flecken, luftige Krone
##   scenes/kulisse/baum_fichte.tscn    Nadelbaum aus gestaffelten Kegeln
##   scenes/kulisse/baum_apfel.tscn     niedriger Obstbaum mit roten Äpfeln
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
	for art: String in ["kastanie", "linde", "ahorn", "birke", "fichte", "apfel"]:
		rng.seed = hash(art)
		laub = StandardMaterial3D.new()
		laub.roughness = 0.9
		match art:
			"kastanie":
				laub.albedo_color = Color(0.17, 0.35, 0.16)
			"linde":
				laub.albedo_color = Color(0.29, 0.5, 0.2)
			"birke":
				laub.albedo_color = Color(0.45, 0.62, 0.24)
			"fichte":
				laub.albedo_color = Color(0.1, 0.26, 0.15)
			"apfel":
				laub.albedo_color = Color(0.25, 0.45, 0.17)
			_:
				laub.albedo_color = Color(0.42, 0.55, 0.18)
		_speichern(_baum(art), SZENE + "baum_%s.tscn" % art)
	print("BAEUME FERTIG")
	quit()

func _baum(art: String) -> Node3D:
	var r := Node3D.new()
	r.name = "Baum" + art.capitalize()
	_own = r
	if art == "fichte":
		return _fichte(r)
	var stamm_mat: Material = rinde
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
		"birke":
			hoehe = 8.0
			stamm_r = 0.2
			breite = 2.2
			ballen = 9
			stamm_mat = _birkenrinde()
		"apfel":
			hoehe = 4.6
			stamm_r = 0.22
			breite = 2.8
			ballen = 8
		_:
			hoehe = 7.2
			stamm_r = 0.26
			breite = 2.6
			ballen = 7
	# Stamm: leicht kegelig, mit drei Wurzelanläufen
	_zyl(r, "Stamm", stamm_r * 1.25, stamm_r * 0.7, hoehe * 0.62, Vector3(0, hoehe * 0.31, 0), stamm_mat, Vector3.ZERO, 10)
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
			stamm_mat, Vector3(rad_to_deg(cos(a)) * 0.45, 0, -rad_to_deg(sin(a)) * 0.45), 6)
	# Blattballen: eine große Mitte, außen kleinere, unregelmäßig versetzt
	_kugel(r, "Krone", breite * 0.62, Vector3(0, krone_y + breite * 0.55, 0), laub, Vector3(1.0, 0.82, 1.0))
	for i in ballen:
		var a := TAU * i / float(ballen) + rng.randf_range(-0.2, 0.2)
		var rad := breite * rng.randf_range(0.42, 0.62)
		var y := krone_y + breite * rng.randf_range(0.18, 0.85)
		_kugel(r, "Ballen%d" % i, breite * rng.randf_range(0.3, 0.42), Vector3(sin(a) * rad, y, cos(a) * rad), laub,
			Vector3(1.0, rng.randf_range(0.75, 0.95), 1.0))
	match art:
		"apfel":
			# rote Äpfel außen an der Krone
			var apfel := StandardMaterial3D.new()
			apfel.albedo_color = Color(0.78, 0.12, 0.08)
			apfel.roughness = 0.5
			for i in 40:
				var a := rng.randf() * TAU
				var rad := breite * rng.randf_range(0.86, 0.98)
				_kugel(r, "Apfel%d" % i, 0.1, Vector3(sin(a) * rad, krone_y + breite * rng.randf_range(0.3, 0.8), cos(a) * rad), apfel, Vector3.ONE)
		"birke":
			# dunkle Rindenflecken rund um den Stamm
			var fleck := StandardMaterial3D.new()
			fleck.albedo_color = Color(0.12, 0.11, 0.1)
			for i in 40:
				var y := rng.randf_range(0.3, hoehe * 0.6)
				var sr := lerpf(stamm_r * 1.25, stamm_r * 0.7, y / (hoehe * 0.62))
				var a := rng.randf() * TAU
				var fl := MeshInstance3D.new()
				var b := BoxMesh.new()
				b.size = Vector3(rng.randf_range(0.06, 0.16), rng.randf_range(0.02, 0.05), 0.02)
				fl.mesh = b
				fl.material_override = fleck
				fl.transform = Transform3D(Basis(Vector3.UP, a), Vector3(sin(a) * sr, y, cos(a) * sr))
				fl.name = "Fleck%d" % i
				r.add_child(fl)
				fl.owner = r
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

func _birkenrinde() -> StandardMaterial3D:
	var b := StandardMaterial3D.new()
	b.albedo_color = Color(0.9, 0.88, 0.84)
	b.roughness = 0.85
	return b

## Fichte: brauner Stamm, sechs gestaffelte Nadelkegel, Spitze
func _fichte(r: Node3D) -> Node3D:
	var hoehe := 10.0
	_zyl(r, "Stamm", 0.3, 0.12, hoehe * 0.9, Vector3(0, hoehe * 0.45, 0), rinde, Vector3.ZERO, 8)
	var dunkel := laub.duplicate() as StandardMaterial3D
	dunkel.albedo_color = laub.albedo_color.darkened(0.25)
	for i in 6:
		var t := i / 5.0
		var breite := lerpf(2.6, 0.7, t)
		var y := lerpf(1.6, hoehe - 1.6, t)
		_zyl(r, "Ebene%d" % i, breite, 0.05, lerpf(2.6, 1.6, t), Vector3(0, y + 0.8, 0), laub if i % 2 == 0 else dunkel, Vector3(0, rng.randf() * 360.0, 0), 9)
	_zyl(r, "Spitze", 0.35, 0.0, 1.2, Vector3(0, hoehe + 0.2, 0), laub, Vector3.ZERO, 8)
	var koerper := StaticBody3D.new()
	koerper.name = "Kollision"
	r.add_child(koerper)
	koerper.owner = r
	var form := CylinderShape3D.new()
	form.radius = 0.3
	form.height = 3.0
	var cs := CollisionShape3D.new()
	cs.shape = form
	cs.position = Vector3(0, 1.5, 0)
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
