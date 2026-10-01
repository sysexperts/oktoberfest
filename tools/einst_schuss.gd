extends Node
## Zeigt die Einstellungen ueber dem Hauptmenue — so sieht man sie im echten
## Umfeld. Zweiter Schuss auf dem Ton-Reiter, damit man Regler und Schalter sieht.
##   Godot.exe --path . res://tools/einst_schuss.tscn → tools/einst_<Reiter>.png
func _ready() -> void:
	get_window().size = Vector2i(1024, 600)
	# Feste Sprache: sonst haengt das Bild an der Systemsprache des Rechners
	Einstellungen.sprache = "de"
	Einstellungen.anwenden()
	add_child(load("res://scenes/ui/hauptmenue.tscn").instantiate())
	await _warte(9.0)
	_schuss("menue_haupt")
	var e: CanvasLayer = load("res://scenes/ui/einstellungen.tscn").instantiate()
	add_child(e)
	await _warte(0.8)
	# Jeder Reiter einmal, bei mehreren Oberflächengrößen — die Lage von Kategorien
	# und Seite muss auf allen Reitern gleich bleiben (sonst wirken die Reiter versetzt)
	var reiter: TabContainer = e.get_node("Rahmen/Spalte/Inhalt/Reiter")
	for basis: Vector2i in [Vector2i(1100, 620), Vector2i(1440, 810), Vector2i(1920, 1080)]:
		get_tree().root.content_scale_size = basis
		for i in reiter.get_tab_count():
			reiter.current_tab = i
			(e.get_node("Rahmen/Spalte/Inhalt/Kategorien/Kat%d" % i) as Button).button_pressed = true
			await _warte(0.4)
			if basis == Vector2i(1440, 810):
				_schuss("einst_%d" % i)
			print("%s Reiter %d: Kat0 %s · Kat3 %s · Seite %s" % [basis, i, (e.get_node("Rahmen/Spalte/Inhalt/Kategorien/Kat0") as Control).get_global_rect().position,
				(e.get_node("Rahmen/Spalte/Inhalt/Kategorien/Kat3") as Control).get_global_rect().position, reiter.get_global_rect()])
	get_tree().quit()

func _schuss(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
	print("gespeichert %s.png" % name)

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
