extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Festbüro von innen fotografieren → SHOT_DIR/buero_*.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		for i in 40:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var hut := gm.get_node("Kirmes/Festbuero") as Node3D
		var cam := Camera3D.new()
		cam.fov = 80
		gm.add_child(cam)
		var ans := [[Vector3(0, 1.7, -3.2), Vector3(0, 1.1, 3.0)], [Vector3(3.5, 1.8, 2.8), Vector3(-3, 1.0, -1.5)], [Vector3(-3.5, 1.8, 2.5), Vector3(3.5, 1.0, -1.5)]]
		for i in ans.size():
			cam.global_position = hut.to_global(ans[i][0])
			cam.look_at(hut.to_global(ans[i][1]), Vector3.UP)
			cam.current = true
			for f in 15:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/buero_%d.png" % i)
		get_tree().quit()
