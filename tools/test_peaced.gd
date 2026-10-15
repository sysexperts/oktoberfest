extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## MrPeaced: Runde für alle beim ersten Bedienen (Einnahme = Bierpreis x Gäste), Kellner-Angebot mit 40 %, Kellner rennt raus
## godot --path . res://tools/test_peaced.tscn --resolution 1280x720
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
		Game.add_money(60000 - Game.money)
		gm.net_book_tent("Test")
		for i in 3:
			gm.net_buy_table()
		gm.net_hire_staff(gm.ROLE_KELLNER)   # Personal geht nur vor der Schicht
		gm._phase = gm.Phase.SHIFT
		gm._zelt_offen = true
		await _warten(1.0)
		_check("ein Kellner angestellt", gm._staff_sim.size() == 1)
		var si: int = gm._free_seat()
		gm._spawn_guest(si)
		var id: int = gm._guest_next - 1
		gm._remove_guest(id)
		gm._stamm_gast_setzen(id, gm._guest_sim[id].pos, "peaced", si)
		await _warten(1.0)
		var c: Node = gm._guests.get(id)
		_check("MrPeaced-Gast gesetzt", gm._peaced_gast == id and c != null and c.stamm == "peaced")
		_check("zwei Leibwächter", gm._lw_nodes.size() == 2)
		var gaeste: int = gm._guest_sim.size()
		var vorher: int = gm._income_today if "_income_today" in gm else 0
		var geld_vorher: int = Game.money
		# Kellner-Angebot auf sicher stellen (40 % sonst im Test zufällig)
		gm._stamm_bedient(gm._guest_sim[id])
		var plus: int = Game.money - geld_vorher
		var erwartet: int = gm._reward_for(1, 1) * gaeste
		_check("Runde bezahlt: +%d (erwartet %d bei %d Gästen)" % [plus, erwartet, gaeste], plus == erwartet and erwartet > 0)
		var spruch: Label3D = c.get_node("Spruch")
		_check("Spruch zur Runde sichtbar: '%s'" % spruch.text, spruch.visible and not spruch.text.begins_with("PEACED_"))
		gm._stamm_bedient(gm._guest_sim[id])
		_check("zweites Bedienen löst keine zweite Runde aus", Game.money - geld_vorher - plus < erwartet)
		# Kellner-Angebot direkt auslösen
		gm._peaced_kellner_angebot()
		var sid: int = gm._staff_sim.keys()[0]
		_check("Kellner kündigt (heim=1, kuendigt)", int(gm._staff_sim[sid].heim) == 1 and bool(gm._staff_sim[sid].kuendigt))
		var t := 0.0
		while gm._staff_sim.has(sid) and t < 40.0:
			await _warten(1.0)
			t += 1.0
		gm._despawn_guest(id)
		await _warten(0.5)
		_check("Leibwächter weg nach Abgang", gm._lw_nodes.is_empty())
		_check("Kellner ist nach %.0f s weg (für immer entlassen)" % t, not gm._staff_sim.has(sid))
		print("ERGEBNIS: %s" % ("BESTANDEN" if ok else "FEHLGESCHLAGEN"))
		get_tree().quit()
