extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Casino zum Selbsttesten: startet das echte Spiel in Kapitel 3 mit Geld, Tarnung und offener Quest "Das Hinterzimmer".
## Du spielst normal (WASD, Maus, E). Zusätzlich Zifferntasten zum Springen:
##   1 Gustav · 2 Türsteher · 3 Roulette · 4 Blackjack · 5 Watten · 6 Würfel · 7 Spielautomat · 8 Konrads Fass (Sabotage)
##   9 +10.000 € und alle Werkzeuge · 0 Tarnung an/aus · T Tarnung kaufen/entfernen
## godot --path . res://tools/casino_testen.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var gm: Node
	var sp: Node3D
	var _hinweis: Label
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
		await get_tree().create_timer(0.5).timeout
		story.ereignis("wette_gewonnen")
		story.quests["3.2"] = {"z": "erfuellt"}
		story.quests["3.3"] = {"z": "erfuellt"}
		story.ereignis("saboteur_gefasst")
		Game.money = 20000
		gm._tarnung_stufe = 2
		gm._tarnung_an = true
		gm._broadcast_meta()
		var ebene := CanvasLayer.new()
		ebene.layer = 50
		add_child(ebene)
		_hinweis = Label.new()
		_hinweis.position = Vector2(20, 120)
		_hinweis.add_theme_font_size_override("font_size", 16)
		_hinweis.add_theme_color_override("font_outline_color", Color.BLACK)
		_hinweis.add_theme_constant_override("outline_size", 6)
		_hinweis.text = "Casino-Test: 1 Gustav · 2 Türsteher · 3 Roulette · 4 Blackjack · 5 Watten · 6 Würfel · 7 Automat · 8 Konrads Fass\n9 +10.000 € und Werkzeuge · 0 Tarnung an/aus · T Tarnung kaufen/entfernen"
		ebene.add_child(_hinweis)
		_springen("tuer")
	func _ding(art: String) -> Node3D:
		for n in get_tree().get_nodes_in_group("interactable"):
			if n.has_method("kasino_aktion") and str(n.get("art")) == art:
				return n
		return null
	func _springen(art: String) -> void:
		var ziel: Node3D = _ding(art)
		if ziel == null or sp == null:
			return
		var vor := ziel.global_position + ziel.global_transform.basis.z * 1.8
		sp.global_position = Vector3(vor.x, 0.1, vor.z)
		sp.look_at(Vector3(ziel.global_position.x, 1.2, ziel.global_position.z), Vector3.UP)
		sp._head.rotation.x = 0.0
	func _unhandled_input(e: InputEvent) -> void:
		if not (e is InputEventKey and e.pressed and not e.echo) or sp == null:
			return
		match (e as InputEventKey).physical_keycode:
			KEY_1:
				var g: Node3D = null
				for n in get_tree().get_nodes_in_group("gustav"):
					g = n
				if g:
					sp.global_position = g.global_position + Vector3(0, 0.1, 2.2)
					sp.look_at(Vector3(g.global_position.x, 1.2, g.global_position.z), Vector3.UP)
			KEY_2: _springen("tuer")
			KEY_3: _springen("roulette")
			KEY_4: _springen("blackjack")
			KEY_5: _springen("watten")
			KEY_6: _springen("wuerfel")
			KEY_7: _springen("slot")
			KEY_8:
				for z in get_tree().get_nodes_in_group("sab_ziel"):
					if str(z.get("art")) == "fass":
						sp.global_position = z.global_position + Vector3(0, 0.1, 1.6)
						sp.look_at(Vector3(z.global_position.x, 1.2, z.global_position.z), Vector3.UP)
			KEY_9:
				Game.money += 10000
				for w in ["fassbohrer", "zange", "stinkbombe", "juckpulver", "dietrich"]:
					gm._sab_inv[w] = int(gm._sab_inv.get(w, 0)) + 1
				gm._sab_tag.clear()
				gm._broadcast_meta()
			KEY_0:
				gm._tarnung_an = not gm._tarnung_an
				gm._broadcast_meta()
			KEY_T:
				gm._tarnung_stufe = 0 if gm._tarnung_stufe > 0 else 2
				gm._tarnung_an = gm._tarnung_stufe > 0
				gm._casino_tag = -1
				gm._broadcast_meta()
