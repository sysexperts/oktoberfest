extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert die Abwerbe-Meldung und die Personal-App (SHOT_DIR/abwerben.png).
##   SHOT_DIR=build godot --path . res://tools/shot_abwerben.tscn --resolution 1280x720

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
		gm.net_hire_staff(gm.ROLE_KELLNER)
		for sid in gm._staff_sim.keys():
			gm._staff_sim[sid].anliegen = "huber"
			gm._melde("MSG_PERSONAL_HUBER", [str(gm._staff_sim[sid].name), "30 €"], 1)
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0.0, 0.1, 6.0)
		var hud: Node = gm.get_node("HUD")
		hud.open_desktop()
		await _warten(1.0)
		hud.get("_desktop").app_oeffnen("personal")
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/abwerben.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
