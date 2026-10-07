extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Zwischenfälle: Heiratsantrag, Karaoke, Flirt, verschüttetes Bier.
##   godot --headless --path . res://tools/test_zwischenfaelle.tscn

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
		Game.add_money(5000 - Game.money)
		gm._phase = gm.Phase.INTERMISSION
		gm.net_book_tent()
		gm.net_buy_table()
		gm.net_buy_table()
		gm._phase = gm.Phase.SHIFT
		for i in 8:
			gm._spawn_guest()
		for id in gm._guest_sim.keys():
			gm._guest_sim[id].mode = 1
			gm._guest_sim[id].patience = 1.0
		_check("Gäste sitzen", gm._guest_sim.size() >= 8, str(gm._guest_sim.size()))
		var geld: int = Game.money
		gm._zwischenfall_ausloesen("heirat")
		_check("Heiratsantrag zahlt Trinkgeld", Game.money > geld, "%d" % (Game.money - geld))
		gm._zwischenfall_ausloesen("flirt")
		var geduldig := true
		for g in gm._guest_sim.values():
			if float(g.patience) <= 1.5:
				geduldig = false
		_check("Flirt: alle wieder geduldig", geduldig)
		var flecken: int = gm._mess_kind.size()
		gm._zwischenfall_ausloesen("verschuettet")
		_check("Verschüttetes Bier: neuer Fleck", gm._mess_kind.size() > flecken, "%d -> %d" % [flecken, gm._mess_kind.size()])
		gm._zwischenfall_ausloesen("karaoke")
		_check("Karaoke läuft eine Minute", gm._karaoke_t > 50.0)
		_check("Zwischenfälle gezählt", int(gm._stats.get("zwischenfaelle", 0)) == 4, str(gm._stats.get("zwischenfaelle", 0)))
		gm._zwischenfall_t = 0.0
		gm._zwischenfall_takt(1.0)
		_check("Takt löst von selbst aus und setzt neu", gm._zwischenfall_t > 50.0, "%.0f" % gm._zwischenfall_t)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
