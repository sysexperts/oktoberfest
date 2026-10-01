extends Node
## Zeigt Fenster der Oberfläche bei kleinem Bildschirm und großer Oberfläche
## (Einstellung 130 %), damit man sieht, ob sie im Bild bleiben (scripts/ui/passend.gd).
## Bilder: tools/passend_<name>.png
##   godot --path . res://tools/test_passend.tscn

func _ready() -> void:
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1190, 846)
	get_tree().root.content_scale_size = Vector2i(1108, 623)
	await _warte(20)
	var hilfe: CanvasLayer = load("res://scenes/ui/hilfe.tscn").instantiate()
	add_child(hilfe)
	await _warte(10)
	hilfe.visible = true
	if hilfe.has_method("oeffnen"):
		hilfe.oeffnen()
	await _warte(30)
	get_viewport().get_texture().get_image().save_png("res://tools/passend_hilfe.png")
	hilfe.visible = false
	hilfe.queue_free()
	var wahl: Control = load("res://scenes/ui/figurenwahl.tscn").instantiate()
	add_child(wahl)
	await _warte(5)
	wahl.zeigen(0, {})
	await _warte(30)
	get_viewport().get_texture().get_image().save_png("res://tools/passend_figurenwahl.png")
	print("TEST FERTIG ", get_viewport().get_visible_rect().size)
	get_tree().quit()

func _warte(n: int) -> void:
	for i in n:
		await get_tree().process_frame
