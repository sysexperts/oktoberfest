extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Die Casino-Spiele so, wie man sie spielt (Dialog, Karten, Ergebnis, Kessel, Automat) → SHOT_DIR/spiel_*.png
##   SHOT_DIR=build/casino godot --path . res://tools/shot_casino_spielen.tscn --resolution 1280x720
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
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/spiel_%s.png" % name)
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
		# --- Roulette
		var r := await _hin("roulette")
		r.kasino_aktion(sp)
		await _bild("roulette_frage")
		await _dialog_zu()
		gm.net_roulette.rpc_id(1, 0)
		await _warten(1.2)
		await _bild("roulette_dreht")
		await _warten(3.6)
		await _bild("roulette_ergebnis")
		# --- Blackjack
		var b := await _hin("blackjack")
		b.kasino_aktion(sp)
		await _bild("blackjack_frage")
		await _dialog_zu()
		gm.net_blackjack.rpc_id(1, 0)
		await _warten(1.0)
		await _bild("blackjack_karten")
		gm.net_blackjack.rpc_id(1, 1)
		await _warten(1.0)
		await _bild("blackjack_nach_karte")
		gm.net_blackjack.rpc_id(1, 2)
		await _warten(1.0)
		await _bild("blackjack_ende")
		await _dialog_zu()
		# --- Würfel
		var w := await _hin("wuerfel")
		w.kasino_aktion(sp)
		await _bild("wuerfel_frage")
		await _dialog_zu()
		gm.net_wuerfel.rpc_id(1, 1)
		await _warten(1.0)
		await _bild("wuerfel_wurf")
		await _warten(3.0)
		await _bild("wuerfel_ergebnis")
		# --- Automat
		var s := await _hin("slot")
		s.kasino_aktion(sp)
		await _warten(0.8)
		await _bild("automat_dreht")
		await _warten(3.2)
		await _bild("automat_ergebnis")
		# --- Watten
		var wa := await _hin("watten")
		wa.kasino_aktion(sp)
		await _warten(0.8)
		await _bild("watten_start")
		await _warten(2.0)
		await _bild("watten_spaeter")
		get_tree().quit()
