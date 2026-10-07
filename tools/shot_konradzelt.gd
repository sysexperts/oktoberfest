extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Konrads Zelt im Spiel (SHOT_DIR/konrad_zelt.png).
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
		story.kapitel_setzen(5)
		gm._broadcast_meta()
		await _warten(1.0)
		var zelt := get_tree().get_first_node_in_group("huber_zelt") as Node3D
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = zelt.to_global(Vector3(0, 0.1, 30))
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(zelt.to_global(Vector3(0.5, 1.9, 5.5)), zelt.to_global(Vector3(2.5, 1.1, -8.0)))
		kam.make_current()
		await _warten(2.0)
		await _warten(1.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/konrad_zelt.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
