extends Node
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert die Punkte der Gefallen-Varianten nebeneinander, vorher und nachher (SHOT_DIR/gefallen_punkte.png).
##   SHOT_DIR=build godot --path . res://tools/shot_punkte.tscn --resolution 1280x720

const PUNKT := preload("res://scenes/gefallen/punkt.tscn")
const VARIANTEN := ["fahne", "laterne", "ballon", "pfuetze", "noten"]

func _ready() -> void:
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(30, 12)
	boden.mesh = ebene
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 0.25)
	boden.material_override = mat
	add_child(boden)
	var umgebung := WorldEnvironment.new()
	umgebung.environment = Environment.new()
	umgebung.environment.background_mode = Environment.BG_COLOR
	umgebung.environment.background_color = Color(0.55, 0.7, 0.9)
	umgebung.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	umgebung.environment.ambient_light_color = Color(0.6, 0.6, 0.65)
	add_child(umgebung)
	for i in VARIANTEN.size():
		for reihe in 2:
			var p := PUNKT.instantiate() as Node3D
			p.set("variante", VARIANTEN[i])
			add_child(p)
			p.position = Vector3((i - 2) * 2.2, 0, reihe * -3.0)
			if reihe == 1:
				p.call("erledigt_setzen")
	var kam := Camera3D.new()
	add_child(kam)
	kam.look_at_from_position(Vector3(0, 3.2, 6.5), Vector3(0, 1.0, -1.5))
	kam.make_current()
	for _i in 30:
		await get_tree().process_frame
	Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/gefallen_punkte.png")
	get_tree().quit()
