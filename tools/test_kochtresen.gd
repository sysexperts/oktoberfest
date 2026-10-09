extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kochtresen (v406): mehrere Portionen auflegen, werden gar, verbrennen nach 20 s, verbrannte Portion nehmen, Mülleimer.
##   godot --headless --path . res://tools/test_kochtresen.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1
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
		await _warten(2.0)
		var st: Node = gm.get_node("Stations/FoodSosis")
		var n: int = st._slots.size()
		_check("mehrere Plätze am Grill", n >= 3, "%d Plätze" % n)
		for i in n:
			st.net_legen()
		await _warten(0.5)
		_check("alle Plätze belegt", not st.hat_frei(), "")
		_check("Portionen braten (noch nicht fertig)", not st.hat_fertig(), "")
		await _warten(9.0)
		_check("nach 8 s sind sie gar", st.hat_fertig(), "")
		var p = gm._players_nodes.get(1)
		p.carry_state = 0
		st.net_nehmen()
		await _warten(0.5)
		_check("fertige Portion in der Hand", p.carry_state == 2, "carry_state %d" % p.carry_state)
		_check("Platz wieder frei", st.hat_frei(), "")
		p.carry_state = 0
		await _warten(21.0)
		_check("nach 20 s verbrennt sie", st.hat_verbrannt(), "")
		st.net_nehmen()
		await _warten(0.5)
		_check("verbrannte Portion in der Hand", p.carry_state == 4, "carry_state %d" % p.carry_state)
		var eimer := get_tree().get_nodes_in_group("interactable").filter(func(e): return e.has_method("ist_muell") and e.ist_muell())
		_check("Mülleimer ist da", eimer.size() >= 1, "%d" % eimer.size())
		var sichtbar: int = 0
		for s in st._slots:
			for nm in ["Wuerstl", "Brezn", "Hendl"]:
				if (s.get_node(nm) as Node3D).visible:
					sichtbar += 1
		_check("pro Platz genau ein Grillmodell sichtbar", sichtbar == n, "%d von %d" % [sichtbar, n])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
