extends Node3D
## Kontaktbogen: je Animation ein Mann und eine Frau (Dirndl) in der Pose bei Zeitpunkt t.
## godot --path . res://tools/mixamo_blatt.tscn --resolution 2000x700 -- <Zeitanteil 0..1> Name1 Name2 …
## Ergebnis build/blender/mixamo_blatt.png
const Look := preload("res://scripts/charakter_look.gd")

func _ready() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var t := float(args.pop_front()) if not args.is_empty() else 0.5
	var namen: Array = args if not args.is_empty() else ["Idle", "Walking", "Drinking", "Sitting_Drinking"]
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	var figuren: Array[Figur] = []
	var n := namen.size()
	for i in n:
		for g in ["m", "w"]:
			var l := Look.standard(g)
			if g == "m":
				l["hut"] = "tirolerhut"
			var f := Look.bauen(l)
			f.position = Vector3((i - (n - 1) * 0.5) * 1.9 + (-0.45 if g == "m" else 0.45), 0, 0)
			add_child(f)
			Look.faerben(f, l)
			figuren.append(f)
	await get_tree().process_frame
	for i in figuren.size():
		var f := figuren[i]
		var an: String = namen[i / 2] if "/" in str(namen[i / 2]) else "mixamo/" + str(namen[i / 2])
		if not f.abspielen(an):
			print("FEHLT: ", an)
			continue
		f.anim.pause()
		f.anim.seek(t * f.anim.get_animation(an).length, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var breite := (n - 1) * 1.9 + 2.4
	kam.look_at_from_position(Vector3(0, 1.0, breite * 1.35 + 1.5), Vector3(0, 0.85, 0))
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/blender/mixamo_blatt.png")
	print("FERTIG")
	get_tree().quit()
