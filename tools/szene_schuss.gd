extends Node
## Screenshot einer beliebigen UI-Szene — zum Vergleichen von Entwürfen.
##
##   Godot.exe --path . res://tools/szene_schuss.tscn -- <szene> <name> [sekunden]
##   → user://<name>.png

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var pfad: String = args[0] if args.size() > 0 else "res://scenes/ui/menue_design_test.tscn"
	var name: String = args[1] if args.size() > 1 else "szene"
	var warten: float = float(args[2]) if args.size() > 2 else 2.6
	get_window().size = Vector2i(1280, 800)
	add_child(load(pfad).instantiate())
	var t := 0.0
	while t < warten:
		await get_tree().process_frame
		t += get_process_delta_time()
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("gespeichert %s.png" % name)
	get_tree().quit()
