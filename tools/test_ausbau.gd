extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Late-Game-Ausbauten: kaufen, Wirkung (VIP, Biergarten, Bierhandel, Konrads Zelt aufgekauft).
##   godot --headless --path . res://tools/test_ausbau.tscn

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
		gm._tent_stage = 3
		gm._phase = gm.Phase.INTERMISSION
		Game.add_money(60000 - Game.money)
		gm.net_ausbau_kauf("biergarten")
		_check("Vor Kapitel 5 nichts", gm._ausbau.is_empty())
		story.kapitel_setzen(5)
		gm.net_ausbau_kauf("vip")
		_check("VIP-Lounge gekauft", gm._ausbau.has("vip") and Game.money == 60000 - 4000, str(Game.money))
		gm.net_ausbau_kauf("vip")
		_check("Nicht doppelt", Game.money == 60000 - 4000)
		var vip := 0
		for i in 2000:
			if gm._gast_typ_waehlen() == "vip":
				vip += 1
		_check("Mehr VIP-Gäste (ca. 14 % statt 5 %)", vip > 200, "%d von 2000" % vip)
		gm.net_ausbau_kauf("handel")
		gm._eigenbier = 20
		gm._stock[gm.WARE_BIER] = 50
		var geld: int = Game.money
		gm._ausbau_abend()
		_check("Bierhandel verkauft 12 Maß", gm._eigenbier == 8 and Game.money > geld, "%d -> %d" % [geld, Game.money])
		_check("Ohne Akademie: höchstens Stufe 5", gm.staff_max_level() == 5 and gm.kellner_kapazitaet(5) == 12)
		gm.net_ausbau_kauf("akademie")
		_check("Mit Akademie: Stufe 10, größeres Tablett", gm.staff_max_level() == 10 and gm.kellner_kapazitaet(8) == 15, "%d" % gm.kellner_kapazitaet(8))
		gm.net_ausbau_kauf("konrad")
		_check("Konrads Zelt gekauft", gm._ausbau.has("konrad"))
		gm._streich_art = "dieb"
		gm._huber_morgen()
		_check("Keine Streiche mehr", gm._streich_art == "" and gm._sabotage_t < 0.0)
		geld = Game.money
		gm._ausbau_abend()
		_check("Pacht von Konrads Zelt", Game.money >= geld + gm.AUSBAU_KONRAD_PACHT, "%d -> %d" % [geld, Game.money])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit()
