extends Node
## Tutorial-Anfang prüfen: Brief → Wiesnchef (Nein, dann Ja) → er geht zum Zelt
## → Zelt mieten → Dreck liegt im Zelt → wegfegen → er geht ins Büro.
## → SHOT_DIR/tut_*.png

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
		var dir := OS.get_environment("SHOT_DIR")
		var kino = gm.get_node("Kino")
		var dialog = gm.get_node("Dialog")
		var chef = gm.get_node("Kirmes/Wiesnchef")
		var sp: Node3D = gm._players_nodes.get(1)
		while kino.aktiv:
			kino._weiter()
			await _warten(0.2)
		await _warten(8.0)
		var start: Vector3 = chef.global_position
		_check("Wiesnchef wartet im Büro", not chef.unterwegs() and chef.global_position.distance_to(start) < 0.1 and gm._quest_step == 0, "Schritt %d" % gm._quest_step)
		sp.global_position = chef.global_position + chef.global_transform.basis.z * 2.2 + Vector3(0, 0.1, 0)
		sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.5)
		chef.ansprechen()
		for i in 4:
			await _warten(0.4)
			dialog._weiter()
		await _warten(1.0)
		_bild(dir + "/tut_frage.png")
		_check("Frage mit Ja/Nein", dialog._auswahl.visible, dialog._text.text)
		dialog._waehlen(1)
		await _warten(1.0)
		_bild(dir + "/tut_nein.png")
		while dialog.aktiv:
			dialog._weiter()
			await _warten(0.3)
		await _warten(1.0)
		_check("Nein: bleibt im Büro", gm._quest_step == 0 and not chef.unterwegs(), "")
		chef.ansprechen()
		for i in 4:
			await _warten(0.4)
			dialog._weiter()
		await _warten(0.5)
		dialog._waehlen(0)
		await _warten(1.0)
		while dialog.aktiv:
			dialog._weiter()
			await _warten(0.3)
		await _warten(1.0)
		_check("Ja: Schritt 1, er läuft los", gm._quest_step == 1 and chef.unterwegs(), "Schritt %d" % gm._quest_step)
		var t := 0.0
		while chef.unterwegs() and t < 60.0:
			await _warten(0.5)
			t += 0.5
		gm.net_book_tent.rpc_id(1, "Testzelt")
		await _warten(1.0)
		var dreck := 0
		for m in gm._messes.values():
			if m.ist_dreck():
				dreck += 1
		_check("Nach dem Mieten: Schritt 2 und Dreck im Zelt", gm._quest_step == 2 and dreck >= 10, "Schritt %d, Dreck %d" % [gm._quest_step, dreck])
		t = 0.0
		while chef.unterwegs() and t < 60.0:
			await _warten(0.5)
			t += 0.5
		# Blick ins Zelt auf den Dreck
		sp.global_position = Vector3(0, 0.1, 13)
		sp.rotation.y = 0.0
		sp.look_at(Vector3(0, 0.0, 2), Vector3.UP)
		await _warten(1.0)
		_bild(dir + "/tut_dreck.png")
		sp.global_position = Vector3(-1, 0.1, -3)
		sp.look_at(Vector3(-3, 0.5, -10), Vector3.UP)
		await _warten(0.6)
		_bild(dir + "/tut_planen.png")
		for id in gm._messes.keys():
			if gm._mess_kind.get(id, 0) == 10:
				for k in 110:
					gm.net_clean(id)
		await _warten(0.4)
		_bild(dir + "/tut_plane_halb.png")
		var geld_plane: int = Game.money
		for id in gm._messes.keys():
			if gm._mess_kind.get(id, 0) == 10:
				for k in 200:
					gm.net_clean(id)
		await _warten(0.2)
		_bild(dir + "/tut_plane_faellt.png")
		_check("Plane bringt kein Geld", Game.money == geld_plane, "%d → %d" % [geld_plane, Game.money])
		# nah an einem Haufen, mit Besen
		var ms: Array = gm._messes.values()
		for i in 5:
			var m: Node3D = ms[i]
			sp.global_position = m.global_position + Vector3(0, 0.1, 1.6)
			sp.look_at(m.global_position + Vector3(0, 0.1, 0), Vector3.UP)
			sp._fegt_bis = Time.get_ticks_msec() / 1000.0 + 0.1
			sp._head.rotation.x = -0.75
			await _warten(0.6)
			_bild(dir + "/tut_haufen_%d.png" % i)
		# alles wegfegen
		for id in gm._messes.keys().duplicate():
			for k in 400:
				if not gm._messes.has(id):
					break
				gm.net_clean(id)
			await _warten(0.05)
		await _warten(1.0)
		_check("Noch Säcke offen: Schritt bleibt 2", gm._quest_step == 2, "Schritt %d, Säcke %d" % [gm._quest_step, gm._muell_erzeugt])
		# Säcke zum Müllplatz tragen
		for id in gm._packages.keys().duplicate():
			if gm._packages[id].kind == 3:
				gm.net_pickup_package(id)
				gm.net_muell_abgeben()
		await _warten(1.0)
		sp.global_position = Vector3(-3, 0.1, 19.5)
		sp.global_position = Vector3(-3.3, 0.1, 18.3)
		sp.look_at(Vector3(-5, 0.4, 16.3), Vector3.UP)
		await _warten(0.6)
		_bild(dir + "/tut_muellplatz.png")
		_check("Sauber: Schritt 3, er geht ins Büro", gm._quest_step == 3 and chef.unterwegs(), "Schritt %d" % gm._quest_step)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(pfad: String) -> void:
		get_viewport().get_texture().get_image().save_png(pfad)
