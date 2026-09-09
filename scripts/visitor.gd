class_name Visitor
extends Node3D
## Kirmes-Besucher. Bummelt von Stand zu Stand, bleibt davor stehen, geht weiter.
## Läuft immer in Blickrichtung — dadurch nie rückwärts oder seitlich schlurfend.
const LOD_DIST := 42.0      # weiter weg: Animation aus (Leistung)
const TURN_SPEED := 6.0

## Das Bean-Modell schaut nicht in Godots Standardrichtung. Bei Rückwärtslaufen
## hier auf 0 oder 180 stellen — gilt für alle Besucher.
@export var model_yaw_offset := 180.0

var speed := 1.5

var _crowd: Node = null
var _tgt := Vector3.ZERO
var _pause := 0.0
var _anim: AnimationPlayer
var _cur := ""
var _lod_timer := 0.0
var _far := false
var _jitter_t := 0.0
var _jitter := 0.0

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	speed = randf_range(1.1, 2.0)
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk", "Dance"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_anim.speed_scale = randf_range(0.85, 1.2)
		if _anim.has_animation("Walk"):
			_anim.play("Walk")
			_cur = "Walk"
			_anim.seek(randf() * 2.0, true)   # versetzt starten

func setup(crowd: Node) -> void:
	_crowd = crowd
	position = crowd.random_start()
	_tgt = crowd.next_point(position)
	var d := _tgt - position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)

func _process(delta: float) -> void:
	_update_lod(delta)
	if _crowd == null:
		return
	if _pause > 0.0:
		_pause -= delta
		_idle_look(delta)
		return
	var to := _tgt - position
	to.y = 0
	if to.length() < 0.7:
		# vor dem Stand stehenbleiben und schauen
		_pause = randf_range(1.5, 6.0)
		# ein Teil feiert kurz statt nur dazustehen
		_set_anim("Dance" if randf() < 0.25 else "Idle")
		_tgt = _crowd.next_point(position)
		return
	# erst drehen, dann in Blickrichtung laufen — nie seitwärts oder rückwärts
	var want := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * TURN_SPEED, 0.0, 1.0))
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	if fwd.dot(to.normalized()) > 0.25:
		position += fwd * speed * delta
	_set_anim("Walk")
	_model.rotation.y = lerp_angle(_model.rotation.y, deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))

## Beim Stehen den Kopf/Körper leicht drehen, damit nicht alle erstarrt wirken.
func _idle_look(delta: float) -> void:
	_jitter_t -= delta
	if _jitter_t <= 0.0:
		_jitter_t = randf_range(1.2, 3.5)
		_jitter = randf_range(-0.7, 0.7)
	_model.rotation.y = lerp_angle(_model.rotation.y,
		deg_to_rad(model_yaw_offset) + _jitter, clampf(delta * 2.0, 0.0, 1.0))

func _set_anim(n: String) -> void:
	if _anim and n != _cur and _anim.has_animation(n):
		_anim.play(n)
		_anim.seek(randf() * 1.5, true)
		_cur = n

func _update_lod(delta: float) -> void:
	_lod_timer -= delta
	if _lod_timer > 0.0:
		return
	_lod_timer = randf_range(0.4, 0.8)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var far := global_position.distance_to(cam.global_position) > LOD_DIST
	if far == _far:
		return
	_far = far
	if _anim:
		_anim.active = not far
