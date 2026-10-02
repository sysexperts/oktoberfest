extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft, dass sich mehrere volle Krüge vom Boden aufheben lassen (bis MAX_KRUEGE):
## legt drei volle Krüge vor den Spieler und drückt dreimal E.
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_krugstapel.tscn   (mit Fenster)

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
		# Freie Stelle: im Freien vor dem Zelt, Blick nach unten auf den Boden
		sp.global_position = Vector3(0, 0.1, 30)
		sp.rotation = Vector3.ZERO
		await _frames(20)
		var ort := sp.global_position - sp.global_transform.basis.z * 0.9
		for i in 3:
			gm.net_ablegen.rpc_id(1, 1, 1, 1.0, ort + Vector3(0.0, 0.0, 0.0))
			await _frames(5)
		print("Abgelegt: ", gm._abgelegt.size())
		sp._head.rotation.x = -0.9   # Blick auf den Boden vor den Füßen
		await _frames(20)
		print("Ziel: ", sp._current_target)
		for i in 3:
			await _e()
			await _frames(15)
			print("  nach E %d: Hand=%d fill=%.1f extra=%d, übrig am Boden=%d" % [i + 1, sp.carry_state, sp.carry_fill, sp.extra_kruege.size(), gm._abgelegt.size()])
		var gesamt: int = (1 if sp.carry_state == 1 else 0) + sp.extra_kruege.size()
		print("Krüge getragen: ", gesamt)
		return gesamt == 3

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
