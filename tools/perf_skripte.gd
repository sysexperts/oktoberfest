extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Welches Skript kostet wie viele Millisekunden pro Bild? Schaltet je Skript alle Knoten ab (process/physics)
## und misst Performance.TIME_PROCESS davor und danach. Ausgabe sortiert, größter Gewinn zuerst.
##   godot --path . res://tools/perf_skripte.tscn   (mit Fenster, ohne wäre die Messung leer)

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	## Mittelwert von TIME_PROCESS (ms) über ca. s Sekunden
	func _messen(s: float) -> float:
		var summe := 0.0
		var n := 0
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
			summe += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
			n += 1
		return summe / maxf(1.0, float(n))

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		await _warten(4.0)
		var gruppen := {}
		for n in gm.find_children("*", "", true, false):
			var sk: Script = n.get_script()
			if sk == null:
				continue
			if n.is_processing() or n.is_physics_processing():
				var pfad := sk.resource_path
				if not gruppen.has(pfad):
					gruppen[pfad] = []
				(gruppen[pfad] as Array).append(n)
		var basis := await _messen(3.0)
		print("BASIS Skripte %.1f ms, Gruppen %d" % [basis, gruppen.size()])
		var ergebnis := []
		var ruhe := []
		for i in 4:
			ruhe.append(await _messen(1.5))
		print("KONTROLLE ohne Eingriff: ", ruhe)
		for pfad: String in gruppen.keys():
			var knoten: Array = gruppen[pfad]
			for n: Node in knoten:
				n.set_process(false)
				n.set_physics_process(false)
			var danach := await _messen(1.5)
			for n: Node in knoten:
				n.set_process(true)
				n.set_physics_process(true)
			var davor := await _messen(1.5)
			ergebnis.append([davor - danach, pfad, knoten.size(), davor, danach])
		ergebnis.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		for e: Array in ergebnis.slice(0, 25):
			print("PERF %6.1f ms (davor %.1f, danach %.1f) %4d Knoten  %s" % [e[0], e[3], e[4], e[2], e[1]])
		get_tree().quit()
