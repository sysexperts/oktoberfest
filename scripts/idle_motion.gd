class_name IdleMotion
extends SkeletonModifier3D
## Organische Stehhaltung. Das Charaktermodell hat keine echte Idle-Animation
## (die mitgelieferte "Idle" ist nur ein Einzelbild = T-Pose), deshalb bauen
## wir das Stehen hier zusammen:
##
##  * BEINE  -> zurück auf die Ruhepose (gerade und beieinander). Ohne das
##              bleibt die Figur im Schritt stehen wie mitten im Gehen.
##  * ARME   -> bleiben aus der angehaltenen Laufpose (hängen an der Seite).
##              Die Ruhepose wäre hier die T-Pose, also nicht anfassen.
##  * OBERKÖRPER -> leichte Eigenbewegung obendrauf: Atmen, Gewicht verlagern,
##              Kopf drehen. Kleine Winkel, damit nichts verrenkt.

var idle := false          # true, solange die Figur steht

var _t := 0.0
var _phase := 0.0
var _found := false
# Oberkörper
var _spine := -1
var _spine01 := -1
var _spine02 := -1
var _neck := -1
var _head := -1
# Beine (werden im Stehen auf die Ruhepose gesetzt)
var _legs: Array[int] = []

func _ready() -> void:
	_phase = randf() * 20.0   # jeder atmet in seinem eigenen Takt

func _find(sk: Skeleton3D) -> void:
	_spine = sk.find_bone("Spine")
	_spine01 = sk.find_bone("Spine01")
	_spine02 = sk.find_bone("Spine02")
	_neck = sk.find_bone("neck")
	_head = sk.find_bone("Head")
	_legs.clear()
	for n in ["LeftUpLeg", "LeftLeg", "LeftFoot", "LeftToeBase",
			  "RightUpLeg", "RightLeg", "RightFoot", "RightToeBase"]:
		var b := sk.find_bone(n)
		if b >= 0:
			_legs.append(b)
	_found = true

func _process_modification() -> void:
	if not idle:
		return
	var sk := get_skeleton()
	if sk == null:
		return
	if not _found:
		_find(sk)
	# Beine gerade stellen — beendet die "eingefrorene Schrittstellung"
	for b in _legs:
		sk.set_bone_pose_rotation(b, sk.get_bone_rest(b).basis.get_rotation_quaternion())
	_t = float(Time.get_ticks_msec()) * 0.001 + _phase
	# Atmen
	_add(sk, _spine02, Vector3.RIGHT, sin(_t * 1.2) * 0.03)
	# Gewicht langsam von einem Bein aufs andere verlagern
	_add(sk, _spine01, Vector3.FORWARD, sin(_t * 0.55) * 0.05)
	_add(sk, _spine, Vector3.FORWARD, sin(_t * 0.55 + 0.4) * 0.035)
	# Kopf schaut gemächlich umher
	_add(sk, _neck, Vector3.UP, sin(_t * 0.37) * 0.18)
	_add(sk, _head, Vector3.UP, sin(_t * 0.29) * 0.12)

## Dreht den Knochen relativ zu seiner aktuellen Pose weiter.
func _add(sk: Skeleton3D, bone: int, axis: Vector3, ang: float) -> void:
	if bone < 0:
		return
	var cur := sk.get_bone_pose_rotation(bone)
	sk.set_bone_pose_rotation(bone, cur * Quaternion(axis, ang))
