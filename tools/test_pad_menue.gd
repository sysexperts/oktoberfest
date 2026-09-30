extends Node
## Einstellungen am Controller: Kommt man mit Steuerkreuz und Knöpfen überall
## hin, bleibt der Fokus beim Umbelegen erhalten, blättern die Schultertasten?
##
##   Godot.exe --headless --path . res://tools/test_pad_menue.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0

	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _knopf(index: int) -> InputEventJoypadButton:
		var ev := InputEventJoypadButton.new()
		ev.button_index = index
		ev.pressed = true
		return ev

	func _fokus() -> Control:
		return get_viewport().gui_get_focus_owner()

	## Alle Bedienelemente unter n, die man anwählen kann.
	func _bedienbar(n: Node, aus: Array[Control]) -> void:
		for c in n.get_children():
			if c is Control:
				var k := c as Control
				if not k.is_visible_in_tree():
					continue
				if k.focus_mode == Control.FOCUS_ALL and not (k is ScrollContainer):
					aus.append(k)
			_bedienbar(c, aus)

	## Alles, was vom Start aus mit den vier Richtungen erreichbar ist.
	func _erreichbar(start: Control) -> Dictionary:
		var gesehen := {start: true}
		var offen: Array[Control] = [start]
		while not offen.is_empty():
			var k: Control = offen.pop_back()
			for seite in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				var n := k.find_valid_focus_neighbor(seite)
				if n != null and not gesehen.has(n):
					gesehen[n] = true
					offen.append(n)
		return gesehen

	func _ready() -> void:
		var menue: Node = (load("res://scenes/ui/einstellungen.tscn") as PackedScene).instantiate()
		add_child(menue)
		for i in 3:
			await get_tree().process_frame
		var reiter: TabContainer = menue.get_node("%Reiter")
		var kategorien: Node = menue.get_node("%Kategorien")

		print("-- Fokus beim Öffnen")
		_check("etwas ist angewählt", _fokus() != null)
		_check("es ist die erste Kategorie", _fokus() == kategorien.get_node("Kat0"))

		print("-- Schultertasten blättern")
		menue._unhandled_input(_knopf(JOY_BUTTON_RIGHT_SHOULDER))
		_check("RB: nächste Seite", reiter.current_tab == 1, str(reiter.current_tab))
		_check("RB: Fokus auf ihrer Kategorie", _fokus() == kategorien.get_node("Kat1"))
		menue._unhandled_input(_knopf(JOY_BUTTON_LEFT_SHOULDER))
		menue._unhandled_input(_knopf(JOY_BUTTON_LEFT_SHOULDER))
		_check("LB läuft vorn herum nach hinten", reiter.current_tab == reiter.get_tab_count() - 1,
			str(reiter.current_tab))

		print("-- Jedes Bedienelement ist erreichbar")
		for i in reiter.get_tab_count():
			menue._kategorie(i)
			for f in 2:
				await get_tree().process_frame
			var kat: Control = kategorien.get_node("Kat%d" % i)
			var gesehen := _erreichbar(kat)
			var alle: Array[Control] = []
			_bedienbar(reiter.get_current_tab_control(), alle)
			alle.append(menue.get_node("%Schliessen"))
			var fehlt := ""
			for k in alle:
				if not gesehen.has(k):
					fehlt += k.name + " "
			_check("Seite %d: %d Elemente" % [i, alle.size()], fehlt == "", fehlt)
			var rechts := kat.find_valid_focus_neighbor(SIDE_RIGHT)
			_check("Seite %d: rechts geht es in die Seite" % i,
				rechts != null and reiter.get_current_tab_control().is_ancestor_of(rechts),
				str(rechts.name) if rechts else "nichts")

		print("-- Umbelegen")
		menue._kategorie(2)
		await get_tree().process_frame
		var liste: Node = menue.get_node("%TastenListe")
		var knopf: Button = null
		for c in liste.get_children():
			if c is Button and str(c.get_meta("aktion", "")) == "interact":
				knopf = c
		_check("Knopf für Benutzen gefunden", knopf != null)
		knopf.grab_focus()
		knopf.pressed.emit()
		await get_tree().process_frame
		var f := _fokus()
		_check("Fokus bleibt beim Warten auf die Taste",
			f != null and str(f.get_meta("aktion", "")) == "interact", str(f))
		menue._input(_knopf(JOY_BUTTON_B))
		await get_tree().process_frame
		_check("Controller-Knopf bricht das Warten ab", menue._warte_auf == "")
		f = _fokus()
		_check("Fokus danach wieder auf dem Knopf",
			f != null and str(f.get_meta("aktion", "")) == "interact", str(f))
		_check("Belegung unverändert", Einstellungen.taste("interact") == KEY_E)
		# Wechsel Tastatur -> Controller baut die Liste neu: Fokus muss bleiben
		Einstellungen.geaendert.emit()
		await get_tree().process_frame
		f = _fokus()
		_check("Fokus überlebt den Neuaufbau",
			f != null and str(f.get_meta("aktion", "")) == "interact", str(f))

		print("-- Regler gehalten")
		var regler: HSlider = menue.get_node("%Aufloesung")
		regler.value = regler.min_value
		var zeit := 0.0
		while zeit < 1.0:
			menue._regler_schieben(regler, 1.0, 1.0 / 60.0)
			zeit += 1.0 / 60.0
		_check("eine Sekunde halten = halbe Breite",
			absf(regler.value - (regler.min_value + regler.max_value) * 0.5) < 0.02, str(regler.value))
		regler.value = regler.max_value

		print("ERGEBNIS: ", "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(1 if fehler > 0 else 0)
