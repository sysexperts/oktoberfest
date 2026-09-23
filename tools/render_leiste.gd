extends Node
## Bilder von der Leiste oben links und der Aufgabenkarte, in drei Lagen:
## draußen am Abend, im Zelt (heller Hintergrund hinter dem Milchglas) und
## morgens mit Minus auf dem Konto. Damit lässt sich das Aussehen beurteilen,
## ohne selbst durchs Spiel zu laufen.
## Aufruf: godot --path . res://tools/render_leiste.tscn --resolution 1280x720

const DATEIEN := ["user://oktoberfest_save.json", "user://saves/slot_1.json", "user://saves/slot_2.json",
	"user://saves/slot_3.json", "user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".renderbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".renderbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".renderbackup"))
		Einstellungen.sprache = "de"
		Einstellungen.anwenden()
		Net.start_solo(true)
		for i in 6000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(60)
		var gm := get_tree().current_scene
		var hud: HUD = gm.get_node("HUD")
		gm.net_book_tent.rpc_id(1)
		gm.net_buy_table.rpc_id(1)
		await _frames(10)

		# 1 Abend im Betrieb, draußen
		hud.set_money(4280)
		hud.set_day(3)
		hud.set_time(18.5)
		hud.set_stock(34, 12)
		hud.set_hygiene(62.0)
		hud.set_popularity(78.0)
		hud.melde("MSG_EVENING")
		await _bild("leiste_abend")

		# 2 Im Zelt: helle Wand hinter dem Milchglas
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.global_position = Vector3(0.0, spieler.global_position.y, 6.0)
		spieler.rotation.y = PI
		await _frames(20)
		hud.set_money(4280)
		hud.set_time(18.5)
		hud.set_stock(34, 12)
		hud.set_hygiene(62.0)
		hud.set_popularity(78.0)
		await _bild("leiste_zelt")

		# 3 Morgens, Zelt noch zu, Konto im Minus, Lager leer
		hud.set_money(-350)
		hud.set_day(1)
		hud.set_time(-1.0)
		hud.set_stock(0, 0)
		hud.set_hygiene(100.0)
		hud.set_popularity(20.0)
		await _bild("leiste_morgen")

		for pfad: String in DATEIEN:
			var sich := ProjectSettings.globalize_path(pfad + ".renderbackup")
			if _gab_es[pfad] and FileAccess.file_exists(pfad + ".renderbackup"):
				DirAccess.copy_absolute(sich, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(sich)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad))
		get_tree().quit()

	func _bild(name: String) -> void:
		await _frames(8)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
		print("  gespeichert: ", name)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
