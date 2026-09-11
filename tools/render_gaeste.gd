extends Node
## Zeigt die NPC-Figuren im echten Zelt: Gäste beider Figuren sitzen an einem
## Tisch, Personal steht daneben, Blick aus Spielersicht. Prüft, ob Sitzhöhe,
## Krug in der Hand und Namensschilder zu jeder Figur passen.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_gaeste.tscn --resolution 1280x720

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const Figuren := preload("res://scripts/figuren.gd")

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".gaestebackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".gaestebackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".gaestebackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".gaestebackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		var gm := get_tree().current_scene
		gm.net_book_tent.rpc_id(1)
		gm.net_buy_table.rpc_id(1)
		await _frames(5)
		gm.set_process(false)   # keine echten Gäste und keine Tageszeit dazwischen

		# Die sechs Plätze des ersten Tisches, abwechselnd beide Figuren
		var plaetze: Array = gm._seats.filter(func(s: Dictionary) -> bool: return int(s.table) == 0)
		var ids := _ids_je_figur()
		for i in plaetze.size():
			var platz: Dictionary = plaetze[i]
			var gast: Node3D = gm.CUSTOMER_SCENE.instantiate()
			gast.cust_id = ids[i % ids.size()] + i * Figuren.ALLE.size()
			gast.position = platz.pos
			gast.rotation.y = float(platz.yaw)
			gm.get_node("Customers").add_child(gast)
			gast.set_net(platz.pos, float(platz.yaw))
			gast.set_order(1 if i % 2 == 0 else 2, 1, 1, 1.0)

		# Personal beider Figuren neben dem Tisch, einer trägt Krüge
		var tisch: Node3D = gm._beertables[0]
		for j in Figuren.ALLE.size():
			var kellner: Node3D = gm.STAFF_SCENE.instantiate()
			var sid := 0
			while Figuren.fuer_id(sid + 1000) != Figuren.ALLE[j]:
				sid += 1
			kellner.staff_id = sid
			var pos := tisch.global_position + Vector3(-1.2 + j * 2.4, 0.0, 2.2)
			kellner.position = pos
			gm.get_node("Customers").add_child(kellner)
			kellner.set_net(pos, 0.0)
			kellner.set_info(2, 3)
			kellner.set_carrying(3 if j == 0 else 1)

		# Spieler vor den Tisch stellen, Blick auf die Gäste
		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		spieler.global_position = tisch.global_position + Vector3(0.0, 0.0, 4.6)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-12.0)
		gm.get_node("HUD").visible = false
		await _frames(90)
		get_viewport().get_texture().get_image().save_png("res://tools/gaeste_tisch.png")
		print("  gespeichert: gaeste_tisch")
		# Näher ran
		spieler.global_position = tisch.global_position + Vector3(0.6, 0.0, 2.6)
		spieler.rotation.y = deg_to_rad(15.0)
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/gaeste_nah.png")
		print("  gespeichert: gaeste_nah")
		# Von der anderen Tischseite — dort sieht man die andere Bankreihe von vorn
		spieler.global_position = tisch.global_position + Vector3(-0.4, 0.0, -2.8)
		spieler.rotation.y = PI
		await _frames(30)
		get_viewport().get_texture().get_image().save_png("res://tools/gaeste_gegenueber.png")
		print("  gespeichert: gaeste_gegenueber")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".gaestebackup", echt)
				DirAccess.remove_absolute(echt + ".gaestebackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	## Eine ID je Figur, damit am Tisch jede Figur vorkommt.
	func _ids_je_figur() -> Array:
		var ids := []
		for szene in Figuren.ALLE:
			var id := 0
			while Figuren.fuer_id(id) != szene:
				id += 1
			ids.append(id)
		return ids

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame
