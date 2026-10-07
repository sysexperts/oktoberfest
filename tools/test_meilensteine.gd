extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Meilensteine := preload("res://scripts/meilensteine.gd")
## Neue Meilensteine: Kapitel, Meister-Liste, Sabotage, Casino, Fest. Jeder hat Titel und Text in allen Sprachen.
##   godot --headless --path . res://tools/test_meilensteine.tscn

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
		var ohne := 0
		for m: Dictionary in Meilensteine.LISTE:
			if TranslationServer.translate("MS_%s_TITLE" % m.id) == "MS_%s_TITLE" % m.id:
				ohne += 1
		_check("Alle Meilensteine haben Titel", ohne == 0, "%d ohne" % ohne)
		_check("Mehr als 40 Meilensteine", Meilensteine.LISTE.size() > 40, str(Meilensteine.LISTE.size()))
		var ms0: int = gm._meilensteine.size()
		gm._stats["sab_ok"] = 1
		gm._stats["roulette"] = 1
		var neu: bool = gm._pruefe_meilensteine()
		_check("Sabotage und Roulette zählen", neu and gm._meilensteine.has("SABOTAGE_1") and gm._meilensteine.has("CASINO_ROULETTE"))
		_check("Kapitel 2 erreicht", gm._meilensteine.has("KAPITEL_2") and not gm._meilensteine.has("KAPITEL_3"))
		story.kapitel_setzen(3)
		gm._pruefe_meilensteine()
		_check("Kapitel 3 erreicht", gm._meilensteine.has("KAPITEL_3"))
		_check("Meister-Liste als Quelle (Gefallen)", Meilensteine.wert_von("meister:MEISTER_GEFALLEN", {}, {"meister": [["MEISTER_GEFALLEN", 5, 9]]}) == 5)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
