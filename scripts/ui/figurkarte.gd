extends Button
## Karte in der Figurenwahl: beim Überfahren (oder Fokus) hebt sich das Porträt,
## wird etwas größer und heller; die gewählte Karte atmet leicht golden.

const HOVER_ZOOM := 1.1
const HOVER_HUB := -5.0

var _hover := false
var _tween: Tween
var _atmen: Tween

@onready var _inhalt: Control = $Inhalt

func _ready() -> void:
	mouse_entered.connect(_an.bind(true))
	mouse_exited.connect(_an.bind(false))
	focus_entered.connect(_an.bind(true))
	focus_exited.connect(_an.bind(false))
	toggled.connect(func(_a: bool) -> void: _atmen_pruefen())
	resized.connect(func() -> void: _inhalt.pivot_offset = _inhalt.size * Vector2(0.5, 0.45))
	_inhalt.pivot_offset = _inhalt.size * Vector2(0.5, 0.45)
	_atmen_pruefen()

func _an(an: bool) -> void:
	_hover = an
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_inhalt, "scale", Vector2.ONE * (HOVER_ZOOM if an else 1.0), 0.18)
	_tween.tween_property(_inhalt, "position:y", HOVER_HUB if an else 0.0, 0.18)
	_tween.tween_property(_inhalt, "modulate", Color(1.12, 1.08, 1.0) if an else Color.WHITE, 0.15)

## Gewählte Karte: sanftes Pulsieren der Helligkeit
func _atmen_pruefen() -> void:
	if _atmen:
		_atmen.kill()
	if not button_pressed:
		self_modulate = Color.WHITE
		return
	_atmen = create_tween().set_loops()
	_atmen.tween_property(self, "self_modulate", Color(1.18, 1.12, 0.95), 0.9).set_trans(Tween.TRANS_SINE)
	_atmen.tween_property(self, "self_modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)
