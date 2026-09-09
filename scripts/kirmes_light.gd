class_name KirmesLight
extends OmniLight3D
## Buntes, langsam wanderndes Kirmeslicht an den Ständen.

@export var hue_speed := 0.12
@export var pulse := 0.7

var _t := 0.0

func _ready() -> void:
	_t = randf() * 20.0   # jeder Stand fängt woanders an

func _process(delta: float) -> void:
	_t += delta
	light_color = Color.from_hsv(fmod(_t * hue_speed, 1.0), 0.7, 1.0)
	light_energy = 2.4 + sin(_t * 1.8) * pulse
