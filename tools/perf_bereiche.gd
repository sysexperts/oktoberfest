extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wohin geht die Zeit? Bereiche einzeln abschalten und die Bildzeit messen (nach dem Aufbau der Besucher).
##   godot --path . res://tools/perf_bereiche.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino._eroeffnung_ende()
		var crowd := gm.get_node("Crowd")
		var t0 := Time.get_ticks_msec()
		while crowd._visitors.size() < crowd._target and Time.get_ticks_msec() - t0 < 90000:
			await get_tree().process_frame
		print("Besucher da: ", crowd._visitors.size(), " nach ", (Time.get_ticks_msec() - t0) / 1000, " s")
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		sp.rotation.y = 0.0
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		Einstellungen.grafik = 0
		Einstellungen.geaendert.emit()
		var t1 := Time.get_ticks_msec()
		while crowd._visitors.size() != crowd._target and Time.get_ticks_msec() - t1 < 40000:
			await get_tree().process_frame
		await _mess("Niedrig Ausgang")
		crowd.process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("+ Besucher eingefroren")
		crowd.visible = false
		await _mess("+ Besucher unsichtbar")
		gm.get_node("HUD").process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("+ HUD aus")
		gm.set_process(false)
		gm.set_physics_process(false)
		await _mess("+ GameManager aus")
		gm.get_node("Kirmes").process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("+ Kirmes aus")
		for p in gm._players_nodes.values():
			p.process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("+ Spieler aus")
		var alle := get_tree().root.find_children("*", "", true, false)
		var z := {}
		for n in alle:
			if n.can_process() and (n.is_processing() or n.is_physics_processing()):
				var k: String = n.get_script().resource_path if n.get_script() else n.get_class()
				z[k] = int(z.get(k, 0)) + 1
		print("Noch aktiv: ", z)
		get_tree().quit()

	func _mess(was: String) -> void:
		for i in 12:
			await get_tree().process_frame
		var f := 0
		var t := 0.0
		var gpu := 0.0
		var cpu := 0.0
		var dc := 0
		var tri := 0
		while t < 3.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			f += 1
			var rid := get_viewport().get_viewport_rid()
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
			dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			tri += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		print("%-34s Bild %5.1f ms  Render CPU %5.1f  GPU %5.1f  Aufrufe %6d  Dreiecke %8d" % [was, t / f * 1000.0, cpu / f, gpu / f, dc / f, tri / f])
