extends Node
## Startet das echte Hauptmenü (mit Autoloads) und speichert einen Screenshot
## nach ein paar Sekunden nach user://menue.png — zur Layoutkontrolle.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	var menue: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menue)
	await _warte(2.5)
	var logo := menue.get_node("Mitte/Hauptspalte/LogoBox/Logo")
	for n in logo.get_children():
		var c: Control = n
		print("%s sichtbar=%s a=%.2f pos=%s groesse=%s" % [c.name, c.visible, c.modulate.a, c.position, c.size])
	print("Logo scale=%s pos=%s boxgroesse=%s" % [logo.scale, logo.position, logo.get_parent().size])
	var img := get_viewport().get_texture().get_image()
	img.save_png("user://menue.png")
	# Ausschnitt um das Logo, dreifach vergrößert — zur Sichtkontrolle
	var box: Control = logo.get_parent()
	var r := Rect2i(box.global_position - Vector2(20, 20), box.size + Vector2(40, 40))
	var aus := img.get_region(r.intersection(Rect2i(Vector2i.ZERO, img.get_size())))
	aus.resize(aus.get_width() * 3, aus.get_height() * 3, Image.INTERPOLATE_NEAREST)
	aus.save_png("user://menue_logo.png")
	print("menue-screenshot gespeichert")
	get_tree().quit()

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
