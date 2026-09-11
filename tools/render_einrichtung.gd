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
		# In einer Reihe quer durchs Zelt, die Lichterkette in die Mitte
		var i := 0
		for did in gm._einrichtung.keys():
			var n: Node3D = gm._einrichtung_nodes[did]
			n.position = Vector3(-8.0 + i * 4.0, 0.0, 2.0)
			i += 1
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		spieler.global_position = Vector3(0.0, 0.0, 10.0)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-4.0)
		gm.get_node("HUD").visible = false
		await _frames(90)
		get_viewport().get_texture().get_image().save_png("res://tools/einrichtung_zelt.png")
		print("  gespeichert: einrichtung_zelt")

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
