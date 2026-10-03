extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Controller und die neueren Funktionen: nur mit Gamepad-Ereignissen (Knöpfe, Abzüge, Sticks).
## Prüft: Spielerliste mit Back, Sprint mit L3, Zeitung schließen mit A, Glücksrad komplett
## (A am Budenbesitzer, Einsatz per Steuerkreuz + A, B beendet), Emote-Rad mit LB, Figurenwahl
## und Warteraum-Karten per Fokus, und dass der Mauszeiger am Controller verschwindet.
## Sichert Spielstände und Einstellungen vorher und stellt sie danach wieder her.
##   godot --path . res://tools/test_pad_neu.tscn --resolution 1280x720   (mit Fenster)

const DATEIEN := ["user://saves/slot_1.json", "user://saves/slot_2.json", "user://saves/slot_3.json",
	"user://einstellungen.cfg"]

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	var _gab_es := {}

	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _frames(n: int) -> void:
		for i in n:
			await get_tree().process_frame

	func _knopf(index: int, unten: bool) -> void:
		var ev := InputEventJoypadButton.new()
		ev.button_index = index
		ev.pressed = unten
		ev.pressure = 1.0 if unten else 0.0
		Input.parse_input_event(ev)

	func _achse(achse: int, wert: float) -> void:
		var ev := InputEventJoypadMotion.new()
		ev.axis = achse
		ev.axis_value = wert
		Input.parse_input_event(ev)

	func _tippen(index: int) -> void:
		_knopf(index, true)
		await _frames(4)
		_knopf(index, false)
		await _frames(4)

	func _fokus_in(k: Node) -> bool:
		var f := get_viewport().gui_get_focus_owner()
		return f != null and k.is_ancestor_of(f)

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
		await _pruefen()
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(echt + ".testbackup", echt)
				DirAccess.remove_absolute(echt + ".testbackup")
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)
		print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(0 if fehler == 0 else 1)

	func _pruefen() -> void:
		var gm = await Spielstart.starten(self, true, 2)
		if gm == null:
			fehler += 1
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = gm._players_nodes.get(1)
		var hud: Node = gm.get_node("HUD")
		await _frames(20)

		print("-- Belegung")
		_check("Spielerliste: Taste Tab und Knopf Back", InputMap.has_action("spielerliste")
			and InputMap.action_get_events("spielerliste").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_BACK)
			and InputMap.action_get_events("spielerliste").any(func(e): return e is InputEventKey and e.physical_keycode == KEY_TAB))
		_check("Sprint auch auf L3", InputMap.action_get_events("sprint").any(func(e): return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_LEFT_STICK))
		var rolle := {"interact": JOY_BUTTON_A, "springen": JOY_BUTTON_B, "trinken": JOY_BUTTON_X, "ping": JOY_BUTTON_Y,
			"emote": JOY_BUTTON_LEFT_SHOULDER, "sprint": JOY_BUTTON_RIGHT_SHOULDER, "kalender": JOY_BUTTON_DPAD_DOWN, "help": JOY_BUTTON_DPAD_LEFT}
		for aktion: String in rolle:
			_check("Belegung %s" % aktion, InputMap.action_get_events(aktion).any(func(e): return e is InputEventJoypadButton and e.button_index == rolle[aktion]))

		print("-- Spielerliste mit Back")
		hud.melde("MSG_RAUSCH")
		_knopf(JOY_BUTTON_BACK, true)
		await _frames(10)
		var liste: Control = hud.get_node("%Spielerliste")
		_check("Back halten zeigt die Liste", liste.visible)
		_check("Ereignisse stehen drin", liste.get_node("%Ereignisse").get_child_count() >= 1)
		_knopf(JOY_BUTTON_BACK, false)
		await _frames(10)
		_check("Loslassen blendet aus", not liste.visible)

		print("-- Sprint mit L3")
		_knopf(JOY_BUTTON_LEFT_STICK, true)
		await _frames(3)
		_check("L3 löst Sprint aus", Input.is_action_pressed("sprint"))
		_knopf(JOY_BUTTON_LEFT_STICK, false)
		await _frames(3)

		print("-- Emote-Rad mit LB")
		_knopf(JOY_BUTTON_LEFT_SHOULDER, true)
		await _frames(25)
		var rad = hud.get_node_or_null("EmoteRad")
		_check("LB halten öffnet das Rad", rad != null and rad.ist_offen())
		_knopf(JOY_BUTTON_LEFT_SHOULDER, false)
		await _frames(10)
		_check("Loslassen schließt das Rad", rad != null and not rad.ist_offen())

		print("-- Zeitung mit A schließen")
		var zeitung = gm.get_node("Zeitung")
		zeitung.zeigen({"day": 3, "served": 112, "earn": 2450, "net": 900, "pop": 71, "missed": 2, "toilet": false,
			"kellner": true, "gekocht": 38, "rausgeworfen": 3}, hud._zustand)
		await get_tree().create_timer(0.8).timeout
		_check("Zeitung offen", zeitung.aktiv)
		await _tippen(JOY_BUTTON_A)
		_check("A schließt die Zeitung", not zeitung.aktiv)
		_check("Danach wieder gefangene Maus", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
		await get_tree().create_timer(0.5).timeout

		print("-- Glücksrad nur mit Controller")
		var bude: Node3D = null
		for s in get_tree().get_nodes_in_group("kirmes_spiel"):
			if s.get_script() and String(s.get_script().resource_path).get_file() == "gluecksrad.gd":
				bude = s
				break
		_check("Glücksrad-Bude da", bude != null)
		if bude != null:
			var besitzer: Node3D = bude.get_node("Besitzer")
			var vor: Vector3 = besitzer.global_position + bude.global_basis.z * 1.4
			sp.global_position = Vector3(vor.x, 0.1, vor.z)
			var blick := besitzer.global_position - sp.global_position
			sp.rotation.y = atan2(-blick.x, -blick.z)
			await _frames(30)
			await _tippen(JOY_BUTTON_A)
			await _frames(25)
			_check("A am Budenbesitzer startet das Spiel", sp.minispiel != null and bude._anzeige.visible)
			var fokus := get_viewport().gui_get_focus_owner()
			_check("Ein Einsatzknopf hat den Fokus", fokus != null and bude._knoepfe.has(fokus))
			await _tippen(JOY_BUTTON_DPAD_RIGHT)
			var fokus2 := get_viewport().gui_get_focus_owner()
			_check("Steuerkreuz rechts wechselt zum nächsten Einsatz", fokus2 == bude._knoepfe[1])
			var geld := int(Game.money)
			await _tippen(JOY_BUTTON_A)
			await _frames(10)
			_check("A auf dem Einsatzknopf dreht das Rad", bude._zustand == bude.DREHT)
			_check("10 € Einsatz abgebucht", Game.money <= geld - 10 + 500, "Geld %d → %d" % [geld, Game.money])
			var t0 := Time.get_ticks_msec()
			while bude._zustand != bude.ZEIGT and Time.get_ticks_msec() - t0 < 12000:
				await get_tree().process_frame
			_check("Ergebnis erscheint", bude._zustand == bude.ZEIGT, bude._ergebnis.text)
			await _tippen(JOY_BUTTON_B)
			await _frames(10)
			_check("B beendet das Glücksrad", sp.minispiel == null and not bude._anzeige.visible)
			_check("Maus danach wieder gefangen", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)

		print("-- Figurenwahl per Fokus")
		# Weg vom Budenbesitzer: A löst sonst auch dort das Benutzen aus
		sp.global_position = Vector3(0, 0.1, 30)
		await _frames(10)
		var wahl: Control = load("res://scenes/ui/figurenwahl.tscn").instantiate()
		get_tree().root.add_child(wahl)
		var gewaehlt := [-1]
		wahl.gewaehlt.connect(func(nr: int) -> void: gewaehlt[0] = nr)
		wahl.zeigen(0, {})
		await _frames(10)
		var f0 := get_viewport().gui_get_focus_owner()
		_check("Figurenwahl: Fokus auf einer Karte", f0 is Button and wahl.get_node("%Raster").is_ancestor_of(f0))
		await _tippen(JOY_BUTTON_DPAD_RIGHT)
		var f1 := get_viewport().gui_get_focus_owner()
		_check("Steuerkreuz rechts: nächste Karte", f1 != f0 and f1 is Button)
		await _tippen(JOY_BUTTON_DPAD_DOWN)
		await _tippen(JOY_BUTTON_DPAD_DOWN)
		var f2 := get_viewport().gui_get_focus_owner()
		_check("Steuerkreuz unten: Zeilen darunter, auch die letzte (Figur 10–12)", f2 is Button and f2.get_index() >= 10, str(f2.get_index() if f2 else -1))
		await _tippen(JOY_BUTTON_A)
		_check("A wählt die Figur", gewaehlt[0] >= 0, str(gewaehlt[0]))
		wahl.queue_free()

		print("-- Lobby-Fenster im Spiel")
		hud.open_lobby()
		await _frames(10)
		var lobby: Control = hud.get_node("%Lobby")
		lobby._wahl_oeffnen()
		await _frames(10)
		_check("Lobby: Figurenwahl offen mit Fokus", lobby.get_node("%Wahl").visible and _fokus_in(lobby.get_node("%Wahl")))
		await _tippen(JOY_BUTTON_B)
		await _frames(5)
		_check("B schließt die Figurenwahl in der Lobby", not lobby.get_node("%Wahl").visible)
		_check("Lobby selbst bleibt offen", lobby.visible)
		hud.close_lobby()
		await _frames(5)

		print("-- Mauszeiger am Controller")
		Einstellungen.am_pad = true
		Einstellungen._pad_maus_bis = 0
		await get_tree().create_timer(3.0).timeout
		_check("Zeiger verschwindet, wenn der Stick ruht", Einstellungen.zeiger_versteckt())
		_achse(JOY_AXIS_RIGHT_X, 0.9)
		await _frames(8)
		_check("Stick bewegt: Zeiger wieder da", not Einstellungen.zeiger_versteckt())
		_achse(JOY_AXIS_RIGHT_X, 0.0)
		await get_tree().create_timer(3.2).timeout
		_check("Wieder versteckt", Einstellungen.zeiger_versteckt())
		var maus := InputEventMouseMotion.new()
		maus.relative = Vector2(5, 5)
		Input.parse_input_event(maus)
		await _frames(8)
		_check("Echte Maus: Zeiger sichtbar", not Einstellungen.zeiger_versteckt() and not Einstellungen.am_pad)
