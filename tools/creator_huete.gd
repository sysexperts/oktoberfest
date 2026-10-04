extends Node3D
## Zeigt alle Creator-Hüte (scripts/creator_assets.gd) auf dem Standardkörper, in ihrer Standardfarbe.
## godot --path . res://tools/creator_huete.tscn --resolution 1800x500
const Assets := preload("res://scripts/creator_assets.gd")

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 24.0; add_child(kam); kam.current = true
	var n := Assets.HUETE.size()
	var figuren: Array[Figur] = []
	for i in n:
		var f: Figur = (load("res://scenes/figuren/standard.tscn") as PackedScene).instantiate()
		var z: Array[PackedScene] = []
		if Assets.HUETE[i]["szene"] != null:
			z.append(Assets.laden(Assets.HUETE[i]))
		f.zubehoer = z
		f.position = Vector3((i - (n - 1) * 0.5) * 0.62, 0, 0)
		add_child(f)
		figuren.append(f)
	await get_tree().process_frame
	for i in n:
		figuren[i].stehen()
		Assets.faerben(figuren[i], Assets.HUETE[i]["farbe"])
	await get_tree().process_frame
	await get_tree().process_frame
	for a in [["vorn", 0.0], ["seite", -90.0]]:
		for f in figuren:
			f.rotation_degrees.y = a[1]
		kam.look_at_from_position(Vector3(0, 1.4, 11.0), Vector3(0, 1.4, 0))
		await get_tree().process_frame
		await get_tree().process_frame
		var bild := get_viewport().get_texture().get_image()
		bild.save_png("res://build/blender/huete_%s.png" % a[0])
		var b := bild.get_width()
		var h := bild.get_height()
		bild.get_region(Rect2i(0, int(h * 0.36), b, int(h * 0.22))).save_png("res://build/blender/huete_%s_kopf.png" % a[0])
	print("FERTIG")
	get_tree().quit()
