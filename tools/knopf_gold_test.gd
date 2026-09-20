extends Node
## Vergleich am Pausemenue und Hauptmenue: alle Knoepfe ruhig, oder ruhig mit
## einer goldenen Hauptaktion. Gold als Akzent statt als Grundfarbe.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	for haupt_gold in [false, true]:
		var p: CanvasLayer = load("res://scenes/ui/pause.tscn").instantiate()
		add_child(p)
		p.visible = true
		await _warte(0.5)
		if haupt_gold:
			var k := _knoepfe(p)
			if not k.is_empty():
				k[0].theme_type_variation = "GoldKnopf"
		await _warte(0.4)
		_schuss("pause_ruhig_gold" if haupt_gold else "pause_ruhig")
		p.queue_free()
		await _warte(0.2)
	var m: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(m)
	await _warte(2.2)
	(m.get_node("Mitte/Hauptspalte/Weiterspielen") as Button).theme_type_variation = "GoldKnopf"
	await _warte(0.4)
	_schuss("menue_ruhig_gold")
	get_tree().quit()

func _knoepfe(n: Node) -> Array[Button]:
	var liste: Array[Button] = []
	for k in n.get_children():
		if k is Button:
			liste.append(k)
		liste.append_array(_knoepfe(k))
	return liste

func _schuss(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("gespeichert %s.png" % name)

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
