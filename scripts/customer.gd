class_name Customer
extends Node3D
## Müşteri NPC. Host otoriter konum belirler, tüm peer'lar senkron konuma lerp
## eder + yürüme/oturma animasyonu.
## Die Figur kommt aus der Gast-ID (scripts/figuren.gd) — so sieht im Koop jeder
## Mitspieler denselben Gast, ohne dass die Wahl übers Netz geht.

const Figuren := preload("res://scripts/figuren.gd")
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
var _figur: Figur
var _anim: AnimationPlayer
var _skel: Skeleton3D
var _mug: MeshInstance3D
var _cur := ""
var _last := Vector3.ZERO
var _seated := false
var _vomit_t := 0.0        # C3: kusma süresi (sn), >0 ise öne eğilir
var _vomit_active := false
## Tanzt gerade auf dem Tisch (gute Stimmung, vom Server)
var _tanzt := false
## Höhe der Tischplatte — so hoch steht ein Tänzer
const TISCH_HOEHE := 0.78

@onready var _model: Node3D = $Model
@onready var _bubble: Label3D = $Bubble

func _ready() -> void:
	add_to_group("customer")
	add_to_group("interactable")
	_net_pos = position
	_net_yaw = rotation.y
	_last = position
	_figur = Figuren.einsetzen(self, Figuren.fuer_gast(cust_id))
	_model = _figur
	_anim = _figur.anim
	_skel = _figur.skelett
	if _anim:
		_figur.stehen()
		_cur = "Idle"
	if _skel:
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

## Gute Stimmung: auf den Tisch steigen und tanzen (an) bzw. zurück (aus).
func set_tanz(an: bool) -> void:
	if an == _tanzt:
		return
	_tanzt = an
	if an:
		if _seated:
			_exit_sit()
		if _anim:
			_anim.active = true
		if not _figur.tanzen(randf_range(0.9, 1.15)):
			_figur.gehen(1.5)
		_cur = "Tanz"
		if _mug:
			_mug.visible = true
	else:
		_cur = ""
	_update_bubble()

func tanzt() -> bool:
	return _tanzt

## 0 normal, 1 verpasste Bestellung (😤), 2 geht genervt (😠) — vom Server.
var _laune := 0

func set_laune(l: int) -> void:
	if l == _laune:
		return
	_laune = l
	_update_bubble()

## C3: sarhoş misafir kusar — kısa süre öne eğilir + 🤮 baloncuk.
func play_vomit() -> void:
	_vomit_t = 1.8

func _update_vomit(delta: float) -> void:
	if _vomit_t > 0.0:
		_vomit_t -= delta
		if not _vomit_active:
			_vomit_active = true
			# Eine laufende Animation (etwa Sitzen mit Trinken) würde die Knochenpose
			# jedes Bild überschreiben — solange angehalten
			if _anim:
				_anim.active = false
			if _bubble:
				_bubble.visible = true
				_bubble.text = "🤮"
				_bubble.modulate = Color(0.6, 0.9, 0.4)
		if _skel:
			# öne eğil (model 180 baked → negatif RIGHT ileri)
			var wob := sin(float(Time.get_ticks_msec()) * 0.02) * 0.12
			_pose(_skel.find_bone("Spine"), Vector3.RIGHT, -0.85 + wob)
			_pose(_skel.find_bone("Head"), Vector3.RIGHT, -0.5)
	elif _vomit_active:
		_vomit_active = false
		if _skel:
			_pose(_skel.find_bone("Spine"), Vector3.RIGHT, 0.0)
			_pose(_skel.find_bone("Head"), Vector3.RIGHT, 0.0)
		# Figuren mit Sitzanimation weitertrinken lassen; die Knochenpose-Sitzer
		# bleiben ohne Animation, wie beim Hinsetzen
		if _anim and (not _seated or _figur.kann_sitzen()):
			_anim.active = true
		_update_bubble()

func can_serve(kind: int, type: int) -> bool:
	return order_state == 1 and kind == order_kind and type == order_type

func _update_bubble() -> void:
	if _bubble == null or _vomit_active:
		return   # kusarken 🤮 baloncuğu ezilmesin
	if _laune > 0:
		_bubble.visible = true
		_bubble.text = "😠" if _laune == 2 else "😤"
		_bubble.modulate = Color(1, 0.45, 0.35)
		return
	if _tanzt:
		_bubble.visible = true
		_bubble.text = "🎶"
		_bubble.modulate = Color(1, 0.85, 0.4)
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
	# Auf dem Tisch: hoch auf die Platte, tanzen, leicht schwanken
	if _tanzt:
		if _model:
			_model.position.y = lerpf(_model.position.y, TISCH_HOEHE, clampf(delta * 5.0, 0.0, 1.0))
			_model.rotation.z = sin(float(Time.get_ticks_msec()) * 0.004 + float(cust_id)) * 0.08
		_update_vomit(delta)
		return
	var want := "Walk" if spd > 0.4 else "Idle"
	# Oturma / kalkma geçişi
	if want == "Idle" and not _seated:
		_enter_sit()
	elif want == "Walk" and _seated:
		_exit_sit()
	if not _seated and want != _cur and _anim:
		if want == "Walk":
			_figur.gehen()
		else:
			_figur.stehen()
		_cur = want
	# Otururken bankta biraz alçal + hafif sarhoş sallanma
	if _model:
		var target_y := _figur.sitz_hoehe if _seated else 0.0
		_model.position.y = lerpf(_model.position.y, target_y, clampf(delta * 6.0, 0.0, 1.0))
		_model.rotation.z = sin(float(Time.get_ticks_msec()) * 0.003 + float(cust_id)) * 0.06 if _seated else 0.0
	# C3: kusma pozu (kutlamayı bastırır)
	_update_vomit(delta)
	# Otururken kutlama: kol kaldır-indir (içme/Prost) — nur ohne Sitzanimation,
	# die bringt das Trinken selbst mit
	if _seated and _skel and not _vomit_active and not _figur.kann_sitzen():
		var tt := float(Time.get_ticks_msec()) * 0.004 + float(cust_id)
		var fore := _skel.find_bone("RightForeArm")
		if fore >= 0:
			var rest := _skel.get_bone_rest(fore).basis.get_rotation_quaternion()
			_skel.set_bone_pose_rotation(fore, rest * Quaternion(Vector3.RIGHT, 1.2 + (sin(tt) * 0.5 + 0.5) * 0.7))

func _enter_sit() -> void:
	_seated = true
	if _mug:
		_mug.visible = true
	# Figur mit eigener Sitzanimation: die übernimmt Beine, Oberkörper und Trinken
	if _figur.kann_sitzen():
		_figur.sitzen()
		return
	if _anim:
		_anim.active = false
	if _skel == null:
		return
	# Bacakları büküp oturt (kalça öne, diz aşağı) — model 180 baked, işaretler buna göre
	_pose(_skel.find_bone("LeftUpLeg"), Vector3.RIGHT, -1.5)
	_pose(_skel.find_bone("RightUpLeg"), Vector3.RIGHT, -1.5)
	_pose(_skel.find_bone("LeftLeg"), Vector3.RIGHT, 1.6)
	_pose(_skel.find_bone("RightLeg"), Vector3.RIGHT, 1.6)
	# Sağ kolu kaldır (bira içme pozu)
	_pose(_skel.find_bone("RightArm"), Vector3.RIGHT, 0.8)
	_pose(_skel.find_bone("RightForeArm"), Vector3.RIGHT, 1.4)

func _exit_sit() -> void:
	_seated = false
	if _mug:
		_mug.visible = false
	if _anim:
		_figur.gehen()
		_cur = "Walk"

func _pose(bone: int, axis: Vector3, ang: float) -> void:
	if bone < 0:
		return
	var rest := _skel.get_bone_rest(bone).basis.get_rotation_quaternion()
	_skel.set_bone_pose_rotation(bone, rest * Quaternion(axis, ang))

## Für Tests: ob der Gast gerade sitzt.
func sitzt() -> bool:
	return _seated
