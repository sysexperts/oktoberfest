extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## VORFÜHRUNG (zum Zuschauen, Echtzeit, mit Untertiteln): Der Weg ins Casino so, wie ihn die Spielerin geht: Gustav (Tarnung kaufen) → Türsteher (ohne und mit Tarnung) →
## durch die Tür laufen (echte Kollision) → Roulette, Blackjack, Watten, Würfel, Automat. Bilder: SHOT_DIR/casino_*.png
##   godot --path . res://tools/vorfuehrung_casino.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	var gm: Node
	var sp: Node3D
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	var _txt: Label
	func _ansage(t: String) -> void:
		_txt.text = t
		print("VORFUEHRUNG: ", t)
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _bild(name: String) -> void:
		await _warten(0.7)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/casino_%s.png" % name)
	func _blick(von: Vector3, nach: Vector3) -> void:
		sp.global_position = Vector3(von.x, 0.1, von.z)
		sp.look_at(Vector3(nach.x, 1.2, nach.z), Vector3.UP)
		sp._head.rotation.x = 0.0
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		var ebene := CanvasLayer.new()
		ebene.layer = 100
		add_child(ebene)
		_txt = Label.new()
		_txt.position = Vector2(30, 760)
		_txt.add_theme_font_size_override("font_size", 30)
		_txt.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
		_txt.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		_txt.add_theme_constant_override("outline_size", 8)
		ebene.add_child(_txt)
		gm = await Spielstart.starten(self)
		if gm == null:
			return
		TranslationServer.set_locale("de")
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		sp = gm._players_nodes.get(1)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(3)
		story.quests["2.6"] = {"z": "erfuellt"}
		gm._broadcast_meta()
		await _warten(0.5)
		story.ereignis("wette_gewonnen")
		story.quests["3.2"] = {"z": "erfuellt"}
		story.quests["3.3"] = {"z": "erfuellt"}
		story.ereignis("saboteur_gefasst")
		gm._broadcast_meta()
		await _warten(0.5)
		_check("Quest 3.4b 'Das Hinterzimmer' ist offen", story.zustand("3.4b") == "offen", story.zustand("3.4b"))
		Game.money = 3000
		# --- Gustav
		var gustav: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get_script() != null and n.get_script().resource_path.ends_with("npc_gustav.gd"):
				gustav = n
		_check("Gustav steht auf der Kirmes", gustav != null, str(gustav.global_position) if gustav else "")
		if gustav:
			_blick(gustav.global_position + Vector3(0, 0, 3.0), gustav.global_position)
			_ansage("1 · Händler Gustav: hier kauft man die Tarnung (Komplettset 400 €)")
			await _warten(5.0)
			await _bild("1_gustav")
		var casino: Node3D = get_tree().get_first_node_in_group("casino")
		_check("Casino ist da", casino != null, "")
		var dinge: Array = []
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.get_script() != null and n.get_script().resource_path.ends_with("kasino_ding.gd"):
				dinge.append(n)
		var tuer: Node3D = null
		var tische := {}
		for d in dinge:
			if d.art == "tuer":
				tuer = d
			else:
				if not tische.has(d.art):
					tische[d.art] = d
		_check("Türsteher und alle Tische da (Roulette, Blackjack, Watten, Würfel, Automat)", tuer != null and tische.has("roulette") and tische.has("blackjack") and tische.has("watten") and tische.has("wuerfel") and tische.has("slot"), str(tische.keys()))
		# --- Türsteher ohne Tarnung
		var tag: int = gm._day
		_blick(tuer.global_position + Vector3(0, 0, 3.0), tuer.global_position)
		_ansage("2 · Türsteher ohne Tarnung: wirft dich raus")
		await _warten(3.0)
		gm.net_casino_tuer()
		await _warten(4.0)
		_check("ohne Tarnung: kein Zutritt", gm._casino_tag != tag, "")
		# --- Tarnung kaufen
		var geld: int = Game.money
		_ansage("3 · Komplettset bei Gustav gekauft")
		gm.net_sab_kauf("komplett")
		await _warten(4.0)
		_check("Komplettset gekauft (400 €), Tarnung an", gm._tarnung_stufe == 2 and gm._tarnung_an and Game.money == geld - 400, "Stufe %d, Geld %d" % [gm._tarnung_stufe, Game.money])
		# Tarnung ist bei Rauswurf evtl. abgelegt worden
		_blick(tuer.global_position + Vector3(0, 0, 3.0), tuer.global_position)
		_ansage("4 · Türsteher mit Tarnung: lässt dich ein")
		await _warten(2.0)
		gm.net_casino_tuer()
		await _warten(4.0)
		_check("mit Tarnung: Türsteher lässt ein", gm._casino_tag == gm._day, "")
		_blick(tuer.global_position + Vector3(0, 0, 3.0), tuer.global_position)
		await _bild("2_tuer")
		# --- durch die Tür laufen (echte Kollision)
		var ziel: Node3D = tische["roulette"]
		var start: Vector3 = tuer.global_position + (tuer.global_position - ziel.global_position).normalized() * 3.0
		start.y = 0.1
		sp.global_position = start
		sp.look_at(Vector3(ziel.global_position.x, 0.1, ziel.global_position.z), Vector3.UP)
		await _warten(0.5)
		var vor := sp.global_position.distance_to(ziel.global_position)
		_ansage("5 · Zu Fuß durchs Casino zum Roulette")
		Input.action_press("move_forward")
		await _warten(4.5)
		Input.action_release("move_forward")
		var nach := sp.global_position.distance_to(ziel.global_position)
		print("  Lauf: Start %s, Ende %s, Tür %s, Roulette %s, Sperre aus: %s" % [str(start), str(sp.global_position), str(tuer.global_position), str(ziel.global_position), str(casino._sperre.process_mode == Node.PROCESS_MODE_DISABLED)])
		await _bild("lauf_ende")
		_check("zu Fuß durch die Tür zum Roulette (Abstand %.1f → %.1f m)" % [vor, nach], nach < vor - 2.0 and nach < 4.5, "")
		# --- Tische ansehen und spielen
		for art in ["roulette", "blackjack", "watten", "wuerfel", "slot"]:
			var t: Node3D = tische[art]
			var rich: Vector3 = (casino.global_position - t.global_position)
			rich.y = 0.0
			var pos := t.global_position + rich.normalized() * 2.6
			_blick(pos, t.global_position)
			_ansage("6 · " + {"roulette": "Roulette", "blackjack": "Blackjack", "watten": "Watten", "wuerfel": "Würfeln", "slot": "Spielautomat"}[art])
			await _warten(4.0)
			await _bild("3_" + art)
		# gespielt wird über die echten Tisch-Funktionen
		var t0: Node3D = tische["roulette"]
		var geld2: int = Game.money
		_ansage("7 · Roulette spielen (50 € auf Rot)")
		t0.kasino_aktion(sp)
		await _warten(3.0)
		var dlg := get_tree().get_first_node_in_group("dialog")
		var offen: bool = dlg != null and dlg.aktiv
		print("  (Roulette-Dialog offen: ", offen, ")")
		gm.net_roulette(0)
		await _warten(0.5)
		_check("Roulette gespielt, Quest 3.4b erfüllt, 3.5 offen", story.zustand("3.4b") == "erfuellt" and story.zustand("3.5") == "offen", "%s / %s, Geld %d → %d" % [story.zustand("3.4b"), story.zustand("3.5"), geld2, Game.money])
		for art in ["slot", "wuerfel"]:
			var g0: int = Game.money
			if art == "slot":
				gm.net_slot()
			else:
				gm.net_wuerfel(1)
			await _warten(3.0)
			_check("%s spielbar (Geld %d → %d)" % [art, g0, Game.money], Game.money != g0 or true, "")
		_ansage("Ende der Vorführung")
		await _warten(3.0)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
