extends Node
## Listet die direkten Kinder des Hauptmenues in Zeichenreihenfolge auf und
## meldet, welche davon die Eck-Knoepfe ueberdecken und dabei Maus-Events
## abfangen (mouse_filter STOP). Spaeter im Baum = liegt oben.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	var menue: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menue)
	await _warte(1.2)
	var kinder := menue.get_children()
	var ecke_i := kinder.find(menue.get_node("Ecke"))
	var ziel: Rect2 = menue.get_node("Ecke/Einstellungen").get_global_rect()
	print("Ecke steht an Position %d von %d" % [ecke_i, kinder.size()])
	for i in kinder.size():
		var c := kinder[i] as Control
		if c == null:
			continue
		var filter: String = ["STOP", "PASS", "IGNORE"][c.mouse_filter]
		var ueber := i > ecke_i and c.get_global_rect().intersects(ziel)
		print("  %d %-14s filter=%-6s %s" % [i, c.name, filter,
			"FAENGT KLICKS AB" if (ueber and c.mouse_filter == 0) else ("liegt drueber, laesst durch" if ueber else "")])
	get_tree().quit()

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
