extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kirmes-Besucher: am ersten Tag keine, ab dem ersten Aufwachen (Tag 2) kommen sie.
##   godot --headless --path . res://tools/test_besucher_start.tscn

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
		gm._apply_crowd(-1.0)
		_check("Tag 1: keine Besucher draußen", gm._crowd._target == 0, str(gm._crowd._target))
		gm._day = 2
		gm._apply_crowd(-1.0)
		_check("Tag 2: Besucher kommen", gm._crowd._target > 100, str(gm._crowd._target))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
