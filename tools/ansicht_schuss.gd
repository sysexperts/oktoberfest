extends Node
## Öffnet die Animationen-Ansicht, wählt einen Clip und speichert ein Bild (build/blender/ansicht.png).
## godot --path . res://tools/ansicht_schuss.tscn --resolution 1600x900 -- mixamo/Sitting_Drinking
func _ready() -> void:
	var a := (load("res://scenes/werkzeuge/animationen_ansicht.tscn") as PackedScene).instantiate()
	add_child(a)
	for i in 20:
		await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		a.get_node("%Suche").text = args[0].get_file()
		a.call("_liste_fuellen")
		a.get_node("%Clips").select(0)
		a.call("_gewaehlt", 0)
	for i in 50:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/blender/ansicht.png")
	print("FERTIG")
	get_tree().quit()
