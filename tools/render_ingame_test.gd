extends Node
## Fotografiert den Ingame-UI-Test (scenes/ui/ingame_test.tscn): HUD, Ereignis-Band,
## Wiesenbüro auf Pergament mit echten (übersetzbaren) Texten über einem Spielbild.
## Aufruf: godot --path . res://tools/render_ingame_test.tscn --resolution 1600x900
## Bild: tools/ingame_test.png (nicht im Git)

func _ready() -> void:
	add_child(preload("res://scenes/ui/ingame_test.tscn").instantiate())
	for k in 20:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/ingame_test.png")
	print("RENDER FERTIG")
	get_tree().quit()
