extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Was kosten die Kirmes-Besucher? Misst an einem Standpunkt auf dem Platz je
## 4 s mit 0, der Hälfte und allen Besuchern: Skriptzeit, Physikzeit,
## Render-CPU/GPU (ms) und Zeichenaufrufe. FPS im Testfenster sind unbrauchbar.
## Aufruf: godot --path . res://tools/perf_besucher.tscn --resolution 1600x900

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		gm.set_process(false)   # Dichte nicht von der Uhr überschreiben lassen
		var menge := gm.get_node("Crowd")
		var vp := get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(vp, true)
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		cam.global_position = Vector3(-8, 1.7, 30)
		cam.look_at(Vector3(0, 1.5, 0))
		for stufe in [0.0, 0.5, 1.0]:
			menge.set_density(stufe)
			for i in 600:
				await get_tree().process_frame
				if menge._visitors.size() == menge._target:
					break
			await get_tree().create_timer(2.0).timeout
			var n := 0
			var s := {"proz": 0.0, "phys": 0.0, "rcpu": 0.0, "rgpu": 0.0, "calls": 0.0}
			var ende := Time.get_ticks_msec() + 4000
			while Time.get_ticks_msec() < ende:
				await get_tree().process_frame
				s.proz += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
				s.phys += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
				s.rcpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
				s.rgpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
				s.calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
				n += 1
			print("Besucher %4d: Skript %.2f ms · Physik %.2f ms · Render-CPU %.2f ms · Render-GPU %.2f ms · Aufrufe %d" % [
				menge._visitors.size(), s.proz / n, s.phys / n, s.rcpu / n, s.rgpu / n, int(s.calls / n)])
		get_tree().quit()
