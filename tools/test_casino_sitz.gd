extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Sitzplätze im Casino: hinsetzen, belegt, aufstehen; Bilder (mit SHOT_DIR) von außen gesehen → SHOT_DIR/sitz_*.png
##   godot --headless --path . res://tools/test_casino_sitz.tscn   (Bilder: SHOT_DIR=build/casino, mit Fenster)
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var gm: Node
	var sp: Node3D
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
	func _bild(name: String) -> void:
		await _warten(0.35)
		if OS.get_environment("SHOT_DIR") != "":
			get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/sitz_%s.png" % name)
	func _ding(art: String) -> Node3D:
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.has_method("kasino_aktion") and str(n.get("art")) == art:
				return n
		return null
	func _hin(art: String) -> Node3D:
		var ziel := _ding(art)
		var vor := ziel.global_position + ziel.global_transform.basis.z * 1.8
		sp.global_position = Vector3(vor.x, 0.1, vor.z)
		sp.look_at(Vector3(ziel.global_position.x, 1.0, ziel.global_position.z), Vector3.UP)
		sp._head.rotation.x = -0.35
		await _warten(0.8)
		return ziel
	func _dialog_zu() -> void:
		var d := get_tree().get_first_node_in_group("dialog")
		if d and d.has_method("beenden"):
			d.beenden()
		await _warten(0.2)
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
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
		await _warten(0.5)
		story.ereignis("wette_gewonnen")
		story.quests["3.2"] = {"z": "erfuellt"}
		story.quests["3.3"] = {"z": "erfuellt"}
		story.ereignis("saboteur_gefasst")
		Game.money = 5000
		gm._tarnung_stufe = 2
		gm._tarnung_an = true
		gm._casino_tag = gm._day
		gm._broadcast_meta()
		await _warten(1.0)
		# Das Casino ist für heute offen. Zum Blackjack-Tisch gehen und ihn benutzen.
		var tisch := _ding("blackjack")
		var sitz := tisch.get_node("Sitz")
		await _hin("blackjack")
		_check("Sitzplatz am Tisch vorhanden", sitz != null and sitz.has_method("sitz_id"))
		_check("Tisch zeigt den normalen Hinweis", tisch.hinweis_text(false) == "HINT_CASINO_BLACKJACK")
		tisch.kasino_aktion(sp)
		await _warten(0.6)
		var ui: Node = get_tree().get_first_node_in_group("blackjack_ui")
		_check("Spieler sitzt", sp.sitz_kasino == sitz)
		_check("Server hat den Platz vergeben", int(gm.kasino_sitze.get("Kartentisch", 0)) == 1, str(gm.kasino_sitze))
		_check("Spiel ist offen", ui.aktiv)
		_check("Spieler steht auf dem Hocker", sp.global_position.distance_to(sitz.global_position) < 0.05, str(sp.global_position.distance_to(sitz.global_position)))
		_check("Sitz-Pose wird gesendet (Emote 6)", sp.emote == 6, str(sp.emote))
		# Von außen gesehen (Fenster ausblenden)
		ui.visible = false
		sp._schulterkamera = true   # die eigene Figur sieht man sonst nicht (F5); Mitspieler sehen sie immer
		await _warten(0.8)
		var kam := Camera3D.new()
		get_tree().current_scene.add_child(kam)
		kam.fov = 60.0
		kam.current = true
		kam.global_position = sitz.global_position + sitz.global_transform.basis.z * 2.2 + sitz.global_transform.basis.x * 1.2 + Vector3(0, 1.4, 0)
		kam.look_at(sitz.global_position + Vector3(0, 0.8, 0))
		await _bild("von_aussen")
		kam.global_position = sitz.global_position + sitz.global_transform.basis.z * 1.0 + sitz.global_transform.basis.x * 0.6 + Vector3(0, 1.2, 0)
		kam.look_at(sitz.global_position + Vector3(0, 0.75, 0))
		await _bild("von_aussen_nah")
		kam.queue_free()
		sp._schulterkamera = false
		sp._cam.current = true
		ui.visible = true
		# Ein zweiter Spieler kann sich nicht dazusetzen: der Platz ist belegt
		var wer_sitzt: int = gm.kasino_sitze["Kartentisch"]
		gm.kasino_sitze["Kartentisch"] = 77
		_check("Fremd belegt: Hinweis „belegt“", tisch.hinweis_text(false) == "HINT_CASINO_BELEGT")
		gm.kasino_sitze["Kartentisch"] = wer_sitzt
		# Aufstehen gibt den Platz frei
		ui.beenden()
		await _warten(0.4)
		_check("Spieler steht wieder", sp.sitz_kasino == null)
		_check("Platz ist frei", not gm.kasino_sitze.has("Kartentisch"), str(gm.kasino_sitze))
		_check("Spieler ist vom Hocker weg", sp.global_position.distance_to(sitz.global_position) > 0.4)
		# Platz gehört einem anderen: kein Hinsetzen
		gm.kasino_sitze["Kartentisch"] = 77
		tisch.kasino_aktion(sp)
		await _warten(0.5)
		_check("Besetzt: Spieler setzt sich nicht", sp.sitz_kasino == null and not ui.aktiv)
		_check("Besetzt: Platz bleibt beim anderen", int(gm.kasino_sitze.get("Kartentisch", 0)) == 77)
		gm.kasino_sitze.erase("Kartentisch")
		# Ohne Einlass kein Platz (Server prüft)
		gm._casino_tag = -1
		tisch.kasino_aktion(sp)
		await _warten(0.5)
		_check("Ohne Einlass kein Platz", sp.sitz_kasino == null and gm.kasino_sitze.is_empty())
		gm._casino_tag = gm._day
		# Wieder hinsetzen, dann an einen anderen Platz wechseln: immer nur ein Platz je Spieler
		tisch.kasino_aktion(sp)
		await _warten(0.5)
		_check("Wieder gesetzt", sp.sitz_kasino == sitz)
		ui.beenden()
		await _warten(0.3)
		var wuerfel := _ding("wuerfel")
		await _hin("wuerfel")
		wuerfel.kasino_aktion(sp)
		await _warten(0.5)
		_check("Würfeltisch: sitzt dort", sp.sitz_kasino == wuerfel.get_node("Sitz") and gm.kasino_sitze.size() == 1, str(gm.kasino_sitze))
		get_tree().call_group("wuerfel_ui", "beenden")
		await _warten(0.3)
		_check("Alle Plätze frei am Ende", gm.kasino_sitze.is_empty() and sp.sitz_kasino == null)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
