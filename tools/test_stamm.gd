extends Node
## Stammgäste prüfen: benannter Gast erscheint mit Name, Wunsch, dreimal bedient → Belohnung.
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
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._quest_step = gm.QUEST_COUNT
		gm.net_book_tent("Test")
		gm._active_count = 2
		gm._apply_tent()
		gm._rebuild_seats()
		gm._stamm_heute = ""
		var alt: float = gm.STAMM_CHANCE
		# Zufall ausschalten: garantiert Alois
		for i in 50:
			gm._stamm_heute = ""
			if gm._stammgast_waehlen() == "alois":
				break
		gm._stamm_heute = ""
		gm.set("_stamm_heute", "")
		seed(1)
		var id: int = gm._guest_next
		# direkt einen Stammgast erzeugen
		for versuch in 400:
			if gm._stamm_heute != "":
				break
			gm._spawn_guest()
			for gid2 in gm._guest_sim.keys().duplicate():
				if not gm._guest_sim[gid2].has("stamm"):
					gm._despawn_guest(gid2)
		var gefunden := false
		for gid in gm._guest_sim:
			if gm._guest_sim[gid].has("stamm"):
				gefunden = true
		await _warten(0.3)
		var name_da := false
		for c in get_tree().get_nodes_in_group("customer"):
			if c.stamm != "":
				name_da = true
		_check("Stammgast erscheint, Figur kennt den Namen", gefunden and name_da, gm._stamm_heute)
		var g := {"stamm": "alois", "okind": 2, "otype": 2}
		gm._stamm_wunsch(g)
		_check("Alois will Helles", int(g.okind) == 1 and int(g.otype) == 1, str(g))
		var pop: float = gm._popularity
		for i in 3:
			gm._stamm_bedient({"stamm": "alois"})
		_check("Dreimal zufrieden → Belohnung", bool(gm._stamm.alois.belohnt) and gm._popularity > pop, str(gm._stamm))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
