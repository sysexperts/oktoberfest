extends Node
## Rendert das Hauptmenü in allen drei Sprachen plus Koop- und Credits-Panel.
## Läuft als Szene (nicht per --script), damit die Autoloads aktiv sind.
## Aufruf: godot --path . res://tools/render_menu.tscn --resolution 1280x720

func _ready() -> void:
	var menu: Control = load("res://scenes/ui/hauptmenue.tscn").instantiate()
	add_child(menu)
	for lang in ["de", "en", "tr"]:
		Einstellungen.sprache = lang
		Einstellungen.anwenden()   # löst auch die Platzhaltertexte neu aus
		await _bild("menu_%s" % lang)
	# Längste Texte stehen im Türkischen — dort die Panels prüfen
	menu._zeige(menu.get_node("%KoopPanel"))
	await _bild("menu_koop_tr")
	menu._zeige(menu.get_node("%CreditsPanel"))
	await _bild("menu_credits_tr")
	# Einstellung nicht dauerhaft verändern — nur zurücksetzen, nicht speichern
	Einstellungen.sprache = "auto"
	Einstellungen.anwenden()
	print("RENDER FERTIG")
	get_tree().quit()

func _bild(name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
	print("  gespeichert: ", name)
