extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Glücksrad wie im echten Spiel: der Spieler steht vor dem Budenbesitzer, drückt E
## (Interaktion), wählt per Taste 1 den Einsatz und das Rad dreht. Sichert Spielstände
## vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_gluecksrad_echt.tscn   (mit Fenster)

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
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("TEST ", "BESTANDEN" if ok else "FEHLGESCHLAGEN")
		get_tree().quit(0 if ok else 1)

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _taste(code: Key, an: bool) -> void:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = an
		Input.parse_input_event(ev)

	func _pruefen() -> bool:
		var gm = await Spielstart.starten(self, true, 2)
		if gm == null:
			return false
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm.set_process(true)
		var bude: Node3D = null
		for s in get_tree().get_nodes_in_group("kirmes_spiel"):
			if s.get_script() and String(s.get_script().resource_path).get_file() == "gluecksrad.gd":
				bude = s
				break
		if bude == null:
			print("keine Glücksrad-Bude auf der Karte")
			return false
		var sp: Node3D = gm._players_nodes.get(1)
		var besitzer: Node3D = bude.get_node("Besitzer")
		# Vor den Budenbesitzer stellen, ihn ansehen
		var vor: Vector3 = besitzer.global_position + bude.global_basis.z * 1.4
		sp.global_position = Vector3(vor.x, 0.1, vor.z)
		var blick := besitzer.global_position - sp.global_position
		sp.rotation.y = atan2(-blick.x, -blick.z)
		await _frames(30)
		print("Ziel: ", sp._current_target, " Hinweis sichtbar")
		var ziel_ok: bool = sp._current_target != null and sp._current_target.has_method("ist_budenbesitzer")
		print("Budenbesitzer im Ziel: ", ziel_ok)
		if not ziel_ok:
			return false
		var money0: int = Game.money
		var e := InputEventAction.new()
		e.action = "interact"
		e.pressed = true
		Input.parse_input_event(e)
		await _frames(10)
		e = InputEventAction.new()
		e.action = "interact"
		e.pressed = false
		Input.parse_input_event(e)
		await _frames(20)
		print("Minispiel läuft: ", sp.minispiel != null, " Anzeige: ", bude._anzeige.visible, " Knöpfe frei: ", bude._knoepfe.map(func(b): return not b.disabled))
		if sp.minispiel == null:
			return false
		# Einsatz 1 über Taste
		_taste(KEY_1, true)
		await _frames(2)
		_taste(KEY_1, false)
		await _frames(10)
		print("Zustand nach Einsatz: ", bude._zustand, " (1 = dreht) Geld ", Game.money, " vorher ", money0)
		var dreht: bool = bude._zustand == bude.DREHT
		# Auf Ergebnis warten
		var t0 := Time.get_ticks_msec()
		while bude._zustand != bude.ZEIGT and Time.get_ticks_msec() - t0 < 12000:
			await get_tree().process_frame
		print("Ergebnis gezeigt: ", bude._zustand == bude.ZEIGT, " Text: ", bude._ergebnis.text)
		var gezeigt: bool = bude._zustand == bude.ZEIGT
		# Per Mausklick auf den Einsatzknopf 10
		await get_tree().create_timer(3.8).timeout
		bude._knoepfe[1].pressed.emit()
		await _frames(10)
		print("Zustand nach Klick: ", bude._zustand)
		var klick_dreht: bool = bude._zustand == bude.DREHT
		return dreht and gezeigt and klick_dreht
