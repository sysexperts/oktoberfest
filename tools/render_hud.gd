extends Node
## Startet ein Solo-Spiel und rendert das HUD in allen drei Sprachen, dazu
## das Hinweisfenster. Sichert Spielstand und Einstellungen vorher und stellt
## beide am Ende wieder her.
## Aufruf: godot --path . res://tools/render_hud.tscn --resolution 1280x720

const DATEIEN := ["user://oktoberfest_save.json", "user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".renderbackup"))
		Net.start_solo(true)
		await _frames(60)
		var gm := get_tree().current_scene
		var hud: HUD = gm.get_node("HUD")
		hud.set_money(-350)
		hud.set_popularity(62.0)
		hud.set_hygiene(34.0)
		hud.set_stock(12, 0)
		hud.set_day(3)
		hud.set_time(19.5, true)
		for lang in ["de", "en", "tr"]:
			Einstellungen.sprache = lang
			Einstellungen.anwenden()
			hud.set_quest(5, 11)
			await _bild("hud_%s" % lang)
		hud.set_time(-1.0)
		hud.show_popup("📦 Erst Ware einkaufen!\n\nDu hast kein Bier im Lager.")
		await _bild("hud_popup")
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".renderbackup", echt)
				DirAccess.remove_absolute(echt + ".renderbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _bild(name: String) -> void:
		await _frames(6)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)
