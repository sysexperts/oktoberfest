extends Node3D
## Kontaktbogen der Zufalls-NPCs (scripts/figuren.gd, npc_look): 24 Figuren aus den IDs 0..23, dazu eine Prüfung der Regeln
## (nie nackt, keine grellen Farben) über 2000 IDs. godot --path . res://tools/npc_blatt.tscn --resolution 2400x900 -- [Startnummer]
const Figuren := preload("res://scripts/figuren.gd")
const Look := preload("res://scripts/charakter_look.gd")

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var start := int(args[0]) if not args.is_empty() else 0
	# Regeln über viele IDs prüfen
	var nackt := 0
	var grell := 0
	var frauen := 0
	var max_s := 0.0
	var t0 := Time.get_ticks_usec()
	for id in 2000:
		var l := Figuren.npc_look(id)
		if l["geschlecht"] == "w":
			frauen += 1
		if str(l["hemd"]) == "ohne" or str(l["hose"]) == "ohne":
			nackt += 1
		for k: String in ["hemd_farbe", "hemd_muster", "jacke_farbe", "jacke_muster", "hose_farbe", "hose_muster", "hut_farbe"]:
			if k.begins_with("hemd_farbe"):
				continue
			var c := Color.html(str(l[k]))
			if str(l[k.get_slice("_", 0)] if k.get_slice("_", 0) in l else "x") == "ohne":
				continue
			max_s = maxf(max_s, c.s * c.v)
			if c.s > 0.62 and c.v > 0.55:
				grell += 1
	print("NPC-Regeln über 2000 IDs: nackt=%d  grelle Farben=%d  Frauen=%d (%.0f%%)  höchste Sättigung*Helligkeit=%.2f  (%d ms)" % [nackt, grell, frauen, frauen / 20.0, max_s, (Time.get_ticks_usec() - t0) / 1000])
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	var t1 := Time.get_ticks_usec()
	var figuren: Array[Figur] = []
	for i in 24:
		var l := Figuren.npc_look(start + i)
		var f := Look.bauen(l)
		f.position = Vector3((i % 12 - 5.5) * 0.75, 0, -float(i / 12) * 1.3 * -1.0)
		f.rotation_degrees.y = 0
		add_child(f)
		Look.faerben(f, l)
		figuren.append(f)
	print("24 Figuren gebaut in %d ms" % ((Time.get_ticks_usec() - t1) / 1000))
	await get_tree().process_frame
	for f in figuren:
		f.stehen()
	await get_tree().process_frame
	await get_tree().process_frame
	kam.look_at_from_position(Vector3(0, 1.1, 8.2), Vector3(0, 0.75, 0.3))
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/blender/npc_blatt.png")
	print("FERTIG")
	get_tree().quit()
