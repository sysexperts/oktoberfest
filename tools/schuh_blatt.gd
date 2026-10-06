extends Node3D
## Alle Schuhe an Mann (oben) und Frau (unten): build/schuh_blatt.png (Füße im Blick)
const Look := preload("res://scripts/charakter_look.gd")
const SCHUHE := ["schuh_halb", "schuh_haferl", "schuh_sneaker", "schuh_stiefel", "schuh_clog", "schuh_ballerina", "schuh_spangen"]

func _ready() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.3, 0.3, 0.36)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.85, 0.88)
	var we := WorldEnvironment.new(); we.environment = env; add_child(we)
	var sonne := DirectionalLight3D.new(); sonne.rotation_degrees = Vector3(-35, 30, 0); add_child(sonne)
	var kam := Camera3D.new(); kam.fov = 30.0; add_child(kam); kam.current = true
	for r in 2:
		for i in SCHUHE.size():
			var g := "m" if r == 0 else "w"
			if r == 0 and i >= 5:
				continue
			var l := Look.standard(g)
			l["schuhe"] = SCHUHE[i]
			var e := Look._eintrag("schuhe", SCHUHE[i])
			l["schuhe_farbe"] = (e["farbe"] as Color).to_html(false)
			l["schuhe_muster"] = (e["muster"] as Color).to_html(false)
			var f := Look.bauen(Look.pruefen(l))
			f.position = Vector3((i - 3) * 0.8, -r * 1.9, 0)
			add_child(f)
			Look.faerben(f, Look.pruefen(l))
			f.stehen()
			var lb := Label3D.new()
			lb.text = ["Halbschuh", "Haferl", "Sneaker", "Stiefel", "Clog", "Ballerina", "Spangen"][i]
			lb.font_size = 30
			lb.pixel_size = 0.0035
			lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lb.no_depth_test = true
			lb.position = f.position + Vector3(0, -0.12, 0.3)
			add_child(lb)
	kam.position = Vector3(0, -0.9, 11.0)
	await get_tree().create_timer(1.5).timeout
	get_viewport().get_texture().get_image().save_png("res://build/schuh_blatt.png")
	for k in 2:
		kam.fov = 12.0
		kam.position = Vector3(-1.6 + k * 1.6, -0.2 + 0.0, 11.0)
		kam.look_at(Vector3(-1.6 + k * 1.6, -0.2 - 1.2, 0))
		await get_tree().create_timer(0.4).timeout
		get_viewport().get_texture().get_image().save_png("res://build/schuh_nah_%d.png" % k)
	print("FERTIG")
	get_tree().quit()
