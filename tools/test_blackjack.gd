extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Blackjack im Casino: Kartenwerte (Ass 1 oder 11), Runde mit Einsatz, Abrechnung.
##   godot --headless --path . res://tools/test_blackjack.tscn

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
		# Karten: Farbe * 13 + Rang (1 Ass, 11 Bube, 12 Dame, 13 König)
		_check("Ass und König = 21", gm._bj_wert([1, 13]) == 21)
		_check("Zwei Asse = 12", gm._bj_wert([1, 14]) == 12)
		_check("Ass zählt 1 wenn nötig", gm._bj_wert([1, 9, 8]) == 18)
		_check("Bube Dame König = 30", gm._bj_wert([11, 12, 13]) == 30)
		_check("Kreuz-Zehn zählt 10 (Rang 10 in Farbe 3)", gm._bj_wert([3 * 13 + 10]) == 10)
		Game.add_money(1000 - Game.money)
		gm.net_blackjack(0, 100)
		_check("Ohne Einlass keine Runde", gm._bj.is_empty())
		gm._casino_tag = gm._day
		gm.net_blackjack(0, -5)
		gm.net_blackjack(0, 0)
		_check("Ungültiger Einsatz wird abgelehnt", gm._bj.is_empty() and Game.money == 1000)
		# Runde mit Einsatz: der Einsatz geht sofort vom Konto
		gm.net_blackjack(0, 100)
		var laufend: bool = gm._bj.has(1)
		if laufend:
			_check("Einsatz sofort abgebucht", Game.money == 900, str(Game.money))
			gm.net_blackjack(3)   # verdoppeln
			_check("Verdoppeln bucht nochmal den Einsatz und beendet die Runde", Game.money == 800 and not gm._bj.has(1), str(Game.money))
			await get_tree().create_timer(4.5).timeout
		else:
			await get_tree().create_timer(2.0).timeout   # sofort Blackjack ausgespielt
		# Spielerhand 20 gegen Bank 19: der Einsatz kommt doppelt zurück
		Game.add_money(1000 - Game.money)
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [10, 13], "bank": [10, 9], "einsatz": 100, "doppelt": false}
		gm.net_blackjack(2)
		await get_tree().create_timer(2.0).timeout
		_check("20 gegen 19 gewonnen (+100)", Game.money == 1100, str(Game.money))
		Game.add_money(1000 - Game.money)
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [10, 8], "bank": [10, 9], "einsatz": 100, "doppelt": false}
		gm.net_blackjack(2)
		await get_tree().create_timer(2.0).timeout
		_check("18 gegen 19 verloren (-100)", Game.money == 900, str(Game.money))
		Game.add_money(1000 - Game.money)
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [10, 10, 5], "bank": [10, 9], "einsatz": 100, "doppelt": false}
		gm.net_blackjack(2)
		await get_tree().create_timer(2.0).timeout
		_check("Überkauft verloren (-100)", Game.money == 900, str(Game.money))
		Game.add_money(1000 - Game.money)
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [10, 9], "bank": [10, 9], "einsatz": 100, "doppelt": false}
		gm.net_blackjack(2)
		await get_tree().create_timer(2.0).timeout
		_check("Gleichstand: Einsatz zurück", Game.money == 1000, str(Game.money))
		Game.add_money(1000 - Game.money)
		Game.add_money(-100)
		gm._bj[1] = {"spieler": [1, 13], "bank": [10, 7], "einsatz": 100, "doppelt": false}
		gm._bj_ende(1)
		await get_tree().create_timer(2.0).timeout
		_check("Blackjack zahlt 3:2 (+150)", Game.money == 1150, str(Game.money))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
