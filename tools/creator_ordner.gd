extends Node3D
## Zeigt alle Szenen eines Ordners (scenes/creator/<ordner>/*.tscn) als Zubehör auf dem Standardkörper,
## eingefärbt mit den Haarfarben. Aufruf:
## godot --path . res://tools/creator_ordner.tscn --resolution 3000x900 -- frisuren_q
const Assets := preload("res://scripts/creator_assets.gd")

func _ready() -> void:
	var ordner := "frisuren_q"
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		ordner = args[0]
	var pfade: Array[String] = []
	for d in DirAccess.get_files_at("res://scenes/creator/%s" % ordner):
		if d.ends_with(".tscn"):
			pfade.append("res://scenes/creator/%s/%s" % [ordner, d])
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 24.0; add_child(kam); kam.current = true
	var n := pfade.size()
	var figuren: Array[Figur] = []
	for i in n:
		var f: Figur = (load("res://scenes/figuren/%s.tscn" % ("basis" if ordner in ["augen", "emotionen"] else "standard")) as PackedScene).instantiate()
		var z: Array[PackedScene] = [load(pfade[i])]
		if ordner == "emotionen":
			z.append(Assets.AUGEN[0]["szene"])
		f.zubehoer = z
		f.position = Vector3((i - (n - 1) * 0.5) * 0.7, 0, 0)
		add_child(f)
		figuren.append(f)
	await get_tree().process_frame
	for i in n:
		figuren[i].stehen()
		if ordner == "brillen":
			Assets.faerben(figuren[i], Assets.BRILLEN[(i + 1) % Assets.BRILLEN.size()]["farbe"])
	await get_tree().process_frame
	await get_tree().process_frame
	for a in [["vorn", 0.0], ["seite", -90.0], ["schraeg", -40.0], ["nah", 0.0]]:
		for f in figuren:
			f.rotation_degrees.y = a[1]
		kam.look_at_from_position(Vector3(0, 1.5, (5.0 + n * 0.5) if a[0] != "nah" else 2.2), Vector3(0, 1.5 if a[0] != "nah" else 1.3, 0))
		await get_tree().process_frame
		await get_tree().process_frame
		var bild := get_viewport().get_texture().get_image()
		bild.get_region(Rect2i(0, int(bild.get_height() * 0.18), bild.get_width(), int(bild.get_height() * 0.5))).save_png("res://build/blender/%s_%s.png" % [ordner, a[0]])
	print("FERTIG")
	get_tree().quit()
