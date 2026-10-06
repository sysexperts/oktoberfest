extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Gefallen „Der Spanner": Posten stehen, Annehmen bringt den Täter, Packen, Übergeben, Belohnung.
##   godot --headless --path . res://tools/test_gefallen.tscn

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
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var g: Node = gm.get_node("Gefallen")
		await _warten(4.0)
		_check("Security-Posten stehen", g._posten.size() == g.POSTEN_ANZAHL, str(g._posten.size()))
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(2)
		var q: Dictionary = g.Daten.quest("G-1")
		_check("Quest G-1 in den Daten", not q.is_empty())
		story._freischalten(q)
		story.annehmen("G-1")
		await _warten(0.5)
		_check("Täter taucht auf", g._taeter != null and is_instance_valid(g._taeter), str(g._lauf))
		var sp: Node3D = gm._players_nodes.get(1)
		var geld0: int = Game.money
		g.net_packen()
		await _warten(0.3)
		_check("Täter gepackt, Spieler trägt ihn", g._phase == "getragen" and bool(sp.traegt_taeter), g._phase)
		await _warten(0.3)
		_check("Täter hängt am Spieler", g._taeter.global_position.distance_to(sp.global_position) < 2.0, str(g._taeter.global_position))
		g.net_uebergeben()
		await _warten(0.5)
		_check("Quest erfüllt", story.zustand("G-1") == "erfuellt", story.zustand("G-1"))
		_check("250 € Belohnung", Game.money == geld0 + 250, "%d -> %d" % [geld0, Game.money])
		_check("Täter weg, Spieler frei", g._taeter == null and not bool(sp.traegt_taeter))
		# Taschendieb
		story._freischalten(g.Daten.quest("G-2"))
		story.annehmen("G-2")
		await _warten(0.6)
		_check("Dieb taucht auf", g._taeter != null and str(g._lauf.get("art", "")) == "dieb", str(g._lauf))
		var start: Vector3 = g._dieb_pos
		for i in 40:
			g._dieb_schritt(0.1)
		_check("Dieb läuft von selbst", g._dieb_pos.distance_to(start) > 1.0, "%.1f m" % g._dieb_pos.distance_to(start))
		sp.global_position = g._dieb_pos + Vector3(4, 0, 0)
		var d0: float = sp.global_position.distance_to(g._dieb_pos)
		for i in 30:
			g._dieb_schritt(0.1)
		var d1: float = sp.global_position.distance_to(g._dieb_pos)
		_check("Dieb rennt vor dem Spieler weg", d1 > d0 + 3.0, "%.1f -> %.1f m" % [d0, d1])
		await _warten(0.5)
		_check("Dieb-Figur folgt der Meldung", g._taeter.global_position.distance_to(g._dieb_pos) < 3.0, "")
		sp.global_position = g._taeter.global_position + Vector3(0.5, 0, 0)
		g.net_packen()
		await _warten(0.3)
		g.net_uebergeben()
		await _warten(0.5)
		_check("Dieb übergeben: Quest erfüllt", story.zustand("G-2") == "erfuellt", story.zustand("G-2"))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
