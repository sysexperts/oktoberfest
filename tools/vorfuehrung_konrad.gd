extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Vorführung: Konrads Zelt (Eingang, Kochtresen, Tanzfläche) und das Casino. Spielstand Platz 3.
##   godot --path . res://tools/vorfuehrung_konrad.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var _text: Label
	var _sp: Node3D
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	var _nr := 0
	func _ansage(s: String) -> void:
		_text.text = s
		print("VORFUEHRUNG: ", s)
	func _bild() -> void:
		_nr += 1
		var dir := OS.get_environment("SHOT_DIR")
		if dir != "":
			get_viewport().get_texture().get_image().save_png("%s/konrad_%d.png" % [dir, _nr])
	func _blick(von: Vector3, nach: Vector3) -> void:
		_sp.global_position = Vector3(von.x, 0.1, von.z)
		_sp.look_at(nach, Vector3.UP)
		_sp._head.rotation.x = 0.0
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
		var gm := await Spielstart.starten(self, false, 3)
		if gm == null:
			return
		TranslationServer.set_locale("de")
		_sp = gm._players_nodes.get(1)
		var kino = gm.get_node_or_null("Kino")
		while kino and kino.aktiv:
			kino._weiter()
			await _warten(0.3)
		if gm._phase != gm.Phase.SHIFT:
			gm._start_shift()
		gm._zelt_offen = true
		await _warten(8.0)
		var zelt: Node3D = get_tree().get_first_node_in_group("huber_zelt")
		var z0 := zelt.global_position
		_ansage("1 · Konrads Zelt von außen (offen: %s)" % str(gm.konrad_leute_da()))
		_blick(z0 + Vector3(0, 0, 20), z0 + Vector3(0, 2, 0))
		await _warten(6.0)
		_bild()
		await _warten(1.0)
		_ansage("2 · Konrads Zelt innen: Gäste, Personal")
		_blick(z0 + Vector3(0, 0, 8), z0 + Vector3(0, 1.2, -8))
		await _warten(7.0)
		_bild()
		await _warten(1.0)
		var koch: Node3D = null
		for n in zelt.find_children("*", "Node3D", true, false):
			if String(n.name).begins_with("Kochtheke"):
				koch = n
				break
		if koch:
			_ansage("3 · Kochtresen")
			_blick(koch.global_position + Vector3(0, 0, 4), koch.global_position + Vector3(0, 1.0, 0))
			await _warten(7.0)
			_bild()
			await _warten(1.0)
		var casino: Node3D = null
		for n in zelt.find_children("*", "Node3D", true, false):
			if String(n.name).to_lower().begins_with("casino"):
				casino = n
				break
		if casino:
			_ansage("4 · Casino hinter Konrads Zelt")
			_blick(casino.global_position + Vector3(0, 0, 7), casino.global_position + Vector3(0, 1.0, 0))
			await _warten(7.0)
			_bild()
			await _warten(1.0)
		_ansage("Ende der Vorführung")
		await _warten(3.0)
		get_tree().quit()
