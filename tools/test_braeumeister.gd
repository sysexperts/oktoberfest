extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Bräumeister Gerhard (Rolle 6): einstellen ab Kapitel 4, braut von allein bis ins Lager.
##   godot --headless --path . res://tools/test_braeumeister.tscn

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
		Game.add_money(5000 - Game.money)
		gm._phase = gm.Phase.INTERMISSION
		gm.net_hire_staff(gm.ROLE_BRAEUMEISTER)
		_check("Kapitel 3: kein Bräumeister", not gm._has_staff(gm.ROLE_BRAEUMEISTER))
		story.kapitel_setzen(4)
		gm.net_hire_staff(gm.ROLE_BRAEUMEISTER)
		_check("Kapitel 4: Bräumeister eingestellt", gm._has_staff(gm.ROLE_BRAEUMEISTER))
		gm._zutat = {"malz": 1, "hopfen": 1, "hefe": 1}
		gm._eigenbier = 0
		var s: Dictionary
		for i in 400:
			for sid in gm._staff_sim.keys():
				if int(gm._staff_sim[sid].role) == gm.ROLE_BRAEUMEISTER:
					gm._update_braeumeister(gm._staff_sim[sid], 2.0)
			# Gärung überspringen
			for f in gm._gaerfaesser.size():
				if int(gm._gaerfaesser[f].zustand) == 1:
					gm._gaerfaesser[f].rest = 0.0
			gm._gaerung_zaehlen(0.1)
		_check("Gerhard hat gebraut und abgefüllt", gm._eigenbier == gm.ANSATZ_MENGE, str(gm._eigenbier))
		_check("Zutaten verbraucht", int(gm._zutat.malz) == 0 and int(gm._zutat.hopfen) == 0 and int(gm._zutat.hefe) == 0, str(gm._zutat))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
