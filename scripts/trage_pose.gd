@tool
class_name TragePose
extends SkeletonModifier3D
## Arme nach vorn, Hände seitlich am Fass — über die laufende Animation gelegt,
## damit die Beine beim Tragen weiterlaufen. Figur.trage_pose() hängt den
## Modifier ans Skelett und schaltet ihn mit `active` an und aus.
## Die Winkel stehen in assets/trage_haltung.tres (einstellen mit
## scenes/werkzeuge/trage_haltung.tscn).

const HALTUNG := preload("res://assets/trage_haltung.tres")

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	var h: TrageHaltung = HALTUNG
	_setze(sk, "arm_l", h.oberarm_vor, h.oberarm_innen)
	_setze(sk, "arm_r", h.oberarm_vor, -h.oberarm_innen)
	_setze(sk, "unterarm_l", h.unterarm, 0.0)
	_setze(sk, "unterarm_r", h.unterarm, 0.0)

func _setze(sk: Skeleton3D, rolle: String, vor: float, seit: float) -> void:
	var b := -1
	for name: String in Figur.KNOCHEN_NAMEN.get(rolle, [rolle]):
		b = sk.find_bone(name)
		if b >= 0:
			break
	if b < 0:
		return
	var rest := sk.get_bone_rest(b).basis.get_rotation_quaternion()
	sk.set_bone_pose_rotation(b, rest * Quaternion(Vector3.RIGHT, vor) * Quaternion(Vector3.FORWARD, seit))
