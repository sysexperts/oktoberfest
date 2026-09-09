class_name Visitor
extends Node3D
## Kirmes-Besucher. Bummelt von Stand zu Stand, bleibt davor stehen, geht weiter.
## Läuft immer in Blickrichtung — dadurch nie rückwärts oder seitlich schlurfend.

const LOD_DIST := 42.0      # weiter weg: Animation aus (Leistung)
const TURN_SPEED := 6.0

var speed := 1.5

var _crowd: Node = null
var _tgt := Vector3.ZERO
var _pause := 0.0
var _anim: AnimationPlayer
var _cur := ""
var _lod_timer := 0.0
var _far := false

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	speed = randf_range(1.1, 2.0)
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Walk"):
			_anim.play("Walk")
			_cur = "Walk"
			_anim.seek(randf(), true)   # versetzt starten

func setup(crowd: Node) -> void:
	_crowd = crowd
	position = crowd.random_start()
	_tgt = crowd.next_point(position)
	# gleich in Richtung Ziel schauen, damit der Start nicht rückwärts aussieht
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
		_set_anim("Idle")
		return
	var to := _tgt - position
	to.y = 0
	if to.length() < 0.7:
		# vor dem Stand stehenbleiben und schauen
		_pause = randf_range(1.5, 6.0)
		_tgt = _crowd.next_point(position)
		return
	# erst drehen, dann in Blickrichtung laufen — nie seitwärts/rückwärts
	var want := atan2(-to.x, -to.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * TURN_SPEED, 0.0, 1.0))
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	# nur losgehen, wenn er halbwegs in die richtige Richtung schaut
	if fwd.dot(to.normalized()) > 0.25:
		position += fwd * speed * delta
	_set_anim("Walk")

func _set_anim(n: String) -> void:
	if _anim and n != _cur and _anim.has_animation(n):
		_anim.play(n)
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
