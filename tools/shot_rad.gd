extends SceneTree
## Yardımcı araç: dönme dolabı gerçekten render edip PNG olarak kaydeder.
## Sahne ağacını kontrol etmek yetmedi — bu sefer göze bakıyoruz.
## Kullanım: godot --path . --script res://tools/shot_rad.gd  (headless DEĞİL)

func _init() -> void:
	root.call_deferred("add_child", _bau())
	_warten()

func _bau() -> Node3D:
	var w := Node3D.new()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.03, 0.03, 0.07)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.3, 0.32, 0.45)
	e.ambient_light_energy = 0.15
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_hdr_threshold = 1.0
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	w.add_child(env)
	var rad := (load("res://scenes/props/riesenrad.tscn") as PackedScene).instantiate()
	w.add_child(rad)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 11, 34)
	cam.look_at_from_position(Vector3(0, 11, 34), Vector3(0, 11, 0), Vector3.UP)
	cam.current = true
	w.add_child(cam)
	return w

func _warten() -> void:
	await process_frame
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("res://tools/rad_shot.png")
	print("Bild gespeichert: tools/rad_shot.png")
	quit()
