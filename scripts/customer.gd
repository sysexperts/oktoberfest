class_name Customer
extends Node3D
## Müşteri NPC — oyuncularla aynı bean modeli. Host otoriter konum belirler,
## tüm peer'lar senkron konuma lerp eder + yürüme/idle animasyonu.

const BEER_NAMES := {1: "Helles", 2: "Weizen", 3: "Radler"}
const BEER_COLORS := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45)}
const FOOD_NAMES := {1: "Pretzel", 2: "Sosis"}
const FOOD_COLORS := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2)}

var cust_id := -1
var order_state := 0     # 0 yok, 1 bekliyor, 2 servis edildi (senkron)
var order_kind := 1
var order_type := 1
var patience_ratio := 1.0
var _net_pos: Vector3
var _net_yaw: float
var _anim: AnimationPlayer
var _skel: Skeleton3D
var _mug: MeshInstance3D
var _cur := ""
var _last := Vector3.ZERO
var _seated := false

@onready var _model: Node3D = $Model
@onready var _bubble: Label3D = $Bubble

func _ready() -> void:
	add_to_group("customer")
	add_to_group("interactable")
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
	var sks := _model.find_children("*", "Skeleton3D", true, false)
	if sks.size() > 0:
		_skel = sks[0]
		_make_mug()

func _make_mug() -> void:
	var ba := BoneAttachment3D.new()
	ba.bone_name = "RightHand"
	_skel.add_child(ba)
	_mug = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = 0.045
	cyl.height = 0.13
	_mug.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.7, 0.1)
	_mug.material_override = m
	_mug.position = Vector3(0.04, 0.02, 0.0)
	_mug.visible = false
	ba.add_child(_mug)

func set_net(pos: Vector3, yaw: float) -> void:
	_net_pos = pos
	_net_yaw = yaw

func set_order(state: int, kind: int, type: int, ratio: float) -> void:
	order_state = state
	order_kind = kind
	order_type = type
	patience_ratio = ratio
	_update_bubble()

func can_serve(kind: int, type: int) -> bool:
	return order_state == 1 and kind == order_kind and type == order_type

func _update_bubble() -> void:
	if _bubble == null:
		return
	if order_state == 1:
		_bubble.visible = true
		if order_kind == 2:
			_bubble.text = "🥨 " + FOOD_NAMES.get(order_type, "Yemek")
			_bubble.modulate = FOOD_COLORS.get(order_type, Color.WHITE)
		else:
			_bubble.text = "🍺 " + BEER_NAMES.get(order_type, "Bira")
			_bubble.modulate = BEER_COLORS.get(order_type, Color.WHITE)
	elif order_state == 2:
		_bubble.visible = true
		_bubble.text = "😄"
		_bubble.modulate = Color.WHITE
	else:
		_bubble.visible = false

func _process(delta: float) -> void:
	var t := clampf(delta * 10.0, 0.0, 1.0)
	position = position.lerp(_net_pos, t)
	rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	var spd := (position - _last).length() / maxf(delta, 0.001)
	_last = position
	var want := "Walk" if spd > 0.4 else "Idle"
	# Oturma / kalkma geçişi (iskelet pozu)
	if want == "Idle" and not _seated:
		_enter_sit()
	elif want == "Walk" and _seated:
		_exit_sit()
	if not _seated:
		if want != _cur and _anim and _anim.has_animation(want):
			_anim.play(want)
			_cur = want
	# Otururken bankta biraz alçal + hafif sarhoş sallanma
	if _model:
		var target_y := 0.05 if _seated else 0.0
		_model.position.y = lerpf(_model.position.y, target_y, clampf(delta * 6.0, 0.0, 1.0))
		_model.rotation.z = sin(float(Time.get_ticks_msec()) * 0.003 + float(cust_id)) * 0.06 if _seated else 0.0
	# Otururken kutlama: kol kaldır-indir (içme/Prost)
	if _seated and _skel:
		var tt := float(Time.get_ticks_msec()) * 0.004 + float(cust_id)
		var fore := _skel.find_bone("RightForeArm")
		if fore >= 0:
			var rest := _skel.get_bone_rest(fore).basis.get_rotation_quaternion()
			_skel.set_bone_pose_rotation(fore, rest * Quaternion(Vector3.RIGHT, 1.2 + (sin(tt) * 0.5 + 0.5) * 0.7))

func _enter_sit() -> void:
	_seated = true
	if _anim:
		_anim.active = false
	if _skel == null:
		return
	# Bacakları büküp oturt (kalça öne, diz aşağı) — model 180 baked, işaretler buna göre
	_pose(_skel.find_bone("LeftUpLeg"), Vector3.RIGHT, -1.5)
	_pose(_skel.find_bone("RightUpLeg"), Vector3.RIGHT, -1.5)
	_pose(_skel.find_bone("LeftLeg"), Vector3.RIGHT, 1.6)
	_pose(_skel.find_bone("RightLeg"), Vector3.RIGHT, 1.6)
	# Sağ kolu kaldır (bira içme pozu) + bardağı göster
	_pose(_skel.find_bone("RightArm"), Vector3.RIGHT, 0.8)
	_pose(_skel.find_bone("RightForeArm"), Vector3.RIGHT, 1.4)
	if _mug:
		_mug.visible = true

func _exit_sit() -> void:
	_seated = false
	if _mug:
		_mug.visible = false
	if _anim:
		_anim.active = true
		_anim.play("Walk")
		_cur = "Walk"

func _pose(bone: int, axis: Vector3, ang: float) -> void:
	if bone < 0:
		return
	var rest := _skel.get_bone_rest(bone).basis.get_rotation_quaternion()
	_skel.set_bone_pose_rotation(bone, rest * Quaternion(axis, ang))
