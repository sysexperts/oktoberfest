extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Müllsack werfen: landet er in der Tonne, zählt er; sonst liegt er am Boden.
##   godot --headless --path . res://tools/test_muellwurf.tscn

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
		var tonne := get_tree().get_first_node_in_group("muellplatz") as Node3D
		_check("Mülltonne gefunden", tonne != null)
		gm._muell_erzeugt = 3
		gm._muell_entsorgt = 0
		var sp: Node3D = gm._players_nodes.get(1)
		var boden: float = gm.ebene_boden(gm.ebene_von(tonne.global_position))
		# Flugbahn so wählen, dass der Sack in der Tonne landet: 2 m davor, waagerecht aus 1,5 m Höhe geworfen
		var start := tonne.global_position + Vector3(0, 0, 2.0) - Vector3(0, 0, 0)
		start.y = boden + 1.5
		sp.global_position = Vector3(start.x, boden, start.z)
		var t_flug: float = sqrt(2.0 * (1.5 - 0.15) / 9.8)
		var tempo := Vector3(0, 0, -2.0 / t_flug)
		gm.net_muellsack_werfen(start, tempo)
		await get_tree().create_timer(t_flug + 0.3).timeout
		_check("Sack in der Tonne: entsorgt", gm._muell_entsorgt == 1, str(gm._muell_entsorgt))
		# daneben: liegt als Sack am Boden
		var pakete_vorher: int = get_tree().get_nodes_in_group("package").size() if get_tree().has_group("package") else -1
		gm.net_muellsack_werfen(start + Vector3(8, 0, 0), Vector3(0, 0, 3.0))
		sp.global_position = Vector3(start.x + 8, boden, start.z)
		gm.net_muellsack_werfen(start + Vector3(8, 0, 0), Vector3(0, 0, 3.0))
		await get_tree().create_timer(1.0).timeout
		_check("Daneben: nicht entsorgt", gm._muell_entsorgt == 1, str(gm._muell_entsorgt))
		print("ERGEBNIS: ", "OK" if fehler == 0 else "FEHLGESCHLAGEN (%d)" % fehler)
		get_tree().quit(fehler)
