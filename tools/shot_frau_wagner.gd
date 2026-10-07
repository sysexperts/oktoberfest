extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Frau Wagner bei der Hygienekontrolle (SHOT_DIR/frau_wagner.png).
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
		gm._kontrolle_beginnen()
		await _warten(21.0)
		var w := get_tree().get_first_node_in_group("wagner") as Node3D
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(Vector3(w.global_position.x + 3.0, 1.7, w.global_position.z + 4.5), w.global_position + Vector3(0, 1.0, 0))
		kam.make_current()
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/frau_wagner.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
