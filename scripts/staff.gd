class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5)}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🍺", 3: "🧹"}

var staff_id := -1
var role := 2
var level := 1

var _net_pos: Vector3
var _net_yaw := 0.0
var _anim: AnimationPlayer
var _cur := ""
var _last := Vector3.ZERO

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
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk", "Run"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Idle"):
			_anim.play("Idle")
			_cur = "Idle"
	_refresh_label()

func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw

func set_info(r: int, lv: int) -> void:
	role = r
	level = lv
	_refresh_label()

func _refresh_label() -> void:
	if _label == null:
		return
	_label.text = "%s %s Lv%d" % [ROLE_ICONS.get(role, ""), Staff.role_name(role), level]
	_label.modulate = ROLE_COLORS.get(role, Color.WHITE)

func _process(delta: float) -> void:
	var t := clampf(delta * 10.0, 0.0, 1.0)
	position = position.lerp(_net_pos, t)
	rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	var spd := (position - _last).length() / maxf(delta, 0.001)
	_last = position
	var want := "Walk" if spd > 0.4 else "Idle"
	if want != _cur and _anim and _anim.has_animation(want):
		_anim.play(want)
		_cur = want
