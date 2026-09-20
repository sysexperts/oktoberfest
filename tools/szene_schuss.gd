extends Node
## Screenshot einer beliebigen UI-Szene — zum Vergleichen von Entwuerfen.
## Viele Oberflaechen stehen in der Szene auf visible = false, weil sie im Spiel
## erst eingeblendet werden; fuer den Schuss wird das aufgehoben.
##
##   Godot.exe --path . res://tools/szene_schuss.tscn -- <szene> <name> [sekunden]
##   → user://<name>.png

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var pfad: String = args[0] if args.size() > 0 else "res://scenes/ui/hauptmenue.tscn"
	var name: String = args[1] if args.size() > 1 else "szene"
	var warten: float = float(args[2]) if args.size() > 2 else 1.0
	get_window().size = Vector2i(1280, 800)
	# Dunkler Grund, damit halbdurchsichtige Oberflaechen nicht vor Grau stehen
	var grund := ColorRect.new()
	grund.color = Color(0.09, 0.07, 0.06)
	grund.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(grund)
	var szene: Node = load(pfad).instantiate()
	add_child(szene)
	_sichtbar(szene)
	var t := 0.0
	while t < warten:
		await get_tree().process_frame
		t += get_process_delta_time()
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("gespeichert %s.png" % name)
	get_tree().quit()

## Wurzel und Panels einblenden. Geschwister-Panels, die sich im Spiel
## gegenseitig ausschliessen, bleiben aus — sonst liegen sie uebereinander.
func _sichtbar(n: Node) -> void:
	if n is CanvasItem:
		(n as CanvasItem).visible = true
	elif n is CanvasLayer:
		(n as CanvasLayer).visible = true
