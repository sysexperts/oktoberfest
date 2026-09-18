extends Node
## Büromöbel kaufen: alle neuen Arten, Wiesenbüro-Reiter Einrichtung ansehen.
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
		gm._quest_step = gm.QUEST_COUNT
		gm.net_book_tent("Test")
		Game.add_money(10000)
		var vorher: int = gm._einrichtung.size()
		for art in ["aktenschrank", "ordnerregal", "buerostuhl", "topfpflanze", "wanduhr", "plakat", "bueroleuchte", "teppich", "wartebank", "garderobe", "kaffeeecke"]:
			gm.net_buy_einrichtung(art)
			await _warten(0.1)
		print("  gekauft: ", gm._einrichtung.size() - vorher, " von 11")
		gm._broadcast_meta()
		gm.open_booking_ui()
		await _warten(0.5)
		var buero = gm.get_node("HUD")._buero
		buero._reiter.current_tab = 7
		await _warten(0.5)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/moebel_buero.png")
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
