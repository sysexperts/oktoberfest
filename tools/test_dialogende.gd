extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Prüft, dass ein Gespräch mit E aufhört und nicht von vorn beginnt: startet ein
## neues Spiel, stellt den Spieler vor den Festleiter, drückt E bis das Gespräch zu
## ist und wartet dann, ob es sich wieder öffnet.
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_dialogende.tscn   (mit Fenster)

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
		var npc: Node3D = null
		npc = _finde_festleiter(gm)
		if npc == null:
			print("kein Festleiter gefunden")
			return false
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = npc.global_position + Vector3(0, 0.1, 1.4)
		sp.look_at(npc.global_position + Vector3(0, 1.4, 0))
		sp.rotation.x = 0
		await _frames(30)
		print("Ziel: ", sp._current_target)
		var dialog: Node = get_tree().get_first_node_in_group("dialog")
		var druecke := 0
		# E drücken, bis das Gespräch auf ist; dann weiter, bis es zu ist
		while druecke < 40:
			await _e()
			druecke += 1
			if dialog.aktiv:
				break
		if not dialog.aktiv:
			print("Gespräch ging nicht auf")
			return false
		var weiter := 0
		while dialog.aktiv and weiter < 40:
			await _frames(20)  # 0,25 s Eingabesperre des Dialogs abwarten
			if dialog._frage_offen():
				await _taste(KEY_2)  # Nein: der Festleiter bleibt ansprechbar — der Fall mit der Schleife
			else:
				await _e()
			weiter += 1
			print("  Druck %d: aktiv=%s Zeile %d von %d, ms=%d" % [weiter, dialog.aktiv, dialog._nr, dialog._zeilen.size(), Time.get_ticks_msec()])
		print("Gespräch nach %d Tastendrücken zu" % weiter)
		await _frames(30)
		var wieder: bool = dialog.aktiv
		print("nach 30 Bildern wieder offen: ", wieder)
		return not wieder and weiter < 40

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

	func _taste(code: Key) -> void:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = true
		Input.parse_input_event(ev)
		await _frames(2)
		var los := ev.duplicate() as InputEventKey
		los.pressed = false
		Input.parse_input_event(los)
		await _frames(2)

	func _finde_festleiter(n: Node) -> Node3D:
		if n.has_method("ist_festleiter") and n is Node3D:
			return n
		for c in n.get_children():
			var r := _finde_festleiter(c)
			if r:
				return r
		return null

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
