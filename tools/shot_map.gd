extends SceneTree
## Yardımcı araç: main.tscn'i gerçekten render eder — dönme dolabına bakan bir
## kamerayla. Prefab tek başına doğru görünüyordu, oyunda görünmüyordu; fark
## burada ortaya çıkmalı.
## Kullanım: godot --path . --script res://tools/shot_map.gd

func _init() -> void:
	root.call_deferred("add_child", (load("res://scenes/main.tscn") as PackedScene).instantiate())
	_los()

func _los() -> void:
	for i in 20:
		await process_frame
	# Riesenrad steht bei (43, -2, -11), Skalierung 2
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.look_at_from_position(Vector3(14, 12, -11), Vector3(43, 14, -11), Vector3.UP)
	cam.current = true
	for i in 10:
		await process_frame
	root.get_texture().get_image().save_png("res://tools/map_shot.png")
	print("Bild gespeichert")
	quit()
