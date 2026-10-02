extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft das Verschieben von Tischen und Regalen morgens (Schicht läuft, Zelt noch zu):
## E am Tisch bzw. Regal nimmt es auf, E noch einmal stellt es ab — das Regal bleibt dabei
## vor dem Spieler (in Weltkoordinaten) und landet im Zelt. Auch mit E ins Leere lässt es sich
## loslassen. Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_verschieben.tscn   (mit Fenster)

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
		# Echter Ablauf: Zelt mieten, Tische kaufen, schlafen — dann ist es Morgen bei noch zugem Zelt
		Game.money = 5000
		gm.net_book_tent.rpc_id(1, "Testzelt")
		await _frames(10)
		gm.net_buy_table.rpc_id(1)
		await _frames(10)
		gm.net_buy_table.rpc_id(1)
		await _frames(10)
		print("vor dem Schlafen: Phase ", gm._phase, " Zelt-Stufe ", gm._tent_stage, " Tische aktiv ", gm._active_count)
		gm.net_sleep.rpc_id(1)
		await _frames(60)
		print("Morgen: Phase ", gm._phase, " Zelt offen ", gm._zelt_offen, " Büro offen ", gm.buero_offen())
		print("Büro offen: ", gm.buero_offen(), " · Tische: ", gm._beertables.size(), " aktiv ", gm._active_count)
		var ok := true
		# --- Tisch
		var tisch: Node3D = gm._beertables[0]
		sp.global_position = tisch.global_position + Vector3(0, 0.1, 2.0)
		sp.look_at(tisch.global_position + Vector3(0, 0.8, 0))
		sp.rotation.x = 0
		await _frames(30)
		print("Ziel (Tisch): ", sp._current_target, " Hinweis: ", sp._hint_for(sp._current_target) if sp._current_target else "-")
		await _e()
		await _frames(10)
		var tisch_getragen: bool = gm._held.has(1)
		print("Tisch aufgenommen: ", tisch_getragen)
		ok = ok and tisch_getragen
		await _e()
		await _frames(10)
		print("Tisch abgestellt: ", not gm._held.has(1))
		ok = ok and not gm._held.has(1)
		# --- Regal (Aufnahme per Aufruf — das Regal steht im Lagerraum hinter Wänden)
		var regal: Node3D = gm._lagerregale()[0]
		var vorher: Vector3 = regal.global_position
		sp.global_position = Vector3(2.0, 0.1, 3.0)
		sp.rotation = Vector3.ZERO
		await _frames(10)
		gm.net_move_lager.rpc_id(1, 0)
		await _frames(30)
		var getragen: bool = gm._held_lager.has(1)
		var soll: Vector3 = sp.global_position - sp.global_transform.basis.z * 2.0
		print("Regal global vorher: ", vorher)
		print("Regal aufgenommen: ", getragen, " · global jetzt ", regal.global_position, " · soll vor dem Spieler ", Vector3(soll.x, 0, soll.z))
		var nah: bool = regal.global_position.distance_to(Vector3(soll.x, 0.0, soll.z)) < 0.3
		ok = ok and getragen and nah
		# Loslassen mit E ins Leere (Blick an die Decke, nichts im Blick)
		sp._head.rotation.x = 1.2
		await _frames(20)
		await _e()
		await _frames(10)
		var los: bool = not gm._held_lager.has(1)
		print("Regal losgelassen mit E ins Leere: ", los, " · global ", regal.global_position)
		var im_zelt: bool = absf(regal.global_position.x) < gm.WAND_X and regal.global_position.z > gm.WAND_HINTEN and regal.global_position.z < gm.WAND_VORN
		print("Regal im Zelt: ", im_zelt)
		ok = ok and los and im_zelt
		return ok

	func _e() -> void:
		var ev := InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		Input.parse_input_event(ev)
		await _frames(2)
		var los := InputEventAction.new()
		los.action = "interact"
		los.pressed = false
		Input.parse_input_event(los)
		await _frames(2)

	func _frames(k: int) -> void:
		for i in k:
			await get_tree().process_frame

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
