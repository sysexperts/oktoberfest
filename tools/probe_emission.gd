extends SceneTree
func _init() -> void:
	var t := load("res://assets/kirmes/textures/Texture_Pallete_Emission.png") as Texture2D
	if t == null:
		print("EMISSION-TEXTUR LAEDT NICHT"); quit(); return
	var img := t.get_image()
	img.decompress()
	print("Groesse=%dx%d Format=%d" % [img.get_width(), img.get_height(), img.get_format()])
	var bright := 0
	var total := 0
	var step := 8
	for y in range(0, img.get_height(), step):
		for x in range(0, img.get_width(), step):
			total += 1
			if img.get_pixel(x, y).get_luminance() > 0.5:
				bright += 1
	print("hell: %d von %d Proben (%.2f%%)" % [bright, total, 100.0 * bright / total])
	# was die Modelle wirklich benutzen
	var n := (load("res://assets/kirmes/Models/Ground/Grass.fbx") as PackedScene).instantiate()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null: continue
		for i in m.mesh.get_surface_count():
			var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
			if mat == null: continue
			print("Grass: emission=%s energy=%.1f tex=%s" % [mat.emission, mat.emission_energy_multiplier,
				"JA" if mat.emission_texture else "NEIN"])
	n.free()
	quit()
