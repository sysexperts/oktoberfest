extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Lieferwagen prüfen: Bier bestellen, Anfahrt über die Allee, Abladen mit Staub,
## Wenden, Abfahrt. Besucher im Weg fliegen. → SHOT_DIR/van_*.png

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._quest_step = gm.QUEST_COUNT
		gm.net_book_tent("Test")
		Game.add_money(5000)
		gm.net_order_goods(1, 3)
		gm._van_state = 0
		await _warten(0.1)
		for o in gm._pending:
			o.t = 0.1
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(-1.8, 0.1, 40)   # Spieler steht im Weg
		var crowd := gm.get_node_or_null("Crowd")
		if crowd:
			crowd.set_density(0.4)
		await _warten(3.0)
		# ein paar Besucher auf die Allee stellen
		var vs := preload("res://scenes/visitor.tscn")
		for i in 6:
			var v := vs.instantiate()
			gm.add_child(v)
			v.setup(crowd)
			v.set_process(true)
		var n := 0
		for v in get_tree().get_nodes_in_group("visitor"):
			if n >= 6:
				break
			(v as Node3D).global_position = Vector3(-1.8 + randf_range(-0.5, 0.5), 0, 34 + n * 2.5)
			v._crowd = null   # stehen bleiben
			n += 1
		print("Besucher auf der Allee: ", n)
		var cam := Camera3D.new()
		gm.add_child(cam)
		cam.current = true
		var bilder := {1.5: "anfahrt", 5.0: "allee", 8.5: "halt", 10.0: "abladen", 12.5: "wenden", 15.0: "abfahrt"}
		var t := 0.0
		var geflogen := 0
		var spieler_flog := false
		while t < 16.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			var van: Node3D = gm._van_node
			if van:
				cam.global_position = van.global_position + Vector3(9, 5, 6)
				cam.look_at(van.global_position + Vector3(0, 1, 0), Vector3.UP)
			if sp.wird_geschleudert():
				spieler_flog = true
			for v in get_tree().get_nodes_in_group("visitor"):
				if v.fliegt():
					geflogen += 1
			for k in bilder.keys():
				if t >= k:
					Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/van_%s.png" % bilder[k])
					print("  %.1f s  Zustand %d  Wagen %s" % [t, gm._van_state, van.global_position if van else "weg"])
					bilder.erase(k)
		var pakete := 0
		for p in gm._packages.values():
			pakete += 1
		print("Pakete abgelegt: ", pakete, "  Besucher-Flugbilder: ", geflogen)
		print("Spieler umgefahren: ", spieler_flog)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
