class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5)}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🍺", 3: "🧹"}

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
var _skel: Skeleton3D
var _mugs: Node3D
var _mug_meshes: Array = []
var _idle_jitter := 0.0
var _jitter_t := 0.0

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
		for n in ["Idle", "Walk", "Run"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Idle"):
			_anim.play("Idle")
			_anim.seek(randf() * 2.0, true)          # nicht alle im Gleichtakt
			_anim.speed_scale = randf_range(0.85, 1.15)
			_cur = "Idle"
	var sks := _model.find_children("*", "Skeleton3D", true, false)
	if sks.size() > 0:
		_skel = sks[0]
		_build_mugs()
	_refresh_label()

## Bierkrüge in der Hand des Kellners (an den Handknochen gehängt).
func _build_mugs() -> void:
	var hand := _skel.find_bone("RightHand")
	if hand < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.bone_idx = hand
	_skel.add_child(ba)
	_mugs = Node3D.new()
	ba.add_child(_mugs)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.75, 0.25)
	# bis zu 4 sichtbare Krüge — mehr wird über die Zahl am Schild angezeigt
	for i in 4:
		var m := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 0.14
		m.mesh = cyl
		m.material_override = mat
		m.position = Vector3(0.06 * float(i % 2), 0.12 * float(i / 2), 0.0)
		m.visible = false
		_mugs.add_child(m)
		_mug_meshes.append(m)

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
		(_mug_meshes[i] as MeshInstance3D).visible = i < mini(n, _mug_meshes.size())
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
	var want := "Walk" if spd > 0.4 else "Idle"
	if want != _cur and _anim and _anim.has_animation(want):
		_anim.play(want)
		if want == "Idle":
			_anim.seek(randf() * 2.0, true)
		_cur = want
	# im Stehen leicht umschauen, damit nicht alle wie angewurzelt dastehen
	if want == "Idle":
		_jitter_t -= delta
		if _jitter_t <= 0.0:
			_jitter_t = randf_range(1.5, 4.0)
			_idle_jitter = randf_range(-0.5, 0.5)
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset) + _idle_jitter, clampf(delta * 2.0, 0.0, 1.0))
	else:
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
