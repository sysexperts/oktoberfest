extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert den Wohnwagen in neuer Farbe (SHOT_DIR/wohnwagen_plaetze.png).
##   SHOT_DIR=build godot --path . res://tools/shot_wagenfarbe.tscn --resolution 1280x720

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(3)
		gm._tent_stage = 2
		Game.add_money(5000 - Game.money)
		Game.add_money(2000 - Game.money)
		gm._phase = gm.Phase.INTERMISSION
		gm._tent_stage = 2
		gm.net_wagen_farbe("rot")
		gm._players_nodes[2] = Node3D.new()
		gm._players_nodes[3] = Node3D.new()
		gm._wagen_farbe_peer[2] = "gruen"
		gm._wagen_farbe_peer[3] = "rot"
		gm._spieler_info[2] = {"name": "Lena"}
		gm._spieler_info[3] = {"name": "Tarik"}
		gm._broadcast_meta()
		var wagen: Node3D = null
		for n in get_tree().get_nodes_in_group("interactable"):
			if n is Caravan and (n as Caravan).is_mine:
				wagen = n
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = wagen.global_position + Vector3(0, 0.1, 14.0)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(wagen.global_position + Vector3(2.0, 3.0, 13.0), wagen.global_position + Vector3(-4.0, 1.4, 0))
		kam.make_current()
		await _warten(1.5)
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/wohnwagen_plaetze.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
