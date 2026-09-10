extends Node
## Rendert Einstellungs- und Pausemenü in allen drei Sprachen.
## Speichert nichts dauerhaft: Menüs werden per queue_free entfernt statt über
## schliessen() (das würde die Einstellungen schreiben).
## Aufruf: godot --path . res://tools/render_ui.tscn --resolution 1280x720

func _ready() -> void:
	# Das Pausemenü hält den Baum an — dieser Knoten muss trotzdem weiterlaufen.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var sprache_vorher := Einstellungen.sprache

	for lang in ["de", "en", "tr"]:
		_sprache(lang)
		var m: CanvasLayer = load("res://scenes/ui/einstellungen.tscn").instantiate()
		add_child(m)
		await _frames(3)
		var reiter: TabContainer = m.get_node("%Reiter")
		for i in reiter.get_tab_count():
			reiter.current_tab = i
			await _bild("set_%s_%d" % [lang, i])
		m.queue_free()
		await _frames(2)

	var p: CanvasLayer = load("res://scenes/ui/pause.tscn").instantiate()
	add_child(p)
	await _frames(2)
	Net.solo = true
	for lang in ["de", "en", "tr"]:
		_sprache(lang)
		p.oeffnen()
		await _bild("pause_%s" % lang)
		_pause_zu(p)
	_sprache("de")
	Net.solo = false
	p.oeffnen()
	await _bild("pause_koop_de")
	_pause_zu(p)

	Einstellungen.sprache = sprache_vorher
	Einstellungen.anwenden()
	print("RENDER FERTIG")
	get_tree().quit()

## Ohne schliessen(), damit der Mauszeiger nicht gefangen wird.
func _pause_zu(p: CanvasLayer) -> void:
	p.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _sprache(lang: String) -> void:
	Einstellungen.sprache = lang
	Einstellungen.anwenden()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _bild(name: String) -> void:
	await _frames(4)
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name)
	print("  gespeichert: ", name)
