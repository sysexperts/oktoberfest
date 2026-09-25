extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Leistung messen: neues Solospiel, von mehreren Standpunkten je 3 s FPS,
## Zeichenaufrufe, Objekte, Dreiecke. Dazu: Knoten, Lichter (mit Schatten),
## Meshes nach Bereich. Ausgabe auf der Konsole.

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
		var alle := gm.find_children("*", "", true, false)
		var meshes := gm.find_children("*", "MeshInstance3D", true, false)
		var mm := gm.find_children("*", "MultiMeshInstance3D", true, false)
		var lichter := gm.find_children("*", "Light3D", true, false)
		var schatten := 0
		for l in lichter:
			if (l as Light3D).shadow_enabled and (l as Light3D).visible:
				schatten += 1
		print("Knoten: %d  Meshes: %d  MultiMeshes: %d  Lichter: %d (mit Schatten: %d)" % [alle.size(), meshes.size(), mm.size(), lichter.size(), schatten])
		# Meshes nach oberstem Bereich
		var bereiche := {}
		for m in meshes:
			var p: Node = m
			while p.get_parent() != gm and p.get_parent() != null:
				p = p.get_parent()
			var k := str(p.name)
			if p.name == "Kirmes":
				var q: Node = m
				while q.get_parent() != p:
					q = q.get_parent()
				k = "Kirmes/" + str(q.name)
			bereiche[k] = int(bereiche.get(k, 0)) + 1
		var sortiert := bereiche.keys()
		sortiert.sort_custom(func(a, b): return bereiche[a] > bereiche[b])
		for k in sortiert.slice(0, 12):
			print("   %-28s %d" % [k, bereiche[k]])
		verarbeiter(gm)
		RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
		print("Fenster: ", get_viewport().get_visible_rect().size, "  Skalierung 3D: ", get_viewport().scaling_3d_scale)
		var sp: Node3D = gm._players_nodes.get(1)
		var orte := {"Tor": [Vector3(0, 0.1, 84), 0.0], "Mitte vor Zelt": [Vector3(0, 0.1, 25), 0.0],
			"Im Zelt": [Vector3(0, 0.1, 8), 0.0], "Ost Buero": [Vector3(30, 0.1, 18), PI / 2], "Sued": [Vector3(0, 0.1, -40), PI]}
		for n in orte:
			sp.global_position = orte[n][0]
			sp.rotation.y = orte[n][1]
			await _warten(1.0)
			var f := 0
			var t := 0.0
			var dc := 0
			var obj := 0
			var prim := 0
			while t < 3.0:
				await get_tree().process_frame
				t += get_process_delta_time()
				f += 1
				dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				obj += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME)
				prim += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/perf_%s.png" % n.replace(" ", "_"))
			print("%-16s FPS %5.1f  Zeichenaufrufe %6d  Objekte %6d  Dreiecke %8d" % [n, f / t, dc / f, obj / f, prim / f])
			var vp := get_viewport().get_viewport_rid()
			print("                 Skripte %.1f ms  Physik %.1f ms  Render-CPU %.1f ms  GPU %.1f ms" % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0, RenderingServer.viewport_get_measured_render_time_cpu(vp), RenderingServer.viewport_get_measured_render_time_gpu(vp)])
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func verarbeiter(gm: Node) -> void:
		var zaehl := {}
		for n in gm.get_tree().root.find_children("*", "", true, false):
			if n.is_processing() or n.is_physics_processing():
				var k: String = n.get_script().resource_path if n.get_script() else n.get_class()
				zaehl[k] = int(zaehl.get(k, 0)) + 1
		var s := zaehl.keys()
		s.sort_custom(func(a, b): return zaehl[a] > zaehl[b])
		for k in s.slice(0, 15):
			print("   verarbeitet: %-50s %d" % [k, zaehl[k]])
