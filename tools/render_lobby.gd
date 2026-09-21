extends Node
## Fotografiert die Lobby (scenes/ui/lobby.tscn) im echten Spiel, mit zwei
## erfundenen Mitspielern.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_lobby.tscn --resolution 1280x720
## Bild: tools/lobby.png (nicht im Git)

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
			if FileAccess.file_exists(pfad + ".lobbybackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".lobbybackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".lobbybackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".lobbybackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("open_lobby_ui"):
				break
			await get_tree().process_frame
		await _frames(40)
		var gm := get_tree().current_scene
		gm._spieler_info = {
			7: {"name": "Anna", "farbe": 2, "figur": 1},
			9: {"name": "Toni", "farbe": 4, "figur": 2},
		}
		gm.open_lobby_ui()
		var lobby := gm.get_node("HUD/Lobby")
		(lobby.get_node("%Name") as LineEdit).text = "Wiesn-Sepp"
		lobby._farbe_waehlen(0)
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/lobby.png")
		print("  gespeichert: lobby")
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".lobbybackup", echt)
				DirAccess.remove_absolute(echt + ".lobbybackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
