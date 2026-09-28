class_name TragePose
extends SkeletonModifier3D
## Arme nach vorn, Hände seitlich am Fass/Karton — über die laufende Animation
## gelegt, damit die Beine beim Tragen weiterlaufen. Figur.trage_pose() hängt
## den Modifier ans Skelett und schaltet ihn mit `active` an und aus.


## Werte aus Seiten- und Vorderansicht (tools/render_fass.tscn): Oberarm aus der
## T-Pose nach unten und etwas vor, Unterarm nach vorn — Hände seitlich am Fass
@export var oberarm_vor := -0.9
@export var oberarm_innen := -0.85
@export var unterarm := 0.9

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	_setze(sk, "arm_l", oberarm_vor, oberarm_innen)
	_setze(sk, "arm_r", oberarm_vor, -oberarm_innen)
	_setze(sk, "unterarm_l", unterarm, 0.0)
	_setze(sk, "unterarm_r", unterarm, 0.0)

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
