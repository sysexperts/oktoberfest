extends Node3D
## Fotografiert eine Fußspur (Mess, Art Mess.FUSS) allein auf einem braunen Boden:
## ein Bild im Ruhezustand und eins halb weggewischt. Bilder: tools/fussspur_1.png, _2.png
##   godot --path . res://tools/render_fussspur.tscn --resolution 960x540
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.4, 0.5, 0.6)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(8, 8)
	boden.mesh = platte
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.25, 0.12)
	boden.material_override = mat
	add_child(boden)
	var spur: Mess = (load("res://scenes/mess.tscn") as PackedScene).instantiate()
	spur.mess_id = 3
	add_child(spur)
	spur.set_kind(Mess.FUSS)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0.6, 2.2, 1.6), Vector3(0, 0, 0))
	for i in 5:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/fussspur_1.png")
	spur.apply_progress(0.6)
	for i in 3:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/fussspur_2.png")
	print("RENDER FERTIG")
	get_tree().quit()
