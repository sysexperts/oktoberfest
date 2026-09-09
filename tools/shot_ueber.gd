extends SceneTree
## Überblick über den ganzen Platz — vier Ansichten als PNG.
func _init() -> void:
	root.call_deferred("add_child", (load("res://scenes/main.tscn") as PackedScene).instantiate())
	_los()
func _los() -> void:
	for i in 25:
		await process_frame
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.current = true
	cam.fov = 70.0
	var views := {
		"nord": [Vector3(0, 34, 62), Vector3(0, 2, 8)],
		"sued": [Vector3(0, 34, -62), Vector3(0, 2, -8)],
		"biergarten": [Vector3(-30, 7, 34), Vector3(-30, 2, 20)],
		"weg": [Vector3(0, 4, 33), Vector3(0, 3, 12)],
	}
	for k in views:
		cam.look_at_from_position(views[k][0], views[k][1], Vector3.UP)
		for i in 6:
			await process_frame
		root.get_texture().get_image().save_png("res://tools/ueb_%s.png" % k)
	print("Bilder gespeichert")
	quit()
