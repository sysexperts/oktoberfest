extends Node
## Fotografiert den Mietdialog (scenes/ui/zelt_mieten.tscn) im echten Spiel mit
## eingetipptem Zeltnamen. Sichert Spielstände und Einstellungen vorher.
## Aufruf: godot --path . res://tools/render_zelt_mieten.tscn --resolution 1280x720
## Bild: tools/zelt_mieten_dialog.png (nicht im Git)

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
			if FileAccess.file_exists(pfad + ".mietbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".mietbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".mietbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".mietbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("open_rent_ui"):
				break
			await get_tree().process_frame
		await _frames(40)
		var gm := get_tree().current_scene
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		spieler.global_position = Vector3(4.2, 0.0, 15.5)
		spieler.rotation.y = 0.0
		gm.open_rent_ui()
		var dialog := gm.get_node("HUD/ZeltMieten")
		(dialog.get_node("%Name") as LineEdit).text = "Zum Durstigen Hirsch"
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/zelt_mieten_dialog.png")
		print("  gespeichert: zelt_mieten_dialog")
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".mietbackup", echt)
				DirAccess.remove_absolute(echt + ".mietbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
