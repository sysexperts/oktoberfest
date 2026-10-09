extends CanvasLayer
## Leistungsanzeige: F3 blendet oben rechts Bildrate, Bildzeit, Zeichenaufrufe und Objekte ein.
## Zum Messen am echten Rechner (Aufbau: autoload/leistungsanzeige.tscn). Zeigt nichts, solange sie aus ist.

const INTERVALL := 0.5
@onready var _text: Label = $Rand/Text
var _t := 0.0

func _ready() -> void:
	layer = 120
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F3:
		visible = not visible
		_t = INTERVALL
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t < INTERVALL:
		return
	_t = 0.0
	var fps := Engine.get_frames_per_second()
	var ms := 1000.0 / maxf(1.0, float(fps))
	_text.text = "%d FPS  ·  %.1f ms\nAufrufe %d  ·  Objekte %d\nDreiecke %.1f Mio." % [
		fps, ms,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)) / 1000000.0]
