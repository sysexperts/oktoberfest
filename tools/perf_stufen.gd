extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kosten je Grafikstufe: Render-CPU und GPU (ms) sowie Zeichenaufrufe, an zwei Standpunkten.
## Mit Fenster starten: godot --path . res://tools/perf_stufen.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _messen(vp: RID) -> String:
		await _warten(1.5)
		var cpu := 0.0
		var gpu := 0.0
		var dc := 0
		var n := 0
		var t := 0.0
		while t < 2.5:
			await get_tree().process_frame
			t += get_process_delta_time()
			cpu += RenderingServer.viewport_get_measured_render_time_cpu(vp)
			gpu += RenderingServer.viewport_get_measured_render_time_gpu(vp)
			dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			n += 1
		return "Render-CPU %5.1f ms  GPU %5.1f ms  Aufrufe %5d" % [cpu / n, gpu / n, dc / n]

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await _warten(3.0)
		var vp := get_viewport().get_viewport_rid()
		RenderingServer.viewport_set_measure_render_time(vp, true)
		var we := gm.get_node("WorldEnvironment") as WorldEnvironment
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		sp.rotation.y = 0.0
		for stufe in [2, 0]:
			Einstellungen.grafik = stufe
			Einstellungen.geaendert.emit()
			var vpn := get_viewport()
			print("EXP stufe %d basis:            %s" % [stufe, await _messen(vp)])
			var lichter := gm.find_children("*", "Light3D", true, false)
			var war := []
			for l in lichter:
				war.append((l as Light3D).visible)
				(l as Light3D).visible = false
			print("EXP stufe %d alle Lichter aus: %s" % [stufe, await _messen(vp)])
			for k in lichter.size():
				(lichter[k] as Light3D).visible = war[k]
			vpn.scaling_3d_scale = 0.5
			print("EXP stufe %d 3D-Aufloesung 50%%: %s" % [stufe, await _messen(vp)])
			vpn.scaling_3d_scale = 1.0
			var env := we.environment
			we.environment = null
			print("EXP stufe %d ohne Environment: %s" % [stufe, await _messen(vp)])
			we.environment = env
			var sonne := gm.get_node("Sun") as Light3D
			var sv := sonne.visible
			sonne.visible = false
			print("EXP stufe %d ohne Sonne:       %s" % [stufe, await _messen(vp)])
			sonne.visible = sv
		get_tree().quit()
