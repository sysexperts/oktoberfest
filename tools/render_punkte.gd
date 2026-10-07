extends Node3D
## Fotografiert die Punkte der Gefallen nebeneinander (build/punkte.png).
##   godot --path . res://tools/render_punkte.tscn --resolution 1280x720
func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.45, 0.62, 0.8)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.9)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-40, -20, 0)
	add_child(sonne)
	var boden := MeshInstance3D.new()
	var ebene := PlaneMesh.new()
	ebene.size = Vector2(30, 30)
	boden.mesh = ebene
	add_child(boden)
	var varianten := ["lager", "lieferung", "hochzeit", "teller", "quelle"]
	for i in varianten.size():
		var p: Node3D = (load("res://scenes/gefallen/punkt.tscn") as PackedScene).instantiate()
		p.set("variante", varianten[i])
		add_child(p)
		p.position = Vector3(-4.0 + i * 2.0, 0.0, 0.0)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	kamera.look_at_from_position(Vector3(0, 1.8, 6.5), Vector3(0, 1.0, 0))
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/punkte.png")
	print("RENDER FERTIG")
	get_tree().quit()
