extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kapitel 4: Konrads Streiche Lieferwagen, Stromausfall, Diebe.
##   godot --headless --path . res://tools/test_streiche.tscn

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
		story.kapitel_setzen(4)
		gm._tent_stage = 2
		gm._lieferproblem = false
		gm._streich_art = "laster"
		gm._streich_ausloesen()
		_check("Laster: Lieferproblem", gm._lieferproblem)
		gm._streich_art = "strom"
		gm._streich_ausloesen()
		_check("Stromausfall läuft", gm._strom_t > 0.0)
		var lichter := get_tree().get_nodes_in_group("deckenlicht")
		_check("Deckenlichter aus", not lichter.is_empty() and not (lichter[0] as Light3D).visible, str(lichter.size()))
		gm._huber_schicht(gm.STROM_DAUER + 1.0)
		_check("Strom wieder da", gm._strom_t == 0.0 and (lichter[0] as Light3D).visible)
		gm._stock[gm.WARE_BIER] = 40
		gm._streich_art = "dieb"
		gm._streich_t = -1.0
		gm._dieb_nacht()
		_check("Diebe stehlen Bier ohne Security", int(gm._stock[gm.WARE_BIER]) == 40 - gm.DIEB_BIER, str(gm._stock[gm.WARE_BIER]))
		# Schutz: Schloss, Alarmanlage, Kamera, Versicherung
		gm._strom_t = 0.0
		gm._ausbau = ["schloss"]
		gm._stock[gm.WARE_BIER] = 40
		gm._streich_art = "dieb"
		gm._streich_t = -1.0
		gm._dieb_nacht()
		_check("Schloss: nichts gestohlen", int(gm._stock[gm.WARE_BIER]) == 40)
		gm._ausbau = ["alarm", "kamera"]
		gm._streich_art = "strom"
		gm._streich_ausloesen()
		_check("Alarmanlage: Stromausfall kürzer", gm._strom_t > 0.0 and gm._strom_t < gm.STROM_DAUER * 0.5, "%.0f" % gm._strom_t)
		gm._strom_t = 0.0
		gm._ausbau = ["versicherung"]
		gm._lieferproblem = false
		gm._streich_art = "laster"
		gm._streich_ausloesen()
		_check("Versicherung: kein Lieferaufschlag", not gm._lieferproblem)
		var geld_v: int = Game.money
		gm._streich_art = "dieb"
		gm._streich_t = -1.0
		gm._stock[gm.WARE_BIER] = 40
		gm._dieb_nacht()
		_check("Versicherung: gestohlenes Bier erstattet", Game.money > geld_v, "%d" % (Game.money - geld_v))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
