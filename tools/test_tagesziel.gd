extends Node
## Tagesziele und Sepps Schulden prüfen (Logik + Bild der Aufgabenkarte und des
## Wiesnchef-Gesprächs). → SHOT_DIR/tagesziel_*.png

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0

	func _check(name: String, ok: bool, info: String) -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])
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
		await _warten(3.0)
		var dir := OS.get_environment("SHOT_DIR")
		_check("Neues Spiel: keine Rate bezahlt", gm._bank_bezahlt == 0, str(gm._bank_bezahlt))
		_check("Nächste Rate Tag 4", gm.bank_naechste() == [4, 1500], str(gm.bank_naechste()))
		# Während des Tutorials kein Tagesziel
		gm._tagesziel_waehlen()
		_check("im Tutorial kein Ziel", gm._tagesziel.is_empty(), str(gm._tagesziel))
		gm._quest_step = gm.QUEST_COUNT
		gm._day = 4
		gm._tagesziel_waehlen()
		_check("Ziel gewählt", not gm._tagesziel.is_empty(), str(gm._tagesziel))
		gm._tagesziel = {"typ": "bedienen", "ziel": 43, "lohn": 260}
		gm._served = 50
		var geld: int = Game.money
		gm._tagesziel_auswerten()
		_check("Belohnung ausgezahlt", Game.money == geld + 260, "%d → %d" % [geld, Game.money])
		geld = Game.money
		gm._bank_abbuchen()
		_check("Rate Tag 4 abgebucht", Game.money == geld - 1500 and gm._bank_bezahlt == 1, "%d, bezahlt %d" % [Game.money, gm._bank_bezahlt])
		gm._bank_abbuchen()
		_check("nicht doppelt", gm._bank_bezahlt == 1, "")
		gm._tagesziel = {"typ": "bedienen", "ziel": 43, "lohn": 260}
		gm._served = 12
		gm._broadcast_meta()
		await _warten(1.5)
		_bild(dir + "/tagesziel_karte.png")
		var zeilen: Array[String] = gm.chef_tageszeilen(false, gm._hud._zustand)
		_check("Chef sagt Ziel + Bank", zeilen.size() == 2 and zeilen[0].contains("43") and zeilen[1].contains("Tag 8"), str(zeilen))
		# Gespräch am Büro
		var chef = gm.get_node("Kirmes/Wiesnchef")
		await _warten(1.0)
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = chef.global_position + chef.global_transform.basis.z * 2.2 + Vector3(0, 0.1, 0)
		sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		# Abschiedsgespräch (Station 13) zuerst hören
		chef.ansprechen()
		var dialog = gm.get_node("Dialog")
		while dialog.aktiv:
			dialog._weiter()
			await _warten(0.1)
		_check("Chef hat Tagesneues", chef.hat_neues(), "")
		chef.ansprechen()
		await _warten(1.5)
		_bild(dir + "/tagesziel_chef.png")
		print("  Chef: ", dialog._text.text)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(pfad: String) -> void:
		get_viewport().get_texture().get_image().save_png(pfad)
