extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wohnwagen-Ausbau: Bett-Stufen, Einrichtung, Prestige, Tempo am Tag.
##   godot --headless --path . res://tools/test_wagen.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(3)
		gm._tent_stage = 2
		gm._phase = gm.Phase.INTERMISSION
		Game.add_money(5000 - Game.money)
		_check("Start: Bett 1, kein Prestige", int(gm._wagen.bett) == 1 and gm.wagen_prestige() == 0)
		gm.net_wagen_kauf("bett")
		_check("Bett Stufe 2 kostet 400", int(gm._wagen.bett) == 2 and Game.money == 4600, str(Game.money))
		gm.net_wagen_kauf("sofa")
		gm.net_wagen_kauf("sofa")
		_check("Sofa nur einmal", (gm._wagen.items as Array).count("sofa") == 1 and Game.money == 4300, str(Game.money))
		_check("Prestige 2", gm.wagen_prestige() == 2)
		gm.net_wagen_kauf("bett")
		gm.net_wagen_kauf("bett")
		_check("Bett bei Stufe 3 am Ende", int(gm._wagen.bett) == 3 and Game.money == 3400, str(Game.money))
		gm._ereignis = "fest"
		gm._fest = {"tag": gm._day, "motto": 0, "band": 1, "feuer": 0, "deko": false, "werbung": false, "hilfe": false}
		gm._served = 0
		gm._popularity = 0.0
		gm._fest_auswerten()
		_check("Prestige zählt beim Festruhm", gm._fest_ruhm == gm._fest_ruhm and gm._fest_ruhm >= 3 + 10, str(gm._fest_ruhm))
		var sp: Node3D = gm._players_nodes.get(1)
		gm._broadcast_meta()
		sp._tarnung_t = 0.0
		sp._tarnung_pruefen(1.0)
		_check("Ausgeschlafen: 6 % mehr Tempo", is_equal_approx(float(sp._ausgeschlafen), 1.06), str(sp._ausgeschlafen))
		var geld_f: int = Game.money
		gm.net_wagen_farbe("rot")
		_check("Neue Farbe kostet 200 €, Wagen ist rot", Game.money == geld_f - 200 and str(gm._wagen.farbe) == "rot", "%d %s" % [geld_f - Game.money, gm._wagen.farbe])
		gm.net_wagen_farbe("blau")
		_check("Zurück zu Blau kostet nichts", Game.money == geld_f - 200 and str(gm._wagen.farbe) == "blau")
		gm.net_wagen_farbe("rot")
		_check("Gekaufte Farbe wechselt frei", Game.money == geld_f - 200 and str(gm._wagen.farbe) == "rot")
		_check("Farbe zählt als Prestige", gm.wagen_prestige() == 4, str(gm.wagen_prestige()))
		gm._players_nodes[2] = Node3D.new()
		gm._wagen_farbe_peer[2] = "gruen"
		var plaetze: Array = gm.wagen_plaetze()
		_check("Zwei Wagenplätze, Host rot, Gast grün", plaetze.size() == 2 and str(plaetze[0].farbe) == "rot" and str(plaetze[1].farbe) == "gruen" and int(plaetze[1].peer) == 2, str(plaetze))
		gm._players_nodes.erase(2)
		_check("Plätze gehen mit dem Spieler", gm.wagen_plaetze().size() == 1)
		var wagen_reihe := Caravan.plaetze(get_tree())
		_check("Wohnwagenplätze gefunden, eigener zuerst", wagen_reihe.size() >= 2 and (wagen_reihe[0] as Caravan).is_mine, str(wagen_reihe.size()))
		var app := (load("res://scenes/ui/desktop_wagen.tscn") as PackedScene).instantiate()
		add_child(app)
		_check("Wagen-App hat den Spiegel-Knopf", app.get_node_or_null("%Spiegel") is Button and (app.get_node("%Spiegel") as Button).text != "")
		app.queue_free()
		story.kapitel_setzen(2)
		var geld: int = Game.money
		gm.net_wagen_kauf("regal")
		_check("Vor Kapitel 3 nichts kaufbar", Game.money == geld)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
