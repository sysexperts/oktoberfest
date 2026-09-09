extends SceneTree
func _init() -> void:
	var n := (load("res://assets/kirmes/Models/Attractions/OtherRides/FerrisWheel.fbx") as PackedScene).instantiate()
	var hub := n.get_node("FerrisWheel_Rotate") as MeshInstance3D
	var a := hub.mesh.get_aabb()
	print("Radkranz (nur Rotate-Mesh): Groesse=%s  min=%s" % [a.size, a.position])
	var cab := hub.get_node("FerrisWheel_Cabin") as MeshInstance3D
	var ca := cab.mesh.get_aabb()
	print("Gondel: lokal=%s Groesse=%s" % [cab.position, ca.size])
	n.free()
	quit()
