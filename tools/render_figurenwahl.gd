extends Node
## Figurenwahl-Fenster als Bild: build/figurenwahl.png
func _ready() -> void:
	var s: Control = load("res://scenes/ui/figurenwahl.tscn").instantiate()
	add_child(s)
	s.visible = true
	for i in 6: await get_tree().process_frame
	(s.find_child("Raster", true, false).get_child(4) as Button).button_pressed = true
	for i in 6: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://build/figurenwahl.png"))
	get_tree().quit()
