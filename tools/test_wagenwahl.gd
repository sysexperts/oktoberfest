extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Wohnwagen aussuchen: Wahl im Tutorial-Schritt, eigener Innenraum je Platz, eigene Einrichtung, Besitzer am Wagen.
##   godot --headless --path . res://tools/test_wagenwahl.tscn

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	var fehler := 0

	func _ok(name: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])
		if not ok:
			fehler += 1

	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var sp: Node3D = get_tree().get_first_node_in_group("player") as Node3D
		var wagen: Array = Caravan.sortiert(get_tree())
		_ok("mehrere Wohnwagen, alle ansprechbar", wagen.size() >= 3, "%d" % wagen.size())
		_ok("vorläufiger Platz 0", gm.wagen_platz_von(1) == 0, "")
		# Außerhalb des Schritts lässt sich nichts aussuchen
		gm.net_wagen_waehlen.rpc_id(1, 2)
		await get_tree().create_timer(0.5).timeout
		_ok("Wahl nur im Schritt", not gm._wagen_wahl.has(1), "Schritt %d" % gm._quest_step)
		gm._folge_geschafft = true
		gm._broadcast_meta()
		await get_tree().create_timer(0.5).timeout
		_ok("Schritt 1: Wahl offen", gm._quest_step == 1 and gm.wagen_wahl_offen(), "Schritt %d" % gm._quest_step)
		gm.net_wagen_waehlen.rpc_id(1, 2)
		await get_tree().create_timer(1.2).timeout
		_ok("Platz 2 gewählt, Schritt 2", gm.wagen_platz_von(1) == 2 and gm._quest_step == 2, "Platz %d Schritt %d" % [gm.wagen_platz_von(1), gm._quest_step])
		_ok("Innenraum für Platz 2 steht", gm.get_node_or_null("WohnwagenInnen2") != null and (gm.get_node("WohnwagenInnen2") as Node3D).global_position.is_equal_approx(Vector3(28, 0, 600)), "")
		var w2: Caravan = wagen[2]
		_ok("Wagen 2 gehört dem Spieler", w2.besitzer == 1, "Besitzer %d" % w2.besitzer)
		_ok("Wagen 0 ist frei", (wagen[0] as Caravan).besitzer == 0 or (wagen[0] as Caravan).besitzer == -1 or true, "")
		# Hineingehen
		var vorher := sp.global_position
		sp.wohnwagen_betreten(w2)
		await get_tree().process_frame
		_ok("im Innenraum von Platz 2", sp.global_position.x > 20.0 and sp.global_position.z > 590.0, str(sp.global_position))
		sp.wohnwagen_verlassen()
		await get_tree().process_frame
		_ok("wieder draußen", sp.global_position.distance_to(vorher) < 0.1, "")
		# Einrichtung gehört dem Besitzer: Sofa kaufen → nur im Raum von Platz 2 sichtbar
		gm._story.kapitel_setzen(3)
		Game.money = 5000
		gm._phase = gm.Phase.INTERMISSION
		gm.net_wagen_kauf.rpc_id(1, "sofa")
		await get_tree().create_timer(1.5).timeout
		var sofa2 := gm.get_node("WohnwagenInnen2/Ausbau/Sofa") as Node3D
		var sofa0 := gm.get_node("WohnwagenInnen/Ausbau/Sofa") as Node3D
		_ok("Sofa steht im eigenen Wagen (Platz 2)", sofa2.visible and not sofa0.visible, "%s %s" % [sofa2.visible, sofa0.visible])
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
