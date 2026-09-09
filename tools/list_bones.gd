extends SceneTree
func _init() -> void:
	var ps: PackedScene = load("res://assets/character/character/bavarian_bean.glb")
	var root: Node = ps.instantiate()
	for s in root.find_children("*", "Skeleton3D", true, false):
		var sk := s as Skeleton3D
		print("Skeleton: ", sk.name, "  Knochen=", sk.get_bone_count())
		var names := []
		for i in sk.get_bone_count():
			names.append(sk.get_bone_name(i))
		print(names)
	root.free()
	quit()
