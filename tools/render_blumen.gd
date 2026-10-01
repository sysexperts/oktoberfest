extends Node3D
## Fotografiert die Blumenmodelle der Kirmes (Poppies, Poppies_A, Poppies_B) aus der Nähe.
##   godot --path . res://tools/render_blumen.tscn --resolution 640x480
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.55, 0.3)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sonne)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	for n in ["Poppies", "Poppies_A", "Poppies_B"]:
		var m := (load("res://assets/kirmes/Models/Foliage/%s.fbx" % n) as PackedScene).instantiate()
		add_child(m)
		kamera.look_at_from_position(Vector3(0, 1.2, 2.2), Vector3(0, 0.3, 0))
		for i in 4:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://tools/blume_%s.png" % n)
		m.queue_free()
		await get_tree().process_frame
	print("RENDER FERTIG")
	get_tree().quit()
