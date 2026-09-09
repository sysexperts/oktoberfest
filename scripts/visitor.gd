class_name Visitor
extends Node3D
## Kirmes-Besucher draußen. Reine Kulisse: läuft den Ringweg zwischen den Ständen
## entlang, hat nichts mit dem Zelt zu tun. Läuft lokal (kein Netz-Traffic).

var speed := 1.6

var _route: Array = []
var _idx := 0
var _dir := 1
var _offset := Vector3.ZERO   # seitlicher Versatz, damit nicht alle in einer Reihe laufen
var _tgt := Vector3.ZERO
var _anim: AnimationPlayer
var _cur := ""
var _pause := 0.0

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	speed = randf_range(1.1, 2.1)
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Walk"):
			_anim.play("Walk")
			_cur = "Walk"
			_anim.seek(randf(), true)

## route: geschlossener Rundweg, start: Startpunkt, dir: +1 / -1 Laufrichtung.
func set_route(route: Array, start: int, dir: int) -> void:
	_route = route
	if _route.is_empty():
		return
	_idx = start % _route.size()
	_dir = dir
	_offset = Vector3(randf_range(-2.2, 2.2), 0.0, randf_range(-2.2, 2.2))
	position = _route[_idx] + _offset
	_advance()

func _advance() -> void:
	if _route.is_empty():
		return
	_idx = wrapi(_idx + _dir, 0, _route.size())
	_tgt = _route[_idx] + _offset

func _process(delta: float) -> void:
	_update_lod(delta)
	if _route.is_empty():
		return
	if _pause > 0.0:
		_pause -= delta
		_set_anim("Idle")
		return
	var to := _tgt - position
	to.y = 0
	if to.length() < 0.6:
		# ab und zu stehenbleiben, als würde man einen Stand anschauen
		if randf() < 0.25:
			_pause = randf_range(1.0, 3.5)
		_advance()
		return
	position += to.normalized() * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(delta * 4.0, 0.0, 1.0))
	_set_anim("Walk")

func _set_anim(n: String) -> void:
	if _anim and n != _cur and _anim.has_animation(n):
		_anim.play(n)
		_cur = n

## Abstandsabstufung: weit entfernte Besucher animieren nicht mit.
## Ohne das kosten hunderte Figuren zu viel Leistung.
const LOD_DIST := 42.0

var _lod_timer := 0.0
var _far := false

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
