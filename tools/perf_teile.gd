extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Leistung: Bereiche nacheinander abschalten und die Skriptzeit messen.

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
		await _warten(2.0)
		await _mess("alles an")
		print("Fenster echt: ", DisplayServer.window_get_size(), "  Grafikstufe: ", Einstellungen.grafik, "  Render-Skala: ", get_tree().root.scaling_3d_scale)
		var crowd := gm.get_node_or_null("Crowd")
		if crowd:
			print("Besucher-Knoten: ", crowd.get_child_count())
		get_tree().root.scaling_3d_scale = 0.5
		await _mess("Render-Skala 0,5")
		get_tree().root.scaling_3d_scale = 1.0
		if crowd:
			crowd.process_mode = Node.PROCESS_MODE_DISABLED
			crowd.visible = false
		await _mess("ohne Besucher")
		if crowd:
			crowd.process_mode = Node.PROCESS_MODE_INHERIT
			crowd.visible = true
		Einstellungen.grafik = 0
		Einstellungen.geaendert.emit()
		await _mess("Grafik niedrig")
		get_tree().quit()
		for a in gm.find_children("*", "AnimationMixer", true, false):
			(a as AnimationMixer).active = false
		await _mess("ohne Animationen")
		var karte := gm.get_node("Kirmes/Karte")
		for k in karte.get_children():
			k.process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("Kartenteile angehalten")
		for n in ["HUD", "Zielmarker", "Kirmes/Festleiter"]:
			var x := gm.get_node_or_null(n)
			if x:
				x.process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("HUD/Marker/Chef aus")
		gm.set_process(false)
		gm.set_physics_process(false)
		await _mess("GameManager aus")
		for p in gm._players_nodes.values():
			p.process_mode = Node.PROCESS_MODE_DISABLED
		await _mess("Spieler aus")
		karte.visible = false
		await _mess("Karte unsichtbar")
		get_tree().quit()

	func _mess(was: String) -> void:
		await _warten(1.0)
		var t := 0.0
		var summe := 0.0
		var f := 0
		while t < 2.0:
			await get_tree().process_frame
			t += get_process_delta_time()
			summe += Performance.get_monitor(Performance.TIME_PROCESS)
			f += 1
		print("%-26s FPS %5.1f  Skripte %.1f ms" % [was, f / t, summe / f * 1000.0])

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
