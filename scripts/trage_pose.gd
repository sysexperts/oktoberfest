@tool
class_name TragePose
extends SkeletonModifier3D
## Arme nach vorn, Hände seitlich am Fass — über die laufende Animation gelegt,
## damit die Beine beim Tragen weiterlaufen. Figur.trage_pose() hängt den
## Modifier ans Skelett und schaltet ihn mit `active` an und aus.
## Die Winkel stehen in assets/trage_haltung.tres (einstellen mit
## scenes/werkzeuge/trage_haltung.tscn).

const HALTUNG := preload("res://assets/trage_haltung.tres")

## Was getragen wird: 0 = Fass, 1 = Karton, 2 = Tablett — jedes hat eigene Armwinkel
@export var art := 0

## Schulter bis Hand: die Gehanimation bewegt auch diese Knochen — dann säßen
## die Hände im Spiel woanders als im Editor (Ruhelage). Darum die ganze Kette
## erst auf die Ruhelage, danach die eingestellten Winkel.
const KETTE := [["LeftShoulder", "mixamorig_LeftShoulder"], ["RightShoulder", "mixamorig_RightShoulder"],
	["LeftHand", "mixamorig_LeftHand"], ["RightHand", "mixamorig_RightHand"]]

func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for namen: Array in KETTE:
		_ruhe(sk, _knochen(sk, namen))
	var h: TrageHaltung = HALTUNG
	var vor := h.oberarm_vor
	var innen := h.oberarm_innen
	var unten := h.unterarm
	if art == 1:
		vor = h.karton_oberarm_vor
		innen = h.karton_oberarm_innen
		unten = h.karton_unterarm
	elif art == 2:
		vor = h.tablett_oberarm_vor
		innen = h.tablett_oberarm_innen
		unten = h.tablett_unterarm
	_setze(sk, "arm_l", vor, innen)
	_setze(sk, "arm_r", vor, -innen)
	_setze(sk, "unterarm_l", unten, 0.0)
	_setze(sk, "unterarm_r", unten, 0.0)

func _knochen(sk: Skeleton3D, namen: Array) -> int:
	for name: String in namen:
		var b := sk.find_bone(name)
		if b >= 0:
			return b
	return -1

func _ruhe(sk: Skeleton3D, b: int) -> void:
	if b < 0:
		return
	var rest := sk.get_bone_rest(b)
	sk.set_bone_pose_position(b, rest.origin)
	sk.set_bone_pose_rotation(b, rest.basis.get_rotation_quaternion())

func _setze(sk: Skeleton3D, rolle: String, vor: float, seit: float) -> void:
	var b := _knochen(sk, Figur.KNOCHEN_NAMEN.get(rolle, [rolle]))
	if b < 0:
		return
	var rest := sk.get_bone_rest(b)
	sk.set_bone_pose_position(b, rest.origin)
	sk.set_bone_pose_rotation(b, rest.basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, vor) * Quaternion(Vector3.FORWARD, seit))
