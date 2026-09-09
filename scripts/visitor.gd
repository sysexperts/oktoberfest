class_name Visitor
extends Node3D
## Kirmes-Besucher. Bummelt von Stand zu Stand, bleibt davor stehen, geht weiter.
## Läuft immer in Blickrichtung — dadurch nie rückwärts oder seitlich schlurfend.

const LOD_DIST := 42.0      # weiter weg: Animation aus (Leistung)
const TURN_SPEED := 6.0
## "Idle" im Modell ist nur ein Einzelbild (T-Pose) — zum Stehen frieren wir
## die Laufanimation an einer neutralen Stelle ein.
const STAND_ANIM := "Walk"
const STAND_FRAME := 0.25
## So viele Besucher feiern beim Stehenbleiben statt nur dazustehen.
const DANCE_CHANCE := 0.08

## Das Bean-Modell schaut nicht in Godots Standardrichtung.
@export var model_yaw_offset := 180.0

var speed := 1.5

var _crowd: Node = null
var _tgt := Vector3.ZERO
var _pause := 0.0
var _anim: AnimationPlayer
var _state := ""        # "walk", "stand" oder "dance"
var _lod_timer := 0.0
var _far := false
var _jitter_t := 0.0
var _jitter := 0.0
var _bob := 0.0
var _base_y := 0.0
var _walk_speed := 1.0

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	speed = randf_range(1.1, 2.0)
	_walk_speed = randf_range(0.85, 1.15)
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	_base_y = _model.position.y
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Walk", "Dance", "Run"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		_go_walk()

func setup(crowd: Node) -> void:
	_crowd = crowd
	position = crowd.random_start()
	_tgt = crowd.next_point(position)
	var d := _tgt - position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)

func _go_walk() -> void:
	if _anim == null or _state == "walk" or not _anim.has_animation("Walk"):
		return
	_anim.play("Walk")
	_anim.seek(randf(), true)
	_anim.speed_scale = _walk_speed
	_anim.advance(0.0)
	_state = "walk"

func _go_stand() -> void:
	if _anim == null or _state == "stand" or not _anim.has_animation(STAND_ANIM):
		return
	_anim.play(STAND_ANIM)
	_anim.seek(STAND_FRAME, true)
	_anim.advance(0.0)
	_anim.speed_scale = 0.0   # eingefroren: ruhig stehen, kein Tanzen
	_state = "stand"

func _go_dance() -> void:
	if _anim == null or _state == "dance" or not _anim.has_animation("Dance"):
		_go_stand()
		return
	_anim.play("Dance")
	_anim.seek(randf() * 4.0, true)
	_anim.speed_scale = randf_range(0.8, 1.1)
	_state = "dance"

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
		_pause = randf_range(1.5, 6.0)
		if randf() < DANCE_CHANCE:
			_go_dance()
		else:
			_go_stand()
		_tgt = _crowd.next_point(position)
		return
	var want := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * TURN_SPEED, 0.0, 1.0))
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	if fwd.dot(to.normalized()) > 0.25:
		position += fwd * speed * delta
	_go_walk()
	_model.rotation.y = lerp_angle(_model.rotation.y, deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
	_model.position.y = _base_y

## Beim Stehen leicht umschauen und atmen — nur wenn er nicht gerade feiert.
func _idle_look(delta: float) -> void:
	if _state == "dance":
		return
	_jitter_t -= delta
	if _jitter_t <= 0.0:
		_jitter_t = randf_range(2.0, 5.0)
		_jitter = randf_range(-0.5, 0.5)
	_model.rotation.y = lerp_angle(_model.rotation.y,
		deg_to_rad(model_yaw_offset) + _jitter, clampf(delta * 1.5, 0.0, 1.0))
	_bob += delta
	_model.position.y = _base_y + sin(_bob * 1.5) * 0.012

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
		if far:
			_anim.advance(0.0)      # aktuelle Pose einfrieren, sonst T-Pose
			_anim.active = false
		else:
			_anim.active = true
