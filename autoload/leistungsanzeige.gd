extends CanvasLayer
## Leistungsanzeige: F3 blendet oben rechts Bildrate, Bildzeit und die Aufteilung ein (Skripte, Physik,
## Render-CPU, GPU), dazu Zeichenaufrufe, Objekte, Auflösung und Grafikstufe. Zum Messen am echten Rechner
## (Aufbau: autoload/leistungsanzeige.tscn). Zeigt nichts und kostet nichts, solange sie aus ist.

const INTERVALL := 0.5

## Misst die echte Skriptzeit eines Bildes: eine Marke läuft als Erste, eine als Letzte (Priorität).
## Godots eigene Zahl TIME_PROCESS enthält den ganzen Bildaufbau samt Warten auf die Grafikkarte.
class Marke extends Node:
	var zeit := 0
	## Nur bei der letzten Marke: Dauer seit der ersten (µs)
	var erste: Marke = null
	var dauer := 0
	func _process(_delta: float) -> void:
		zeit = Time.get_ticks_usec()
		if erste != null:
			dauer = zeit - erste.zeit

var _anfang: Marke
var _ende: Marke
var _skript_ms := 0.0
@onready var _text: Label = $Rand/Text
var _t := 0.0

func _ready() -> void:
	layer = 120
	visible = false
	_anfang = Marke.new()
	_anfang.process_priority = -2147483647
	add_child(_anfang)
	_ende = Marke.new()
	_ende.process_priority = 2147483647
	_ende.erste = _anfang
	add_child(_ende)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).keycode == KEY_F3:
		visible = not visible
		_t = INTERVALL
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), visible)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not visible:
		return
	# Letztes Bild: Ende minus Anfang der Verarbeitung (geglättet)
	var roh := float(_ende.dauer) / 1000.0
	if roh >= 0.0 and roh < 1000.0:
		_skript_ms = lerpf(_skript_ms, roh, 0.1)
	_t += delta
	if _t < INTERVALL:
		return
	_t = 0.0
	var vp := get_viewport()
	var rid := vp.get_viewport_rid()
	var fps := Engine.get_frames_per_second()
	var groesse := Vector2(DisplayServer.window_get_size()) * vp.scaling_3d_scale
	var fenster := DisplayServer.window_get_size()
	_text.text = "%d FPS  ·  %.1f ms\
Skripte(echt) %.1f  Physik %.1f  Render-CPU %.1f  GPU %.1f ms\
Aufrufe %d  ·  Objekte %d  ·  Dreiecke %.1f Mio.\
Bild %dx%d (3D %dx%d)  ·  Grafik %d  ·  %s" % [
		fps, 1000.0 / maxf(1.0, float(fps)),
		_skript_ms,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(rid),
		RenderingServer.viewport_get_measured_render_time_gpu(rid),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		float(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)) / 1000000.0,
		fenster.x, fenster.y, int(groesse.x), int(groesse.y), Einstellungen.grafik,
		RenderingServer.get_video_adapter_name()]
