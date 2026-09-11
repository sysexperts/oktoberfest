extends Node
## Himmel, Tageslicht und Regen von draußen: Mittag, Dämmerung, nach
## Feierabend und Regen. Prüft Wolken-Himmel, weiche Dämmerung und Regentropfen.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_himmel.tscn --resolution 1280x720

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".himmelbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".himmelbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".himmelbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".himmelbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		spieler.global_position = Vector3(-10.0, 0.0, 30.0)
		spieler.rotation.y = deg_to_rad(-20.0)
		spieler.get_node("Head").rotation.x = deg_to_rad(12.0)

		await _bild(gm, 12.0, false, "", "himmel_mittag")
		await _bild(gm, 19.0, false, "", "himmel_daemmerung")
		await _bild(gm, -1.0, true, "", "himmel_nach_feierabend")
		await _bild(gm, 12.0, false, "regen", "himmel_regen")
		# Im Zelt bei Dämmerung — soll nicht schlagartig hell werden
		spieler.global_position = Vector3(0.0, 0.0, 6.0)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-5.0)
		await _bild(gm, 18.5, false, "", "zelt_18_30")
		await _bild(gm, 19.5, false, "", "zelt_19_30")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".himmelbackup", echt)
				DirAccess.remove_absolute(echt + ".himmelbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _bild(gm: Node, uhr: float, geschlossen: bool, ereignis: String, name: String) -> void:
		gm._ereignis = ereignis
		gm._nachts_geschlossen = geschlossen
		gm._regen_anzeigen()
		gm._night_t = -1.0
		gm._apply_daylight(uhr)
		gm._apply_crowd(uhr)
		await _frames(50)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: " + name)

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
