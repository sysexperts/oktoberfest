extends Node
## Dialogpergament mit echtem Text ansehen — für die Schriftfarbe und den
## Schatten. Ohne Text bleibt das Pergament im Schuss leer.
##   Godot.exe --path . res://tools/dialog_schuss.tscn
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	var grund := ColorRect.new()
	grund.color = Color(0.09, 0.07, 0.06)
	grund.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grund)
	var d: Node = load("res://scenes/ui/dialog.tscn").instantiate()
	add_child(d)
	d.visible = true
	# zeigen() braucht einen Spieler in der Welt — hier direkt die Knoten füllen
	var kasten: Control = d.get_node("Kasten")
	kasten.visible = true
	kasten.modulate.a = 1.0
	(d.get_node("%Sprecher") as Label).text = "Letzter Wille von Onkel Sepp"
	var t := d.get_node("%Text") as Label
	t.text = "Mein liebes Patenkind, wenn du das liest, bin ich schon auf der Wiesn im Himmel. Das Zelt gehoert jetzt dir."
	t.visible_ratio = 1.0
	(d.get_node("%Hinweis") as Label).text = "Linksklick weiter · Esc schliesst"
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("user://dialog_papier.png")
	get_tree().quit()
