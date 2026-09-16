extends Node
## Baumodus prüfen: leere Karte, Vorlage laden, Vorschau an der Maus → PNGs in SHOT_DIR.

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		Net.start_solo(true)
		for i in 60000:
			if get_tree().current_scene != null and get_tree().current_scene.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		for i in 60:
			await get_tree().process_frame
		var gm := get_tree().current_scene
		var bau = gm.get_node("Baumodus")
		var karte = gm.get_node("Kirmes/Karte")
		bau.starten()
		for i in 30:
			await get_tree().process_frame
		_bild("b_leer")
		karte.net_ersetzen(karte.vorlage())
		bau._geist_setzen("res://scenes/kirmes/gluecksrad.tscn")
		for i in 30:
			await get_tree().process_frame
		print("Teile: ", karte.eintraege.size())
		_bild("b_vorlage")
		get_tree().quit()

	func _bild(n: String) -> void:
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/%s.png" % n)
