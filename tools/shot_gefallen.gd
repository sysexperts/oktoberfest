extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Bild vom Security-Posten und vom Täter: build/gefallen_*.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
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
		var g: Node = gm.get_node("Gefallen")
		await _warten(4.0)
		var sp: Node3D = gm._players_nodes.get(1)
		var story: Node = gm.get_node("Story")
		gm._quest_step = gm.QUEST_COUNT
		story.kapitel_setzen(2)
		story._freischalten(g.Daten.quest("G-1"))
		story.annehmen("G-1")
		await _warten(0.5)
		var ziele := [["posten", g._posten[0]], ["taeter", g._taeter]]
		for z in ziele:
			var n: Node3D = z[1]
			sp.global_position = n.global_position + Vector3(0, 0.1, 3.5)
			sp.rotation.y = 0.0
			await _warten(1.5)
			get_viewport().get_texture().get_image().save_png("res://build/gefallen_%s.png" % z[0])
		print("FERTIG")
		get_tree().quit()
