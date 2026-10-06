extends Node3D
## Zeigt Hemden, Jacken und Hosen des Creators in Standardfarben, kombiniert.
## godot --path . res://tools/creator_kleidung.tscn --resolution 2600x1000
const Look := preload("res://scripts/charakter_look.gd")
const Assets := preload("res://scripts/creator_assets.gd")

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	var figuren: Array[Figur] = []
	var kombis := [["hemd_karo", "jacke_janker", "hose_leder"], ["hemd_leinen", "jacke_weste", "hose_kniebund"], ["hemd_karo_kurz", ".", "hose_leder"],
		["hemd_leinen", "jacke_janker", "hose_kniebund"]]
	var frauen := "w" in OS.get_cmdline_user_args()
	var anzahl := 4 if not frauen else 4
	for i in anzahl:
		var l := Look.standard("w" if frauen else "m")
		var k: Array = kombis[i]
		if frauen:
			Look.dirndl_setzen(l, Look.Assets.DIRNDLE[i])
			k = ["", "", ""]
		for n in (0 if frauen else 3):
			var art: String = Look.KLEIDER[n]
			var id: String = k[n] if k[n] != "." else "ohne"
			l[art] = id
			for e: Dictionary in Look.liste(art):
				if e["id"] == id and e["szene"] != null:
					l[art + "_farbe"] = e["farbe"].to_html(false)
					l[art + "_muster"] = e["muster"].to_html(false)
		var f := Look.bauen(l)
		f.position = Vector3(i * 0.85 - 2.1, 0, 0)
		add_child(f)
		Look.faerben(f, l)
		figuren.append(f)
	await get_tree().process_frame
	for f in figuren:
		f.stehen()
	await get_tree().process_frame
	await get_tree().process_frame
	# Optional: -- <Animation> <Sekunde>  friert die Figuren in dieser Pose ein (zum Prüfen von Durchstößen)
	var args := Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return a != "w" and a != "nah")
	var suffix := ""
	if args.size() >= 2:
		suffix = "_" + args[0].get_file()
		for f in figuren:
			f.anim.play("geliehen/" + args[0])
			f.anim.seek(float(args[1]), true)
			f.anim.pause()
	for a in [["vorn", 0.0], ["seite", -90.0], ["hinten", 180.0]]:
		for f in figuren:
			f.rotation_degrees.y = a[1]
		if "nah" in OS.get_cmdline_user_args():
			var fx: float = figuren[1].position.x
			kam.look_at_from_position(Vector3(fx, 0.95, 2.6), Vector3(fx, 0.95, 0))
		else:
			kam.look_at_from_position(Vector3(0, 0.9, 7.6), Vector3(0, 0.85, 0))
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://build/blender/kleidung_%s%s.png" % [a[0], suffix])
	print("FERTIG")
	get_tree().quit()
