extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kostet Konrads Zelt mit Gästen, Personal und Casino Leistung? Gleicher Standpunkt, einmal mit und einmal ohne
## die Figuren und das Casino. Vergleicht Zeichenaufrufe, Dreiecke, Render-CPU und GPU (Bildraten im Testfenster sind unbrauchbar).
##   godot --path . res://tools/perf_konrad.tscn --resolution 1600x900

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await _warten(3.0)
		var zelt := get_tree().get_first_node_in_group("huber_zelt") as Node3D
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		var sp: Node3D = gm._players_nodes.get(1)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(zelt.global_position + Vector3(0, 3.0, 22.0), zelt.global_position + Vector3(0, 2.0, 0))
		kam.make_current()
		sp.global_position = zelt.global_position + Vector3(0, 0.1, 30.0)
		await _mess("mit Figuren (nah)")
		kam.look_at_from_position(zelt.global_position + Vector3(0, 3.0, 80.0), zelt.global_position + Vector3(0, 2.0, 0))
		sp.global_position = zelt.global_position + Vector3(0, 0.1, 85.0)
		await _mess("mit Figuren (80 m weg)")
		kam.look_at_from_position(zelt.global_position + Vector3(0, 3.0, 22.0), zelt.global_position + Vector3(0, 2.0, 0))
		sp.global_position = zelt.global_position + Vector3(0, 0.1, 30.0)
		var figuren := 0
		for f in zelt.find_children("*", "Node3D", true, false):
			if f.get_script() != null and (f.get_script() as Script).resource_path.ends_with("huber_figur.gd"):
				f.visible = false
				f.process_mode = Node.PROCESS_MODE_DISABLED
				figuren += 1
		await _mess("ohne %d Figuren" % figuren)
		var casino := zelt.get_node_or_null("Casino") as Node3D
		if casino:
			casino.visible = false
		await _mess("ohne Figuren und Casino")
		get_tree().quit()

	func _mess(name: String) -> void:
		await _warten(1.5)
		var f := 0
		var t := 0.0
		var dc := 0
		var prim := 0
		while t < 3.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			f += 1
			dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		var vp := get_viewport().get_viewport_rid()
		print("%-28s Zeichenaufrufe %6d  Dreiecke %8d  Render-CPU %.1f ms  GPU %.1f ms" % [name, dc / f, prim / f, RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp)])

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
