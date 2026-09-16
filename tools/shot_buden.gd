extends Node
## Bilder der Minispiel-Buden von außen (Vorderseite), auf Deutsch.
## Godot --path . res://tools/shot_buden.tscn   (SHOT_DIR = Zielordner)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var ARTEN: Array = ["ringwurf", "entenangeln", "gluecksrad", "stemmen", "nagelbalken", "kegeln"]

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var eigen: Node3D = gm.get_node("Players").get_child(0)
		eigen.visible = false
		var kamera := Camera3D.new()
		kamera.fov = 48.0
		gm.add_child(kamera)
		kamera.current = true
		if not OS.get_cmdline_user_args().is_empty():
			ARTEN = OS.get_cmdline_user_args()
		for art: String in ARTEN:
			var bude: Node3D = null
			for s in get_tree().get_nodes_in_group("kirmes_spiel"):
				if s.get_script() and String(s.get_script().resource_path).get_file().get_basename() == art:
					bude = s as Node3D
					break
			if bude == null:
				for n in gm.get_node("Kirmes").find_children(art.capitalize() + "*", "Node3D", true, false):
					bude = n as Node3D
					break
			if bude == null:
				print("FEHLT ", art)
				continue
			var vorn := bude.global_basis.z.normalized()
			var rechts := bude.global_basis.x.normalized()
			kamera.global_position = bude.global_position + vorn * 11.0 + rechts * 3.0 + Vector3(0, 5.5, 0)
			kamera.look_at(bude.global_position + vorn * 0.3 + Vector3(0, 1.5, 0))
			for i in 12:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/bude_%s.png" % art)
		print("BUDEN FERTIG")
		get_tree().quit()
