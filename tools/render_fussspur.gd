extends Node3D
## Fotografiert Fußspuren-Stücke (Mess, Art Mess.FUSS + Richtung) von oben, damit man die
## Laufrichtung prüfen kann: Pfeil-Beschriftung = gewollte Richtung, Kamera schaut nach
## unten, Bildoben = -Z, Bildrechts = +X. Bild: tools/fussspur_richtung.png
##   godot --path . res://tools/render_fussspur.tscn --resolution 960x540
const RICHTUNGEN := {"+Z": 0, "+X": 9, "-Z": 18, "-X": 27}
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.4, 0.5, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(14, 14)
	boden.mesh = platte
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.55, 0.4)
	boden.material_override = mat
	add_child(boden)
	var i := 0
	for name_ in RICHTUNGEN:
		var spur: Mess = (load("res://scenes/mess.tscn") as PackedScene).instantiate()
		spur.mess_id = 3 + i
		spur.position = Vector3(-4.5 + 3.0 * i, 0.0, 0.0)
		add_child(spur)
		spur.set_kind(Mess.FUSS + int(RICHTUNGEN[name_]))
		var l := Label3D.new()
		l.text = name_
		l.font_size = 120
		l.pixel_size = 0.01
		l.rotation_degrees = Vector3(-90, 0, 0)
		l.position = Vector3(-4.5 + 3.0 * i, 0.2, 2.4)
		l.modulate = Color(0, 0, 0)
		add_child(l)
		i += 1
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0, 9, 0.01), Vector3(0, 0, 0), Vector3(0, 0, -1))
	for k in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/fussspur_richtung.png")
	print("RENDER FERTIG")
	get_tree().quit()
