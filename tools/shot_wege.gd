extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Draufsicht auf Platzwege und Straßen → SHOT_DIR/w_oben.png

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		cam.projection = Camera3D.PROJECTION_ORTHOGONAL
		cam.size = 200.0
		cam.far = 500.0
		cam.global_position = Vector3(0, 150, -8)
		cam.rotation = Vector3(-PI / 2, 0, 0)
		for i in 10:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/w_oben.png")
		get_tree().quit()
