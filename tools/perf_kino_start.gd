extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Ruckeln nach dem Start messen: Bildzeiten (ms) sekundenweise für 24 s nach dem Laden.
## Mit Umgebungsvariable OHNE=1 wird die Eröffnung sofort beendet (Vergleich).
##   godot --path . res://tools/perf_kino_start.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var _zeiten: Array[float] = []

	var _proben: Array[String] = []
	var _letzte := 0

	func _process(delta: float) -> void:
		_zeiten.append(delta * 1000.0)
		var jetzt := Time.get_ticks_msec()
		if jetzt - _letzte >= 1000:
			_letzte = jetzt
			var rid := get_viewport().get_viewport_rid()
			_proben.append("Skript %5.1f ms  Physik %5.1f ms  Render CPU %5.1f ms  GPU %5.1f ms  Aufrufe %d  Objekte-Knoten %d" % [
				Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				RenderingServer.viewport_get_measured_render_time_cpu(rid), RenderingServer.viewport_get_measured_render_time_gpu(rid),
				int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		var kino = gm.get_node("Kino")
		var ohne := OS.get_environment("OHNE") == "1"
		print("Start: Eröffnung aktiv=", kino.aktiv, " t=", kino._titel_t, " ohne=", ohne)
		if ohne and kino.aktiv:
			kino._eroeffnung_ende()
		_zeiten.clear()
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 24000:
			await get_tree().process_frame
		var s := 0
		var i := 0
		while i < _zeiten.size():
			var summe := 0.0
			var hoechst := 0.0
			var n := 0
			var t := 0.0
			while i < _zeiten.size() and t < 1000.0:
				t += _zeiten[i]
				summe += _zeiten[i]
				hoechst = maxf(hoechst, _zeiten[i])
				n += 1
				i += 1
			print("Sekunde %2d: Bilder %3d  Schnitt %6.1f ms  schlimmstes %7.1f ms" % [s, n, summe / maxf(n, 1), hoechst])
			s += 1
		for k in _proben.size():
			print("Probe %2d: %s" % [k, _proben[k]])
		print("FERTIG")
		get_tree().quit()
