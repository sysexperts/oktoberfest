extends Node
## Zeigt den Ladebildschirm mit einer schweren Zielszene und schiesst zweimal,
## damit man den Balken bei Teilfortschritt und kurz vor Schluss sieht.
##   Godot.exe --path . res://tools/lade_schuss.tscn → user://lade_1/2.png
func _ready() -> void:
	get_window().size = Vector2i(1280, 800)
	Net.ziel_szene = "res://scenes/ui/menue_hintergrund.tscn"
	add_child(load("res://scenes/ui/ladebildschirm.tscn").instantiate())
	await _warte(0.45)
	_schuss("lade_1")
	await _warte(0.35)
	_schuss("lade_2")
	get_tree().quit()

func _schuss(name: String) -> void:
	get_viewport().get_texture().get_image().save_png("user://%s.png" % name)
	print("gespeichert %s.png" % name)

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await get_tree().process_frame
		t += get_process_delta_time()
