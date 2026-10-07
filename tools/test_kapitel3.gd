extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kapitel 3: Wette, Stinkbombe, Security, Saboteur, Zettel, Konrad zur Rede.
##   godot --headless --path . res://tools/test_kapitel3.tscn

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
		# Kapitel 2 abgeschlossen: 2.6 erfüllt
		story.kapitel_setzen(3)
		story.quests["2.6"] = {"z": "erfuellt"}
		gm._broadcast_meta()
		await _warten(0.3)
		_check("3.1 ist offen", story.zustand("3.1") == "offen", story.zustand("3.1"))
		var ids: Array = story.post.map(func(m: Dictionary) -> String: return m.id)
		_check("Konrads Wetten-Mail", ids.has("M3-01"), str(ids))
		# Wette gewinnen
		story.ereignis("wette_gewonnen")
		gm._broadcast_meta()
		_check("3.2 offen nach der Wette", story.zustand("3.1") == "erfuellt" and story.zustand("3.2") == "offen", story.zustand("3.2"))
		# Streich erzwingt Stinkbombe
		gm._day = 20
		gm._huber_morgen()
		_check("Stinkbombe wird für heute erzwungen", gm._saboteur_art == "stink" and gm._sabotage_t > 0.0, str(gm._saboteur_art))
		gm._saboteur_losschicken()
		_check("Saboteur unterwegs", not gm._saboteur.is_empty(), str(gm._saboteur))
		gm._saboteur.rest = 0.0
		gm._saboteur_schicht(0.1)
		_check("Stinkbombe liegt", gm._stink_offen, "")
		# Flecken weg
		for k in gm._mess_kind.keys():
			gm._mess_kind.erase(k)
		gm._huber_schicht(0.1)
		gm._broadcast_meta()
		_check("3.3 offen nach dem Putzen", story.zustand("3.2") == "erfuellt" and story.zustand("3.3") == "offen", story.zustand("3.3"))
		# Security einstellen
		Game.add_money(5000 - Game.money)
		gm._phase = gm.Phase.INTERMISSION
		gm.net_hire_staff(gm.ROLE_SECURITY)
		await _warten(0.3)
		gm._broadcast_meta()
		_check("Security eingestellt, 3.4 offen", gm._staff_anzahl(gm.ROLE_SECURITY) == 1 and story.zustand("3.4") == "offen", story.zustand("3.4"))
		# Saboteur fangen
		gm._saboteur = {"art": "fass", "rest": 50.0}
		gm.net_saboteur_fangen()
		gm._broadcast_meta()
		_check("3.4b offen nach dem Fang", story.zustand("3.4") == "erfuellt" and story.zustand("3.4b") == "offen" and bool(story.flags.get("zettel_da", false)), story.zustand("3.4b"))
		# Casino: Komplettset bei Gustav, Türsteher, eine Runde Roulette
		gm.net_casino_tuer()
		_check("Ohne Tarnung kein Zutritt", gm._casino_tag != gm._day)
		Game.add_money(1000)
		gm.net_sab_kauf("komplett")
		gm.net_casino_tuer()
		_check("Mit Tarnung eingelassen", gm._casino_tag == gm._day)
		gm.net_roulette(0)
		gm._broadcast_meta()
		_check("3.5 offen nach dem Roulette", story.zustand("3.4b") == "erfuellt" and story.zustand("3.5") == "offen", story.zustand("3.5"))
		gm.net_story_flag("zettel_uebergeben")
		_check("3.6 offen nach dem Zettel", story.zustand("3.6") == "offen", story.zustand("3.6"))
		gm.net_story_flag("konrad_zur_rede")
		gm._broadcast_meta()
		_check("Kapitel 3 abgeschlossen", story.zustand("3.6") == "erfuellt" and story.kapitel == 4, "Kapitel %d" % story.kapitel)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
