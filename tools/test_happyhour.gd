extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Nebenquest „Happy Hour“ (N-2-4): erzwingt die Happy Hour, zählt Maß, 40 Maß erfüllen sie.
##   godot --headless --path . res://tools/test_happyhour.tscn

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
		story._folge({"quest_starten": "N-2-4"})
		_check("Happy-Hour-Quest läuft", story.zustand("N-2-4") == "offen", story.zustand("N-2-4"))
		gm._ereignis_waehlen()
		_check("Heute ist Happy Hour", gm._ereignis == "happy", gm._ereignis)
		var geld: int = Game.money
		gm._happy_masse = 40
		gm._broadcast_meta()
		_check("40 Maß erfüllen die Quest", story.zustand("N-2-4") == "erfuellt" and Game.money == geld + 200, "%s %d" % [story.zustand("N-2-4"), Game.money - geld])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
