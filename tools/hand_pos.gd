extends SceneTree
var done := false

func _process(_d: float) -> bool:
	if done:
		return true
	done = true
	var ps: PackedScene = load("res://assets/character/character/bavarian_bean.glb")
	var inst: Node = ps.instantiate()
	get_root().add_child(inst)
	var aps := inst.find_children("*", "AnimationPlayer", true, false)
	var sks := inst.find_children("*", "Skeleton3D", true, false)
	if aps.is_empty() or sks.is_empty():
		print("nicht gefunden")
		quit()
		return true
	var ap := aps[0] as AnimationPlayer
	var sk := sks[0] as Skeleton3D
	ap.play("Walk")
	ap.seek(0.25, true)
	ap.advance(0.0)
	for bn in ["RightHand", "LeftHand", "Head", "Hips", "RightFoot"]:
		var b := sk.find_bone(bn)
		if b < 0:
			continue
		# Knochenposition im Raum des GLB-Wurzelknotens
		var world: Transform3D = sk.global_transform * sk.get_bone_global_pose(b)
		var local: Vector3 = (inst as Node3D).global_transform.affine_inverse() * world.origin
		print("%-11s  x=%.3f  y=%.3f  z=%.3f" % [bn, local.x, local.y, local.z])
	quit()
	return true
