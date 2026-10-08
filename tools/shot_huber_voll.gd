extends Node3D
## Foto von Konrads Zelt innen (build/huber_voll.png): godot --path . res://tools/shot_huber_voll.tscn
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	add_child(env)
	var z: Node3D = (load("res://scenes/huber_zelt.tscn") as PackedScene).instantiate()
	add_child(z)
	var k := Camera3D.new()
	add_child(k)
	k.current = true
	k.look_at_from_position(Vector3(0, 6.5, 9.0), Vector3(0, 0.8, -3.0))
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("res://build/huber_voll.png")
	get_tree().quit()
