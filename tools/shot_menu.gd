extends SceneTree
func _init() -> void:
	root.call_deferred("add_child", (load("res://scenes/menu.tscn") as PackedScene).instantiate())
	_los()
func _los() -> void:
	for i in 15:
		await process_frame
	root.get_texture().get_image().save_png("res://tools/menu_shot.png")
	print("Bild gespeichert")
	quit()
