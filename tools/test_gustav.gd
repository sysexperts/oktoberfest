extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Händler Gustav: Kauf von Tarnung und Werkzeug erst ab Kapitel 3, Geld wird gebucht.
##   godot --headless --path . res://tools/test_gustav.tscn

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
		story.kapitel_setzen(2)
		Game.add_money(2000 - Game.money)
		gm.net_sab_kauf("fassbohrer")
		_check("Kapitel 2: nichts gekauft", int(gm._sab_inv.get("fassbohrer", 0)) == 0 and Game.money == 2000)
		story.kapitel_setzen(3)
		gm.net_sab_kauf("fassbohrer")
		_check("Fassbohrer gekauft", int(gm._sab_inv.get("fassbohrer", 0)) == 1 and Game.money == 2000 - gm.SAB_WAREN.fassbohrer, str(Game.money))
		gm.net_sab_kauf("komplett")
		_check("Komplettset: Tarnung Stufe 2, an", gm._tarnung_stufe == 2 and gm._tarnung_an)
		gm.net_tarnung_wechseln()
		_check("Tarnung ausgezogen", not gm._tarnung_an)
		var geld: int = Game.money
		gm.net_sab_kauf("komplett")
		_check("Nicht doppelt kaufen", Game.money == geld)
		_check("Laden und Gustav in der Welt", get_tree().get_first_node_in_group("gustav_laden") != null)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
