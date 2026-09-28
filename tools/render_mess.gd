extends Node3D
## Vorschau Erbrochenes/Urin. Aufruf: godot --path . res://tools/render_mess.tscn

func _ready() -> void:
	var boden := MeshInstance3D.new()
	var pm := PlaneMesh.new(); pm.size = Vector2(8, 8)
	var bm := StandardMaterial3D.new(); bm.albedo_color = Color(0.45, 0.32, 0.2)
	pm.material = bm; boden.mesh = pm; add_child(boden)
	for i in 2:
		var m: Node3D = load("res://scenes/mess.tscn").instantiate()
		m.kind = i; m.mess_id = 0
		m.position = Vector3(-0.9 + i * 1.8, 0, 0)
		add_child(m)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-55, 30, 0); add_child(l)
	var c := Camera3D.new(); c.position = Vector3(0, 1.6, 1.9); add_child(c); c.look_at(Vector3.ZERO)
	for f in 10: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(OS.get_environment("VORSCHAU"))
	get_tree().quit()
