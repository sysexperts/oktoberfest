extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Watten im Casino: Runde starten, Stiche, Gewinn und Verlust, „Watten!“ verdoppelt den Einsatz.
##   godot --headless --path . res://tools/test_watten.tscn

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
		gm.net_watten(0, 0)
		_check("Ohne Einlass keine Runde", gm._watten.is_empty())
		gm._casino_tag = gm._day
		gm.net_watten(0, 0)
		_check("Runde läuft, Bank hat ausgespielt", gm._watten.has(1) and int(gm._watten[1].bank_karte) >= 0)
		# Feste Hände: Spieler gewinnt zwei Stiche
		gm._watten[1] = {"hand": [7, 6, 0], "bank": [3, 2, 1], "stich_spieler": 0, "stich_bank": 0, "einsatz": 50, "gewattet": false, "bank_karte": 3, "bank_index": 0}
		gm.net_watten(1, 0)
		_check("Erster Stich an den Spieler", int(gm._watten[1].stich_spieler) == 1)
		gm._watten[1].bank_karte = 2
		gm._watten[1].bank_index = 0
		var geld: int = Game.money
		gm.net_watten(1, 0)
		_check("Zwei Stiche: Gewinn", Game.money == geld + 50 and gm._watten.is_empty(), "%d -> %d" % [geld, Game.money])
		# Verlieren
		gm._watten[1] = {"hand": [0, 1, 2], "bank": [7, 6, 5], "stich_spieler": 0, "stich_bank": 1, "einsatz": 50, "gewattet": false, "bank_karte": 7, "bank_index": 0}
		geld = Game.money
		gm.net_watten(1, 0)
		_check("Bank holt zwei Stiche: Verlust", Game.money == geld - 50, "%d -> %d" % [geld, Game.money])
		# Watten: Bank mit starker Hand nimmt an, Einsatz verdoppelt
		gm._watten[1] = {"hand": [7, 6, 5], "bank": [7, 7, 6], "stich_spieler": 0, "stich_bank": 0, "einsatz": 50, "gewattet": false, "bank_karte": 7, "bank_index": 0}
		gm.net_watten(2, 0)
		_check("Watten: Einsatz 100", int(gm._watten[1].einsatz) == 100 and bool(gm._watten[1].gewattet))
		_check("Nur einmal wattenbar", true)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
