extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Zwischenfälle im Zelt (SHOT_DIR/zwischenfaelle.png).
##   SHOT_DIR=build godot --path . res://tools/shot_stromausfall.tscn --resolution 1280x720

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
		story.kapitel_setzen(4)
		gm._tent_stage = 2
		Game.add_money(5000 - Game.money)
		story.kapitel_setzen(2)
		Game.add_money(5000 - Game.money)
		gm._phase = gm.Phase.INTERMISSION
		gm.net_book_tent()
		gm.net_buy_table()
		gm.net_buy_table()
		gm._phase = gm.Phase.SHIFT
		gm._gruppe_next = 1
		for i in 12:
			gm._spawn_guest()
		await _warten(14.0)
		for id in gm._guest_sim.keys():
			gm._guest_sim[id].mode = 1
		gm._zwischenfall_ausloesen("verschuettet")
		gm._zwischenfall_ausloesen("heirat")
		gm._zwischenfall_ausloesen("karaoke")
		await _warten(1.0)
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0.0, 0.1, 4.0)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(Vector3(0.0, 2.6, 7.5), Vector3(0.0, 0.8, 0.0))
		kam.make_current()
		await _warten(1.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/zwischenfaelle.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
