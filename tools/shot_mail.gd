extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._story.post_senden("M2-06")
		await _warten(0.6)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/mail.png")
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
