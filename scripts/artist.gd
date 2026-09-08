class_name Artist
extends Node3D
## Künstler auf der Bühne — tanzt die ganze Schicht (Dance-Animation aus dem Modell).

var tier := 1

var _anim: AnimationPlayer
var _t := 0.0

@onready var _model: Node3D = $Model
@onready var _label: Label3D = $Label

func _ready() -> void:
	add_to_group("artist")
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		if _anim.has_animation("Dance"):
			_anim.get_animation("Dance").loop_mode = Animation.LOOP_LINEAR
			_anim.play("Dance")
		elif _anim.has_animation("Idle"):
			_anim.get_animation("Idle").loop_mode = Animation.LOOP_LINEAR
			_anim.play("Idle")
	# leicht versetzt starten, damit nicht alle synchron zappeln
	_t = randf() * 6.0

func set_tier(t: int) -> void:
	tier = t
	if _label:
		match t:
			1: _label.text = "🎸 Straßenmusiker"
			2: _label.text = "🎺 Blaskapelle"
			_: _label.text = "⭐ Star-Act"

func _process(delta: float) -> void:
	_t += delta
	if _model:
		_model.rotation.y = sin(_t * 1.4) * 0.35
		_model.position.y = absf(sin(_t * 3.0)) * 0.08
