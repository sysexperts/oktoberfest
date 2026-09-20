extends Node
## Kontaktbogen aller Symbole — zum Prüfen, ob sie einheitlich wirken.
##   Godot.exe --path . res://tools/symbol_blatt.tscn
func _ready() -> void:
	get_window().size = Vector2i(900, 560)
	var grund := ColorRect.new()
	grund.color = Color(0.09, 0.07, 0.06)
	grund.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grund)
	var gitter := GridContainer.new()
	gitter.columns = 8
	gitter.add_theme_constant_override("h_separation", 14)
	gitter.add_theme_constant_override("v_separation", 14)
	gitter.position = Vector2(24, 24)
	add_child(gitter)
	var d := DirAccess.open("res://assets/ui/symbole")
	for f: String in d.get_files():
		if not f.ends_with(".svg"):
			continue
		var sp := VBoxContainer.new()
		var t := TextureRect.new()
		t.texture = load("res://assets/ui/symbole/%s" % f)
		t.custom_minimum_size = Vector2(48, 48)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sp.add_child(t)
		var l := Label.new()
		l.text = f.get_basename()
		l.add_theme_font_size_override("font_size", 12)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sp.add_child(l)
		gitter.add_child(sp)
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://symbole.png")
	get_tree().quit()
