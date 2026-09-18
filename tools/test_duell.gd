extends Node
## Finale prüfen: letzter Wiesn-Tag, Duell starten, der Spieler läuft die Tore
## automatisch ab (ohne Rennen), Ergebnis vom Server, Brief nach dem Sieg.
## → SHOT_DIR/duell_*.png

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._quest_step = gm.QUEST_COUNT
		gm._tent_stage = 1
		gm._day = 16
		gm._schwierigkeit = 0
		gm._broadcast_meta()
		await _warten(0.5)
		_check("Finale-Tag, Duell möglich", gm.duell_moeglich(), "")
		var w = gm.get_node("Kirmes/Wettschleppen")
		_check("Tore sichtbar", w.visible, "")
		var sp: Node3D = gm._players_nodes.get(1)
		gm.net_duell_start()
		await _warten(1.0)
		_check("Duell läuft", w.aktiv and w.ich_laufe, "")
		_bild("duell_start")
		await _warten(2.5)
		# Tore ablaufen: den Spieler Schritt für Schritt aufs nächste Tor schieben (Gehtempo)
		var zeit := 0.0
		var bild := false
		while w.ich_laufe and zeit < 60.0:
			var ziel: Node3D = w.naechstes_tor()
			if ziel == null:
				break
			var zu := ziel.global_position - sp.global_position
			zu.y = 0.0
			sp.rotation.y = atan2(-zu.x, -zu.z)
			sp.global_position += zu.normalized() * minf(3.2 * get_process_delta_time(), zu.length())
			sp.velocity = zu.normalized() * 3.2
			await get_tree().process_frame
			zeit += get_process_delta_time()
			if zeit > 6.0 and not bild:
				bild = true
				_bild("duell_lauf")
		await _warten(1.5)
		_bild("duell_ergebnis")
		_check("Duell beendet", not w.aktiv, "Zeit %.1f" % zeit)
		var dialog = gm.get_node("Dialog")
		print("  Huber sagt: ", dialog._text.text)
		while dialog.aktiv:
			dialog._weiter()
			await _warten(0.3)
		await _warten(0.5)
		_check("Sieg gespeichert, Brief offen", gm._duell_saison == gm._saison_nr and kino.aktiv, "Saison %d / %d, Brief %s" % [gm._duell_saison, gm._saison_nr, kino.aktiv])
		await _warten(0.8)
		_bild("duell_brief")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(n: String) -> void:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/%s.png" % n)
