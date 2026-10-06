extends Node3D
## Berufskleidung: je Beruf ein Mann und eine Frau (build/beruf_blatt.png, beruf_blatt_nah.png)
const Figuren := preload("res://scripts/figuren.gd")
const BERUFE := ["koch", "kellner", "zapfer", "reinigung", "security", "bude", "kuenstler"]
const NAMEN := ["KOCH", "KELLNER", "ZAPFER", "REINIGUNG", "SECURITY", "BUDENBESITZER", "KÜNSTLER"]

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	for r in 2:
		for i in BERUFE.size():
			var gesucht := "m" if r == 0 else "w"
			var id := 1
			while Figuren.npc_look_beruf(id, BERUFE[i])["geschlecht"] != gesucht:
				id += 1
			var h := Node3D.new()
			h.position = Vector3((i - 3) * 0.85, -r * 1.7, 0)
			var m := Node3D.new(); m.name = "Model"; h.add_child(m)
			add_child(h)
			var f := Figuren.einsetzen_beruf(h, id, BERUFE[i])
			f.stehen()
			if r == 1:
				var lb := Label3D.new()
				lb.text = NAMEN[i]
				lb.font_size = 30
				lb.pixel_size = 0.0035
				lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lb.no_depth_test = true
				lb.position = Vector3(0, -0.12, 0.3)
				h.add_child(lb)
	kam.position = Vector3(0, -0.8, 13.0)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/beruf_blatt.png")
	kam.position = Vector3(-1.7, 1.1, 3.4)
	kam.look_at(Vector3(-1.7, 0.9, 0))
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/beruf_blatt_nah.png")
	kam.position = Vector3(0.9, 1.1, 3.4)
	kam.look_at(Vector3(0.9, 0.9, 0))
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/beruf_blatt_nah2.png")
	print("FERTIG")
	get_tree().quit()
