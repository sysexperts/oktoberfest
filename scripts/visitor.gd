class_name Visitor
extends Node3D
## Kirmes-Besucher. Bummelt von Stand zu Stand, bleibt davor stehen, geht weiter.
## Läuft immer in Blickrichtung — dadurch nie rückwärts oder seitlich schlurfend.
## Jeder Besucher bekommt zufällig eine Figur aus scripts/figuren.gd.

const Figuren := preload("res://scripts/figuren.gd")
const LOD_DIST := 42.0      # weiter weg: Animation aus (Leistung)
const TURN_SPEED := 6.0
## So viele Besucher feiern beim Stehenbleiben statt nur dazustehen.
const DANCE_CHANCE := 0.08
## So viele machen stattdessen eine Extra-Bewegung (Kopf kratzen …), wenn die Figur eine hat.
const EXTRA_CHANCE := 0.12

## Die Figuren schauen nicht in Godots Standardrichtung.
@export var model_yaw_offset := 180.0

var speed := 1.5

var _crowd: Node = null
var _tgt := Vector3.ZERO
var _pause := 0.0
var _figur: Figur
var _state := ""        # "walk", "stand", "dance" oder "extra"
var _lod_timer := 0.0
var _far := false
var _jitter_t := 0.0
var _jitter := 0.0
var _base_y := 0.0
var _walk_speed := 1.0
var _idle_motion: IdleMotion

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	# Draußen läuft alles nur lokal — Zufall reicht, niemand muss dieselbe Figur sehen
	_figur = Figuren.einsetzen(self, Figuren.zufaellig())
	_model = _figur
	speed = randf_range(1.1, 2.0)
	_walk_speed = randf_range(0.85, 1.15)
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	_base_y = _model.position.y
	_go_walk()
	if _figur.braucht_idle_bewegung():
		_setup_idle_motion()

func setup(crowd: Node) -> void:
	_crowd = crowd
	position = crowd.random_start()
	_tgt = crowd.next_point(position)
	var d := _tgt - position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)

func _go_walk() -> void:
	if _state == "walk":
		return
	_figur.gehen(_walk_speed)
	_state = "walk"

func _go_stand() -> void:
	if _state == "stand":
		return
	_figur.stehen()
	_state = "stand"

func _go_dance() -> void:
	if _state == "dance":
		return
	if _figur.tanzen(randf_range(0.8, 1.1)):
		_state = "dance"
	else:
		_go_stand()

func _go_extra() -> void:
	if _figur.extra():
		_state = "extra"
	else:
		_go_stand()

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
		var wurf := randf()
		if wurf < DANCE_CHANCE:
			_go_dance()
		elif wurf < DANCE_CHANCE + EXTRA_CHANCE:
			_go_extra()
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
	if _idle_motion:
		_idle_motion.idle = false
	_model.rotation.y = lerp_angle(_model.rotation.y, deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
	_model.position.y = _base_y

## Beim Stehen leicht umschauen und atmen — nur wenn er nicht gerade feiert.
func _idle_look(delta: float) -> void:
	if _idle_motion:
		_idle_motion.idle = true
	if _state == "stand":
		_figur.pose_auffrischen()   # nur beim Standbild-Modell nötig
	if _state == "dance" or _state == "extra":
		return
	_jitter_t -= delta
	if _jitter_t <= 0.0:
		_jitter_t = randf_range(2.0, 5.0)
		_jitter = randf_range(-0.5, 0.5)
	_model.rotation.y = lerp_angle(_model.rotation.y,
		deg_to_rad(model_yaw_offset) + _jitter, clampf(delta * 1.5, 0.0, 1.0))

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
	var anim := _figur.anim
	if anim:
		if far:
			anim.advance(0.0)      # aktuelle Pose einfrieren, sonst T-Pose
			anim.active = false
		else:
			anim.active = true

## Organische Stehbewegung — nur für Figuren ohne echte Stehanimation.
func _setup_idle_motion() -> void:
	if _figur.skelett == null:
		return
	_idle_motion = IdleMotion.new()
	_idle_motion.name = "IdleMotion"
	_figur.skelett.add_child(_idle_motion)
