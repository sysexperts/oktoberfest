extends SceneTree
func _init() -> void:
	print("SkeletonModifier3D vorhanden: ", ClassDB.class_exists("SkeletonModifier3D"))
	if ClassDB.class_exists("SkeletonModifier3D"):
		var ms := []
		for m in ClassDB.class_get_method_list("SkeletonModifier3D", true):
			ms.append(m["name"])
		print("Methoden: ", ms)
	quit()
