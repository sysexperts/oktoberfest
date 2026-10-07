extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Gustav und seinen Koffer (SHOT_DIR/gustav.png).
##   SHOT_DIR=build godot --path . res://tools/shot_gustav.tscn --resolution 1280x720

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
		gm.net_sab_kauf("fassbohrer")
		var gu := get_tree().get_first_node_in_group("gustav") as Node3D
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = gu.global_position + Vector3(0, 0.1, 3.0)
		sp.rotation.y = 0.0
		var laden := get_tree().get_first_node_in_group("gustav_laden")
		await _warten(1.5)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/gustav_figur.png")
		laden.zeigen(sp)
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/gustav.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
