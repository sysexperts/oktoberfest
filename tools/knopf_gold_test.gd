extends Node
## Zeigt das Pausemenue mit den beiden goldenen Knopfvarianten zum Vergleich.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	for paar in [["GoldKnopf", "pause_gold"], ["SchimmerKnopf", "pause_schimmer"]]:
		var p: CanvasLayer = load("res://scenes/ui/pause.tscn").instantiate()
		add_child(p)
		p.visible = true
		await _warte(0.5)
		for n in _knoepfe(p):
			n.theme_type_variation = paar[0]
		await _warte(0.4)
		get_viewport().get_texture().get_image().save_png("user://%s.png" % paar[1])
		print("gespeichert %s.png" % paar[1])
		p.queue_free()
		await _warte(0.2)
	get_tree().quit()

func _knoepfe(n: Node) -> Array[Button]:
	var liste: Array[Button] = []
	for k in n.get_children():
		if k is Button:
			liste.append(k)
		liste.append_array(_knoepfe(k))
	return liste

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
