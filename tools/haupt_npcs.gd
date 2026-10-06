extends Node3D
## Huber, Festleiter und Stammgäste nebeneinander (build/haupt_npcs.png)
const Figuren := preload("res://scripts/figuren.gd")

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	var reihe: Array[Node3D] = []
	for i in 8:
		var h := Node3D.new()
		h.position = Vector3((i - 3.5) * 0.8, 0, 0)
		var m := Node3D.new(); m.name = "Model"; h.add_child(m)
		add_child(h)
		reihe.append(h)
	Figuren.einsetzen_look(reihe[0], Figuren.look_huber())
	Figuren.einsetzen_look(reihe[1], Figuren.look_festleiter())
	var namen := ["alois", "veronika", "katharina", "franz", "giulia", "ludwig"]
	for i in 6:
		Figuren.einsetzen_stamm(reihe[2 + i], namen[i])
	for h in reihe:
		for c in h.get_children():
			if c is Figur: (c as Figur).stehen()
	kam.position = Vector3(0, 1.0, 9.5)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/haupt_npcs.png")
	kam.position = Vector3(-1.6, 1.4, 3.2)
	kam.look_at(Vector3(-1.6, 0.9, 0))
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/haupt_npcs_nah.png")
	print("FERTIG")
	get_tree().quit()
