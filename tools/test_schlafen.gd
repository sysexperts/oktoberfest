extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Schlafen ohne Abstimmung: Mehrheit der Spieler im Bett startet den Tag (Solo: sofort), nochmal E steht wieder auf.
##   godot --headless --path . res://tools/test_schlafen.tscn

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
		gm._quest_step = gm.QUEST_COUNT
		gm._tent_stage = 1
		gm._active_count = 2
		gm._phase = gm.Phase.INTERMISSION
		var tag: int = gm._day
		_ok("Mehrheitsregel", gm.schlafen_mehrheit(2, 3) and not gm.schlafen_mehrheit(2, 4) and gm.schlafen_mehrheit(1, 1), "")
		# Zwei Spieler vortäuschen: einer liegt, der andere nicht → kein Tag
		gm._players_nodes[2] = sp
		gm.net_sleep.rpc_id(1)
		await get_tree().create_timer(0.5).timeout
		_ok("1 von 2 im Bett: kein neuer Tag, Spieler liegt", gm._day == tag and sp.schlaeft and gm._schlaefer.size() == 1, "Tag %d" % gm._day)
		gm.net_sleep.rpc_id(1)
		await get_tree().create_timer(0.5).timeout
		_ok("Nochmal E: aufgestanden", not sp.schlaeft and gm._schlaefer.is_empty(), "")
		gm._players_nodes.erase(2)
		gm.net_sleep.rpc_id(1)
		await get_tree().create_timer(1.5).timeout
		_ok("Allein: Tag beginnt sofort, niemand liegt mehr", gm._day == tag + 1 and not sp.schlaeft and gm._schlaefer.is_empty(), "Tag %d" % gm._day)
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN")
		get_tree().quit(fehler)
