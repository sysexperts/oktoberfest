extends Node
const Schuss := preload("res://tools/schuss.gd")
## Huber prüfen: Wette an Tag 3 anbieten, annehmen, abrechnen; Sabotage auslösen
## (Leck kostet Bier bis weggeputzt). → SHOT_DIR/huber_*.png

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
		var huber = gm.get_node("Kirmes/Huber")
		var dialog = gm.get_node("Dialog")
		gm._quest_step = gm.QUEST_COUNT
		gm._day = 3
		gm._huber_morgen()
		_check("Wette an Tag 3", not gm._huber_wette.is_empty(), str(gm._huber_wette))
		gm._broadcast_meta()
		await _warten(0.5)
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = huber.global_position + Vector3(0, 0.1, 2.2)
		sp.look_at(huber.global_position + Vector3(0, 0.1, 0), Vector3.UP)
		await _warten(0.5)
		_check("Huber hat !", huber.wette_offen(), "")
		huber.ansprechen()
		await _warten(1.2)
		_bild("huber_gespraech")
		while dialog.aktiv and not dialog._frage_offen():
			dialog._weiter()
			await _warten(0.3)
		await _warten(0.8)
		_bild("huber_wette")
		dialog._waehlen(0)
		await _warten(0.5)
		_check("Wette angenommen", bool(gm._huber_wette.get("angenommen", false)), "")
		while dialog.aktiv:
			dialog._weiter()
			await _warten(0.2)
		gm._huber_wette = {"typ": "mass", "ziel": 40, "einsatz": 300, "angenommen": true}
		gm._served = 50
		var geld: int = Game.money
		gm._huber_abrechnen()
		_check("Gewonnen: +300", Game.money == geld + 300, "%d → %d" % [geld, Game.money])
		# Sabotage: Leck
		gm._stock[gm.WARE_BIER] = 20
		var vorher: int = gm._messes.size()
		seed(1)
		for i in 5:
			gm._sabotieren()
			if gm._mess_kind.values().has(Mess.SABOTAGE):
				break
		_check("Leck liegt", gm._mess_kind.values().has(Mess.SABOTAGE), "Flecken %d → %d" % [vorher, gm._messes.size()])
		for i in 360:
			gm._huber_schicht(1.0 / 60.0)
		_check("Leck kostet Bier", int(gm._stock[gm.WARE_BIER]) < 20, "Bier %d" % int(gm._stock[gm.WARE_BIER]))
		sp.global_position = Vector3(-3.4, 0.1, -6.5)
		sp.look_at(Vector3(-3.4, 0.0, -11), Vector3.UP)
		await _warten(0.6)
		_bild("huber_leck")
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _bild(n: String) -> void:
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/%s.png" % n)
