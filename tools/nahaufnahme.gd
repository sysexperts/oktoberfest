extends Node3D
## Nahaufnahmen des Standardkörpers neben Wilhelm (Hand von vorn/seitlich, Kopf von der
## Seite) — Ergebnis build/blender/nah_*.png.
## godot --path . res://tools/nahaufnahme.tscn --resolution 1000x800
func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 25.0; add_child(kam); kam.current = true
	var f: Figur = (load("res://scenes/figuren/franz.tscn") as PackedScene).instantiate()
	add_child(f)
	await get_tree().process_frame
	f.stehen()
	await get_tree().process_frame
	await get_tree().process_frame
	for a in [["hand_vorn", 0.0, 0.7, 2.4], ["hand_seite", -90.0, 0.7, 2.4], ["kopf_seite", -90.0, 1.3, 2.2],
			["gesicht_nah", 0.0, 1.3, 1.5], ["gesicht_seite", -60.0, 1.3, 1.5], ["ganz", 0.0, 0.85, 4.6], ["oberkoerper", 0.0, 1.1, 2.6], ["schraeg", -35.0, 0.9, 3.6], ["seite_ober", -90.0, 1.1, 2.6], ["ruecken", 180.0, 1.1, 2.6], ["hose_seite", -90.0, 0.65, 2.4], ["seite_hinten", -135.0, 1.0, 2.6], ["kopf_hinten", 150.0, 1.5, 2.2]]:
		f.rotation_degrees.y = a[1]
		kam.look_at_from_position(Vector3(0, a[2], a[3]), Vector3(0, a[2], 0))
		await get_tree().process_frame
		await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://build/blender/nah_%s.png" % a[0])
	print("FERTIG")
	get_tree().quit()
