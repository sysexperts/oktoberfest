extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Vorführung: Zelt jeden Morgen am Eingang eröffnen, erst dann kommen Gäste und Leute in Konrads Zelt.
## Lädt Spielstand Platz 3 (ohne Überschreiben, es wird nicht gespeichert), die Kamera wird vom Bot gesetzt.
##   godot --path . res://tools/vorfuehrung_eroeffnung.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _text: Label
	var _gm: Node
	var _sp: Node3D

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
		_gm = await Spielstart.starten(self, false, 3)
		if _gm == null:
			return
		TranslationServer.set_locale("de")
		_sp = _gm._players_nodes.get(1)
		await _ablauf()

	func _ansage(s: String) -> void:
		_text.text = s
		print("VORFUEHRUNG: ", s)

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _blick(von: Vector3, nach: Vector3) -> void:
		_sp.global_position = Vector3(von.x, 0.1, von.z)
		_sp.look_at(nach, Vector3.UP)
		_sp._head.rotation.x = 0.0

	func _ablauf() -> void:
		var kino = _gm.get_node_or_null("Kino")
		while kino and kino.aktiv:
			kino._weiter()
			await _warten(0.3)
		var fass: Node3D = get_tree().get_first_node_in_group("zelt_eroeffnung")
		var konrad: Node3D = get_tree().get_first_node_in_group("huber_zelt")
		_ansage("1 · Neuer Tag: Zelt ist zu (Phase %d, offen: %s)" % [_gm._phase, str(_gm._zelt_offen)])
		if _gm._phase != _gm.Phase.SHIFT:
			_gm._start_shift()
		_gm._zelt_offen = false   # Spielstand kann vom letzten Lauf offen gespeichert sein
		_gm._eroeffnung_anzeigen()
		await _warten(2.0)
		_ansage("2 · Morgens: Zelt zu, Fass am Eingang wartet (offen: %s)" % str(_gm._zelt_offen))
		if fass:
			_blick(fass.global_position + Vector3(0, 0, 4.0), fass.global_position + Vector3(0, 1.0, 0))
		await _warten(5.0)
		_ansage("3 · Konrads Zelt von außen: noch keine Leute")
		if konrad:
			_blick(konrad.global_position + Vector3(0, 0, 18.0), konrad.global_position + Vector3(0, 1.5, 0))
		await _warten(6.0)
		_ansage("4 · Eröffnen am Eingang (E am Fass)")
		if fass:
			_blick(fass.global_position + Vector3(0, 0, 4.0), fass.global_position + Vector3(0, 1.0, 0))
		await _warten(2.0)
		_gm.net_zelt_eroeffnen()
		await _warten(5.0)
		_ansage("5 · Zelt offen: Gäste kommen (offen: %s)" % str(_gm._zelt_offen))
		_blick(Vector3(0, 0, 12), Vector3(0, 1.0, 0))
		await _warten(12.0)
		_ansage("6 · Konrads Zelt jetzt mit Leuten")
		if konrad:
			_blick(konrad.global_position + Vector3(0, 0, 18.0), konrad.global_position + Vector3(0, 1.5, 0))
		await _warten(8.0)
		_ansage("Ende der Vorführung")
		await _warten(3.0)
		get_tree().quit()
