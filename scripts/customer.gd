class_name Customer
extends Node3D
## Müşteri NPC — oyuncularla aynı bean modeli. Host otoriter konum belirler,
## tüm peer'lar senkron konuma lerp eder + yürüme/idle animasyonu.

var cust_id := -1
var _net_pos: Vector3
var _net_yaw: float
var _anim: AnimationPlayer
var _cur := ""
var _last := Vector3.ZERO

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("customer")
	_net_pos = position
	_net_yaw = rotation.y
	_last = position
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Idle"):
			_anim.play("Idle")
			_cur = "Idle"

func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw

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
	# Otururken (Idle) hafif sarhoş sallanma
	if _model:
		if want == "Idle":
			_model.rotation.z = sin(float(Time.get_ticks_msec()) * 0.003 + float(cust_id)) * 0.08
		else:
			_model.rotation.z = 0.0
