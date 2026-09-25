extends Node
## Einleitung prüfen: neues Solospiel, Brief (jede Seite), Überblende, dann
## Gespräch mit dem Festleiter am Büro, Weg zum Zelt, Gespräch am Zelt.
## → SHOT_DIR/kino_*.png

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
		var dialog = gm.get_node_or_null("Dialog")
		var chef = gm.get_node_or_null("Kirmes/Festleiter")
		var sp: Node3D = gm._players_nodes.get(1)
		print("Brief offen: ", kino.aktiv, "   Chef: ", chef != null, "  Dialog: ", dialog != null)
		var dir := OS.get_environment("SHOT_DIR")
		for seite in 3:
			await _warten(0.8)
			_bild(dir + "/kino_brief_%d.png" % seite)
			kino._weiter()
		await _warten(1.0)
		_bild(dir + "/kino_blende.png")
		await _warten(2.0)
		_bild(dir + "/kino_tor.png")
		# zum Büro, Festleiter ansprechen
		sp.global_position = chef.global_position + Vector3(-3.0, 0.1, 0)
		sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.5)
		print("Hinweis: ", sp._hint_for(chef))
		chef.ansprechen()
		await _warten(1.0)
		_bild(dir + "/kino_dialog_buero.png")
		for i in 3:
			await _warten(0.4)
			dialog._weiter()
		print("Dialog zu: ", not dialog.aktiv, "  Chef unterwegs: ", chef.unterwegs())
		await _warten(6.0)
		sp.global_position = chef.global_position + Vector3(4.0, 0.1, 0.5)
		sp.rotation.y = PI / 2
		await _warten(0.3)
		_bild(dir + "/kino_weg.png")
		await _warten(30.0)
		print("Chef angekommen: ", chef.angekommen(), " bei ", chef.global_position)
		sp.global_position = chef.global_position + Vector3(2.5, 0.1, 1.5)
		sp.look_at(chef.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.3)
		chef.ansprechen()
		await _warten(1.0)
		_bild(dir + "/kino_dialog_zelt.png")
		print("Quest: ", gm._quest_step)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(pfad: String) -> void:
		get_viewport().get_texture().get_image().save_png(pfad)
