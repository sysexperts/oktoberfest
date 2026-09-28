@tool
class_name SitzKorrektur
extends SkeletonModifier3D
## Legt eine SitzHaltung über die laufende Sitzanimation (siehe Figur.sitzen).

@export var haltung: SitzHaltung

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or haltung == null:
		return
	var h := haltung
	_dreh(sk, "oberschenkel_l", h.oberschenkel_vor, h.beine_zusammen)
	_dreh(sk, "oberschenkel_r", h.oberschenkel_vor, -h.beine_zusammen)
	_dreh(sk, "unterschenkel_l", h.unterschenkel, 0.0)
	_dreh(sk, "unterschenkel_r", h.unterschenkel, 0.0)
	_dreh(sk, "wirbel_oben", h.oberkoerper, 0.0)

## Zusätzlich zur aktuellen Pose drehen (vor/zurück um RIGHT, seitlich um FORWARD)
func _dreh(sk: Skeleton3D, rolle: String, vor: float, seit: float) -> void:
	if absf(vor) < 0.0001 and absf(seit) < 0.0001:
		return
	var b := -1
	for name: String in Figur.KNOCHEN_NAMEN.get(rolle, [rolle]):
		b = sk.find_bone(name)
		if b >= 0:
			break
	if b < 0:
		return
	sk.set_bone_pose_rotation(b, sk.get_bone_pose_rotation(b) * Quaternion(Vector3.RIGHT, vor) * Quaternion(Vector3.FORWARD, seit))
