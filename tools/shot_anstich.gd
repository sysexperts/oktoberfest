extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Zwischenfälle im Zelt (SHOT_DIR/fassanstich.png).
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
		story.kapitel_setzen(6)
		gm._fest = {"tag": gm._day, "motto": 1, "band": 2, "feuer": 1, "deko": false, "werbung": true, "hilfe": false}
		gm._fest_morgen()
		gm._broadcast_meta()
		await _warten(0.8)
		var kino2 = gm.get_node_or_null("Kino")
		if kino2 and kino2.aktiv:
			kino2.beenden()
		await _warten(0.8)
		var sp: Node3D = gm._players_nodes.get(1)
		var ff := gm.get_node("Festfass") as Node3D
		sp.global_position = ff.global_position + Vector3(0, 0.1, 3.0)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(ff.global_position + Vector3(-3.0, 2.2, 4.5), ff.global_position + Vector3(0, 0.8, 0))
		kam.make_current()
		await _warten(1.2)
		var ui := get_tree().get_first_node_in_group("fassanstich_ui")
		ui.zeigen(sp)
		ui._t = 1.0
		await _warten(0.8)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/fassanstich.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
