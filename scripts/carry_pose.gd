class_name CarryPose
extends SkeletonModifier3D
## Biegt die Arme in Tragehaltung, während der Kellner Krüge ausliefert.
##
## Ein SkeletonModifier3D läuft garantiert NACH dem AnimationPlayer — deshalb
## überschreibt die Laufanimation die Armhaltung nicht mehr. Beine und Körper
## animieren normal weiter, nur die Arme werden festgehalten.

## Wie viele Krüge gerade getragen werden (0 = normale Armhaltung).
var carrying := 0

## Oberarm/Unterarm-Winkel in Bogenmaß.
@export var upper_arm := 0.5
@export var fore_arm := 1.3

var _rarm := -1
var _rfore := -1
var _larm := -1
var _lfore := -1
var _ready_bones := false

func _find_bones() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	_rarm = sk.find_bone("RightArm")
	_rfore = sk.find_bone("RightForeArm")
	_larm = sk.find_bone("LeftArm")
	_lfore = sk.find_bone("LeftForeArm")
	_ready_bones = true

func _process_modification() -> void:
	if carrying <= 0:
		return
	var sk := get_skeleton()
	if sk == null:
		return
	if not _ready_bones:
		_find_bones()
	_bend(sk, _rarm, upper_arm)
	_bend(sk, _rfore, fore_arm)
	_bend(sk, _larm, upper_arm)
	_bend(sk, _lfore, fore_arm)

func _bend(sk: Skeleton3D, bone: int, ang: float) -> void:
	if bone < 0:
		return
	var rest := sk.get_bone_rest(bone).basis.get_rotation_quaternion()
	sk.set_bone_pose_rotation(bone, rest * Quaternion(Vector3.RIGHT, ang))
