extends Node3D
## Rendert Figur-Szenen nebeneinander von vorn und schräg — zum Prüfen von
## Varianten (Kleidung, Hut, Bart, Brille).
## Aufruf: godot --path . res://tools/render_varianten.tscn --resolution 1600x900 -- res://scenes/figuren/a.tscn res://scenes/figuren/b.tscn

const ABSTAND := 1.1

func _ready() -> void:
	var szenen := OS.get_cmdline_user_args()
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
		f.stehen()
	await _bilder(20)
	var breite := (szenen.size() - 1) * ABSTAND
	for ansicht in [["vorn", Vector3(0, 1.2, 1.6 + breite * 0.9), 1.0], ["kopf", Vector3(0, 1.45, 0.6 + breite * 0.45), 1.4], ["schraeg", Vector3(1.4 + breite * 0.4, 1.5, 1.2 + breite * 0.6), 1.3]]:
		var ziel := Vector3(0, ansicht[2], 0)
		kamera.look_at_from_position(ansicht[1], ziel)
		await _bilder(4)
		get_viewport().get_texture().get_image().save_png("res://tools/varianten_%s.png" % ansicht[0])
	print("RENDER FERTIG")
	get_tree().quit()

func _bilder(n: int) -> void:
	for i in n:
		await get_tree().process_frame
