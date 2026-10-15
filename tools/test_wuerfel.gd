extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Würfelbecher im Casino: Tief, Sieben, Hoch mit Einsatz und Auszahlung.
##   godot --headless --path . res://tools/test_wuerfel.tscn

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
		Game.add_money(1000 - Game.money)
		var hoch := {"typ": "hoch", "einsatz": 50}
		gm.net_wuerfel([hoch])
		_check("Ohne Einlass kein Wurf", Game.money == 1000, str(Game.money))
		gm._casino_tag = gm._day
		_check("Hoch (11) zahlt 1:1", gm.wuerfel_auszahlung(hoch, 5, 6) == 100)
		_check("Sieben zahlt 4:1", gm.wuerfel_auszahlung({"typ": "sieben", "einsatz": 50}, 3, 4) == 250)
		_check("Sieben schlägt Hoch nicht", gm.wuerfel_auszahlung(hoch, 3, 4) == 0)
		_check("Tief (3) zahlt 1:1", gm.wuerfel_auszahlung({"typ": "tief", "einsatz": 50}, 1, 2) == 100)
		_check("Pasch zahlt 4:1, sonst nichts", gm.wuerfel_auszahlung({"typ": "pasch", "einsatz": 50}, 2, 2) == 250 and gm.wuerfel_auszahlung({"typ": "pasch", "einsatz": 50}, 2, 3) == 0)
		gm.net_wuerfel([{"typ": "tief", "einsatz": 100}, {"typ": "pasch", "einsatz": 50}])
		_check("Wurf bucht den Einsatz sofort ab", Game.money == 850, str(Game.money))
		_check("Würfe gezählt", int(gm._stats.get("wuerfel", 0)) == 1)
		var vorher_ungueltig: int = Game.money
		gm.net_wuerfel([{"typ": "quatsch", "einsatz": 50}])
		gm.net_wuerfel([{"typ": "tief", "einsatz": -5}])
		gm.net_wuerfel([])
		_check("Ungültige Wetten werden abgelehnt", Game.money == vorher_ungueltig)
		Game.add_money(-gm.OVERDRAFT_LIMIT + 10 - Game.money)
		var vorher: int = Game.money
		gm.net_wuerfel([hoch])
		_check("Ohne Geld kein Wurf", Game.money == vorher)
		Game.add_money(1000 - Game.money)
		var linien: Array = gm.slot_linien_treffer([[1, 1, 1], [1, 1, 1], [1, 1, 1]])
		_check("Neun Brezn: alle fünf Linien", linien.size() == 5 and int(linien[0].faktor) == 4)
		var sieben: Array = gm.slot_linien_treffer([[0, 5, 1], [2, 5, 3], [4, 5, 0]])
		_check("Drei Sieben in der Mitte: x60", sieben.size() == 1 and int(sieben[0].faktor) == 60 and int(sieben[0].linie) == 0)
		var wild: Array = gm.slot_linien_treffer([[1, 0, 1], [1, 6, 1], [1, 0, 1]])
		_check("Raute ersetzt ein Symbol (Maß x14)", wild.size() >= 1 and int(wild[0].faktor) == 14)
		var alles_wild: Array = gm.slot_linien_treffer([[1, 6, 1], [1, 6, 1], [1, 6, 1]])
		_check("Drei Rauten x80", int(alles_wild[0].faktor) == 80)
		_check("Kein Treffer", gm.slot_linien_treffer([[0, 1, 2], [3, 4, 5], [0, 1, 2]]).is_empty())
		gm.net_slot(100)
		_check("Automat bucht den Einsatz ab und zählt", Game.money == 900 and int(gm._stats.get("slot", 0)) == 1, str(Game.money))
		gm.net_slot(7)
		_check("Einsatz muss durch 5 teilbar sein", Game.money == 900)
		var tisch := (load("res://scenes/casino.tscn") as PackedScene).instantiate()
		add_child(tisch)
		var da := false
		for n in tisch.get_children():
			if n.get("art") == "wuerfel":
				da = n.hinweis_text(false) == "HINT_CASINO_WUERFEL"
		_check("Würfeltisch im Casino", da)
		var automaten := 0
		for n in tisch.get_children():
			if str(n.name).begins_with("Slot") and n.get("art") == "slot" and n.hinweis_text(false) == "HINT_CASINO_SLOT":
				automaten += 1
		_check("Zwei Spielautomaten im Casino", automaten == 2, str(automaten))
		get_tree().call_group("slot", "drehen", [1, 2, 3])
		await get_tree().create_timer(3.0).timeout
		var walze := tisch.get_node("Slot0/Kontrolle/Walzen/Walze2") as Sprite3D
		_check("Walzen laufen aus", walze.texture == load("res://assets/casino/slot_herz.png"))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
