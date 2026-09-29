extends Node3D
## Rendert Figur-Szenen nebeneinander von vorn und schräg — zum Prüfen von
## Varianten (Kleidung, Hut, Bart, Brille).
## Aufruf: godot --path . res://tools/render_varianten.tscn --resolution 1600x900 -- res://scenes/figuren/a.tscn res://scenes/figuren/b.tscn
## Optional "rolle=tanzen" (stehen, gehen, rennen, tanzen, sitzen, extra,
## torkeln) und "zeit=0.4" (Anteil der Animationslänge) — dann heißen die
## Bilder varianten_<rolle>_<ansicht>.png.

const ABSTAND := 1.1

func _ready() -> void:
	var szenen: Array[String] = []
	var rolle := ""
	var zeit := 0.4
	for a in OS.get_cmdline_user_args():
		if a.begins_with("rolle="):
			rolle = a.trim_prefix("rolle=")
		elif a.begins_with("zeit="):
			zeit = float(a.trim_prefix("zeit="))
		else:
			szenen.append(a)
	var umgebung := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.16, 0.15, 0.22)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.7, 0.75)
	env.ambient_light_energy = 0.6
	umgebung.environment = env
	add_child(umgebung)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-35, 20, 0)
	add_child(sonne)
	var figuren: Array[Figur] = []
	for i in szenen.size():
		var f := (load(szenen[i]) as PackedScene).instantiate() as Figur
		f.position = Vector3((i - (szenen.size() - 1) * 0.5) * ABSTAND, 0, 0)
		add_child(f)
		figuren.append(f)
	var kamera := Camera3D.new()
	kamera.current = true
	add_child(kamera)
	await _bilder(3)
	for f in figuren:
		match rolle:
			"gehen": f.gehen()
			"rennen": f.rennen()
			"tanzen": f.tanzen()
			"sitzen": f.sitzen()
			"extra": f.extra()
			"torkeln": f.torkeln()
			_: f.stehen()
		if rolle != "" and f.anim and f.anim.current_animation != "":
			f.anim.seek(f.anim.current_animation_length * zeit, true)
			f.anim.speed_scale = 0.0
	await _bilder(20)
	var breite := (szenen.size() - 1) * ABSTAND
	for ansicht in [["vorn", Vector3(0, 1.2, 1.6 + breite * 0.9), 1.0], ["kopf", Vector3(0, 1.45, 0.6 + breite * 0.45), 1.4], ["schraeg", Vector3(1.4 + breite * 0.4, 1.5, 1.2 + breite * 0.6), 1.3]]:
		var ziel := Vector3(0, ansicht[2], 0)
		kamera.look_at_from_position(ansicht[1], ziel)
		await _bilder(4)
		get_viewport().get_texture().get_image().save_png("res://tools/varianten_%s%s.png" % [rolle + "_" if rolle != "" else "", ansicht[0]])
	print("RENDER FERTIG")
	get_tree().quit()

func _bilder(n: int) -> void:
	for i in n:
		await get_tree().process_frame
