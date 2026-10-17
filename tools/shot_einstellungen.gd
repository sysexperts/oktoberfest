extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Alle Casino-Fenster durchspielen (Roulette, Blackjack, Würfel, Automat) → SHOT_DIR/casino_*.png, prüft Abbuchung und Auszahlung
##   SHOT_DIR=build/casino godot --path . res://tools/shot_einstellungen.tscn --resolution 1280x720
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
	func _bild(name: String) -> void:
		await _warten(0.35)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/einst_%s.png" % name)
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
		var m: Node = load("res://scenes/ui/einstellungen.tscn").instantiate()
		gm.add_child(m)
		await _warten(0.8)
		var reiter := m.find_child("Reiter", true, false) as TabContainer
		reiter.current_tab = 0
		for i in reiter.get_tab_count():
			if reiter.get_child(i).name == "Grafik":
				reiter.current_tab = i
		await _warten(0.5)
		await _bild("grafik")
		var sc := m.find_child("Grafik", true, false) as ScrollContainer
		sc.scroll_vertical = 2000
		await _warten(0.4)
		await _bild("grafik_unten")
		# ein Regler setzen und prüfen, dass die Auswirkung ankommt
		Einstellungen.fein["schatten"] = 0
		Einstellungen.anwenden()
		await _warten(0.3)
		print("SONNE Schatten an: ", gm.get_node("Sun").shadow_enabled)
		Einstellungen.fein["schatten"] = -1
		Einstellungen.anwenden()
		await _warten(0.3)
		print("SONNE Schatten an (zurueck): ", gm.get_node("Sun").shadow_enabled)
		get_tree().quit()
