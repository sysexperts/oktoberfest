extends Node
## Screenshots für die Steam-Store-Seite (1920 × 1080): volles Zelt am Abend,
## Nahaufnahme am Tisch, Einrichtung, Blick über die Kirmes, Spielansicht mit HUD.
## Legt die Bilder in build/store/ ab (nicht im Git).
## Sichert Spielstände und Einstellungen vorher und stellt sie wieder her.
## Aufruf: godot --path . res://tools/render_store.tscn --resolution 1920x1080

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]
const ZIEL := "res://build/store/"

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".storebackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".storebackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".storebackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".storebackup"))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(ZIEL))
		Net.start_solo(true)
		for i in 3000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		await _frames(30)
		var gm := get_tree().current_scene
		Einstellungen.sprache = "de"
		Einstellungen.grafik = 2
		Einstellungen.anwenden()
		Game.add_money(20000)
		gm.net_book_tent.rpc_id(1)
		await _frames(3)
		for i in 4:
			gm.net_buy_table.rpc_id(1)
			await _frames(2)
		gm.net_order_goods.rpc_id(1, 1, 10)
		await _frames(3)
		for art: String in ["laterne", "lichterkette", "stehlampe", "busch", "blumen"]:
			gm.net_buy_einrichtung.rpc_id(1, art)
			await _frames(2)
		gm._stock[gm.WARE_BIER] = 200
		gm.set_process(false)

		# Einrichtung an die Zeltränder
		var orte := [Vector3(-10.5, 0, 6.5), Vector3(0, 0, -6.5), Vector3(10.5, 0, 6.5), Vector3(-10.5, 0, -6.5), Vector3(10.5, 0, -6.5)]
		var i := 0
		for did in gm._einrichtung.keys():
			(gm._einrichtung_nodes[did] as Node3D).position = orte[i % orte.size()]
			i += 1

		# Abend, Zelt voll: Schicht starten, alle Plätze füllen, Gäste hinsetzen
		gm._start_shift()
		gm._phase_time = gm.SHIFT_TIME * 0.2   # etwa 19:00
		for k in gm._seats.size():
			gm._spawn_guest()
		for schritt in 2400:
			gm._update_guests(0.05)
		gm._broadcast_sync()
		gm._net_env(Game.money, Game.score, gm._clock_hour(), 90.0, 70.0, PackedInt32Array(), PackedFloat32Array(), true)
		await _frames(20)

		var spieler: Node3D = gm.get_node("Players").get_child(0)
		spieler.set_physics_process(false)
		var kopf: Node3D = spieler.get_node("Head")
		var hud: CanvasLayer = gm.get_node("HUD")
		hud.visible = false

		await _bild(spieler, kopf, Vector3(0, 0, 10.5), 0.0, -8.0, "01_zelt_voll")
		await _bild(spieler, kopf, Vector3(-3.2, 0, 5.8), deg_to_rad(-25.0), -14.0, "02_am_tisch")
		await _bild(spieler, kopf, Vector3(6.0, 0, -3.0), deg_to_rad(120.0), -6.0, "03_einrichtung")
		await _bild(spieler, kopf, Vector3(4.0, 0, 30.0), deg_to_rad(20.0), 2.0, "04_kirmes")
		hud.visible = true
		await _bild(spieler, kopf, Vector3(0, 0, 8.0), 0.0, -10.0, "05_spielansicht")

		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".storebackup", echt)
				DirAccess.remove_absolute(echt + ".storebackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("RENDER FERTIG")
		get_tree().quit()

	func _bild(spieler: Node3D, kopf: Node3D, pos: Vector3, yaw: float, neigung: float, name: String) -> void:
		spieler.global_position = pos
		spieler.rotation.y = yaw
		kopf.rotation.x = deg_to_rad(neigung)
		await _frames(40)
		get_viewport().get_texture().get_image().save_png(ZIEL + name + ".png")
		print("  gespeichert: " + name)

	func _frames(n: int) -> void:
		for k in n:
			await get_tree().process_frame
