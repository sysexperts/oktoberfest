extends Node3D
## Stellt alle Figuren aus scripts/figuren.gd nebeneinander und rendert jede Rolle
## (stehen, gehen, rennen, tanzen, sitzen, extra) von vorn. Druckt Kopf- und
## Handhöhe, damit Krüge, Namensschilder und Sitzhöhe zu jeder Figur passen.
## Aufruf: godot --path . res://tools/render_figuren.tscn --resolution 1280x720

const Figuren := preload("res://scripts/figuren.gd")
const ABSTAND := 1.4

var _figuren: Array[Figur] = []

func _ready() -> void:
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
	sonne.rotation_degrees = Vector3(-40, 25, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var platte := PlaneMesh.new()
	platte.size = Vector2(8, 4)
	boden.mesh = platte
	add_child(boden)
	# Messlatte: 1,70 m
	var latte := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.04, 1.7, 0.04)
	latte.mesh = box
	latte.position = Vector3(-ABSTAND * 1.2, 0.85, 0)
	add_child(latte)
	var kamera := Camera3D.new()
	kamera.position = Vector3(0, 1.1, 4.2)
	kamera.look_at_from_position(kamera.position, Vector3(0, 0.9, 0))
	kamera.current = true
	add_child(kamera)

	for i in Figuren.ALLE.size():
		var f := Figuren.ALLE[i].instantiate() as Figur
		f.position = Vector3((i - (Figuren.ALLE.size() - 1) * 0.5) * ABSTAND, 0, 0)
		add_child(f)
		_figuren.append(f)
	await _frames(3)

	for f in _figuren:
		f.stehen()
	await _frames(20)
	for f in _figuren:
		print("%-12s Kopf %.2f m · rechte Hand %.2f m · Standbild=%s" % [f.name, _knochen_hoehe(f, "Head"),
			_knochen_hoehe(f, "RightHand"), f.idle_ist_standbild])

	for rolle in ["stehen", "gehen", "rennen", "tanzen", "sitzen", "extra"]:
		for f in _figuren:
			match rolle:
				"stehen": f.stehen()
				"gehen": f.gehen()
				"rennen": f.rennen()
				"tanzen": f.tanzen()
				"sitzen":
					if f.kann_sitzen():
						f.sitzen()
					else:
						f.stehen()
				"extra":
					if not f.extra():
						f.stehen()
			if f.anim and f.anim.current_animation != "":
				f.anim.seek(f.anim.current_animation_length * 0.4, true)
		await _frames(6)
		if rolle == "sitzen":
			for f in _figuren:
				print("%-12s sitzend: Hüfte %.2f m · Hand %.2f m" % [f.name, _knochen_hoehe(f, "Hips"), _knochen_hoehe(f, "RightHand")])
		get_viewport().get_texture().get_image().save_png("res://tools/figuren_%s.png" % rolle)
		print("  gespeichert: figuren_", rolle)
	print("RENDER FERTIG")
	get_tree().quit()

func _knochen_hoehe(f: Figur, name: String) -> float:
	if f.skelett == null or f.skelett.find_bone(name) < 0:
		return -1.0
	var b := f.skelett.find_bone(name)
	return (f.skelett.global_transform * f.skelett.get_bone_global_pose(b).origin).y

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
