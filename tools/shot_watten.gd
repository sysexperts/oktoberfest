extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert das Watten-Fenster (SHOT_DIR/watten.png).
##   SHOT_DIR=build godot --path . res://tools/shot_watten.tscn --resolution 1280x720

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
		gm._casino_tag = gm._day
		var sp: Node3D = gm._players_nodes.get(1)
		var w := get_tree().get_first_node_in_group("watten_ui")
		w.zeigen(sp)
		await _warten(1.0)
		gm._watten[1].hand = [7, 4, 2]
		gm._watten_senden(1, gm._watten[1])
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/watten.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
