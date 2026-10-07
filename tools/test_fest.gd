extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Das Fest (ab Kapitel 6): planen und bezahlen, am Festtag Ereignis und Band, abends Festruhm, Pause bis zum nächsten.
##   godot --headless --path . res://tools/test_fest.tscn

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
		gm._tent_stage = 3
		gm._phase = gm.Phase.INTERMISSION
		Game.add_money(5000 - Game.money)
		_check("Vor Kapitel 6 kein Fest", not gm.fest_moeglich())
		story.kapitel_setzen(6)
		gm._day = 12
		_check("Fest möglich", gm.fest_moeglich())
		var kosten: int = gm.fest_kosten(2, 2, true, true, false)
		_check("Kosten stimmen", kosten == 400 + 500 + 150 + 300, str(kosten))
		gm.net_fest_planen(1, 2, 2, true, true, false)
		_check("Bezahlt und geplant", Game.money == 5000 - kosten and int(gm._fest.tag) == 13, str(Game.money))
		_check("Nicht noch ein Fest", not gm.fest_moeglich())
		gm._day = 13
		gm._ereignis_waehlen()
		_check("Festtag: Ereignis und Band", gm._ereignis == "fest" and gm._artist_tier == 2, "%s %d" % [gm._ereignis, gm._artist_tier])
		_check("Andrang erhöht", gm._ereignis_andrang() > 1.5, "%.2f" % gm._ereignis_andrang())
		gm._served = 40
		gm._popularity = 60.0
		gm._fest_auswerten()
		_check("Festruhm gebucht", gm._fest_ruhm > 0 and gm._fest.is_empty() and gm._fest_letzter == 13, str(gm._fest_ruhm))
		_check("Pause bis zum nächsten Fest", not gm.fest_moeglich())
		gm._day = 23
		_check("Nach 10 Tagen wieder möglich", gm.fest_moeglich())
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
