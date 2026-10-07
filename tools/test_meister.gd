extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Meister-Liste: Einträge zählen mit, Titel „Fest-Meister“ erst bei 100 %.
##   godot --headless --path . res://tools/test_meister.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _fertige(gm: Node) -> int:
		var n := 0
		for e: Array in gm.meister_liste():
			if int(e[1]) >= int(e[2]):
				n += 1
		return n

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(2)
		gm._tent_stage = 1
		var n0 := _fertige(gm)
		_check("Liste hat 16 Einträge", gm.meister_liste().size() == 16)
		gm._stats["meisterfaesser"] = 1
		gm._stats["sab_ok"] = 1
		_check("Einträge zählen mit", _fertige(gm) == n0 + 2, "%d -> %d" % [n0, _fertige(gm)])
		_check("Noch kein Titel", not gm.meister_fertig())
		# Alles erfüllen
		story.kapitel_setzen(6)
		gm._tent_stage = 4
		gm._schulden = 0
		gm._fest_ruhm = 5000
		gm._stats.duell_siege = 5
		gm._stats["roulette"] = 1
		gm._stats["blackjack"] = 1
		gm._stats["fakes_gemeldet"] = 1
		for r in range(1, 7):
			gm._stats["hire_%d" % r] = 1
		for i in range(1, 8):
			story.quests["K-%d" % i] = {"z": "erfuellt"}
		gm._ausbau = ["biergarten", "vip", "theke2", "buehne", "handel", "konrad"]
		gm._wagen = {"bett": 3, "items": ["sofa", "poster", "pflanze", "regal"]}
		story.flags["kontrolle_bestanden"] = true
		story.flags["rezeptseite3"] = true
		for i in range(1, 10):
			story.quests["G-%d" % i] = {"z": "erfuellt"}
		_check("Liste komplett", gm.meister_fertig(), str(gm.meister_liste()))
		gm._meister_pruefen()
		_check("Titel vergeben", int(gm._stats.get("meister_titel", 0)) == 1)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
