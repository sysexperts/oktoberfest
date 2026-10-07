extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kapitel 5: Konrads letztes Angebot, Duell-Sieg, dritte Seite, drei Suds, Riesenzelt, Schulden, großes Fest.
##   godot --headless --path . res://tools/test_kapitel5.tscn

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
		story.kapitel_setzen(5)
		story.quests["4.7"] = {"z": "erfuellt"}
		gm._tent_stage = 1
		gm._broadcast_meta()
		_check("5.1 offen mit Konrads Mail", story.zustand("5.1") == "offen" and story.post.any(func(m: Dictionary) -> bool: return m.id == "M5-01"), story.zustand("5.1"))
		story.post_antworten(story.post.size() - 1, 0) if false else story.ereignis("konrad_letztes_angebot")
		gm._broadcast_meta()
		_check("5.2 offen, Duell möglich", story.zustand("5.2") == "offen" and gm.duell_moeglich(), story.zustand("5.2"))
		gm._duell = {"peer": 1, "huber": 99.0}
		gm.net_duell_ende(10.0, 0)
		gm._broadcast_meta()
		_check("Duell gewonnen: 5.3 offen", story.zustand("5.2") == "erfuellt" and story.zustand("5.3") == "offen", story.zustand("5.3"))
		gm.net_story_flag("rezeptseite3")
		_check("5.4 offen", story.zustand("5.4") == "offen", story.zustand("5.4"))
		_check("Rezeptbuch: drei Seiten", gm.rezeptseiten() == 3, str(gm.rezeptseiten()))
		gm._gaerfaesser[0] = {"zustand": 2, "rest": 0.0, "menge": 8, "q": gm.rezeptseiten()}
		gm._tent_stage = maxi(gm._tent_stage, gm.KELLER_AB_STUFE)
		gm._eigenbier = 0
		gm._eigenbier_q = [0, 0, 0]
		gm.net_gaerfass_fuellen(0)
		_check("Meisterbräu im Lager", int(gm._eigenbier_q[2]) == 8 and int(gm._stats.get("meisterfaesser", 0)) == 1, str(gm._eigenbier_q))
		var geld_q: int = Game.money
		gm._consume_stock(1)
		_check("Aufschlag für Meisterbräu", Game.money > geld_q, "%d -> %d" % [geld_q, Game.money])
		gm._broadcast_meta()
		_check("5.5 offen", story.zustand("5.5") == "offen", story.zustand("5.5"))
		gm._tent_stage = 4
		gm._broadcast_meta()
		_check("5.6 offen", story.zustand("5.6") == "offen", story.zustand("5.6"))
		gm._schulden = 0
		gm._broadcast_meta()
		_check("5.7 offen", story.zustand("5.7") == "offen", story.zustand("5.7"))
		var geld0: int = Game.money
		story.ereignis("fest_gefeiert")
		gm._broadcast_meta()
		_check("Das große Fest: Story abgeschlossen (Kapitel 6), 1.000 € Belohnung", story.zustand("5.7") == "erfuellt" and story.kapitel == 6 and Game.money >= geld0 + 1000, "Kapitel %d" % story.kapitel)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
