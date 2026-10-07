extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Sabotage in Konrads Zelt: Werkzeug verbraucht, Cooldown, Erfolg zahlt, Erwischt kostet, Konrad schlägt zurück.
##   godot --headless --path . res://tools/test_sabotage.tscn

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
		Game.add_money(3000 - Game.money)
		gm._sab_inv = {"fassbohrer": 1, "zange": 1, "stinkbombe": 1}
		gm.net_sabotage("juck", false)
		_check("Ohne Werkzeug nichts", gm._rache_tag == -1)
		gm.net_sabotage("fass", false)
		_check("Erfolg zahlt, Werkzeug weg", Game.money == 3000 + gm.SAB_ERFOLG and int(gm._sab_inv.fassbohrer) == 0, str(Game.money))
		_check("Konrad schlägt morgen zurück", gm._rache_tag == gm._day + 1)
		gm._sab_inv["fassbohrer"] = 1
		gm.net_sabotage("fass", false)
		_check("Pro Tag nur einmal je Ziel", int(gm._sab_inv.fassbohrer) == 1)
		var geld: int = Game.money
		gm.net_sabotage("strom", true)
		_check("Erwischt kostet Bußgeld", Game.money == geld - gm.SAB_BUSSE, "%d -> %d" % [geld, Game.money])
		var konrad := get_tree().get_first_node_in_group("huber")
		_check("Konrad hat ein Blickfeld", konrad != null and konrad.has_method("sieht"))
		gm._day += 1
		gm._huber_morgen()
		_check("Rache: Streich ist gesetzt", gm._streich_art != "", gm._streich_art)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
