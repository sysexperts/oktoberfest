extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Gäste in Gruppen und Wunschlieder: Bonus nach vollständiger Bedienung, Wunsch erscheint und wird erfüllt oder verpasst.
##   godot --headless --path . res://tools/test_gaeste.tscn

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
		gm._tent_stage = 1
		# Gruppe aus drei Gästen
		gm._gruppen[7] = {"n": 3, "ids": {}, "art": 1}
		var geld: int = Game.money
		gm._gruppe_bedient(1, {"gruppe": 7})
		gm._gruppe_bedient(1, {"gruppe": 7})
		gm._gruppe_bedient(2, {"gruppe": 7})
		_check("Zwei von drei: noch kein Bonus", Game.money == geld)
		gm._gruppe_bedient(3, {"gruppe": 7})
		_check("Alle drei bedient: Bonus", Game.money >= geld + gm.GRUPPE_BONUS * 3 and int(gm._stats.get("gruppen", 0)) == 1, "%d -> %d" % [geld, Game.money])
		gm._gruppe_bedient(4, {"gruppe": 7})
		_check("Bonus nur einmal", int(gm._stats.get("gruppen", 0)) == 1)
		# Wunschlied
		gm._phase = gm.Phase.SHIFT
		gm._artist_tier = 0
		gm._wunsch_takt(500.0)
		_check("Ohne Künstler kein Wunsch", gm._wunsch.is_empty())
		gm._artist_tier = 1
		gm._wunsch_t = 1.0
		gm._wunsch_takt(2.0)
		_check("Mit Künstler: Wunsch erscheint", not gm._wunsch.is_empty(), str(gm._wunsch))
		var pop: float = gm._popularity
		geld = Game.money
		gm.net_wunsch_erfuellen()
		_check("Wunsch erfüllt: Beliebtheit und Trinkgeld", gm._popularity > pop and Game.money > geld and int(gm._stats.wuensche) == 1, "%d" % (Game.money - geld))
		gm._wunsch = {"titel": 2, "rest": 3.0}
		pop = gm._popularity
		gm._wunsch_takt(5.0)
		_check("Wunsch verpasst: Beliebtheit sinkt", gm._wunsch.is_empty() and gm._popularity < pop)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
