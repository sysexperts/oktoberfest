extends Node3D
## Lisa (alte Frau) neben dem Basiskörper des Creators, Ergebnis build/blender/vergleich_frau_*.png
## godot --path . res://tools/vergleich_frau.tscn --resolution 1400x800
const Look := preload("res://scripts/charakter_look.gd")
func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 25.0; add_child(kam); kam.current = true
	var figuren: Array[Figur] = []
	var lisa: Figur = (load("res://scenes/figuren/lisa_blau.tscn") as PackedScene).instantiate()
	figuren.append(lisa)
	var l := Look.standard()
	l["hut"] = "ohne"
	figuren.append(Look.bauen(l))
	for i in figuren.size():
		figuren[i].position.x = (i - 0.5) * 0.9
		add_child(figuren[i])
	Look.faerben(figuren[1], l)
	await get_tree().process_frame
	for f in figuren:
		f.stehen()
	await get_tree().process_frame
	await get_tree().process_frame
	for a in [["ganz", 0.0, 0.85, 5.2], ["gesicht", 0.0, 1.35, 2.0], ["seite", -90.0, 1.35, 2.0]]:
		for f in figuren:
			f.rotation_degrees.y = a[1]
		kam.look_at_from_position(Vector3(0, a[2], a[3]), Vector3(0, a[2], 0))
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://build/blender/vergleich_frau_%s.png" % a[0])
	print("FERTIG")
	get_tree().quit()
