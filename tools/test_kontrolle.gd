extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Hygienekontrolle mit Frau Wagner: Figur läuft los, nach der Runde fällt das Urteil.
##   godot --headless --path . res://tools/test_kontrolle.tscn

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
		gm._tent_stage = 2
		gm._hygiene = 90.0
		var pop0: float = gm._popularity
		gm._kontrolle_beginnen()
		await get_tree().process_frame
		_check("Frau Wagner ist da", get_tree().get_nodes_in_group("wagner").size() == 1)
		_check("Runde dauert", gm._kontrolle_t > 20.0, "%.0f s" % gm._kontrolle_t)
		gm._update_ereignis(gm._kontrolle_t + 1.0)
		_check("Urteil: bestanden, Beliebtheit steigt", gm._popularity > pop0 or pop0 >= 100.0, "%.1f -> %.1f" % [pop0, gm._popularity])
		var geld: int = Game.money
		gm._hygiene = 10.0
		gm._kontrolle_beginnen()
		gm._update_ereignis(gm._kontrolle_t + 1.0)
		_check("Urteil: durchgefallen, Strafe", Game.money == geld - gm.KONTROLLE_STRAFE, "%d -> %d" % [geld, Game.money])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
