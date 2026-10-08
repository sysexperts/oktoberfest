extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Vorführung des Tutorials im Fenster (zum Zuschauen, z. B. über Remotedesktop ohne Mausblick):
## Eröffnung → Horst (Brief, Ja) → Wohnwagen aussuchen → Zelt mieten → Dreck → fegen → Müll → Büro.
## Die Kamera folgt Horst, oben steht, was gerade passiert. Überschreibt Spielstand Platz 1!
##   godot --path . res://tools/vorfuehrung_tutorial.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _text: Label
	var _gm: Node
	var _sp: Node3D
	var _chef: Node3D

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		var ebene := CanvasLayer.new()
		ebene.layer = 100
		add_child(ebene)
		_text = Label.new()
		_text.position = Vector2(30, 20)
		_text.add_theme_font_size_override("font_size", 30)
		_text.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		_text.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_text.add_theme_constant_override("outline_size", 8)
		ebene.add_child(_text)
		_gm = await Spielstart.starten(self)
		if _gm == null:
			return
		TranslationServer.set_locale("de")
		_sp = _gm._players_nodes.get(1)
		_chef = _gm.get_node("Kirmes/Festleiter")
		await _ablauf()

	func _ansage(s: String) -> void:
		_text.text = s
		print("VORFUEHRUNG: ", s)

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	## Kamera hinter Horst, bis er steht
	func _folgen(max_s: float) -> void:
		var t := 0.0
		while _chef.unterwegs() and t < max_s:
			var hinten: Vector3 = _chef.global_position - _chef.global_transform.basis.z * 4.0
			_sp.global_position = Vector3(hinten.x, 0.1, hinten.z)
			_sp.look_at(_chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
			await _warten(0.3)
			t += 0.3

	func _zu_horst() -> void:
		_sp.global_position = _chef.global_position + _chef.global_transform.basis.z * 2.2 + Vector3(0, 0.1, 0)
		_sp.look_at(_chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)

	func _durchblaettern(auswahl: int) -> void:
		var dialog = _gm.get_node("Dialog")
		var kino = _gm.get_node("Kino")
		for _i in 60:
			await _warten(1.6)
			if dialog._auswahl.visible:
				await _warten(2.0)
				dialog._waehlen(auswahl)
				await _warten(1.5)
				break
			if kino.aktiv:
				kino._weiter()
			elif dialog.aktiv:
				dialog._weiter()
		while dialog.aktiv:
			await _warten(1.6)
			dialog._weiter()

	func _ablauf() -> void:
		var kino = _gm.get_node("Kino")
		_ansage("1 · Eröffnung: Logo und Kamerafahrt")
		await _warten(3.0)
		while kino.aktiv:
			await _warten(2.0)
			kino._weiter()
		await _warten(2.0)
		_ansage("2 · Horst im Büro: Brief von Onkel Sepp")
		_zu_horst()
		await _warten(1.0)
		_chef.ansprechen()
		await _durchblaettern(0)
		_ansage("3 · Horst läuft zur Wohnwagengasse")
		await _folgen(90.0)
		await _warten(1.0)
		_ansage("4 · Wohnwagen aussuchen (kostenlos, Platz 2)")
		_zu_horst()
		await _warten(4.0)
		_gm.net_wagen_waehlen.rpc_id(1, 2)
		await _warten(2.0)
		_ansage("5 · Horst läuft zurück zum Zelt")
		await _folgen(60.0)
		_ansage("6 · Zelt mieten")
		await _warten(2.0)
		_gm.net_book_tent.rpc_id(1, "Vorführzelt")
		await _warten(2.0)
		_ansage("7 · Dreck im Zelt")
		_sp.global_position = Vector3(0, 0.1, 13)
		_sp.look_at(Vector3(0, 0.0, 2), Vector3.UP)
		await _warten(6.0)
		_ansage("8 · Fegen (hier im Zeitraffer)")
		for id in _gm._messes.keys().duplicate():
			var m: Node3D = _gm._messes.get(id)
			if m == null:
				continue
			_sp.global_position = m.global_position + Vector3(0, 0.1, 1.6)
			_sp.look_at(m.global_position + Vector3(0, 0.1, 0), Vector3.UP)
			_sp._fegt_bis = Time.get_ticks_msec() / 1000.0 + 0.3
			for k in 400:
				if not _gm._messes.has(id):
					break
				_gm.net_clean(id)
			await _warten(0.35)
		_ansage("9 · Müllsäcke zum Müllplatz")
		for id in _gm._packages.keys().duplicate():
			if _gm._packages[id].kind == 3:
				_gm.net_pickup_package(id)
				_gm.net_muell_abgeben()
		_sp.global_position = Vector3(-3.3, 0.1, 18.3)
		_sp.look_at(Vector3(-5, 0.4, 16.3), Vector3.UP)
		await _warten(3.0)
		_ansage("10 · Horst geht ins Büro (Schritt %d)" % _gm._quest_step)
		await _folgen(60.0)
		_ansage("Ende der Vorführung — Schritt %d" % _gm._quest_step)
		await _warten(8.0)
		get_tree().quit()
