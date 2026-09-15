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
