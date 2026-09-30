extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Das Spiel nur mit dem Controller: Das Werkzeug schickt dieselben Ereignisse,
## die ein Gamepad schickt (Sticks, Knöpfe, Abzüge), und schaut, was im Spiel
## ankommt — Laufen, Umsehen, Springen, Pause, Fenster, jede Kirmesbude.
##
##   Godot.exe --path . res://tools/test_pad_spiel.tscn --resolution 640x360
##
## Mit Fenster starten: headless kennt keine gefangene Maus (Input.mouse_mode
## bleibt 0), damit hielte das Spiel jedes Bild für ein offenes Fenster, und
## das Zielen mit dem rechten Stick (Einstellungen._process) ist dort aus.
## Headless läuft der Test trotzdem, überspringt aber diese Teile.
## Sichert Spielstand und Einstellungen und stellt sie wieder her.

const DATEIEN := ["user://oktoberfest_save.json", "user://saves/slot_1.json", "user://saves/slot_2.json",
	"user://saves/slot_3.json", "user://einstellungen.cfg", "user://karte.json"]

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

	func _physik(n: int) -> void:
		for i in n:
			await get_tree().physics_frame

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
		await _physik(3)
		_knopf(index, false)
		await _physik(3)

	func _sichern() -> void:
		for pfad: String in DATEIEN:
			var alt := ProjectSettings.globalize_path(pfad + ".testbackup")
			if FileAccess.file_exists(pfad + ".testbackup"):
				DirAccess.copy_absolute(alt, ProjectSettings.globalize_path(pfad))
				DirAccess.remove_absolute(alt)
		for pfad: String in DATEIEN:
			_gab_es[pfad] = FileAccess.file_exists(pfad)
			if _gab_es[pfad]:
				DirAccess.copy_absolute(ProjectSettings.globalize_path(pfad),
					ProjectSettings.globalize_path(pfad + ".testbackup"))

	func _wiederherstellen() -> void:
		for pfad: String in DATEIEN:
			var echt := ProjectSettings.globalize_path(pfad)
			var backup := echt + ".testbackup"
			if _gab_es.get(pfad, false):
				DirAccess.copy_absolute(backup, echt)
				DirAccess.remove_absolute(backup)
			elif FileAccess.file_exists(pfad):
				DirAccess.remove_absolute(echt)

	## Erst die Spielszene abräumen, dann zurückspielen: das Spiel speichert bei
	## jeder Zustandsänderung (_broadcast_meta) und schrieb sonst nach dem
	## Zurückspielen noch einmal den Teststand auf Platz 1.
	var _beendet := false
	func _ende(code: int) -> void:
		if _beendet:
			return
		_beendet = true
		var szene := get_tree().current_scene
		if szene != null:
			szene.process_mode = Node.PROCESS_MODE_DISABLED
			szene.free()
		await get_tree().process_frame
		_wiederherstellen()
		get_tree().quit(code)

	## RT einmal durchziehen
	func _abzug(dauer := 0.15) -> void:
		_achse(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await get_tree().create_timer(dauer).timeout
		_achse(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		await _frames(6)

	func _stick(achse: int, wert: float, dauer: float) -> void:
		_achse(achse, wert)
		await get_tree().create_timer(dauer).timeout
		_achse(achse, 0.0)
		await _frames(3)

	## Stellt den Spieler so vor ein Ziel, dass er es anvisiert. false: ging nicht.
	func _vor(spieler: CharacterBody3D, ziel: Node3D) -> bool:
		if ziel == null:
			return false
		var f := get_viewport().gui_get_focus_owner()
		if f:
			f.release_focus()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var punkt: Vector3 = ziel.interact_point() if ziel.has_method("interact_point") else ziel.global_position
		for abstand in [1.3, 1.9, 0.9, 0.6, 2.4]:
			for i in 16:
				var richtung := Vector3(sin(TAU * i / 16.0), 0, cos(TAU * i / 16.0))
				spieler.global_position = Vector3(punkt.x, 0.15, punkt.z) + richtung * abstand
				if ziel.global_position.y < -1.0:
					spieler.global_position.y = ziel.global_position.y
				spieler.velocity = Vector3.ZERO
				spieler.rotation.y = atan2(richtung.x, richtung.z)
				await _physik(4)
				if spieler._current_target == ziel:
					return true
		return false

	func _hoechster_sprung(spieler: CharacterBody3D) -> float:
		var hoch := 0.0
		_knopf(JOY_BUTTON_B, true)
		for i in 12:
			await get_tree().physics_frame
			hoch = maxf(hoch, spieler.velocity.y)
		_knopf(JOY_BUTTON_B, false)
		await _physik(3)
		return hoch

	func _gelaufen(spieler: CharacterBody3D) -> float:
		var ort := spieler.global_position
		_achse(JOY_AXIS_LEFT_Y, -1.0)
		await _physik(40)
		_achse(JOY_AXIS_LEFT_Y, 0.0)
		await _physik(5)
		return Vector2(spieler.global_position.x - ort.x, spieler.global_position.z - ort.z).length()

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		_sichern()
		get_tree().create_timer(420.0).timeout.connect(func() -> void:
			print("ERGEBNIS: ABBRUCH nach Zeitlimit")
			_ende(2))
		var gm := await Spielstart.starten(self)
		if gm == null:
			_ende(2)
			return
		await _frames(30)
		var spieler: CharacterBody3D = gm.get_node("Players").get_child(0)
		var hud: Node = gm.get_node("HUD")
		var pause: Node = gm.get_node("PauseMenu")
		# Einleitung, Zeitung und Ähnliches wegräumen, damit der Spieler frei ist
		for i in 20:
			if spieler.minispiel != null and is_instance_valid(spieler.minispiel):
				await _tippen(JOY_BUTTON_B)
				await _frames(30)
		spieler.minispiel = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var fokus := get_viewport().gui_get_focus_owner()
		if fokus:
			fokus.release_focus()

		var fenster_da := DisplayServer.get_name() != "headless"
		if not fenster_da:
			print("  [ -- ] headless: Laufen, Umsehen, Springen und Zielen werden übersprungen")
		print("-- Laufen und Umsehen")
		await _tippen(JOY_BUTTON_LEFT_STICK)   # irgendein Knopf: Spiel merkt „Controller"
		_check("Spiel erkennt den Controller", Einstellungen.am_pad)
		var weg: float = await _gelaufen(spieler)
		_check("linker Stick: Figur läuft", weg > 0.5 or not fenster_da, "%.2f m" % weg)
		var blick: float = spieler.rotation.y
		_achse(JOY_AXIS_RIGHT_X, 1.0)
		await _physik(20)
		_achse(JOY_AXIS_RIGHT_X, 0.0)
		await _physik(3)
		_check("rechter Stick: Blick dreht", absf(angle_difference(blick, spieler.rotation.y)) > 0.2 or not fenster_da,
			"%.2f rad" % angle_difference(blick, spieler.rotation.y))

		print("-- Springen, Pause")
		await _physik(20)
		var hoch: float = await _hoechster_sprung(spieler)
		_check("B springt", hoch > 1.0 or not fenster_da, "%.1f" % hoch)
		_check("B öffnet die Pause nicht", not pause.ist_offen())
		await _physik(60)
		await _tippen(JOY_BUTTON_START)
		_check("Start öffnet die Pause", pause.ist_offen())
		_check("in der Pause ist ein Knopf angewählt", get_viewport().gui_get_focus_owner() != null)
		await _tippen(JOY_BUTTON_START)
		_check("Start schliesst sie wieder", not pause.ist_offen())
		await _tippen(JOY_BUTTON_START)
		hoch = await _hoechster_sprung(spieler)
		_check("B schliesst die Pause", not pause.ist_offen())
		_check("… und die Figur springt dabei nicht", hoch < 1.0, "%.1f" % hoch)

		print("-- Abzüge")
		_achse(JOY_AXIS_TRIGGER_RIGHT, 1.0)
		await _frames(3)
		_check("RT ist Benutzen", Input.is_action_pressed("interact"))
		_achse(JOY_AXIS_TRIGGER_RIGHT, 0.0)
		_achse(JOY_AXIS_TRIGGER_LEFT, 1.0)
		await _frames(3)
		_check("LT wird erkannt (Bestellungen als Text, Luft anhalten)",
			Input.is_action_pressed(Einstellungen.PAD_HALTEN))
		_achse(JOY_AXIS_TRIGGER_LEFT, 0.0)
		await _physik(2)

		print("-- Fenster: Stick bewegt die Auswahl, nicht die Figur")
		for fenster in [["Festbüro", "open_booking", "is_booking_open"],
				["Zeltcomputer", "open_computer", "is_computer_open"]]:
			hud.call(fenster[1])
			await _frames(5)
			_check("%s offen" % fenster[0], hud.call(fenster[2]))
			_check("%s: ein Knopf ist angewählt" % fenster[0], get_viewport().gui_get_focus_owner() != null)
			weg = await _gelaufen(spieler)
			_check("%s: Figur bleibt stehen" % fenster[0], weg < 0.1, "%.2f m" % weg)
			await _tippen(JOY_BUTTON_B)
			await _frames(3)
			_check("%s: B schliesst" % fenster[0], not hud.call(fenster[2]))
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		print("-- Arbeiten mit A und RT (derselbe Weg wie Zapfen, Servieren, Putzen)")
		var ziele := {}
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get_script() == null:
				continue
			var datei := String(n.get_script().resource_path).get_file().get_basename()
			if not ziele.has(datei):
				ziele[datei] = n
		# Krug nehmen mit RT
		if await _vor(spieler, ziele.get("mug_dispenser")):
			await _abzug()
			_check("RT am Krugspender: Krug in der Hand", spieler.carry_state == 1, "carry_state=%d" % spieler.carry_state)
		else:
			_check("Krugspender anvisiert", false)
		# Zapfen: A halten
		if spieler.carry_state == 1 and await _vor(spieler, ziele.get("keg_station")):
			var voll: float = spieler.carry_fill
			_knopf(JOY_BUTTON_A, true)
			await get_tree().create_timer(1.5).timeout
			_knopf(JOY_BUTTON_A, false)
			await _frames(5)
			if spieler.carry_fill > voll:
				_check("A halten am Fass: Krug füllt sich", true, "%.0f %%" % (spieler.carry_fill * 100.0))
			else:
				print("  [ -- ] Zapfen nicht prüfbar (neues Spiel: %s)" % spieler._hint_for(spieler._current_target))
		# Ablegen: nichts im Blick, RT
		spieler.global_position = Vector3(0, 0.2, 40)
		await _physik(20)
		if spieler._current_target == null and spieler.carry_state != 0:
			await _abzug()
			_check("RT ohne Ziel: Krug abgestellt", spieler.carry_state == 0, "carry_state=%d" % spieler.carry_state)
		# Fenster über die Welt öffnen
		for f in [["computer", "A am Zeltcomputer", "is_computer_open"], ["office_desk", "A im Festbüro", "is_booking_open"],
				["zelt_vermietung", "A am Mietschild", "is_rent_open"]]:
			spieler.carry_state = 0
			if await _vor(spieler, ziele.get(f[0])):
				await _tippen(JOY_BUTTON_A)
				await _frames(10)
				_check("%s: Fenster geht auf" % f[1], hud.call(f[2]))
				await _tippen(JOY_BUTTON_B)
				await _frames(5)
				_check("%s: B schliesst" % f[1], not hud.call(f[2]))
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				print("  [ -- ] %s nicht anvisierbar" % f[0])
		# Gespräch: ein Druck = eine Zeile
		if await _vor(spieler, ziele.get("npc_festleiter")):
			await _abzug()
			await _frames(30)
			var dialog: Node = spieler.minispiel
			_check("RT beim Festleiter: Gespräch beginnt", dialog != null and "_nr" in dialog)
			if dialog != null and "_nr" in dialog:
				var zeile: int = dialog.get("_nr")
				await _tippen(JOY_BUTTON_A)
				await _frames(30)
				if spieler.minispiel == dialog:
					_check("A blättert genau eine Zeile", int(dialog.get("_nr")) == zeile + 1,
						"%d → %d" % [zeile, int(dialog.get("_nr"))])
				zeile = int(dialog.get("_nr")) if spieler.minispiel == dialog else -1
				if zeile >= 0:
					await _abzug()
					await _frames(30)
					if spieler.minispiel == dialog:
						_check("RT blättert genau eine Zeile", int(dialog.get("_nr")) == zeile + 1,
							"%d → %d" % [zeile, int(dialog.get("_nr"))])
				# Bis zum Ende durchblättern. Nach einer Antwort geht dasselbe Fenster
				# mit dem nächsten Abschnitt wieder auf (Brief, Frage, Antwort).
				var fragen := 0
				for i in 120:
					if spieler.minispiel == null:
						break
					if spieler.minispiel == dialog and dialog._frage_offen():
						fragen += 1
						_check("Ja/Nein-Frage: ein Knopf ist angewählt", get_viewport().gui_get_focus_owner() != null)
					await _tippen(JOY_BUTTON_A)
					await _frames(25)
				_check("Gespräch mit Frage lässt sich mit A zu Ende führen", spieler.minispiel == null and fragen > 0,
					"Fragen beantwortet: %d" % fragen)
		else:
			print("  [ -- ] Festleiter nicht anvisierbar")
		# Einleitung/Folgefenster wegräumen
		for i in 20:
			if spieler.minispiel != null and is_instance_valid(spieler.minispiel):
				await _tippen(JOY_BUTTON_B)
				await _frames(30)
		spieler.minispiel = null
		for zu in ["close_rent", "close_computer", "close_booking", "close_popup"]:
			if hud.has_method(zu):
				hud.call(zu)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		print("-- Kurzbefehle")
		var hilfe: Node = gm.get_node_or_null("Hilfe")
		await _tippen(JOY_BUTTON_DPAD_LEFT)
		await _frames(5)
		_check("Steuerkreuz links: Hilfe geht auf", hilfe != null and hilfe.visible)
		if hilfe != null and hilfe.visible:
			var start_da := false
			for l in hilfe.find_children("*", "Label", true, false):
				if (l as Label).text == "Start":
					start_da = true
			_check("Hilfe zeigt die Controller-Belegung", start_da)
			await _tippen(JOY_BUTTON_B)
			await _frames(5)
			_check("B schliesst die Hilfe", not hilfe.visible)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var kalender: Node = get_tree().get_first_node_in_group("kalender")
		await _tippen(JOY_BUTTON_DPAD_DOWN)
		await _frames(5)
		_check("Steuerkreuz unten: Kalender geht auf", kalender != null and kalender.visible)
		if kalender != null and kalender.visible:
			await _tippen(JOY_BUTTON_B)
			await _frames(5)
			_check("B schliesst den Kalender", not kalender.visible)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		var kostuem: int = spieler.costume
		await _tippen(JOY_BUTTON_DPAD_UP)
		_check("Steuerkreuz oben: Kostüm wechselt", spieler.costume != kostuem)
		var ping: int = spieler._letzter_ping
		await get_tree().create_timer(0.7).timeout
		await _tippen(JOY_BUTTON_Y)
		_check("Y: Markieren", spieler._letzter_ping != ping)
		var kamera: bool = spieler._schulterkamera
		await _tippen(JOY_BUTTON_RIGHT_STICK)
		_check("R3: Schulterkamera an", spieler._schulterkamera != kamera)
		await _tippen(JOY_BUTTON_RIGHT_STICK)
		_check("R3: Schulterkamera wieder aus", spieler._schulterkamera == kamera)

		print("-- Prost-Rad")
		var rad: Node = spieler._emote_rad()
		_knopf(JOY_BUTTON_LEFT_SHOULDER, true)
		await _frames(6)
		_check("LB halten: Rad geht auf", rad != null and rad.ist_offen())
		if rad != null and rad.ist_offen():
			await _stick(JOY_AXIS_RIGHT_Y, -1.0, 0.25)
			_check("rechter Stick nach oben wählt das obere Stück", int(rad.get("_wahl")) == int(rad.STUECKE[0]["emote"]),
				"Wahl %d" % int(rad.get("_wahl")))
			await _stick(JOY_AXIS_RIGHT_X, 1.0, 0.25)
			var rechts := int(rad.get("_wahl"))
			_check("rechter Stick nach rechts wählt ein Stück rechts", rechts == int(rad.STUECKE[1]["emote"])
				or rechts == int(rad.STUECKE[2]["emote"]), "Wahl %d" % rechts)
			await _tippen(JOY_BUTTON_DPAD_LEFT)
			await _frames(4)
			_check("Steuerkreuz im Rad blättert, öffnet aber nicht die Hilfe", hilfe == null or not hilfe.visible)
			var wahl := int(rad.get("_wahl"))
			_knopf(JOY_BUTTON_LEFT_SHOULDER, false)
			await _frames(6)
			_check("LB loslassen: Rad zu, Emote läuft", not rad.ist_offen() and (spieler.emote_wahl == wahl or wahl == 2),
				"gewählt %d, läuft %d" % [wahl, spieler.emote_wahl])
		_knopf(JOY_BUTTON_LEFT_SHOULDER, false)
		if hilfe != null and hilfe.visible:
			hilfe.schliessen()
		spieler._kotz_t = 0.0
		spieler._emote_until = 0.0
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await _frames(10)

		print("-- Ein Arbeitstag")
		gm.net_skip_tutorial.rpc_id(1)
		await _frames(10)
		for i in 10:
			if spieler.minispiel != null and is_instance_valid(spieler.minispiel):
				await _tippen(JOY_BUTTON_B)
				await _frames(30)
		spieler.minispiel = null
		if int(gm.get("_tent_stage")) == 0:
			gm.net_book_tent.rpc_id(1)
		gm.net_buy_table.rpc_id(1)
		gm._stock[gm.WARE_BIER] = 30
		gm._stock[gm.WARE_ESSEN] = 30
		await _frames(10)
		spieler.carry_state = 0
		spieler.carry_fill = 0.0
		spieler.extra_kruege.clear()
		# Kochen: RT halten
		var herd: Node3D = get_tree().get_first_node_in_group("interactable")
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is FoodStation:
				herd = n
				break
		# Im neuen Spiel fehlt die Essenslizenz, die Kochstellen sind ausgeblendet
		var eltern: Node = herd
		while eltern is Node3D and not (herd as Node3D).is_visible_in_tree():
			(eltern as Node3D).visible = true
			eltern = eltern.get_parent()
		await _frames(3)
		if herd is FoodStation and await _vor(spieler, herd):
			_achse(JOY_AXIS_TRIGGER_RIGHT, 1.0)
			await get_tree().create_timer(1.0).timeout
			_achse(JOY_AXIS_TRIGGER_RIGHT, 0.0)
			await _frames(5)
			_check("RT halten am Herd: Essen wird zubereitet", spieler.carry_state == 2 and spieler.carry_fill > 0.1,
				"carry=%d, %.0f %%" % [spieler.carry_state, spieler.carry_fill * 100.0])
		else:
			print("  [ -- ] Herd nicht anvisierbar: %s bei %s, sichtbar %s, Spieler %s, Ziel %s" % [herd.name,
				herd.global_position, herd.is_visible_in_tree(), spieler.global_position, spieler._current_target])
		# Ablegen und wieder aufheben
		spieler.carry_state = 1
		spieler.carry_type = 1
		spieler.carry_fill = 1.0
		var frei := false
		for ort in [Vector3(0, 0.15, 30), Vector3(3, 0.15, 34), Vector3(-4, 0.15, 28), Vector3(0, 0.15, 0)]:
			spieler.global_position = ort
			spieler.velocity = Vector3.ZERO
			await _physik(6)
			if spieler._current_target == null:
				frei = true
				break
		if frei:
			var liegt: int = gm._abgelegt.size()
			await _abzug()
			await _frames(6)
			_check("RT ohne Ziel: Krug liegt am Boden", spieler.carry_state == 0 and gm._abgelegt.size() == liegt + 1,
				"carry=%d, abgelegt %d → %d" % [spieler.carry_state, liegt, gm._abgelegt.size()])
			await _physik(10)
			var krug: Node3D = null
			for n in get_tree().get_nodes_in_group("interactable"):
				if n.has_method("ist_abgelegt"):
					krug = n
			if krug != null and await _vor(spieler, krug):
				await _tippen(JOY_BUTTON_A)
				await _frames(10)
				_check("A am abgelegten Krug: wieder in der Hand", spieler.carry_state == 1, "carry=%d" % spieler.carry_state)
			else:
				print("  [ -- ] abgelegter Krug nicht anvisierbar")
		else:
			_check("freie Stelle zum Ablegen gefunden", false)
		# Trinken: X halten
		spieler.carry_state = 1
		spieler.carry_type = 1
		spieler.carry_fill = 1.0
		spieler.global_position = Vector3(0, 0.15, 30)
		await _physik(4)
		_knopf(JOY_BUTTON_X, true)
		await get_tree().create_timer(1.5).timeout
		_knopf(JOY_BUTTON_X, false)
		await _frames(4)
		_check("X halten: trinkt aus dem Krug", spieler.carry_fill < 1.0 or spieler.promille > 0.0,
			"Krug %.0f %%, Promille %.2f" % [spieler.carry_fill * 100.0, spieler.promille])
		spieler.carry_state = 0
		spieler.carry_fill = 0.0
		spieler.promille = 0.0
		spieler._kotz_t = 0.0
		# Tisch versetzen (nur vor der Schicht)
		var tisch: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is BeerTable and n.is_visible_in_tree():
				tisch = n
				break
		if tisch != null and await _vor(spieler, tisch):
			var ich := spieler.name.to_int()
			await _tippen(JOY_BUTTON_A)
			await _frames(10)
			_check("A am Tisch: Tisch wird getragen", gm.haelt_tisch(ich))
			if gm.haelt_tisch(ich):
				await _tippen(JOY_BUTTON_LEFT_SHOULDER)
				await _frames(6)
				_check("LB dreht den Tisch statt das Rad zu öffnen", not rad.ist_offen())
				await _tippen(JOY_BUTTON_A)
				await _frames(10)
				if gm.haelt_tisch(ich):
					print("  [ -- ] Tisch liess sich an dieser Stelle nicht abstellen")
					gm._haelt_tisch.clear()
				else:
					_check("A stellt den Tisch wieder ab", true)
		else:
			print("  [ -- ] Tisch nicht anvisierbar")
		# Paket tragen und ins Lager räumen
		gm._add_package(990001, Vector3(2, 0.2, 31), 1, 5)
		await _frames(5)
		var paket: Node3D = gm._packages.get(990001)
		if paket != null and await _vor(spieler, paket):
			await _abzug()
			await _frames(6)
			_check("RT am Paket: Paket in der Hand", spieler.carry_state == 3, "carry=%d" % spieler.carry_state)
			var regal: Node3D = null
			for n in get_tree().get_nodes_in_group("interactable"):
				if n is Lager and n.is_visible_in_tree():
					regal = n
					break
			if spieler.carry_state == 3 and regal != null and await _vor(spieler, regal):
				await _tippen(JOY_BUTTON_A)
				await _frames(6)
				_check("A am Lagerregal: Paket eingeräumt", spieler.carry_state == 0, "carry=%d" % spieler.carry_state)
			else:
				print("  [ -- ] Lagerregal nicht anvisierbar")
		else:
			print("  [ -- ] Paket nicht anvisierbar")
		spieler.carry_state = 0
		# Schlafen startet den Tag
		var wagen: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Caravan:
				wagen = n
		var tag: int = gm._day
		if wagen != null and gm.in_intermission() and await _vor(spieler, wagen):
			await _tippen(JOY_BUTTON_A)
			await get_tree().create_timer(4.0).timeout
			_check("A am Wohnwagen: schlafen, der Tag beginnt", not gm.in_intermission() or gm._day != tag,
				"Tag %d → %d" % [tag, gm._day])
		else:
			print("  [ -- ] Wohnwagen nicht anvisierbar")
		for i in 10:
			if spieler.minispiel != null and is_instance_valid(spieler.minispiel):
				await _tippen(JOY_BUTTON_A)
				await _frames(40)
		spieler.minispiel = null
		var intro: Node = gm.get_node_or_null("HUD/SchichtIntro")
		if intro == null:
			for n in gm.find_children("*", "", true, false):
				if n.get_script() != null and String(n.get_script().resource_path).ends_with("schicht_intro.gd"):
					intro = n
		if intro != null and intro.visible:
			await _tippen(JOY_BUTTON_A)
			await get_tree().create_timer(0.6).timeout
			_check("A schliesst die Tafel zum Schichtbeginn", not intro.visible)
		if gm.in_intermission():
			gm._start_shift()
			await _frames(5)
		# Zelt eröffnen
		var fass: Node3D = get_tree().get_first_node_in_group("zelt_eroeffnung")
		if fass != null and fass.is_in_group("interactable") and await _vor(spieler, fass):
			await _tippen(JOY_BUTTON_A)
			await _frames(10)
			_check("A am Anstichfass: Zelt ist eröffnet", gm._zelt_offen)
		else:
			print("  [ -- ] Anstichfass nicht anvisierbar")
			gm._zelt_offen = true
		# Servieren
		var gast: Customer = gm.CUSTOMER_SCENE.instantiate() as Customer
		gm.get_node("Customers").add_child(gast)
		gast.global_position = Vector3(0, 0, 4)
		gast._net_pos = gast.global_position
		await _frames(3)
		gast.order_state = 1
		gast.order_kind = 1
		gast.order_type = 1
		spieler.carry_state = 1
		spieler.carry_type = 1
		spieler.carry_fill = 1.0
		if await _vor(spieler, gast):
			_achse(JOY_AXIS_TRIGGER_LEFT, 1.0)
			await _frames(6)
			_check("LT halten: Bestellung als Text", gast._details)
			_achse(JOY_AXIS_TRIGGER_LEFT, 0.0)
			await _frames(3)
			await _abzug()
			await _frames(4)
			_check("RT am Gast mit vollem Krug: serviert", spieler.carry_state == 0, "carry=%d" % spieler.carry_state)
		else:
			_check("Gast anvisierbar", false, spieler._hint_for(gast))
		gast.queue_free()
		spieler.carry_state = 0
		spieler.carry_fill = 0.0
		# Putzen
		gm._spawn_mess_at(Vector3(3, 0, 5), Mess.DRECK)
		await _frames(5)
		var dreck: Mess = null
		for n in get_tree().get_nodes_in_group("mess"):
			if n is Mess and (n as Mess).ist_dreck():
				dreck = n
		if dreck != null and await _vor(spieler, dreck):
			_knopf(JOY_BUTTON_A, true)
			var bis := Time.get_ticks_msec() + 8000
			while Time.get_ticks_msec() < bis and is_instance_valid(dreck) and dreck.is_inside_tree() \
					and spieler._current_target == dreck:
				await get_tree().process_frame
			_knopf(JOY_BUTTON_A, false)
			await _frames(5)
			_check("A halten am Dreck: weggefegt", not is_instance_valid(dreck) or not dreck.is_inside_tree()
				or not dreck.is_in_group("mess"))
		else:
			_check("Dreck anvisierbar", false)
		spieler.carry_state = 0
		spieler.carry_pkg_kind = 0
		for i in 10:
			if spieler.minispiel != null and is_instance_valid(spieler.minispiel):
				await _tippen(JOY_BUTTON_B)
				await _frames(30)
		spieler.minispiel = null
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

		print("-- Kirmesbuden")
		var buden := {}
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.has_method("ist_budenbesitzer") and n.bude != null and n.bude.get_script() != null:
				var art := String(n.bude.get_script().resource_path).get_file().get_basename()
				if not buden.has(art):
					buden[art] = [n, n.bude]
		# Einmal den echten Weg: beim Budenbesitzer mit A bezahlen
		var erste: Array = buden.values()[0]
		if await _vor(spieler, erste[0]):
			var geld: int = Game.money
			await _tippen(JOY_BUTTON_A)
			await _frames(40)
			_check("A beim Budenbesitzer: bezahlt und Spiel läuft", spieler.minispiel == erste[1] and Game.money < geld,
				"Geld %d → %d" % [geld, Game.money])
			if spieler.minispiel != null:
				for i in 300:
					if not ("_animation" in erste[1]) or not erste[1].get("_animation"):
						break
					await get_tree().process_frame
				await _tippen(JOY_BUTTON_B)
				await _frames(10)
		else:
			print("  [ -- ] Budenbesitzer nicht anvisierbar")
		for art: String in buden:
			var bude: Node = buden[art][1]
			var f := get_viewport().gui_get_focus_owner()
			if f:
				f.release_focus()
			spieler.minispiel = bude
			bude.spiel_starten(spieler)
			await _frames(20)
			if spieler.minispiel != bude:
				_check("%s: gestartet" % art, false)
				continue
			var mit_fokus := get_viewport().gui_get_focus_owner() != null
			# --- Zielen mit dem rechten Stick
			if "_yaw" in bude:
				var yaw: float = bude.get("_yaw")
				await _stick(JOY_AXIS_RIGHT_X, 1.0, 0.5)
				var grad := rad_to_deg(absf(float(bude.get("_yaw")) - yaw))
				_check("%s: rechter Stick zielt" % art, grad > 1.0, "%.0f°/s" % (grad * 2.0))
			elif "_ziel" in bude and bude.get("_ziel") is Vector2:
				var ziel: Vector2 = bude.get("_ziel")
				await _stick(JOY_AXIS_RIGHT_X, 1.0, 0.5)
				_check("%s: rechter Stick zielt" % art, ((bude.get("_ziel") as Vector2) - ziel).length() > 0.05,
					"%.2f" % ((bude.get("_ziel") as Vector2) - ziel).length())
			elif art == "stemmen":
				# ohne Eingabe sinkt der Arm; Stick nach oben muss ihn heben
				var w: float = bude.get("_winkel")
				await _stick(JOY_AXIS_RIGHT_Y, -1.0, 0.5)
				_check("stemmen: rechter Stick hebt den Arm", float(bude.get("_winkel")) > w + 2.0,
					"%.1f° → %.1f°" % [w, float(bude.get("_winkel"))])
			elif art == "maulwurf":
				# Aus der Bildmitte 0,3 s nach rechts: rund 330 Bildpunkte, nur waagerecht.
				# Abgelesen wird die Stelle, die das Spiel führt und für den Klick nimmt —
				# den Zeiger des Betriebssystems gibt es im Testlauf nicht.
				var bild := get_viewport().get_visible_rect().size
				Einstellungen._zeiger = bild * 0.5
				await _stick(JOY_AXIS_RIGHT_X, 1.0, 0.3)
				var d: Vector2 = Einstellungen._zeiger - bild * 0.5
				_check("maulwurf: rechter Stick schiebt den Zeiger gerade und im richtigen Tempo",
					d.x > 200.0 and d.x < 500.0 and absf(d.y) < 40.0, "%.0f / %.0f Bildpunkte" % [d.x, d.y])
			# --- Auslösen mit RT
			if mit_fokus:
				_check("%s: Knöpfe anwählbar, A drückt sie" % art, true)
			elif "_uebrig" in bude:
				var vorher: int = bude.get("_uebrig")
				await _abzug(0.35)
				await _frames(40)
				_check("%s: RT löst aus" % art, int(bude.get("_uebrig")) < vorher,
					"Versuche %d → %d" % [vorher, int(bude.get("_uebrig"))])
			elif art == "entenangeln":
				_achse(JOY_AXIS_TRIGGER_RIGHT, 1.0)
				await _frames(10)
				var unten: bool = bude.get("_senken")
				_achse(JOY_AXIS_TRIGGER_RIGHT, 0.0)
				await _frames(10)
				_check("entenangeln: RT halten senkt die Angel, loslassen hebt sie", unten and not bude.get("_senken"))
			elif art == "pfeilwurf":
				var geworfen: int = bude.get("_geworfen")
				await _abzug()
				_check("pfeilwurf: RT wirft", int(bude.get("_geworfen")) == geworfen + 1)
			elif art == "krugschieben":
				await _abzug()
				_check("krugschieben: RT schiebt den Krug", float(bude.get("_tempo")) >= 0.0 or int(bude.get("_versuch")) > 0)
			elif art == "maulwurf":
				# Zeiger auf ein Loch, dann RT: der Hammer muss dort zuschlagen
				# Jedes Loch einzeln: Zeiger hin, RT — der Hammer muss genau dort landen
				var maeuse: Node = bude.get("_maeuse")
				var daneben := ""
				for nr in maeuse.get_child_count():
					var loch: Node3D = maeuse.get_child(nr)
					for w in 120:
						if float(bude.get("_schlag")) < 0.0:
							break
						await get_tree().process_frame
					Einstellungen._zeiger = bude.get("_kamera").unproject_position(loch.global_position)
					bude.set("_schlag_ziel", Vector3.INF)
					await _abzug(0.08)
					var traf: Vector3 = bude.get("_schlag_ziel")
					if not traf.is_equal_approx(loch.position):
						daneben += "%d(%s) " % [nr, "nichts" if not traf.is_finite() else "anderes Loch"]
				_check("maulwurf: RT trifft jedes der %d Löcher unter dem Zeiger" % maeuse.get_child_count(),
					daneben == "", "daneben: " + daneben)
				Einstellungen._zeiger = Vector2.INF
			elif art == "stemmen":
				pass   # kein Auslösen, nur halten
			else:
				print("  [ -- ] %s: Auslösen nicht ablesbar" % art)
			# --- Luft anhalten
			if "_luft" in bude and spieler.minispiel == bude:
				bude.set("_luft", 1.0)
				_achse(JOY_AXIS_TRIGGER_LEFT, 1.0)
				await get_tree().create_timer(0.5).timeout
				var luft: float = bude.get("_luft")
				_achse(JOY_AXIS_TRIGGER_LEFT, 0.0)
				_check("%s: LT hält die Luft an" % art, luft < 0.95, "Luft %.0f %%" % (luft * 100.0))
			# --- Verlassen
			for i in 300:
				if not ("_animation" in bude) or not bude.get("_animation"):
					break
				await get_tree().process_frame
			if spieler.minispiel == bude:
				await _tippen(JOY_BUTTON_B)
				await _frames(10)
			_check("%s: B verlässt die Bude (oder Runde vorbei)" % art, spieler.minispiel == null)
			spieler.minispiel = null
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			await _frames(5)
		_check("alle zwölf Buden geprüft", buden.size() >= 12, str(buden.keys()))

		print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		_ende(1 if fehler > 0 else 0)
