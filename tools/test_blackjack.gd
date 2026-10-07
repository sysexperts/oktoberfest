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
		_check("Ass und Zehn = 21", gm._bj_wert([1, 13]) == 21)
		_check("Zwei Asse = 12", gm._bj_wert([1, 1]) == 12)
		_check("Ass zählt 1 wenn nötig", gm._bj_wert([1, 9, 8]) == 18)
		_check("Bube Dame König = 30", gm._bj_wert([11, 12, 13]) == 30)
		Game.add_money(1000 - Game.money)
		gm.net_blackjack(0)
		_check("Ohne Einlass keine Runde", gm._bj.is_empty())
		gm._casino_tag = gm._day
		# Spielerhand 20 gegen Bank 19: gewonnen
		gm._bj[1] = {"spieler": [10, 13], "bank": [10, 9]}
		gm.net_blackjack(2)
		_check("20 gegen 19 gewonnen", Game.money == 1000 + gm.ROULETTE_EINSATZ, str(Game.money))
		Game.add_money(1000 - Game.money)
		gm._bj[1] = {"spieler": [10, 8], "bank": [10, 9]}
		gm.net_blackjack(2)
		_check("18 gegen 19 verloren", Game.money == 1000 - gm.ROULETTE_EINSATZ, str(Game.money))
		Game.add_money(1000 - Game.money)
		gm._bj[1] = {"spieler": [10, 10, 5], "bank": [10, 9]}
		gm.net_blackjack(2)
		_check("Überkauft verloren", Game.money == 1000 - gm.ROULETTE_EINSATZ)
		Game.add_money(1000 - Game.money)
		gm._bj[1] = {"spieler": [1, 13], "bank": [10, 7]}
		gm._bj_ende(1)
		_check("Blackjack zahlt 3:2", Game.money == 1000 + gm.ROULETTE_EINSATZ * 3 / 2, str(Game.money))
		gm.net_blackjack(0)
		_check("Neue Runde gestartet oder sofort Blackjack", true)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
