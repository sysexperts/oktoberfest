class_name Visitor
extends Node3D
## Kirmes-Besucher draußen. Reine Kulisse: läuft zwischen den Ständen umher,
## hat nichts mit dem Zelt zu tun. Läuft lokal auf jedem Client (kein Netz-Traffic).

var speed := 1.6

var _tgt := Vector3.ZERO
var _pick: Callable
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
			_anim.seek(randf() * 1.0, true)

## pick: Callable, die einen neuen Zielpunkt liefert.
func setup(pick: Callable, start: Vector3) -> void:
	_pick = pick
	position = start
	if _pick.is_valid():
		_tgt = _pick.call()

func _process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		_set_anim("Idle")
		return
	var to := _tgt - position
	to.y = 0
	if to.length() < 0.6:
		# kurz stehenbleiben, als würde man den Stand anschauen
		_pause = randf_range(0.0, 3.5)
		if _pick.is_valid():
			_tgt = _pick.call()
		return
	position += to.normalized() * speed * delta
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), clampf(delta * 4.0, 0.0, 1.0))
	_set_anim("Walk")

func _set_anim(n: String) -> void:
	if _anim and n != _cur and _anim.has_animation(n):
		_anim.play(n)
		_cur = n
