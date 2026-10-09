extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Quest 3.1 „Gewinn Konrads Wette“: gilt automatisch, nicht ablehnbar, jeden Morgen neu, Horst-Mail bei
## Niederlage, Sieg schließt die Quest.
##   godot --headless --path . res://tools/test_wette.tscn

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
		story.kapitel_setzen(3)
		story.quests["2.6"] = {"z": "erfuellt"}
		gm._broadcast_meta()
		await _warten(0.3)
		_check("3.1 ist offen", story.zustand("3.1") == "offen", story.zustand("3.1"))
		# Tag 4: kein dritter Tag, trotzdem gibt es die Quest-Wette
		gm._day = 4
		gm._huber_morgen()
		_check("Quest-Wette am Morgen da", not gm._huber_wette.is_empty() and bool(gm._huber_wette.get("quest", false)), str(gm._huber_wette))
		_check("Quest-Wette ist machbar (Gäste bedienen)", str(gm._huber_wette.get("typ", "")) == "mass", str(gm._huber_wette))
		gm.net_huber_wette(false)
		_check("Ablehnen löscht die Quest-Wette nicht", not gm._huber_wette.is_empty(), "")
		gm.net_huber_wette(true)
		_check("Angenommen", bool(gm._huber_wette.get("angenommen", false)), "")
		# Verloren: nichts bedient
		gm._served = 0
		gm._huber_abrechnen()
		var ids: Array = story.post.map(func(m: Dictionary) -> String: return m.id)
		_check("Horst-Mail nach der Niederlage", ids.has("M3-03"), str(ids))
		_check("Quest bleibt offen", story.zustand("3.1") == "offen", story.zustand("3.1"))
		# Nächster Morgen: wieder eine Wette
		gm._day = 5
		gm._huber_morgen()
		_check("Nächster Morgen: neue Quest-Wette", not gm._huber_wette.is_empty() and bool(gm._huber_wette.get("quest", false)), "")
		gm.net_huber_wette(true)
		gm._served = int(gm._huber_wette.get("ziel", 0)) + 5
		gm._huber_abrechnen()
		gm._broadcast_meta()
		_check("Gewonnen: 3.1 erfüllt, 3.2 offen", story.zustand("3.1") == "erfuellt" and story.zustand("3.2") == "offen", "%s %s" % [story.zustand("3.1"), story.zustand("3.2")])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
