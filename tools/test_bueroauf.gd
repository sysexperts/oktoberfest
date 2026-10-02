extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft, wann das Festbüro offen ist: nach Feierabend und morgens bei geschlossenem
## Zelt ja, bei offenem Zelt nein. Prüft Hinweis am Schreibtisch und einen Kauf.
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_bueroauf.tscn   (mit Fenster)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _gab_es := {}

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		for pfad: String in DATEIEN:
			if FileAccess.file_exists(pfad + ".testbackup"):
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"), ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad + ".testbackup"))
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad), ProjectSettings.globalize_path(pfad + ".testbackup"))
		var ok := await _pruefen()
		_wiederherstellen()
		print("TEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
		get_tree().quit(0 if ok else 1)

	func _pruefen() -> bool:
		var gm := await Spielstart.starten(self, true, 2)
		if gm == null:
			return false
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = gm._players_nodes.get(1)
		var tisch: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is OfficeDesk:
				tisch = n
		print("Schreibtisch: ", tisch)
		var ok := tisch != null
		# [Phase, Zelt offen, erwartet offen]
		for fall in [[gm.Phase.INTERMISSION, true, true], [gm.Phase.SHIFT, false, true], [gm.Phase.SHIFT, true, false]]:
			gm._phase = fall[0]
			gm._zelt_offen = fall[1]
			var offen: bool = gm.buero_offen()
			var hinweis: String = sp._hint_for(tisch)
			print("Phase %d, Zelt offen %s -> Büro offen %s, Hinweis %s" % [fall[0], fall[1], offen, hinweis])
			ok = ok and offen == fall[2] and (hinweis == "HINT_OFFICE") == fall[2]
		# Kauf am Morgen (Zelt zu): muss durchgehen
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = false
		gm._tent_stage = 1
		Game.money = 5000
		var vorher: int = gm._active_count
		gm.net_buy_table.rpc_id(1)
		await get_tree().create_timer(0.5).timeout
		print("Tische vorher %d, nachher %d (Morgen, Zelt zu)" % [vorher, gm._active_count])
		ok = ok and gm._active_count == vorher + 1
		# Und bei offenem Zelt nicht
		gm._zelt_offen = true
		var davor: int = gm._active_count
		gm.net_buy_table.rpc_id(1)
		await get_tree().create_timer(0.5).timeout
		print("Tische bei offenem Zelt: %d -> %d" % [davor, gm._active_count])
		ok = ok and gm._active_count == davor
		return ok

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
