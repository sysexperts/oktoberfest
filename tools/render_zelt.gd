extends Node
## Fotografiert die Zeltausstattung im echten Spiel: Theke (Fässer, Krüge,
## Ausgabe mit Essen), Bühne, Kellner mit Tablett und einen Blick von oben.
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_zelt.tscn --resolution 1280x720
## Bilder: tools/zelt_*.png (nicht im Git)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}
	var gm: Node
	var spieler: Node3D

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".zeltbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".zeltbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".zeltbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".zeltbackup"))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		gm = get_tree().current_scene
		Game.add_money(50000)
		gm.net_book_tent.rpc_id(1)
		await _frames(3)
		gm._tent_stage = 4
		gm._active_count = 24
		gm._has_toilet = true
		gm._apply_tent()
		gm.set_process(false)
		spieler = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		gm.get_node("HUD").visible = false

		# Theke mit Fässern, Krugstapel, Ausgabe voller Krüge und Essen
		gm._ausgabe = {"1_1": 5, "1_2": 3, "1_4": 2, "2_1": 2, "2_2": 2, "2_3": 2}
		gm._ausgabe_senden()
		await _foto(Vector3(-2.5, 0.0, -6.2), 0.0, -18.0, "zelt_theke")
		await _foto(Vector3(-6.0, 0.0, -7.4), 20.0, -22.0, "zelt_fass")
		# Spieler hält einen halb gezapften Krug
		spieler.carry_state = 1
		spieler.carry_fill = 0.55
		spieler.carry_type = 1
		await _foto(Vector3(-2.5, 0.0, -6.2), 0.0, -18.0, "zelt_krug_hand")
		spieler.carry_state = 2
		spieler.carry_fill = 1.0
		spieler.carry_type = 3
		await _foto(Vector3(-2.5, 0.0, -6.2), 0.0, -18.0, "zelt_teller_hand")
		spieler.carry_state = 0

		# Kellner mit Tablett direkt vor der Kamera
		gm.net_hire_staff(2)
		await _frames(5)
		var kellner: Node3D = null
		for n in get_tree().get_nodes_in_group("staff"):
			kellner = n
		if kellner:
			kellner.set_process(false)
			kellner.global_position = Vector3(0.0, 0.1, 2.0)
			kellner.rotation.y = PI
			kellner.set_carrying(7)
			await _foto(Vector3(0.0, 0.0, 4.2), 0.0, -12.0, "zelt_kellner")

		# Bühne mit Künstlern
		gm._artist_tier = 3
		gm._spawn_artists()
		await _foto(Vector3(1.5, 0.0, 2.0), -90.0, -8.0, "zelt_buehne")
		# Übersicht von oben
		spieler.global_position = Vector3(0.0, 22.0, 0.0)
		spieler.rotation.y = 0.0
		spieler.get_node("Head").rotation.x = deg_to_rad(-89.0)
		await _frames(60)
		get_viewport().get_texture().get_image().save_png("res://tools/zelt_oben.png")
		print("  gespeichert: zelt_oben")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".zeltbackup", echt)
				DirAccess.remove_absolute(echt + ".zeltbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _foto(pos: Vector3, yaw_grad: float, pitch_grad: float, datei: String) -> void:
		spieler.global_position = pos
		spieler.rotation.y = deg_to_rad(yaw_grad)
		spieler.get_node("Head").rotation.x = deg_to_rad(pitch_grad)
		spieler._update_carry_visual()
		await _frames(45)
		get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % datei)
		print("  gespeichert: ", datei)

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
