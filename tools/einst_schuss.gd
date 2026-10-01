extends Node
## Zeigt die Einstellungen ueber dem Hauptmenue — so sieht man sie im echten
## Umfeld. Zweiter Schuss auf dem Ton-Reiter, damit man Regler und Schalter sieht.
##   Godot.exe --path . res://tools/einst_schuss.tscn → tools/einst_<Reiter>.png
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	# Feste Sprache: sonst haengt das Bild an der Systemsprache des Rechners
	Einstellungen.sprache = "de"
	Einstellungen.anwenden()
	add_child(load("res://scenes/ui/hauptmenue.tscn").instantiate())
	await _warte(9.0)
	_schuss("menue_haupt")
	var e: CanvasLayer = load("res://scenes/ui/einstellungen.tscn").instantiate()
	add_child(e)
	await _warte(0.8)
	# Jeder Reiter einmal — so fallen versetzte Seiten und fehlende Titel auf
	var reiter: TabContainer = e.get_node("Rahmen/Spalte/Inhalt/Reiter")
	for i in reiter.get_tab_count():
		reiter.current_tab = i
		(e.get_node("Rahmen/Spalte/Inhalt/Kategorien/Kat%d" % i) as Button).button_pressed = true
		await _warte(0.5)
		_schuss("einst_%d" % i)
	get_tree().quit()

func _schuss(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
	print("gespeichert %s.png" % name)

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
