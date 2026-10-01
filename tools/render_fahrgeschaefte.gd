extends Node3D
## Fotografiert jedes Fahrgeschäft (scenes/props/*) von vorn und von der Seite,
## in Ruhe und mitten im Schwung. Bilder: tools/fahrt_<Name>_<Ansicht>.png
##   godot --path . res://tools/render_fahrgeschaefte.tscn --resolution 960x540

const NAMEN := ["schiffschaukel", "topspin", "raketen", "wave", "turm", "karussell"]

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.7, 0.9)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 0.95)
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-40, 30, 0)
	add_child(sonne)
	var kamera := Camera3D.new()
	add_child(kamera)
	kamera.current = true
	for n: String in NAMEN:
		var teil := (load("res://scenes/props/%s.tscn" % n) as PackedScene).instantiate()
		add_child(teil)
		teil.set_process(false)
		for ansicht in [["vorn", Vector3(0, 5, 18)], ["seite", Vector3(18, 5, 0)]]:
			for phase in [["ruhe", 0.0], ["schwung", 0.25]]:
				if teil is Fahrgeschaeft:
					teil._t = phase[1] * teil.dauer
					teil._process(0.0)
				kamera.look_at_from_position(ansicht[1], Vector3(0, 4, 0))
				for i in 4:
					await get_tree().process_frame
				get_viewport().get_texture().get_image().save_png("res://tools/fahrt_%s_%s_%s.png" % [n, ansicht[0], phase[0]])
		teil.queue_free()
		await get_tree().process_frame
	print("RENDER FERTIG")
	get_tree().quit()
