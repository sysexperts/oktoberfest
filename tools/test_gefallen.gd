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
		# Die Sau
		story._freischalten(g.Daten.quest("G-3"))
		story.annehmen("G-3")
		await _warten(0.6)
		_check("Sau taucht auf, Gehege steht", g._taeter != null and g._gehege != null and str(g._lauf.get("art", "")) == "sau", str(g._lauf))
		_check("Sau-Modell hat Beine", g._taeter._sau != null and g._taeter._sau.get_node_or_null("BeinVL") != null and g._taeter._sau.get_node_or_null("Koerper") != null, "")
		var s0: Vector3 = g._dieb_pos
		for i in 30:
			g._dieb_schritt(0.1)
		_check("Sau läuft", g._dieb_pos.distance_to(s0) > 1.0, "%.1f m" % g._dieb_pos.distance_to(s0))
		await _warten(0.4)
		sp.global_position = g._taeter.global_position + Vector3(0.5, 0, 0)
		g.net_packen()
		await _warten(0.3)
		_check("Pfeil zeigt zum Gehege", g.ziel_fuer(sp) == g._gehege, "")
		g.net_uebergeben()
		await _warten(0.5)
		_check("Sau abgeliefert: Quest erfüllt", story.zustand("G-3") == "erfuellt" and g._gehege == null, story.zustand("G-3"))
		# Konrads Spion
		story._freischalten(g.Daten.quest("G-4"))
		story.annehmen("G-4")
		await _warten(0.6)
		_check("Spion taucht auf", g._taeter != null and str(g._lauf.get("art", "")) == "spion", str(g._lauf))
		g.net_packen()
		await _warten(0.3)
		g.net_uebergeben()
		await _warten(0.5)
		_check("Spion abgeliefert: Quest erfüllt", story.zustand("G-4") == "erfuellt", story.zustand("G-4"))
		# Sturm: fünf Planen sichern
		story._freischalten(g.Daten.quest("G-5"))
		story.annehmen("G-5")
		await _warten(0.6)
		_check("Sturm: fünf Planen stehen", g._punkte.size() == 5 and str(g._lauf.get("art", "")) == "punkte", str(g._punkte.size()))
		for i in 5:
			g.net_punkt(i)
		await _warten(0.5)
		_check("Sturm: alle gesichert, Quest erfüllt", story.zustand("G-5") == "erfuellt", story.zustand("G-5"))
		# Feuer: ohne Wasser nichts, mit Wasser löschen
		story._freischalten(g.Daten.quest("G-6"))
		story.annehmen("G-6")
		await _warten(0.6)
		_check("Feuer: drei Feuer und ein Brunnen", g._punkte.size() == 3 and g._quelle != null, str(g._punkte.size()))
		g.net_punkt(0)
		_check("Feuer ohne Wasser bleibt", not bool(g._punkte[0].erledigt))
		for i in 3:
			g.net_wasser()
			await _warten(0.2)
			_check("Eimer voll", bool(sp.traegt_wasser))
			g.net_punkt(i)
			await _warten(0.2)
		await _warten(0.4)
		_check("Feuer gelöscht, Quest erfüllt", story.zustand("G-6") == "erfuellt", story.zustand("G-6"))
		# Hochzeit: vier Girlanden, Wettessen: sechs Teller
		story._freischalten(g.Daten.quest("G-10"))
		story.annehmen("G-10")
		await _warten(0.6)
		_check("Hochzeit: vier Girlanden", g._punkte.size() == 4 and g._variante == "hochzeit", str(g._punkte.size()))
		for i in 4:
			g.net_punkt(i)
		await _warten(0.5)
		_check("Hochzeit: Quest erfüllt", story.zustand("G-10") == "erfuellt", story.zustand("G-10"))
		story._freischalten(g.Daten.quest("G-11"))
		story.annehmen("G-11")
		await _warten(0.6)
		_check("Wettessen: sechs Teller", g._punkte.size() == 6 and g._variante == "teller", str(g._punkte.size()))
		for i in 6:
			g.net_punkt(i)
		await _warten(0.5)
		_check("Wettessen: Quest erfüllt", story.zustand("G-11") == "erfuellt", story.zustand("G-11"))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
