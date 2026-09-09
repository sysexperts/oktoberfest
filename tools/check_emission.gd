extends SceneTree
const M := ["res://assets/kirmes/Models/Shops/Bld_Cafe.fbx",
"res://assets/kirmes/Models/Props/Lamp_1.fbx",
"res://assets/kirmes/Models/Attractions/OtherRides/FerrisWheel.fbx",
"res://assets/kirmes/Models/Vehicles/Transport_Car_1_a.fbx"]
func _init() -> void:
	for p in M:
		var n := (load(p) as PackedScene).instantiate()
		var alb := 0; var emi := 0; var tot := 0
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			if m.mesh == null: continue
			for i in m.mesh.get_surface_count():
				var mat := m.mesh.surface_get_material(i) as StandardMaterial3D
				if mat == null: continue
				tot += 1
				if mat.albedo_texture: alb += 1
				if mat.emission_enabled: emi += 1
				if mat.emission_texture: tot += 1000
		print("%-24s Materialien=%d  mit Albedo=%d  mit Emission=%d" % [p.get_file(), tot, alb, emi])
		n.free()
	quit()
