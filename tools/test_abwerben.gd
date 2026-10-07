extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Konrad wirbt Personal ab (ab Kapitel 3): Anliegen "huber", halten mit Lohn oder weg.
##   godot --headless --path . res://tools/test_abwerben.tscn

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
		gm.net_hire_staff(gm.ROLE_KELLNER)
		gm.net_hire_staff(gm.ROLE_REINIGUNG)
		var n0: int = gm._staff_sim.size()
		var abgeworben := false
		for i in 60:
			gm._personal_morgen()
			for s in gm._staff_sim.values():
				if str(s.get("anliegen", "")) == "huber":
					abgeworben = true
			if abgeworben:
				break
		_check("Konrad umwirbt jemanden", abgeworben)
		var sid := -1
		for k in gm._staff_sim.keys():
			if str(gm._staff_sim[k].get("anliegen", "")) == "huber":
				sid = k
		gm.net_personal_lohn(sid)
		_check("Mit Lohnerhöhung gehalten", gm._staff_sim.has(sid) and str(gm._staff_sim[sid].get("anliegen", "")) == "")
		gm._staff_sim[sid].anliegen = "huber"
		gm._personal_morgen()
		_check("Ohne Lohnerhöhung weg", not gm._staff_sim.has(sid), "%d -> %d" % [n0, gm._staff_sim.size()])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
