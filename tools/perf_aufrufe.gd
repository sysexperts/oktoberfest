extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Welche Teile verursachen die Zeichenaufrufe? Versteckt je Bereich alle Knoten und misst die Aufrufe
## (RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME) vor und nach dem Verstecken. Mit Fenster starten.
##   godot --path . res://tools/perf_aufrufe.tscn   (Standpunkt: im Zelt, Blick zur Theke, wie beim Spieler)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _messen() -> Array:
		await _warten(0.4)
		var dc := 0
		var tri := 0
		var n := 0
		for i in 8:
			await get_tree().process_frame
			dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			tri += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			n += 1
		return [dc / n, tri / n]

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
		var sp: Node3D = gm._players_nodes.get(1)
		var orte := {"Im Zelt (Blick Theke)": [Vector3(0, 0.1, 8), PI], "Draussen Mitte": [Vector3(0, 0.1, 25), 0.0]}
		for ort in orte:
			sp.global_position = orte[ort][0]
			sp.rotation.y = orte[ort][1]
			await _warten(1.0)
			var basis := await _messen()
			print("ORT %s: %d Aufrufe, %.2f Mio. Dreiecke" % [ort, basis[0], basis[1] / 1000000.0])
			# Bereiche: Kinder der Wurzel, die Karte nach Szenendatei
			var gruppen := {}
			for k in gm.get_children():
				if k is Node3D and k.name != "Kirmes":
					gruppen[str(k.name)] = [k]
			var kirmes := gm.get_node("Kirmes")
			for k in kirmes.get_children():
				if k.name == "Karte":
					for c in k.get_children():
						var pfad: String = c.scene_file_path if c.scene_file_path != "" else c.get_class()
						var key := "Karte/" + pfad.get_file()
						if not gruppen.has(key):
							gruppen[key] = []
						(gruppen[key] as Array).append(c)
				elif k is Node3D:
					gruppen["Kirmes/" + str(k.name)] = [k]
			var ergebnis := []
			for g in gruppen:
				var knoten: Array = gruppen[g]
				var war := []
				for n: Node3D in knoten:
					war.append(n.visible)
					n.visible = false
				var danach := await _messen()
				for i in knoten.size():
					(knoten[i] as Node3D).visible = war[i]
				ergebnis.append([basis[0] - danach[0], (basis[1] - danach[1]) / 1000000.0, g, knoten.size()])
			ergebnis.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
			for e: Array in ergebnis.slice(0, 22):
				print("AUFRUFE %5d  %.2f Mio. Dreiecke  %-34s (%d)" % [e[0], e[1], e[2], e[3]])
		get_tree().quit()
