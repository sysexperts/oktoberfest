extends Node
## Einleitung prüfen: neues Solospiel starten, Bild vom Brief (jede Seite),
## danach Sprechblasen des Wiesnchefs und ob er zum Zelt läuft. → SHOT_DIR/kino_*.png

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
		for i in 30:
			await get_tree().process_frame
		var kino = gm.get_node_or_null("Kino")
		var chef = gm.get_node_or_null("Kirmes/Wiesnchef")
		print("Brief offen: ", kino != null and kino.aktiv, "   Chef: ", chef != null)
		var dir := OS.get_environment("SHOT_DIR")
		for seite in 3:
			await _warten(0.8)
			_bild(dir + "/kino_brief_%d.png" % seite)
			kino._weiter()
		print("Brief zu: ", not kino.aktiv)
		var t := 0.0
		for nr in 4:
			await _warten(6.0)
			_bild(dir + "/kino_chef_%d.png" % nr)
			print("  Blase: ", chef.get_node("Sprechblase").text.left(50))
		await _warten(40.0)
		print("Chef bei z=%.1f (Ziel 15.6), angekommen: %s, Blase: %s" % [(chef as Node3D).global_position.z, chef.angekommen(), chef.get_node("Sprechblase").text.left(40)])
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(pfad: String) -> void:
		get_viewport().get_texture().get_image().save_png(pfad)
