extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
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
		if await Spielstart.starten(self) == null:
			return
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
		# Nicht auf der Karte? Dann eine auf die Wiese stellen (Baumodus-Karte)
		if bude == null and ResourceLoader.exists("res://scenes/kirmes/%s.tscn" % art):
			var karte = gm.get_node("Kirmes/Karte")
			karte.net_setzen("res://scenes/kirmes/%s.tscn" % art, Vector3(38, 0, -42), 0.0)
			await get_tree().process_frame
			bude = karte.get_child(karte.get_child_count() - 1)
			anzahl = 1
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
		if art == "stemmen":
			await _stemmen(bude, spieler, gm)
			get_tree().quit()
			return
		if art == "nagelbalken":
			await _nagelbalken(bude, spieler, gm)
			get_tree().quit()
			return
		if art in ["pfeilwurf", "maulwurf", "krugschieben"]:
			await call("_" + art, bude, spieler, gm)
			get_tree().quit()
			return
		if art == "kegeln":
			await _kegeln(bude, spieler, gm)
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
		Schuss.speichern(get_viewport(), dir + "/spiel_%s_blick.png" % art)
		bude._beenden()
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 8.0 + Vector3(0, 3.2, 0) + stand.global_basis.x * 3.0
		kamera.look_at(stand.global_position + Vector3(0, 1.4, -1.0))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		Schuss.speichern(get_viewport(), dir + "/spiel_%s_stand.png" % art)
		print("MINISPIEL FERTIG")
		get_tree().quit()

	## Kegeln: gerade mit fester Kraft, leicht schief, zufällig — echte Physik (Frames).
	func _kegeln(bude: Node, spieler: Node, gm: Node) -> void:
		var dir := OS.get_environment("SHOT_DIR")
		# Stehen die Fässchen ohne Kugel still? (umkippende Kegel wären ein Aufbaufehler)
		bude.spiel_starten(spieler)
		for i in 90:
			await get_tree().process_frame
		print("  RUHE: %d umgefallen ohne Wurf" % bude.umgefallen())
		bude._beenden()
		for modus: String in ["gerade", "schief", "zufall"]:
			var summe := 0
			for runde in 3:
				bude.spiel_starten(spieler)
				var bild := false
				while bude.laeuft():
					if bude._kugel == null and bude._ende_in < 0.0 and bude._uebrig > 0:
						match modus:
							"gerade":
								bude.rollen(randf_range(0.75, 0.9), deg_to_rad(randf_range(-0.8, 0.8)))
							"schief":
								bude.rollen(randf_range(0.6, 0.95), deg_to_rad(randf_range(-3.0, 3.0)))
							_:
								bude.rollen(randf(), deg_to_rad(randf_range(-9.0, 9.0)))
					if not bild and modus == "gerade" and runde == 0 and bude._kugel != null and bude._rollt > 0.45:
						bild = true
						Schuss.speichern(get_viewport(), dir + "/spiel_kegeln_blick.png")
					await get_tree().process_frame
				summe += bude.punkte()
			print("  %s: Schnitt %.1f Punkte" % [modus, summe / 3.0])
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.0 + Vector3(0, 2.6, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.0, -1.2))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		Schuss.speichern(get_viewport(), dir + "/spiel_kegeln_stand.png")
		print("MINISPIEL FERTIG")

	## Nagelbalken: Automat „gezielt“ schlägt, wenn Kraft hoch und Hammer mittig ist,
	## „zufall“ klickt irgendwann. Die Tweens laufen echt ab (await Frames).
	func _nagelbalken(bude: Node, spieler: Node, gm: Node) -> void:
		var dir := OS.get_environment("SHOT_DIR")
		bude.spiel_starten(spieler)
		await get_tree().process_frame
		var h: Node3D = bude._hammer
		var kopf := h.global_transform * Vector3(0, 0.98, 0)
		var nagel: Vector3 = bude._nagel.global_position
		print("  HAMMER sichtbar=%s kopf_bild=%s hinter=%s nagel_bild=%s lokal=%s" % [h.is_visible_in_tree(),
			bude._kamera.unproject_position(kopf), bude._kamera.is_position_behind(kopf),
			bude._kamera.unproject_position(nagel), bude._kamera.to_local(kopf)])
		bude._beenden()
		for modus: String in ["gezielt", "ungefaehr", "zufall"]:
			var summe := 0
			var krumm := 0
			for runde in 5:
				bude.spiel_starten(spieler)
				var klick_in := randf_range(0.2, 1.2)
				var bild := false
				var bild_in := 1.2
				while bude.laeuft():
					bild_in -= get_process_delta_time()
					if not bild and bild_in <= 0.0 and modus == "gezielt" and runde == 0 and not bude._animation:
						bild = true
						Schuss.speichern(get_viewport(), dir + "/spiel_nagelbalken_blick.png")
					var los := false
					match modus:
						"gezielt":
							los = bude._kraft > 0.9 and bude.genauigkeit() > 0.85
						"ungefaehr":
							los = bude._kraft > 0.7 and bude.genauigkeit() > 0.5
						_:
							klick_in -= get_process_delta_time()
							los = klick_in <= 0.0
							if los:
								klick_in = randf_range(0.2, 1.2)
					if los:
						bude.schlagen()
					await get_tree().process_frame
				summe += bude.punkte()
				if bude._krumm:
					krumm += 1
			print("  %s: Schnitt %.1f Punkte, %d von 5 krumm" % [modus, summe / 5.0, krumm])
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.0 + Vector3(0, 2.6, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.2, -1.0))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		Schuss.speichern(get_viewport(), dir + "/spiel_nagelbalken_stand.png")
		print("MINISPIEL FERTIG")

	## Maßkrugstemmen: Automaten mit unterschiedlich guter Reaktion (Gegensteuern mit
	## Verzögerung und Ungenauigkeit) — zeigt, wie lange man durchhält.
	func _stemmen(bude: Node, spieler: Node, gm: Node) -> void:
		var dir := OS.get_environment("SHOT_DIR")
		var schritt := 1.0 / 60.0
		for stufe: Array in [["ruhig", 0.12, 0.08], ["normal", 0.3, 0.2], ["hektisch", 0.5, 0.45]]:
			var summe := 0.0
			var punkte := 0
			for runde in 4:
				bude.spiel_starten(spieler)
				var verlauf: Array[float] = []
				var frames := 0
				while bude.laeuft() and frames < 60 * 70:
					frames += 1
					verlauf.append(bude._winkel)
					# Spieler sieht die Lage mit Verzögerung und korrigiert ungenau
					var verzug := int(float(stufe[1]) * 60.0)
					var gesehen: float = verlauf[maxi(0, verlauf.size() - 1 - verzug)]
					if frames % 3 == 0:
						bude.heben(-gesehen * 0.18 * randf_range(1.0 - float(stufe[2]), 1.0 + float(stufe[2])) + randf_range(-0.3, 0.3))
					bude._process(schritt)
					if frames == 60 * 12 and runde == 0 and stufe[0] == "normal":
						await get_tree().process_frame
						Schuss.speichern(get_viewport(), dir + "/spiel_stemmen_blick.png")
				summe += bude._gehalten
				punkte += bude.punkte()
				if bude.laeuft():
					bude._beenden()
			print("  %s: im Schnitt %.1f s gehalten, %.1f Punkte" % [stufe[0], summe / 4.0, punkte / 4.0])
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.5 + Vector3(0, 2.6, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.6, -1.2))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		Schuss.speichern(get_viewport(), dir + "/spiel_stemmen_stand.png")
		print("MINISPIEL FERTIG")

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
						Schuss.speichern(get_viewport(), dir + "/spiel_gluecksrad_blick.png")
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
		Schuss.speichern(get_viewport(), dir + "/spiel_gluecksrad_stand.png")
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
					Schuss.speichern(get_viewport(), dir + "/spiel_entenangeln_blick.png")
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
		Schuss.speichern(get_viewport(), dir + "/spiel_entenangeln_stand.png")
		print("MINISPIEL FERTIG")

	func _bild_stand(bude: Node, gm: Node, name: String) -> void:
		var kamera := Camera3D.new()
		gm.add_child(kamera)
		var stand := bude as Node3D
		kamera.global_position = stand.global_position + stand.global_basis.z * 7.5 + Vector3(0, 2.8, 0) + stand.global_basis.x * 2.5
		kamera.look_at(stand.global_position + Vector3(0, 1.6, -1.2))
		kamera.current = true
		for i in 20:
			await get_tree().process_frame
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/spiel_%s_stand.png" % name)
		kamera.queue_free()

	## Ballonstechen: Werfer, die auf einen Ballon zielen und mit unterschiedlicher
	## Streuung zu zufälligen Zeitpunkten werfen.
	func _pfeilwurf(bude: Node, spieler: Node, gm: Node) -> void:
		var schritt := 1.0 / 60.0
		# [Name, wartet bis Fadenkreuz so nah am Ballon ist (m), Zielfehler (m)]
		for stufe: Array in [["geduldig", 0.05, 0.03], ["normal", 0.1, 0.05], ["hastig", 9.0, 0.05]]:
			var punkte := 0
			for runde in 6:
				bude.spiel_starten(spieler)
				var frames := 0
				while bude.laeuft() and frames < 60 * 40:
					frames += 1
					if bude._flug < 0.0 and bude._ende_in < 0.0:
						var ziel: Node3D = null
						for b in bude._ballons.get_children():
							if not b.has_meta("geplatzt"):
								ziel = b
								break
						if ziel:
							bude._ziel = Vector2(ziel.position.x, ziel.position.y) + Vector2(randf_range(-1, 1), randf_range(-1, 1)) * float(stufe[2])
							var abstand: float = (bude.zielpunkt() - Vector2(ziel.position.x, ziel.position.y)).length()
							if abstand < float(stufe[1]) or frames % 60 == 0 and float(stufe[1]) > 1.0:
								bude.werfen()
					if frames == 60 * 5 and runde == 0 and stufe[0] == "normal":
						await get_tree().process_frame
						Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/spiel_pfeilwurf_blick.png")
					bude._process(schritt)
				punkte += bude.punkte()
				if bude.laeuft():
					bude._beenden()
			print("  %s: im Schnitt %.1f Punkte" % [stufe[0], punkte / 6.0])
		await _bild_stand(bude, gm, "pfeilwurf")
		print("MINISPIEL FERTIG")

	## Hau den Maulwurf: Spieler mit unterschiedlicher Reaktionszeit.
	func _maulwurf(bude: Node, spieler: Node, gm: Node) -> void:
		var schritt := 1.0 / 60.0
		for stufe: Array in [["flink", 0.35], ["normal", 0.5], ["mensch", 0.62], ["traege", 0.75]]:
			var punkte := 0
			for runde in 4:
				bude.spiel_starten(spieler)
				var gesehen := {}
				var frames := 0
				while bude.laeuft() and frames < 60 * 40:
					frames += 1
					for i in 9:
						if bude.ist_oben(i):
							gesehen[i] = float(gesehen.get(i, 0.0)) + schritt
							if gesehen[i] >= float(stufe[1]):
								bude.hauen(i)
						else:
							gesehen.erase(i)
					if frames == 60 * 8 and runde == 0 and stufe[0] == "normal":
						await get_tree().process_frame
						Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/spiel_maulwurf_blick.png")
					bude._process(schritt)
				print("    %s Runde %d: %d Treffer" % [stufe[0], runde, bude._treffer])
				punkte += bude.punkte()
				if bude.laeuft():
					bude._beenden()
			print("  %s: im Schnitt %.1f Punkte" % [stufe[0], punkte / 4.0])
		await _bild_stand(bude, gm, "maulwurf")
		print("MINISPIEL FERTIG")

	## Krugschieben: Spieler, die mit unterschiedlicher Genauigkeit loslassen und auf
	## das 3er- oder 2er-Feld zielen.
	func _krugschieben(bude: Node, spieler: Node, gm: Node) -> void:
		var schritt := 1.0 / 60.0
		for stufe: Array in [["genau", 0.008, -2.7], ["normal", 0.03, -2.5], ["grob", 0.07, -2.35], ["vorsichtig", 0.03, -2.1]]:
			var punkte := 0
			for runde in 6:
				bude.spiel_starten(spieler)
				var frames := 0
				var soll: float = bude.kraft_fuer(float(stufe[2])) + randf_range(-1, 1) * float(stufe[1])
				while bude.laeuft() and frames < 60 * 60:
					frames += 1
					var vorher: float = bude._kraft
					bude._process(schritt)
					if bude._tempo < 0.0 and bude._zeigen < 0.0 and bude._ende_in < 0.0 \
							and (vorher - soll) * (bude._kraft - soll) <= 0.0 and bude._kraft_dir > 0.0:
						bude.schieben()
						soll = bude.kraft_fuer(float(stufe[2])) + randf_range(-1, 1) * float(stufe[1])
					if frames == 40 and runde == 0 and stufe[0] == "normal":
						await get_tree().process_frame
						Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/spiel_krugschieben_blick.png")
				punkte += bude.punkte()
				if bude.laeuft():
					bude._beenden()
			print("  %s: im Schnitt %.1f Punkte" % [stufe[0], punkte / 6.0])
		await _bild_stand(bude, gm, "krugschieben")
		print("MINISPIEL FERTIG")
