extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kirmes-Quests „Rekord“: Bestleistung je Spiel zählt, Quest wird erfüllt und zahlt.
##   godot --headless --path . res://tools/test_kirmesquests.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _stand(gm: Node, skript: String) -> Node:
		for n in get_tree().get_nodes_in_group("kirmes_spiel"):
			if n.get_script() != null and (n.get_script() as Script).resource_path.get_file().get_basename() == skript:
				return n
		return null

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(2)
		gm._tent_stage = 1
		story._folge({"quest_starten": "K-2"})
		_check("Kirmes-Quest läuft", story.zustand("K-2") == "offen", story.zustand("K-2"))
		var stand := _stand(gm, "dosenwurf")
		_check("Dosenwurf-Stand in der Welt", stand != null)
		if stand == null:
			get_tree().quit()
			return
		Game.add_money(500 - Game.money)
		gm._schiessen_bezahlt[1] = gm.get_path_to(stand)
		gm.net_schiessen_ende(5)
		gm._broadcast_meta()
		_check("5 Punkte reichen nicht", story.zustand("K-2") == "offen" and int(gm._stats.get("rekord_dosenwurf", 0)) == 5)
		gm._schiessen_bezahlt[1] = gm.get_path_to(stand)
		var geld: int = Game.money
		gm.net_schiessen_ende(9)
		gm._broadcast_meta()
		_check("9 Punkte: Quest erfüllt", story.zustand("K-2") == "erfuellt" and int(gm._stats.rekord_dosenwurf) == 9, story.zustand("K-2"))
		_check("Belohnung gebucht", Game.money > geld, "%d -> %d" % [geld, Game.money])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
