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
		gm._fest.motto = 0
		var tracht := 0
		for i in 400:
			if gm._gast_typ_waehlen() == "tracht":
				tracht += 1
		_check("Motto Trachtenfest: viele Trachtengäste", tracht > 150, "%d von 400" % tracht)
		gm._fest.motto = 1
		_check("Andrang erhöht", gm._ereignis_andrang() > 1.5, "%.2f" % gm._ereignis_andrang())
		# Katastrophe ohne und mit Schutz
		gm._fest.schutz = 0
		gm._fest_kata = "knapp"
		gm._stock[gm.WARE_BIER] = 100
		gm._fest_katastrophe()
		_check("Ohne Vorrat: Bier wird knapp", int(gm._stock[gm.WARE_BIER]) < 100 and int(gm._fest.kata_ruhm) == -5, str(gm._stock[gm.WARE_BIER]))
		gm._fest.schutz = 2
		gm._fest_kata = "strom"
		gm._fest_katastrophe()
		_check("Mit Notstrom abgewehrt, kein Stromausfall", gm._strom_t == 0.0 and int(gm._fest.kata_ruhm) == 0, str(gm._fest.kata_ruhm))
		gm._fest.schutz = 0
		gm._fest_kata = "strom"
		gm._fest_katastrophe()
		_check("Ohne Notstrom: Stromausfall", gm._strom_t > 0.0)
		gm._strom_t = 0.0
		_check("Schutz kostet extra", gm.fest_kosten(1, 0, false, false, false, 7) == 150 + 200 + 300 + 250, str(gm.fest_kosten(1, 0, false, false, false, 7)))
		_check("Wettbewerb ist gewählt", not gm._fest_wb.is_empty() and int(gm._fest_wb.ziel) > 0, str(gm._fest_wb))
		# Wettbewerb: das gewählte Spiel mit dem Ziel schaffen
		var wb_spiel: String = gm._fest_wb.spiel
		var stand_wb: Node = null
		for n in get_tree().get_nodes_in_group("kirmes_spiel"):
			if n.get_script() != null and (n.get_script() as Script).resource_path.get_file().get_basename() == wb_spiel:
				stand_wb = n
		if stand_wb != null:
			gm._schiessen_bezahlt[1] = gm.get_path_to(stand_wb)
			gm.net_schiessen_ende(int(gm._fest_wb.ziel))
			_check("Wettbewerb: Ziel erreicht", int(gm._fest_wb.best) >= int(gm._fest_wb.ziel))
		else:
			gm._fest_wb.best = int(gm._fest_wb.ziel)
		gm._served = 40
		gm._popularity = 60.0
		var ruhm_vorher: int = gm._fest_ruhm
		gm._fest_auswerten()
		_check("Wettbewerbsbonus im Festruhm", gm._fest_ruhm - ruhm_vorher >= gm.FEST_WB_BONUS and int(gm._stats.get("wettbewerbe", 0)) == 1, str(gm._fest_ruhm - ruhm_vorher))
		_check("Festruhm gebucht", gm._fest_ruhm > 0 and gm._fest.is_empty() and gm._fest_letzter == 13, str(gm._fest_ruhm))
		_check("Pause bis zum nächsten Fest", not gm.fest_moeglich())
		gm._day = 23
		_check("Nach 10 Tagen wieder möglich", gm.fest_moeglich())
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
