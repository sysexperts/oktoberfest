extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kapitel 4: Schlüssel, Keller, Zutaten, Sud, Abfüllen, Hopfenblockade, eigenes Bier ausschenken.
##   godot --headless --path . res://tools/test_kapitel4.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0
	func _check(n: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", n, info])
		if not ok:
			fehler += 1

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		gm.set_process(false)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(4)
		story.quests["3.6"] = {"z": "erfuellt"}
		gm._tent_stage = 2
		Game.add_money(5000 - Game.money)
		gm._broadcast_meta()
		_check("4.1 offen, Mail vom Horst", story.zustand("4.1") == "offen" and story.post.any(func(m: Dictionary) -> bool: return m.id == "M4-01"), story.zustand("4.1"))
		gm.net_story_flag("schluessel_erhalten")
		_check("4.2 offen, Keller offen: 4.3 offen", story.zustand("4.3") == "offen", story.zustand("4.3"))
		gm.net_buy_zutat("malz", 2)
		gm.net_buy_zutat("hopfen", 1)
		gm._broadcast_meta()
		_check("4.4 offen nach dem Einkauf", story.zustand("4.4") == "offen", story.zustand("4.4"))
		# Sud: Maische und Kochen simuliert
		gm._zutat["hefe"] = 1
		gm._sud = 0.99
		gm._sud_hopfen = true
		gm._maische_fertig = true
		gm._zutat["malz"] = 1
		for i in 4:
			gm.net_brauen(2)
		_check("Sud fertig", gm._sud_fertig, str(gm._sud))
		gm.net_gaerfass_fuellen(0)
		_check("Gärfass gärt", int(gm._gaerfaesser[0].zustand) == 1, str(gm._gaerfaesser[0]))
		gm._gaerfaesser[0]["rest"] = 0.1
		gm._gaerung_zaehlen(1.0)
		_check("Gärung fertig (60 Maß)", int(gm._gaerfaesser[0].zustand) == 2 and int(gm._gaerfaesser[0].menge) == 60, str(gm._gaerfaesser[0]))
		var bier0: int = int(gm._stock[gm.WARE_BIER])
		gm.net_gaerfass_fuellen(0)
		gm._broadcast_meta()
		_check("Abgefüllt: 60 Maß im Lager, 4.6 offen", int(gm._stock[gm.WARE_BIER]) == bier0 + 60 and gm._eigenbier == 60 and story.zustand("4.6") == "offen", str(gm._stock[gm.WARE_BIER]))
		var ids: Array = story.post.map(func(m: Dictionary) -> String: return m.id)
		_check("Konrad schreibt wegen des Hopfens", ids.has("M4-02"), str(ids))
		var hopfen0: int = int(gm._zutat.get("hopfen", 0))
		gm.net_buy_zutat("hopfen", 1)
		_check("Hopfen ist blockiert", int(gm._zutat.get("hopfen", 0)) == hopfen0, "")
		gm.net_story_flag("hopfen_besorgt")
		gm._broadcast_meta()
		_check("Hopfen von Horst, 4.7 offen", int(gm._zutat.get("hopfen", 0)) == hopfen0 + 3 and story.zustand("4.7") == "offen", story.zustand("4.7"))
		gm._consume_stock(1)
		gm._broadcast_meta()
		_check("Eigenes Bier getrunken: Kapitel 4 geschafft", story.zustand("4.7") == "erfuellt" and story.kapitel == 5, "Kapitel %d" % story.kapitel)
		gm._eigenbier = 3
		gm._eigenbier_q = [0, 1, 2]
		var gu1: int = gm._consume_stock(1, false)
		var gu2: int = gm._consume_stock(1, false)
		var gu3: int = gm._consume_stock(1, false)
		var gu4: int = gm._consume_stock(1, false)
		_check("Eigenbier: erst Meisterbräu, dann Festbier, dann Fremdbier", gu1 == 2 and gu2 == 2 and gu3 == 1 and gu4 == -1, "%d %d %d %d" % [gu1, gu2, gu3, gu4])
		var gg := {"typ": "", "geduld_bonus": 1.0 + gm.EIGENBIER_GEDULD * 2.0}
		_check("Meisterbräu macht 30 % geduldiger", is_equal_approx(gm._geduld_max(gg), gm._geduld_max({"typ": ""}) * 1.3))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
