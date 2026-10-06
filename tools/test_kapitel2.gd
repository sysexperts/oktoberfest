extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kapitel 2: Schulden abzahlen, Messwerte, Krankmeldung, Konrad-Mail, Hauptquest im HUD.
##   godot --headless --path . res://tools/test_kapitel2.tscn

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
		gm._broadcast_meta()
		var haupt: String = story.haupt_offen()
		_check("Hauptquest offen", haupt != "", haupt)
		var hud: Node = gm.get_node("HUD")
		hud._ziel_anzeigen()
		_check("HUD zeigt die Hauptquest", hud._aufgabe.visible and hud.get_node("%AufgabeTitel").text != "", hud.get_node("%AufgabeTitel").text)
		# Schulden
		Game.add_money(2000 - Game.money)
		var rest0: int = gm._schulden
		gm.net_schulden_zahlen(500)
		_check("500 € gezahlt", gm._schulden == rest0 - 500 and Game.money == 1500, "%d / %d" % [gm._schulden, Game.money])
		gm.net_schulden_zahlen(100000)
		_check("zu viel Geld verlangt: nichts passiert", gm._schulden == rest0 - 500, str(gm._schulden))
		var mw: Dictionary = gm._story_messwerte()
		_check("Messwert schulden_bezahlt", int(mw["schulden_bezahlt"]) == 500 and int(mw["schulden_rest"]) == rest0 - 500, str(mw["schulden_bezahlt"]))
		# Konrads Angebot und Krankmeldung
		gm._day = 4
		gm._krank_sid = -1
		gm._story_morgen()
		var ids: Array = story.post.map(func(m: Dictionary) -> String: return m.id)
		_check("Konrads Angebot (M2-06) kommt ab Tag 4", ids.has("M2-06"), str(ids))
		# Lohn-Folge
		gm.story_folge({"lohn_faktor_tag": 1.2})
		_check("Lohnfaktor gesetzt", is_equal_approx(gm._lohn_faktor_tag, 1.2), str(gm._lohn_faktor_tag))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
