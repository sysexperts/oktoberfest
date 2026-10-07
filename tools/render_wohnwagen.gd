extends Node3D
## Fotografiert den Wohnwagen mit dem Laptop davor (build/wohnwagen_innen.png).
##   godot --path . res://tools/render_wohnwagen.tscn --resolution 1280x720
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.62, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.9)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-45, 25, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(30, 30)
	boden.mesh = ebene
	add_child(boden)
	var wagen := (load("res://scenes/wohnwagen_innen.tscn") as PackedScene).instantiate()
	add_child(wagen)
	# Zweites Bild von innen (mit Dach), erstes ohne Dach und Südwand
	var innen := Camera3D.new()
	add_child(innen)
	innen.look_at_from_position(Vector3(2.9, 1.6, 0.9), Vector3(-1.5, 1.1, -0.6))
	innen.current = true
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/wohnwagen_innen_eye.png")
	innen.queue_free()
	for n in wagen.get_node("Huelle").get_children():
		for pre in ["Decke", "Dach", "Sued", "Leiste", "Spant", "Kappe"]:
			if String(n.name).begins_with(pre):
				n.visible = false
	wagen.get_node("Ausgang").visible = false
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0.5, 4.2, 4.6), Vector3(0, 0.6, -0.3))
	for i in 6:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://build/wohnwagen_innen.png")
	print("RENDER FERTIG")
	get_tree().quit()
