extends Node
## Wohnwagenplatz ansehen (Standardkarte): Übersicht und Nahansicht → SHOT_DIR/ww_*.png

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var kamera := Camera3D.new()
		kamera.fov = 55.0
		gm.add_child(kamera)
		kamera.current = true
		var ansichten := {
			"ww_platz": [Vector3(-6, 9, -30), Vector3(-7, 0, -48)],
			"ww_nah": [Vector3(1.5, 2.2, -41.5), Vector3(-2.5, 1.2, -48)],
			"ww_heck": [Vector3(-8, 2.0, -55), Vector3(-5.5, 1.2, -48)],
			"ww_oben": [Vector3(-7, 30, -47.9), Vector3(-7, 0, -48)],
		}
		for k in ansichten:
			kamera.global_position = ansichten[k][0]
			kamera.look_at(ansichten[k][1])
			for i in 12:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/%s.png" % k)
		get_tree().quit()
