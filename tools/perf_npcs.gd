extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Zählt Figuren und Animationen: wie viele laufen, wie viele sind weit weg, was kosten sie (Zeichenaufrufe, Dreiecke)?
##   godot --path . res://tools/perf_npcs.tscn   (mit Fenster, Tag 5 mit Besuchern)
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _mess() -> String:
		await _warten(1.5)
		var dc := 0
		var tri := 0
		var n := 0
		for i in 10:
			await get_tree().process_frame
			dc += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			tri += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			n += 1
		return "%d Aufrufe, %.2f Mio. Dreiecke" % [dc / n, tri / n / 1000000.0]
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		sp.rotation.y = 0.0
		gm._day = 5
		gm._apply_crowd(14.0)
		await _warten(40.0)
		var pos := sp.global_position
		var skel := gm.find_children("*", "Skeleton3D", true, false)
		var aktiv := 0
		var weit_aktiv := 0
		var sichtbar := 0
		var weit_sichtbar := 0
		for s in skel:
			var sk := s as Skeleton3D
			var d := sk.global_position.distance_to(pos)
			var vis := sk.is_visible_in_tree()
			if vis:
				sichtbar += 1
				if d > 60.0:
					weit_sichtbar += 1
		var anims := gm.find_children("*", "AnimationMixer", true, false)
		for a in anims:
			var m := a as AnimationMixer
			if m.active:
				aktiv += 1
				var n3 := m.get_parent()
				while n3 != null and not (n3 is Node3D):
					n3 = n3.get_parent()
				if n3 != null and (n3 as Node3D).global_position.distance_to(pos) > 60.0:
					weit_aktiv += 1
		print("NPC Skelette: %d, davon sichtbar im Baum: %d (weiter als 60 m: %d)" % [skel.size(), sichtbar, weit_sichtbar])
		print("NPC Animations-Knoten: %d, aktiv: %d (weiter als 60 m aktiv: %d)" % [anims.size(), aktiv, weit_aktiv])
		print("NPC Besucher: %d" % gm._crowd._visitors.size())
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/npcs.png")
		var je := {}
		for a in anims:
			var m := a as AnimationMixer
			if not m.active:
				continue
			var n3: Node = m
			var eigner := ""
			while n3 != null:
				if n3.get_script() != null and n3 != m and not (n3 is AnimationMixer) and (n3.get_script() as Script).resource_path.get_file() != "figur.gd":
					eigner = (n3.get_script() as Script).resource_path.get_file()
					break
				n3 = n3.get_parent()
			var d := 0.0
			var q: Node = m
			while q != null and not (q is Node3D):
				q = q.get_parent()
			if q != null:
				d = (q as Node3D).global_position.distance_to(pos)
			if not je.has(eigner):
				je[eigner] = [0, 0, 0]
			je[eigner][0] += 1
			if d > 25.0:
				je[eigner][1] += 1
			if d > 60.0:
				je[eigner][2] += 1
		for k in je:
			print("NPC aktiv %-24s gesamt %3d  >25 m %3d  >60 m %3d" % [k, je[k][0], je[k][1], je[k][2]])
		get_tree().quit()
