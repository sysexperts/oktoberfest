extends Node3D
## Fotografiert den Wohnwagen mit dem Laptop davor (build/wohnwagen_innen.png).
##   godot --path . res://tools/render_wohnwagen.tscn --resolution 1280x720
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.62, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.9)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-45, 25, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(30, 30)
	boden.mesh = ebene
	add_child(boden)
	var wagen := (load("res://scenes/wohnwagen_innen.tscn") as PackedScene).instantiate()
	add_child(wagen)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(-2.2, 2.0, 2.2), Vector3(1.2, 0.7, -1.0))
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/wohnwagen_innen.png")
	print("RENDER FERTIG")
	get_tree().quit()
