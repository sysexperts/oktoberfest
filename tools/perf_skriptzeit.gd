extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Echte Skriptzeit je Frame (Marken der Leistungsanzeige) je Grafikstufe, Tag 1 und mit Besuchern.
##   godot --path . res://tools/perf_skriptzeit.tscn
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(3.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var anzeige := get_node("/root/Leistungsanzeige")
		anzeige.visible = true
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 25)
		for tag in [1, 5]:
			gm._day = tag
			gm._apply_crowd(12.0)
			for stufe in [2, 0]:
				Einstellungen.grafik = stufe
				Einstellungen.geaendert.emit()
				await _warten(8.0)
				print("SKRIPT tag %d stufe %d: %.1f ms echte Skriptzeit, Besucher %d" % [tag, stufe, anzeige._skript_ms, gm._crowd._visitors.size()])
		get_tree().quit()
