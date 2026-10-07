extends Node3D
## Fotografiert das Feuerwerk (build/feuerwerk.png).
##   godot --path . res://tools/render_feuerwerk.tscn --resolution 1280x720
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.02, 0.03, 0.09)
	add_child(env)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0, 2, 20), Vector3(0, 20, 0))
	var fw: Node3D = (load("res://scenes/effekte/feuerwerk.tscn") as PackedScene).instantiate()
	add_child(fw)
	fw.ausloesen(14, 0.12)
	await get_tree().create_timer(1.6).timeout
	get_viewport().get_texture().get_image().save_png("res://build/feuerwerk.png")
	print("RENDER FERTIG")
	get_tree().quit()
