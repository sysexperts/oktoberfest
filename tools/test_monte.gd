extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## SloptanaBlack88: kommt mit zwei Leibwächtern, Freunde am Tisch, Sprüche, Ansprechen, Abgang
## godot --path . res://tools/test_monte.tscn --resolution 1280x720
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var ok := true
	func _check(n: String, b: bool) -> void:
		print(("OK     " if b else "FEHLER ") + n)
		ok = ok and b
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		Game.add_money(50000 - Game.money)
		gm.net_book_tent("Test")
		for i in 4:
			gm.net_buy_table()
		await _warten(1.0)
		var sp: Node3D = gm._players_nodes.get(1)
		# Monte direkt als Gast anlegen (der Zufall wäre im Test zu selten)
		var si: int = gm._free_seat()
		_check("freier Platz da", si >= 0)
		gm._spawn_guest(si)
		var id: int = gm._guest_next - 1
		gm._remove_guest(id)   # der normale Gast wird zum Stammgast (im Spiel entscheidet das _spawn_guest vorher)
		gm._stamm_gast_setzen(id, gm._guest_sim[id].pos, "monte", si)
		await _warten(30.0)   # bis die Gäste von Tor zu ihrem Platz gelaufen sind
		_check("Monte-Gast gesetzt", gm._monte_gast == id)
		_check("zwei Leibwächter", gm._lw_nodes.size() == 2)
		var tisch := int(gm._seats[si].table)
		var am_tisch := 0
		for g in gm._guest_sim.values():
			if int(gm._seats[int(g.seat)].table) == tisch:
				am_tisch += 1
		_check("mindestens ein Freund am selben Tisch (%d Gäste)" % am_tisch, am_tisch >= 2)
		var c: Node = gm._guests.get(id)
		_check("Figur ist SloptanaBlack88 (Customer.stamm)", c != null and c.stamm == "monte")
		gm.net_monte_ansprechen(id)
		await _warten(0.5)
		var spruch: Label3D = c.get_node("Spruch")
		_check("Spruch sichtbar nach Ansprechen: '%s'" % spruch.text, spruch.visible and spruch.text != "")
		_check("Spruch ist übersetzt (kein Schlüssel)", not spruch.text.begins_with("MONTE_"))
		# Bilder: Tisch von weitem und Monte nah
		var dir := OS.get_environment("SHOT_DIR")
		if dir != "":
			var tisch_pos: Vector3 = (gm._beertables[tisch] as Node3D).global_position
			var kam := Camera3D.new()
			get_tree().root.add_child(kam)
			kam.current = true
			var richtung := (gm._lw_nodes.values()[0] as Node3D).global_position - tisch_pos
			richtung.y = 0.0
			var quer := richtung.normalized().rotated(Vector3.UP, PI / 2.0)
			kam.global_position = tisch_pos + quer * 4.6 + Vector3(0, 2.4, 0)
			kam.look_at(tisch_pos + Vector3(0, 1.0, 0))
			gm.net_monte_ansprechen(id)
			gm._monte_cooldown = 0.0
			await _warten(1.5)
			get_viewport().get_texture().get_image().save_png(dir + "/monte_tisch.png")
			kam.global_position = (c as Node3D).global_position + quer * 2.2 + Vector3(0, 1.5, 0) + richtung.normalized() * 0.4
			kam.look_at((c as Node3D).global_position + Vector3(0, 0.9, 0))
			await _warten(0.8)
			get_viewport().get_texture().get_image().save_png(dir + "/monte_nah.png")
		# Abgang: Leibwächter verschwinden mit ihm
		gm._despawn_guest(id)
		await _warten(0.5)
		_check("Leibwächter weg nach Abgang", gm._lw_nodes.is_empty())
		print("ERGEBNIS: %s" % ("BESTANDEN" if ok else "FEHLGESCHLAGEN"))
		get_tree().quit()
