extends Node
## Personal prüfen: Namen, Lohnwunsch, Huber wirbt ab, Kündigung, Teamliste.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
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
		gm._active_count = 4
		gm.net_hire_staff(2)
		gm.net_hire_staff(2)
		gm.net_hire_staff(3)
		var ids: Array = gm._staff_sim.keys()
		_check("3 mit Namen", ids.size() == 3 and str(gm._staff_sim[ids[0]].name) != "", str(ids.map(func(k): return gm._staff_sim[k].name)))
		# Lohnwunsch erzwingen
		gm._day = 8
		gm._staff_sim[ids[0]].seit = 1
		gm._staff_sim[ids[0]].anliegen = "lohn"
		gm._staff_sim[ids[1]].anliegen = "huber"
		var lohn_vorher: int = gm._total_wages()
		gm.net_personal_lohn(ids[0])
		_check("Lohn erhöht", gm._total_wages() > lohn_vorher and str(gm._staff_sim[ids[0]].anliegen) == "", "%d → %d" % [lohn_vorher, gm._total_wages()])
		seed(5)
		gm._personal_morgen()
		_check("Abgeworben ist weg", not gm._staff_sim.has(ids[1]), "")
		gm._staff_sim[ids[2]].anliegen = "lohn"
		gm._staff_sim[ids[2]].unzufrieden = false
		gm._personal_morgen()
		_check("Ignoriert: unzufrieden", gm._staff_sim.has(ids[2]) and bool(gm._staff_sim[ids[2]].unzufrieden), "")
		gm._personal_morgen()
		_check("Zweimal ignoriert: kündigt", not gm._staff_sim.has(ids[2]), "")
		gm.net_hire_staff(4)
		gm._broadcast_meta()
		gm.open_booking_ui()
		await _warten(0.4)
		var buero = gm.get_node("HUD")._buero
		buero._reiter.current_tab = 2
		await _warten(0.3)
		var scroll := buero.get_node("%Team").get_parent().get_parent().get_parent() as ScrollContainer
		if scroll:
			scroll.scroll_vertical = 10000
		await _warten(0.4)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/personal.png")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
