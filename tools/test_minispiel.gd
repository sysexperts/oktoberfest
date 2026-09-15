extends Node
## Minispiel prüfen: startet das Spiel, sucht die erste Bude mit dem Skript aus
## MINISPIEL, spielt Würfe im Raster (Neigung × Kraft) durch und zählt, wie viele
## Treffer landen — so lässt sich die Schwierigkeit einstellen. Danach eine Runde
## mit Treffern stehen lassen und Bilder speichern (SHOT_DIR).
##   Godot --path . res://tools/test_minispiel.tscn -- ringwurf

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	class Attrappe extends Node:
		func minispiel_beendet() -> void:
			pass

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var art := "ringwurf"
		if not OS.get_cmdline_user_args().is_empty():
			art = OS.get_cmdline_user_args()[0]
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		var bude: Node = null
		var anzahl := 0
		for s in get_tree().get_nodes_in_group("kirmes_spiel"):
			if s.get_script() and String(s.get_script().resource_path).get_file().get_basename() == art:
				anzahl += 1
				if bude == null:
					bude = s
		print("MINISPIEL %s: %d Buden" % [art, anzahl])
		if bude == null:
			get_tree().quit()
			return
		var spieler := Attrappe.new()
		add_child(spieler)
		if art == "entenangeln":
			await _entenangeln(bude, spieler, gm)
			get_tree().quit()
			return
		if art == "gluecksrad":
			await _gluecksrad(bude, spieler, gm)
			get_tree().quit()
			return
		# Raster: wie viele Kombinationen treffen?
		var treffer := 0
		var versuche := 0
		var zeilen := []
		for pitch_grad in range(-12, 13, 2):
			var zeile := ""
			for kraft_i in 21:
				# drei Seitenrichtungen (Krüge stehen versetzt): Zeichen = Anzahl Treffer
				var n := 0
				for yaw_grad: float in [-9.0, 0.0, 9.0]:
					bude.spiel_starten(spieler)
					bude._pitch = deg_to_rad(pitch_grad)
					bude._yaw = deg_to_rad(yaw_grad)
					bude._process(0.0)
					bude.werfen(kraft_i / 20.0)
					for k in 600:
						if bude._flug == null:
							break
						bude._fliegen(1.0 / 120.0)
					versuche += 1
					if pitch_grad == 0 and yaw_grad == 0.0 and kraft_i % 4 == 0 and "letzte_landung" in bude:
						print("  Landung Kraft %.1f: %s" % [kraft_i / 20.0, bude.letzte_landung])
					if bude._treffer > 0:
						treffer += 1
						n += 1
					bude._beenden()
				zeile += "." if n == 0 else str(n)
			zeilen.append("%+4d° %s" % [pitch_grad, zeile])
		for z in zeilen:
			print("  RASTER ", z)
		print("TREFFERQUOTE %d / %d" % [treffer, versuche])
		# Eine Runde mit Treffern für die Bilder
		bude.spiel_starten(spieler)
		var gesetzt := 0
		for pitch_grad in range(-12, 13, 2):
			for kraft_i in 21:
				if gesetzt >= 3 or bude._uebrig <= 0:
					break
				var vorher: int = bude._treffer
				bude._pitch = deg_to_rad(pitch_grad)
				bude._yaw = deg_to_rad([-9.0, 0.0, 9.0][kraft_i % 3])
				bude._process(0.0)
				bude.werfen(kraft_i / 20.0)
				while bude._flug != null:
					bude._fliegen(1.0 / 120.0)
				if bude._treffer > vorher:
					gesetzt += 1
		bude._pitch = 0.0
		bude._yaw = 0.0
		if "_warten" in bude:
			bude._warten = 999.0   # Runde nicht vor dem Bild beenden
		for i in 30:
			await get_tree().process_frame
		var dir := OS.get_environment("SHOT_DIR")
		get_viewport().get_texture().get_image().save_png(dir + "/spiel_%s_blick.png" % art)
		bude._beenden()
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 8.0 + Vector3(0, 3.2, 0) + stand.global_basis.x * 3.0
		kamera.look_at(stand.global_position + Vector3(0, 1.4, -1.0))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(dir + "/spiel_%s_stand.png" % art)
		print("MINISPIEL FERTIG")
		get_tree().quit()

	## Glücksrad: Automat mit perfektem Timing (klickt, wenn Winkel + Bremsweg auf der 10
	## liegt) und einer mit zufälligem Klick — zeigt, wie viel Können und Glück ausmacht.
	func _gluecksrad(bude: Node, spieler: Node, gm: Node) -> void:
		var dir := OS.get_environment("SHOT_DIR")
		var zehn: int = bude.WERTE.find(10)
		for modus: String in ["gezielt", "zufall"]:
			var summe := 0
			for runde in 6:
				bude.spiel_starten(spieler)
				var bild := false
				var klick_in := randf_range(0.2, 1.5)
				while bude.laeuft():
					if bude._zustand == bude.DREHT and bude._uebrig > 0:
						if modus == "gezielt":
							var stop: float = bude._winkel + bude.bremsweg
							var abstand := angle_difference(stop, zehn * bude.FELD)
							if absf(abstand) < 0.06:
								bude.anhalten()
						else:
							klick_in -= get_process_delta_time()
							if klick_in <= 0.0:
								bude.anhalten()
								klick_in = randf_range(0.2, 1.5)
					if not bild and bude._zustand == bude.ZEIGT and modus == "gezielt" and runde == 0:
						bild = true
						for i in 3:
							await get_tree().process_frame
						get_viewport().get_texture().get_image().save_png(dir + "/spiel_gluecksrad_blick.png")
					await get_tree().process_frame
				summe += bude.punkte()
			print("  %s: Schnitt %.1f Punkte" % [modus, summe / 6.0])
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.5 + Vector3(0, 2.6, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.8, -1.5))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(dir + "/spiel_gluecksrad_stand.png")
		print("MINISPIEL FERTIG")

	## Entenangeln: ein einfacher Spieler-Automat. Er fährt die Spitze vor die nächste
	## Ente (Vorhalt), senkt, wenn sie nah ist, und zieht hoch. Bild mitten im Spiel.
	func _entenangeln(bude: Node, spieler: Node, gm: Node) -> void:
		var dir := OS.get_environment("SHOT_DIR")
		for runde in 3:
			bude.spiel_starten(spieler)
			var bild := false
			var schritte := 0
			while bude.laeuft() and schritte < 60 * 40:
				schritte += 1
				var ziel: Node3D = null
				var best := 99.0
				for e: Node3D in bude._enten:
					if bude._raus.has(e):
						continue
					var d := Vector2(e.position.x - bude.haken_ort.x, e.position.z - bude.haken_ort.z).length()
					if d < best:
						best = d
						ziel = e
				if ziel and bude._am_haken == null:
					# Vorhalt: wo die Ente in 0,25 s ist
					var a: float = bude._winkel[ziel] + (bude._t + 0.25) * bude.enten_tempo
					var r: float = bude._radius[ziel]
					var vorn := Vector2(sin(a) * r, cos(a) * r)
					bude.ziel_setzen(bude._ziel.move_toward(vorn, 0.05))
					bude.senken_setzen(best < 0.25 or bude._tiefe > 0.3 and best < 0.4)
				else:
					bude.senken_setzen(false)
				await get_tree().process_frame
				if not bild and bude._am_haken != null and runde == 0:
					bild = true
					get_viewport().get_texture().get_image().save_png(dir + "/spiel_entenangeln_blick.png")
			print("  RUNDE %d: %d Enten, %d Punkte, %.1f s übrig" % [runde, bude._gefangen, bude.punkte(), bude._zeit_rest])
			if bude.laeuft():
				bude._beenden()
			for i in 5:
				await get_tree().process_frame
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.5 + Vector3(0, 3.4, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.2, -1.2))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(dir + "/spiel_entenangeln_stand.png")
		print("MINISPIEL FERTIG")
