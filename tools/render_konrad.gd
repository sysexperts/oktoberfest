extends Node3D
## Sichtprobe für eine einzelne Figur mit Zubehör: Kopf von vorn, schräg, von der
## Seite und von hinten, dazu die ganze Figur. Bilder nach tools/konrad_*.png.
##   godot --path . res://tools/render_konrad.tscn
##   godot --path . res://tools/render_konrad.tscn -- res://scenes/figuren/wilhelm_hut_bart.tscn wilhelm

const STANDARD := "res://scenes/figuren/konrad.tscn"
## Name, Kameraort, Blickpunkt, Brennweite (Grad)
const BLICKE := [
	["vorn", Vector3(0, 1.42, 1.25), Vector3(0, 1.42, 0), 32.0],
	["schraeg", Vector3(0.85, 1.5, 0.95), Vector3(0, 1.42, 0), 32.0],
	["seite", Vector3(1.3, 1.45, 0.0), Vector3(0, 1.42, 0), 32.0],
	["hinten", Vector3(-0.7, 1.55, -1.0), Vector3(0, 1.42, 0), 32.0],
	["unten", Vector3(0.35, 1.0, 1.1), Vector3(0, 1.4, 0), 32.0],
	["ganz", Vector3(0.9, 1.15, 3.1), Vector3(0, 0.95, 0), 38.0],
]

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var pfad: String = args[0] if args.size() > 0 else STANDARD
	var name_: String = args[1] if args.size() > 1 else "konrad"
	var umgebung := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.42, 0.43, 0.47)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.7
	umgebung.environment = env
	add_child(umgebung)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-35, 30, 0)
	sonne.shadow_enabled = true
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(6, 6)
	boden.mesh = platte
	add_child(boden)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true

	var figur := (load(pfad) as PackedScene).instantiate() as Figur
	add_child(figur)
	for i in 4:
		await get_tree().process_frame
	figur.stehen()
	for i in 20:
		await get_tree().process_frame
	for b: Array in BLICKE:
		kamera.fov = b[3]
		kamera.look_at_from_position(b[1], b[2])
		for i in 4:
			await get_tree().process_frame
		var bild := get_viewport().get_texture().get_image()
		if bild.get_width() > 1280:
			bild.resize(1280, int(1280.0 * bild.get_height() / bild.get_width()), Image.INTERPOLATE_LANCZOS)
		bild.save_png(ProjectSettings.globalize_path("res://tools/%s_%s.png" % [name_, b[0]]))
	print("RENDER FERTIG")
	get_tree().quit()
