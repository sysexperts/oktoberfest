extends SceneTree
func _init() -> void:
	for n in ["rund", "sonnenbrille_rund", "wayfarer"]:
		var s := (load("res://scenes/creator/brillen/%s.tscn" % n) as PackedScene).instantiate()
		root.add_child(s)
		var box := AABB()
		var erst := true
		for m in s.find_children("*", "MeshInstance3D", true, false):
			var ab := (m as MeshInstance3D).global_transform * (m as MeshInstance3D).get_aabb()
			box = ab if erst else box.merge(ab)
			erst = false
		print("BRILLE %s: Mitte %s, Größe %s, lage %s" % [n, str(box.get_center()), str(box.size), str(s.get_meta("lage"))])
		s.queue_free()
	quit()
