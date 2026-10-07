extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Fake-Bewertungen: entstehen abends, kosten Beliebtheit, Melden löscht sie.
##   godot --headless --path . res://tools/test_fakes.tscn

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
		gm._popularity = 50.0
		gm._fakes = [{"id": 1, "autor": "Uwe K.", "text": 2, "tag": 1}]
		gm._fake_next = 2
		gm._fakes_abend()
		_check("Ungemeldeter Fake kostet Beliebtheit", gm._popularity <= 50.0 - gm.FAKE_POP + 0.01, "%.1f" % gm._popularity)
		gm._broadcast_meta()
		_check("Fake im Zustand fürs UI", (gm.get_node("HUD")._zustand.get("fakes", []) as Array).size() >= 1)
		var pop: float = gm._popularity
		gm.net_fake_melden(1)
		_check("Melden löscht den Fake und gibt Beliebtheit", not gm._fakes.any(func(f: Dictionary) -> bool: return int(f.id) == 1) and gm._popularity > pop, "%.1f -> %.1f" % [pop, gm._popularity])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
