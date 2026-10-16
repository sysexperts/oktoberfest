extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Alle Casino-Fenster durchspielen (Roulette, Blackjack, Würfel, Automat) → SHOT_DIR/casino_*.png, prüft Abbuchung und Auszahlung
##   SHOT_DIR=build/casino godot --path . res://tools/shot_casino_neu.tscn --resolution 1280x720
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
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/neu_%s.png" % name)
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
		gm._start_shift()
		gm._zelt_offen = true
		await get_tree().create_timer(3.0).timeout
		var zelt := get_tree().get_first_node_in_group("huber_zelt") as Node3D
		var kam := Camera3D.new()
		get_tree().current_scene.add_child(kam)
		kam.fov = 75.0
		kam.current = true
		var ansichten := {
			"1_aussen_vorn": [Vector3(16, 2.2, -4), Vector3(9, 1.6, -14)],
			"2_tuer": [Vector3(14.5, 1.7, -14), Vector3(9, 1.5, -14)],
			"3_ueberblick": [Vector3(24, 10, -1), Vector3(0, 1.5, -14)],
			"5_innen_tuer": [Vector3(8.4, 1.65, -14), Vector3(-4, 1.3, -14)],
			"6_innen_bar": [Vector3(3.5, 1.9, -17.5), Vector3(0.5, 1.2, -10.7)],
			"7_innen_tische": [Vector3(-8.0, 2.0, -10.0), Vector3(1, 1.1, -17.5)],
			"8_innen_slots": [Vector3(-1, 2.0, -12.5), Vector3(-6, 1.4, -9.6)],
			"9_innen_klavier": [Vector3(3.5, 2.0, -12), Vector3(7.5, 1.2, -18)],
		}
		for n in ansichten:
			kam.global_position = zelt.to_global(ansichten[n][0])
			kam.look_at(zelt.to_global(ansichten[n][1]))
			await _bild(n)
		kam.projection = Camera3D.PROJECTION_ORTHOGONAL
		kam.size = 34.0
		kam.global_position = zelt.to_global(Vector3(2, 60, -14))
		kam.look_at(zelt.to_global(Vector3(2, 0, -14)), Vector3.FORWARD)
		await _bild("4_oben")
		get_tree().quit()
