extends Node
## Prüft, ob die Anzeigemodi aus den Einstellungen wirklich ankommen: setzt jeden
## Modus, wartet ein paar Bilder und gibt Modus, Größe und Rand aus.
##   godot --path . res://tools/test_anzeige.tscn   (mit Fenster, nicht --headless)

func _ready() -> void:
	await _warte(20)
	for ablauf in [["fenster", Vector2i(1280, 720)], ["vollbild", Vector2i.ZERO], ["fenster", Vector2i(1600, 900)],
			["exklusiv", Vector2i.ZERO], ["fenster", Vector2i(1280, 720)], ["vollbild", Vector2i.ZERO]]:
		Einstellungen.modus = ablauf[0]
		if ablauf[1] != Vector2i.ZERO:
			Einstellungen.fenster_groesse = ablauf[1]
		Einstellungen.anwenden()
		await _warte(30)
		print("%-9s -> Modus %d · Größe %s · Position %s · Rand %s · Vollbild-Flag %s" % [ablauf[0],
			DisplayServer.window_get_mode(), DisplayServer.window_get_size(), DisplayServer.window_get_position(),
			not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS), Einstellungen.vollbild])
	# Wie im Spiel: über das Einstellungsmenü und seine Auswahlliste
	var menue: CanvasLayer = load("res://scenes/ui/einstellungen.tscn").instantiate()
	add_child(menue)
	await _warte(20)
	var wahl: OptionButton = menue.get_node("%Modus")
	for index in [2, 0, 1, 2, 0]:
		wahl.select(index)
		wahl.item_selected.emit(index)
		await _warte(30)
		print("Liste %d -> Modus %d · Größe %s · Einstellung %s" % [index, DisplayServer.window_get_mode(),
			DisplayServer.window_get_size(), Einstellungen.modus])
	print("TEST FERTIG")
	get_tree().quit()

func _warte(n: int) -> void:
	for i in n:
		await get_tree().process_frame
