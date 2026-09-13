extends Node
## Fotografiert die Schicht-Einführung (scenes/ui/schicht_intro.tscn) im echten
## Spiel, einmal ohne und einmal mit hervorgehobener Abteilung (Service).
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_intro.tscn --resolution 1280x720
## Bilder: tools/intro_solo.png, tools/intro_service.png (nicht im Git)

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
			if FileAccess.file_exists(pfad + ".introbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".introbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".introbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".introbackup"))
		TranslationServer.set_locale("de")
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("open_lobby_ui"):
				break
			await get_tree().process_frame
		await _frames(40)
		var gm := get_tree().current_scene
		var intro := gm.get_node("HUD/SchichtIntro")
		intro.zeigen()
		await _frames(40)
		get_viewport().get_texture().get_image().save_png("res://tools/intro_solo.png")
		print("  gespeichert: intro_solo")
		# Mit Abteilung: so sieht es ein Service-Teamleiter im Koop-Spiel
		Net.solo = false
		gm._spieler_info = {multiplayer.get_unique_id(): {"name": "Sepp", "farbe": 0, "abteilung": "service", "figur": 0}}
		intro._texte()
		await _frames(10)
		get_viewport().get_texture().get_image().save_png("res://tools/intro_service.png")
		print("  gespeichert: intro_service")
		Net.solo = true
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".introbackup", echt)
				DirAccess.remove_absolute(echt + ".introbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
