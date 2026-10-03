extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Zelt- und Außenklang beim Hinausgehen: Lautstärken von Zeltmusik (Bus ZeltMusik),
## Menümusik draußen und Stimmengewirr in verschiedenen Abständen zur Zeltwand.
##   godot --path . res://tools/test_zeltklang.tscn   (mit Fenster)
const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json", "user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _gab_es := {}
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".testbackup"))
		var ok := await _pruefen()
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("TEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
		get_tree().quit(0 if ok else 1)
	func _pruefen() -> bool:
		var gm = await Spielstart.starten(self, true, 2)
		if gm == null:
			return false
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sfx = gm.get_node("Sfx")
		var sp: Node3D = gm._players_nodes.get(1)
		var bus := AudioServer.get_bus_index("ZeltMusik")
		print("Bus ZeltMusik vorhanden: ", bus >= 0)
		var werte := {}
		for x in [0.0, 12.4, 14.4, 17.0, 21.0, 40.0]:
			sp.global_position = Vector3(x, 0.1, -2.0)
			sfx._zelt_db = 0.0 if x == 0.0 else sfx._zelt_db
			for i in 240:
				await get_tree().process_frame
			werte[x] = [AudioServer.get_bus_volume_db(bus), sfx._draussen_player.volume_db, sfx._crowd_player.volume_db]
			print("x=%5.1f  Abstand %4.1f m  Zeltmusik %6.1f dB  Menümusik %6.1f dB  Gewirr %6.1f dB" % [x, sfx._abstand_zum_zelt(sp.global_position + Vector3(0, 1.6, 0)), werte[x][0], werte[x][1], werte[x][2]])
		var innen: Array = werte[0.0]
		var nah: Array = werte[14.4]
		var fern: Array = werte[40.0]
		return bus >= 0 and innen[0] > -3.0 and innen[1] < -50.0 and nah[0] < -25.0 and fern[0] < -60.0 and fern[1] > -30.0
