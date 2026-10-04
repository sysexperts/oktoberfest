extends Node3D
## Prüfstand für Animationen: die vier Grundfiguren nebeneinander, dieselbe Rolle
## (stehen, gehen, rennen, sitzen, tanzen, torkeln, extra) zu vier Zeitpunkten des
## Zyklus. Ergebnis: tools/pruef_<rolle>_vorn.png und _seite.png — Spalten =
## Figuren, Zeilen = Zeitpunkte. Abweichungen zwischen den Figuren sieht man sofort.
## Aufruf: godot --path . res://tools/anim_pruefstand.tscn --resolution 1280x720 -- gehen sitzen
## (ohne Rollen: alle)

const Figuren := preload("res://scripts/figuren.gd")
const ALLE_ROLLEN := ["stehen", "gehen", "rennen", "sitzen", "tanzen", "torkeln", "extra"]
const PHASEN := [0.0, 0.25, 0.5, 0.75]
const ABSTAND := 1.0

var _figuren: Array[Figur] = []
var _kamera: Camera3D

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.2, 0.26)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-40, 25, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(8, 4)
	boden.mesh = platte
	add_child(boden)
	_kamera = Camera3D.new()
	_kamera.fov = 40.0
	_kamera.current = true
	add_child(_kamera)
	_kamera.look_at_from_position(Vector3(0, 1.0, 5.2), Vector3(0, 0.85, 0))
	var szenen: Array[PackedScene] = [Figuren.ALLE[0], Figuren.ALLE[1], Figuren.ALLE[2], Figuren.ALLE[3]]
	# Mit dem Argument "standard" ersetzt der neue Standardkörper den alten Bean
	if "standard" in OS.get_cmdline_user_args():
		szenen[0] = load("res://scenes/figuren/standard.tscn")
	elif "bean" in OS.get_cmdline_user_args():
		szenen[0] = load("res://scenes/figuren/bean.tscn")
	for i in 4:
		var f := szenen[i].instantiate() as Figur
		f.position = Vector3((i - 1.5) * ABSTAND, 0, 0)
		add_child(f)
		_figuren.append(f)
	await _bilder(3)
	var rollen: Array = ALLE_ROLLEN
	var args := OS.get_cmdline_user_args()
	args = PackedStringArray(Array(args).filter(func(a: String) -> bool: return a != "standard" and a != "bean"))
	if not args.is_empty():
		rollen = Array(args)
	for rolle in rollen:
		for ansicht in ["vorn", "seite"]:
			await _rolle(rolle, ansicht)
	print("PRUEFSTAND FERTIG")
	get_tree().quit()

func _bilder(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _rolle(rolle: String, ansicht: String) -> void:
	var gesamt := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	var zeilen: Array[Image] = []
	for phase: float in PHASEN:
		for f in _figuren:
			f.rotation.y = 0.0 if ansicht == "vorn" else -PI * 0.5
			_spielen(f, rolle, phase)
		await _bilder(3)
		# Nach dem Warten noch einmal setzen: der AnimationPlayer läuft weiter
		for f in _figuren:
			_spielen(f, rolle, phase)
			if f.anim:
				f.anim.speed_scale = 0.0
		await _bilder(2)
		var bild := get_viewport().get_texture().get_image()
		bild.convert(Image.FORMAT_RGBA8)
		zeilen.append(bild)
	var b := zeilen[0].get_width()
	var h := zeilen[0].get_height()
	var hoehe := h / 2
	gesamt = Image.create_empty(b, hoehe * PHASEN.size(), false, Image.FORMAT_RGBA8)
	for i in zeilen.size():
		gesamt.blit_rect(zeilen[i], Rect2i(0, h / 6, b, hoehe), Vector2i(0, i * hoehe))
	gesamt.save_png("res://tools/pruef_%s_%s.png" % [rolle, ansicht])
	print("gespeichert: ", rolle, " ", ansicht)

## Rolle abspielen und auf den Zeitpunkt `phase` (0..1 der Länge) setzen.
func _spielen(f: Figur, rolle: String, phase: float) -> void:
	f.pose_loesen()
	match rolle:
		"stehen": f.stehen()
		"gehen": f.gehen()
		"rennen": f.rennen()
		"sitzen":
			if f.kann_sitzen():
				f.sitzen()
			else:
				f.sitz_pose()
		"tanzen": f.tanzen()
		"torkeln": f.torkeln()
		"extra":
			if not f.extra():
				f.stehen()
	if f.anim and f.anim.current_animation != "":
		f.anim.speed_scale = 0.0
		f.anim.seek(f.anim.current_animation_length * phase, true)
