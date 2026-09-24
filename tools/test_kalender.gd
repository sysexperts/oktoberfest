extends Node
const Schuss := preload("res://tools/schuss.gd")
## Kalender prüfen: Plan der Saison, Ansicht an Tag 5, Sondertag wirkt.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._day = 5
		gm._quest_step = gm.QUEST_COUNT
		print("  Plan: ", gm._kalender_plan())
		gm._ereignis_waehlen()
		print("  Tag 5 Ereignis: ", gm._ereignis, "  Andrang ", gm._ereignis_andrang())
		var tracht := 0
		for i in 200:
			if gm._gast_typ_waehlen() == "tracht":
				tracht += 1
		print("  Trachtler von 200: ", tracht)
		gm._broadcast_meta()
		await _warten(0.4)
		gm.get_node("Kalender").zeigen()
		await _warten(0.5)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/kalender.png")
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
