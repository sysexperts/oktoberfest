extends Node
## Einleitung prüfen: neues Solospiel starten, Bilder aus der Kamerafahrt,
## danach schauen, ob der Wiesnchef zum Zelt läuft. → SHOT_DIR/kino_*.png

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
		print("Kino aktiv: ", kino != null and kino.aktiv, "   Chef: ", chef != null)
		var dir := OS.get_environment("SHOT_DIR")
		var marken := [2.0, 16.0, 26.0, 48.0, 58.0]
		var t := 0.0
		var nr := 0
		while nr < marken.size():
			await get_tree().process_frame
			t += get_process_delta_time()
			if t >= float(marken[nr]):
				get_viewport().get_texture().get_image().save_png(dir + "/kino_%d.png" % nr)
				if kino:
					print("  bei %.0f s: Schritt %d, aktiv %s" % [t, kino._schritt, kino.aktiv])
				nr += 1
		# Chef unterwegs?
		print("Chef bei z=%.1f (Start 80, Ziel 15.6), angekommen: %s" % [(chef as Node3D).global_position.z, chef.angekommen()])
		print("Quest-Schritt: ", gm._quest_step, "  Aufgabe: ", TranslationServer.translate("QUEST_0_TITLE"))
		get_tree().quit()
