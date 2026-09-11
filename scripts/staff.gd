class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5)}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🍺", 3: "🧹"}
const Figuren := preload("res://scripts/figuren.gd")
## Versatz, damit Personal und Gäste mit gleicher Nummer nicht gleich aussehen
const FIGUR_VERSATZ := 1000

## Die Figuren schauen nicht in Godots Standardrichtung. Bei Rückwärtslaufen
## hier auf 0 oder 180 stellen.
@export var model_yaw_offset := 180.0

var staff_id := -1
var role := 2
var level := 1
var carrying := 0

var _net_pos: Vector3
var _net_yaw := 0.0
var _figur: Figur
var _anim: AnimationPlayer
var _walking := false
var _last := Vector3.ZERO
var _mug_nodes: Array = []
var _idle_jitter := 0.0
var _jitter_t := 0.0
var _bob := 0.0
var _model_base_y := 0.0
var _idle_motion: IdleMotion
var _hand_mugs: Array = []

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
	# Figur aus der ID: alle Mitspieler sehen denselben Angestellten
	_figur = Figuren.einsetzen(self, Figuren.fuer_id(staff_id + FIGUR_VERSATZ))
	_model = _figur
	_anim = _figur.anim
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	_model_base_y = _model.position.y
	_set_standing()
	_collect_mugs()
	if _figur.braucht_idle_bewegung():
		_setup_idle_motion()
	_setup_hand_mugs()
	_refresh_label()

## Stehen: echte Stehanimation der Figur, beim Bean die eingefrorene Laufpose.
func _set_standing() -> void:
	if _anim == null:
		return
	_figur.stehen()
	_walking = false

func _set_walking() -> void:
	if _anim == null:
		return
	_figur.gehen()
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
## 1-2 Krüge landen in den Händen, der Rest als Traube vor dem Bauch.
func set_carrying(n: int) -> void:
	if carrying == n:
		return
	carrying = n
	for i in _hand_mugs.size():
		(_hand_mugs[i] as Node3D).visible = i < n
	var rest: int = maxi(0, n - _hand_mugs.size())
	for i in _mug_nodes.size():
		(_mug_nodes[i] as Node3D).visible = i < rest
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
		_figur.pose_auffrischen()   # Skelett aktualisieren, damit die Idle-Bewegung greift
		# im Stehen leicht umschauen und atmen, damit er nicht erstarrt wirkt
		_jitter_t -= delta
		if _jitter_t <= 0.0:
			_jitter_t = randf_range(2.0, 5.0)
			_idle_jitter = randf_range(-0.35, 0.35)
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset) + _idle_jitter, clampf(delta * 1.5, 0.0, 1.0))



## Ein Krug pro Hand, direkt an den Handknochen gehängt — der folgt damit
## wirklich der Handbewegung. Alles darüber hinaus wird als Traube vor dem
## Bauch gezeigt (wie eine echte Bedienung mehrere Maß trägt).
func _setup_hand_mugs() -> void:
	var sk := _figur.skelett
	if sk == null:
		return
	for bone_name in ["RightHand", "LeftHand"]:
		var b := sk.find_bone(bone_name)
		if b < 0:
			continue
		var ba := BoneAttachment3D.new()
		ba.bone_idx = b
		sk.add_child(ba)
		var krug := Node3D.new()
		krug.position = Vector3(0.0, -0.05, 0.0)
		krug.visible = false
		ba.add_child(krug)
		var glas := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.032
		cyl.bottom_radius = 0.032
		cyl.height = 0.1
		glas.mesh = cyl
		var mb := StandardMaterial3D.new()
		mb.albedo_color = Color(0.95, 0.72, 0.18)
		glas.material_override = mb
		krug.add_child(glas)
		var schaum := MeshInstance3D.new()
		var cyl2 := CylinderMesh.new()
		cyl2.top_radius = 0.034
		cyl2.bottom_radius = 0.034
		cyl2.height = 0.022
		schaum.mesh = cyl2
		var ms := StandardMaterial3D.new()
		ms.albedo_color = Color(0.98, 0.97, 0.92)
		schaum.material_override = ms
		schaum.position = Vector3(0.0, 0.055, 0.0)
		krug.add_child(schaum)
		_hand_mugs.append(krug)

## Organische Stehbewegung (Atmen, Gewicht verlagern, Kopf drehen) — nur für
## Figuren ohne echte Stehanimation.
func _setup_idle_motion() -> void:
	if _figur.skelett == null:
		return
	_idle_motion = IdleMotion.new()
	_idle_motion.name = "IdleMotion"
	_figur.skelett.add_child(_idle_motion)

## Für Tests: welche Figur dieser Angestellte hat.
func figur() -> Figur:
	return _figur
