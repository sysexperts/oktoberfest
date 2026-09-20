extends Node
## Zeigt Ruhe- und Hover-Zustand nebeneinander: der Hover laesst sich in einem
## Schuss nicht mit der Maus ausloesen, deshalb wird der Stil direkt gesetzt.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	var p: CanvasLayer = load("res://scenes/ui/pause.tscn").instantiate()
	add_child(p)
	p.visible = true
	await _warte(0.6)
	var k := _knoepfe(p)
	# Zweiter und vierter Knopf bekommen den Hover-Stil zum Vergleich
	var thema: Theme = load("res://assets/ui/menue_theme.tres")
	for i in [1, 3]:
		if i < k.size():
			k[i].add_theme_stylebox_override("normal", thema.get_stylebox("hover", "Button"))
			k[i].add_theme_color_override("font_color", thema.get_color("font_hover_color", "Button"))
	await _warte(0.4)
	get_viewport().get_texture().get_image().save_png("user://hover_vergleich.png")
	print("gespeichert hover_vergleich.png")
	get_tree().quit()

func _knoepfe(n: Node) -> Array[Button]:
	var liste: Array[Button] = []
	for c in n.get_children():
		if c is Button:
			liste.append(c)
		liste.append_array(_knoepfe(c))
	return liste

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
