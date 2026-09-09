class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5)}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🍺", 3: "🧹"}
## "Idle" im Modell ist nur ein Einzelbild (T-Pose) — zum Stehen nehmen wir
## ein langsam abgespieltes "Dance".
const ANIM_IDLE := "Dance"

## Das Bean-Modell schaut nicht in Godots Standardrichtung. Falls jemand
## rückwärts läuft, hier auf 0 oder 180 stellen — gilt für alle Angestellten.
@export var model_yaw_offset := 180.0

var staff_id := -1
var role := 2
var level := 1
var carrying := 0

var _net_pos: Vector3
var _net_yaw := 0.0
var _anim: AnimationPlayer
var _cur := ""
var _last := Vector3.ZERO
var _mugs: Node3D
var _mug_meshes: Array = []
var _idle_jitter := 0.0
var _jitter_t := 0.0
var _idle_speed := 0.45
var _walk_speed := 1.0
var _skel: Skeleton3D
var _b_larm := -1
var _b_lfore := -1
var _b_rarm := -1
var _b_rfore := -1

@onready var _model: Node3D = $Model
@onready var _label: Label3D = $Label

static func role_name(r: int) -> String:
	match r:
		1: return "Koch"
		2: return "Kellner"
		3: return "Reinigung"
	return "?"

func _ready() -> void:
	add_to_group("staff")
	_net_pos = position
	_last = position
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Walk", "Run", "Dance"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation(ANIM_IDLE):
			_anim.play(ANIM_IDLE)
			_anim.seek(randf() * 2.0, true)          # nicht alle im Gleichtakt
			_anim.speed_scale = randf_range(0.85, 1.15)
			_cur = ANIM_IDLE
			_anim.advance(0.0)   # Pose sofort anwenden, sonst T-Pose
	_collect_mugs()
	_cache_arm_bones()
	process_priority = 50   # nach dem AnimationPlayer laufen
	_refresh_label()

## Die 12 Maßkrüge liegen als echte Knoten in staff.tscn (vor dem Körper,
## wie eine echte Bedienung sie trägt). Hier werden nur so viele eingeblendet,
## wie der Kellner gerade ausliefert.
func _collect_mugs() -> void:
	var holder := get_node_or_null("Kruege")
	if holder == null:
		return
	for c in holder.get_children():
		_mug_meshes.append(c)
func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw

func set_info(r: int, lv: int) -> void:
	role = r
	level = lv
	_refresh_label()

## Wie viele Bestellungen der Kellner gerade trägt.
func set_carrying(n: int) -> void:
	if carrying == n:
		return
	carrying = n
	for i in _mug_meshes.size():
		(_mug_meshes[i] as Node3D).visible = i < n
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	var extra := ""
	if carrying > 0:
		extra = "  🍺×%d" % carrying
	_label.text = "%s %s Lv%d%s" % [ROLE_ICONS.get(role, ""), Staff.role_name(role), level, extra]
	_label.modulate = ROLE_COLORS.get(role, Color.WHITE)

func _process(delta: float) -> void:
	var t := clampf(delta * 10.0, 0.0, 1.0)
	position = position.lerp(_net_pos, t)
	rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	var spd := (position - _last).length() / maxf(delta, 0.001)
	_last = position
	var want := "Walk" if spd > 0.4 else ANIM_IDLE
	if want != _cur and _anim and _anim.has_animation(want):
		_anim.speed_scale = _idle_speed if want == ANIM_IDLE else _walk_speed
		_anim.play(want)
		if want == ANIM_IDLE:
			_anim.seek(randf() * 2.0, true)
		_cur = want
	# im Stehen leicht umschauen, damit nicht alle wie angewurzelt dastehen
	if want == ANIM_IDLE:
		_jitter_t -= delta
		if _jitter_t <= 0.0:
			_jitter_t = randf_range(1.5, 4.0)
			_idle_jitter = randf_range(-0.5, 0.5)
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset) + _idle_jitter, clampf(delta * 2.0, 0.0, 1.0))
	else:
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
	_apply_carry_pose()

## --- Tragehaltung -----------------------------------------------------------
## Die Laufanimation bewirbt die Arme jedes Bild neu. Damit unsere Pose gewinnt,
## läuft _process dieses Knotens per process_priority NACH dem AnimationPlayer.
func _cache_arm_bones() -> void:
	var sks := _model.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	_skel = sks[0]
	_b_larm = _skel.find_bone("LeftArm")
	_b_lfore = _skel.find_bone("LeftForeArm")
	_b_rarm = _skel.find_bone("RightArm")
	_b_rfore = _skel.find_bone("RightForeArm")

func _pose(bone: int, ang: float) -> void:
	if bone < 0 or _skel == null:
		return
	var rest := _skel.get_bone_rest(bone).basis.get_rotation_quaternion()
	_skel.set_bone_pose_rotation(bone, rest * Quaternion(Vector3.RIGHT, ang))

## Arme nach vorne anwinkeln, als würde er die Krugtraube tragen.
func _apply_carry_pose() -> void:
	if _skel == null:
		return
	if carrying <= 0:
		return
	_pose(_b_rarm, 0.55)
	_pose(_b_rfore, 1.25)
	_pose(_b_larm, 0.55)
	_pose(_b_lfore, 1.25)
