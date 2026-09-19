extends SceneTree
## Rendert das animierte Logo und speichert nach Sekunden Screenshots,
## um Aufbau/Animation zu prüfen: user://logo_1.png (Auftritt) und _2.png (Ruhe).
func _init() -> void:
	get_root().set_size(Vector2i(900, 480))
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.16)
	bg.size = Vector2(900, 480)
	get_root().add_child(bg)
	var logo: Control = load("res://scenes/ui/logo_animiert.tscn").instantiate()
	logo.scale = Vector2(0.5, 0.5)
	logo.position = Vector2(50, 20)
	get_root().add_child(logo)
	await _warte(0.6)
	_schuss("logo_auftritt.png")
	await _warte(2.0)
	_schuss("logo_ruhe.png")
	quit()

func _warte(s: float) -> void:
	var t := 0.0
	while t < s:
		await process_frame
		t += get_root().get_process_delta_time()

func _schuss(name: String) -> void:
	var img := get_root().get_texture().get_image()
	img.save_png("user://%s" % name)
	print("gespeichert ", name)
