extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert Bräumeister Gerhard im Braukeller (SHOT_DIR/braeumeister.png).
##   SHOT_DIR=build godot --path . res://tools/shot_braeumeister.tscn --resolution 1280x720

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
		gm._phase = gm.Phase.INTERMISSION
		gm.net_hire_staff(gm.ROLE_BRAEUMEISTER)
		var kam := Camera3D.new()
		gm.add_child(kam)
		var mb: Node3D = gm.get_node("Braukeller/Maischbottich")
		var g: Node3D = null
		for st in gm._staff.values():
			g = st
		print("MAISCH ", mb.global_position, " GERHARD ", g.global_position if g else "-")
		var z := mb.global_position + Vector3(2.0, 0.0, 0.0)
		kam.look_at_from_position(Vector3(-6.5, -2.0, -8.5), Vector3(-6.5, -2.8, -2.0))
		kam.make_current()
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/braeumeister.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
