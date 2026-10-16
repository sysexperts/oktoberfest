extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Kostet _geduld_max (je Gast jedes Bild) mit viel Deko? 60 Gäste x 3 Aufrufe, 150 Deko-Stücke, 200 Bilder.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		for i in 150:
			gm._einrichtung[1000 + i] = {"art": gm.Katalog.ARTEN.keys()[i % gm.Katalog.ARTEN.size()]}
		var g := {"typ": "", "rausch": 0.0}
		var t0 := Time.get_ticks_usec()
		for bild in 200:
			await get_tree().process_frame
			var t1 := Time.get_ticks_usec()
			for n in 180:
				gm._geduld_max(g)
			t0 += 0
			if bild == 199:
				print("PERF 180 Aufrufe von _geduld_max in einem Bild: %.2f ms" % ((Time.get_ticks_usec() - t1) / 1000.0))
		get_tree().quit()
