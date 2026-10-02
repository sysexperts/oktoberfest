extends Node3D
## Köpfe der Lisa-Varianten mit Zubehör von vorn und schräg: build/vorschau_zubehoer.png
const FIG := [preload("res://scenes/figuren/lisa_blau.tscn"), preload("res://scenes/figuren/lisa_gruen.tscn"), preload("res://scenes/figuren/lisa_lila.tscn")]
func _ready() -> void:
	var v := SubViewport.new()
	v.size = Vector2i(900, 600)
	v.own_world_3d = true
	v.msaa_3d = Viewport.MSAA_4X
	v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(v)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.2, 0.26)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.93, 0.82)
	env.ambient_light_energy = 0.8
	we.environment = env
	v.add_child(we)
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-25, 35, 0)
	v.add_child(l)
	var k := Camera3D.new()
	k.fov = 30
	v.add_child(k)
	k.current = true
	var bilder: Array[Image] = []
	for sc in FIG:
		var f := sc.instantiate() as Figur
		v.add_child(f)
		for i in 4: await get_tree().process_frame
		f.stehen()
		for i in 25: await get_tree().process_frame
		var h := 1.6
		var b := f.skelett.find_bone("Head")
		if b >= 0:
			h = (f.skelett.global_transform * f.skelett.get_bone_global_pose(b).origin).y
		for winkel in [0.0, 50.0]:
			f.rotation_degrees.y = winkel
			k.look_at_from_position(Vector3(0, h + 0.1, 2.0), Vector3(0, h + 0.02, 0))
			for i in 3: await get_tree().process_frame
			var im := v.get_texture().get_image(); im.convert(Image.FORMAT_RGBA8); bilder.append(im)
		f.queue_free()
		await get_tree().process_frame
	var w := Image.create(900 * 2, 600 * 3, false, Image.FORMAT_RGBA8)
	for i in bilder.size():
		w.blit_rect(bilder[i], Rect2i(0, 0, 900, 600), Vector2i((i % 2) * 900, (i / 2) * 600))
	w.resize(1200, 1200)
	w.save_png(ProjectSettings.globalize_path("res://build/vorschau_zubehoer.png"))
	get_tree().quit()
