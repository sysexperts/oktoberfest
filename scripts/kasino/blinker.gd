extends GeometryInstance3D
## Lässt Leuchtröhren und Lampen im Casino flackern (Neon): leuchtet im Wechsel hell und gedämpft.
@export var takt := 0.9
@export var zufall := 0.35
@export var dunkel := 0.45

var _t := 0.0
var _an := true

func _ready() -> void:
	_t = randf() * takt

func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_an = not _an
		_t = takt * randf_range(1.0 - zufall, 1.0 + zufall)
		transparency = 0.0 if _an else 1.0 - dunkel
