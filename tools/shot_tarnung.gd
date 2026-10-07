extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert den Spieler mit Tarnung (SHOT_DIR/tarnung.png).
##   SHOT_DIR=build godot --path . res://tools/shot_tarnung.tscn --resolution 1280x720

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
		var sp: Node3D = gm._players_nodes.get(1)
		var Look := preload("res://scripts/charakter_look.gd")
		sp.look_setzen(Look.zu_code(Look.standard("m")))
		sp.global_position = Vector3(0.0, 0.1, 3.0)
		gm.net_sab_kauf("komplett")
		await _warten(1.5)
		sp.set_process(false)
		sp.set_physics_process(false)
		sp._model.visible = true
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(sp.global_position + Vector3(0.0, 1.5, -2.6), sp.global_position + Vector3(0.0, 1.3, 0.0))
		kam.make_current()
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/tarnung.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
