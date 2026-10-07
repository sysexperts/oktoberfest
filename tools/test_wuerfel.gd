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
		gm.net_wuerfel(2)
		_check("Ohne Einlass kein Wurf", Game.money == 1000, str(Game.money))
		gm._casino_tag = gm._day
		gm._wuerfel_auswerten(5, 6, 2)
		_check("Hoch gewonnen (11): +50", Game.money == 1000 + gm.ROULETTE_EINSATZ, str(Game.money))
		Game.add_money(1000 - Game.money)
		gm._wuerfel_auswerten(3, 4, 1)
		_check("Sieben zahlt 4:1", Game.money == 1000 + gm.ROULETTE_EINSATZ * 4, str(Game.money))
		Game.add_money(1000 - Game.money)
		gm._wuerfel_auswerten(3, 4, 2)
		_check("Sieben schlägt Hoch: verloren", Game.money == 1000 - gm.ROULETTE_EINSATZ, str(Game.money))
		Game.add_money(1000 - Game.money)
		gm._wuerfel_auswerten(1, 2, 0)
		_check("Tief gewonnen (3)", Game.money == 1000 + gm.ROULETTE_EINSATZ, str(Game.money))
		_check("Würfe gezählt", int(gm._stats.get("wuerfel", 0)) == 4)
		Game.add_money(-gm.OVERDRAFT_LIMIT + 10 - Game.money)
		var vorher: int = Game.money
		gm.net_wuerfel(0)
		_check("Ohne Geld kein Wurf", Game.money == vorher)
		var tisch := (load("res://scenes/casino.tscn") as PackedScene).instantiate()
		add_child(tisch)
		var da := false
		for n in tisch.get_children():
			if n.get("art") == "wuerfel":
				da = n.hinweis_text(false) == "HINT_CASINO_WUERFEL"
		_check("Würfeltisch im Casino", da)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
