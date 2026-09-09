extends SceneTree
func _init() -> void:
	var n := (load("res://scenes/props/riesenrad.tscn") as PackedScene).instantiate()
	var l := n.get_node_or_null("Model/FerrisWheel_Rotate/Lichter")
	print("Lichter-Knoten: %s" % ("GEFUNDEN" if l else "FEHLT"))
	if l:
		print("Birnen: %d" % l.get_child_count())
	# Emission der Pack-Modelle stichprobenartig
	for p in ["res://assets/kirmes/Models/Ground/Grass.fbx",
			"res://assets/kirmes/Models/Shops/WC.fbx",
			"res://assets/kirmes/Models/Attractions/OtherRides/FerrisWheel.fbx"]:
		var m := (load(p) as PackedScene).instantiate()
		var an := 0; var tot := 0
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			var me := mi as MeshInstance3D
			if me.mesh == null: continue
			for i in me.mesh.get_surface_count():
				var mat := me.mesh.surface_get_material(i) as StandardMaterial3D
				if mat == null: continue
				tot += 1
				if mat.emission_enabled: an += 1
		print("%-18s Materialien=%d  Emission an=%d" % [p.get_file(), tot, an])
		m.free()
	n.free()
	quit()
