extends Node
## Einzelbilder von Katalogteilen (Baumodus) auf leerer Wiese → SHOT_DIR/kat_<name>.png
## Godot --path . res://tools/shot_katalog.tscn -- res://pfad1.tscn res://pfad2.tscn …

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 30:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var karte = gm.get_node("Kirmes/Karte")
		karte.net_ersetzen("{\"eintraege\": []}")
		var kamera := Camera3D.new()
		kamera.fov = 45.0
		gm.add_child(kamera)
		kamera.current = true
		var ort := Vector3(38, 0, -42)
		for pfad: String in OS.get_cmdline_user_args():
			karte.net_ersetzen("{\"eintraege\": []}")
			karte.net_setzen(pfad, ort, 0.0)
			await get_tree().process_frame
			var k: Node3D = karte.get_child(karte.get_child_count() - 1)
			var box := AABB(ort, Vector3.ZERO)
			for mi in k.find_children("*", "GeometryInstance3D", true, false):
				box = box.merge((mi as VisualInstance3D).global_transform * (mi as VisualInstance3D).get_aabb())
			var groesse := maxf(box.size.length(), 2.0) * float(OS.get_environment("ZOOM") if OS.has_environment("ZOOM") else "1.0")
			var mitte := box.get_center()
			kamera.global_position = mitte + Vector3(groesse * 0.45, groesse * 0.3, groesse * 0.75)
			kamera.look_at(mitte)
			for i in 12:
				await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/kat_%s.png" % pfad.get_file().get_basename())
		get_tree().quit()
