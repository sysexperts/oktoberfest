extends Node3D
## Fotografiert Konrads Zelt von innen (build/huber_zelt.png).
##   godot --path . res://tools/render_huber_zelt.tscn --resolution 1280x720
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.62, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.9)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-50, 25, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(60, 60)
	boden.mesh = ebene
	add_child(boden)
	var zelt := (load("res://scenes/huber_zelt.tscn") as PackedScene).instantiate()
	add_child(zelt)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0.5, 1.7, 5.5), Vector3(-0.5, 1.0, -4.0))
	await get_tree().create_timer(3.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/huber_zelt.png")
	print("RENDER FERTIG")
	get_tree().quit()
