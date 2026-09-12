extends Node
## Zeigt alle kaufbaren Einrichtungsgegenstände nebeneinander im echten Zelt —
## prüft Größe, Licht und ob die Modelle am Boden stehen.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_einrichtung.tscn --resolution 1280x720

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
			if FileAccess.file_exists(pfad + ".einrbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".einrbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".einrbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".einrbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		var gm := get_tree().current_scene
		Game.add_money(10000)
		gm.net_book_tent.rpc_id(1)
		await _frames(3)
		gm.net_order_goods.rpc_id(1, 1, 1)   # sonst sperrt die Warenreserve
		await _frames(3)
		var arten: Array = gm.Katalog.ARTEN.keys()
		for art: String in arten:
			gm.net_buy_einrichtung.rpc_id(1, art)
			await _frames(3)
		print("  gekauft: %d von %d" % [gm._einrichtung.size(), arten.size()])
		gm.set_process(false)
		# Boden- und Deckendeko in einer Reihe quer durchs Zelt, Wanddeko an der Westwand
		var i := 0
		var j := 0
		for did in gm._einrichtung.keys():
			var art := str(gm._einrichtung[did].art)
			var p := Vector3(-8.0 + i * 1.8, 0.0, 1.6)
			if gm.Katalog.platz(art) == "wand":
				p = Vector3(-11.0, 0.0, -4.0 + j * 2.6)
				j += 1
			else:
				i += 1
			var lage: Dictionary = gm._deko_platz(art, p.x, p.z, 0.0)
			gm._einrichtung[did].x = lage.x
			gm._einrichtung[did].z = lage.z
			gm._einrichtung[did].rot = lage.rot
			gm._set_einrichtung(did, lage.x, lage.z, lage.rot)
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		spieler.global_position = Vector3(0.0, 0.0, 10.0)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-4.0)
		gm.get_node("HUD").visible = false
		await _frames(90)
		get_viewport().get_texture().get_image().save_png("res://tools/einrichtung_zelt.png")
		print("  gespeichert: einrichtung_zelt")
		# Blick auf die Westwand mit der Wanddeko
		spieler.global_position = Vector3(-5.5, 0.0, 0.0)
		spieler.rotation.y = PI / 2.0
		spieler.get_node("Head").rotation.x = deg_to_rad(12.0)
		await _frames(40)
		get_viewport().get_texture().get_image().save_png("res://tools/einrichtung_wand.png")
		print("  gespeichert: einrichtung_wand")
		# Nahaufnahme der Theke mit Ausgabe, darauf ein paar fertige Krüge und Essen
		gm._ausgabe = {"1_1": 4, "1_2": 2, "2_1": 2}
		gm._ausgabe_senden()
		spieler.global_position = Vector3(-1.0, 0.0, -5.2)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-14.0)
		await _frames(40)
		get_viewport().get_texture().get_image().save_png("res://tools/theke_nah.png")
		print("  gespeichert: theke_nah")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".einrbackup", echt)
				DirAccess.remove_absolute(echt + ".einrbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
