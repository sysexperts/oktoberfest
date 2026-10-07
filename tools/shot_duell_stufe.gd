extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert die Stufenanzeige des Duells (SHOT_DIR/duell_stufe.png).
##   SHOT_DIR=build godot --path . res://tools/shot_duell_stufe.tscn --resolution 1280x720

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		if await Spielstart.starten(self) == null:
			return
		var gm := get_tree().current_scene
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._net_duell_start(1, 25.0, 2)
		await _warten(4.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/duell_stufe.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
