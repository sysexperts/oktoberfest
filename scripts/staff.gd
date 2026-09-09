class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5)}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🍺", 3: "🧹"}

## Im Modell ist "Idle" nur ein Einzelbild (die T-Pose). Zum Stehen frieren wir
## deshalb die Laufanimation an einer neutralen Stelle ein.
const STAND_ANIM := "Walk"
const STAND_FRAME := 0.25

## Das Bean-Modell schaut nicht in Godots Standardrichtung. Bei Rückwärtslaufen
## hier auf 0 oder 180 stellen.
@export var model_yaw_offset := 180.0

var staff_id := -1
var role := 2
var level := 1
var carrying := 0

var _net_pos: Vector3
var _net_yaw := 0.0
var _anim: AnimationPlayer
var _walking := false
var _last := Vector3.ZERO
var _mug_nodes: Array = []
var _idle_jitter := 0.0
var _jitter_t := 0.0
var _bob := 0.0
var _model_base_y := 0.0
var _idle_motion: IdleMotion

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
	_model_base_y = _model.position.y
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Walk", "Run", "Dance"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_set_standing()
	_collect_mugs()
	_setup_idle_motion()
	_refresh_label()

## Neutrale Stehpose: Laufanimation an einer Stelle mit geschlossenen Beinen
## anhalten. Wirkt ruhig statt tanzend oder erstarrt in T-Pose.
func _set_standing() -> void:
	if _anim == null or not _anim.has_animation(STAND_ANIM):
		return
	_anim.play(STAND_ANIM)
	_anim.seek(STAND_FRAME, true)
	_anim.advance(0.0)      # Pose sofort anwenden
	_anim.speed_scale = 0.0 # eingefroren
	_walking = false

func _set_walking() -> void:
	if _anim == null or not _anim.has_animation("Walk"):
		return
	if not _walking:
		_anim.play("Walk")
	_anim.speed_scale = 1.0
	_walking = true

## Die Maßkrüge liegen als echte Knoten in staff.tscn (Traube vor dem Körper).
func _collect_mugs() -> void:
	var holder := get_node_or_null("Kruege")
	if holder == null:
		return
	for c in holder.get_children():
		_mug_nodes.append(c)

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
	for i in _mug_nodes.size():
		(_mug_nodes[i] as Node3D).visible = i < n
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
	if _idle_motion:
		_idle_motion.idle = spd <= 0.4
	if spd > 0.4:
		_set_walking()
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
		_model.position.y = _model_base_y
	else:
		if _walking:
			_set_standing()
		if _anim:
			_anim.seek(STAND_FRAME, true)   # Skelett aktualisieren, damit die Idle-Bewegung greift
		# im Stehen leicht umschauen und atmen, damit er nicht erstarrt wirkt
		_jitter_t -= delta
		if _jitter_t <= 0.0:
			_jitter_t = randf_range(2.0, 5.0)
			_idle_jitter = randf_range(-0.35, 0.35)
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset) + _idle_jitter, clampf(delta * 1.5, 0.0, 1.0))



## Organische Stehbewegung (Atmen, Gewicht verlagern, Kopf drehen).
func _setup_idle_motion() -> void:
	var sks := _model.find_children("*", "Skeleton3D", true, false)
	if sks.is_empty():
		return
	_idle_motion = IdleMotion.new()
	_idle_motion.name = "IdleMotion"
	(sks[0] as Skeleton3D).add_child(_idle_motion)
