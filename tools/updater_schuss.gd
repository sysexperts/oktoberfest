extends Node
## Zeigt die Updater-Oberflaeche in ihren Zustaenden: Suche (ohne Balken) und
## laufender Download. Echte Bytes gibt es hier nicht, also eingespeist.
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	var ui: Control = load("res://scenes/ui/updater.tscn").instantiate()
	add_child(ui)
	await _warte(0.6)
	ui.status(tr("STATUS_UPDATE_SEARCH"))
	await _warte(0.3)
	_schuss("updater_1")
	ui.status(tr("STATUS_UPDATE_LOAD") % 196)
	ui.fortschritt_an()
	ui.fortschritt(int(302 * 1024 * 1024), int(815 * 1024 * 1024))
	await _warte(0.3)
	_schuss("updater_2")
	get_tree().quit()

func _schuss(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("gespeichert %s.png" % name)

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
