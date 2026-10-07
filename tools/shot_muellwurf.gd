extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
## Fotografiert den Wohnwagen in neuer Farbe (SHOT_DIR/wohnwagen_plaetze.png).
##   SHOT_DIR=build godot --path . res://tools/shot_wagenfarbe.tscn --resolution 1280x720

func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		TranslationServer.set_locale("de")
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		TranslationServer.set_locale("de")
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var tonne := get_tree().get_first_node_in_group("muellplatz") as Node3D
		var sp: Node3D = gm._players_nodes.get(1)
		var boden: float = gm.ebene_boden(gm.ebene_von(tonne.global_position))
		gm._muell_erzeugt = 3
		var start := tonne.global_position + Vector3(0, 0, 4.5)
		start.y = boden + 1.5
		sp.global_position = Vector3(start.x, boden, start.z + 0.5)
		var kam := Camera3D.new()
		gm.add_child(kam)
		kam.look_at_from_position(tonne.global_position + Vector3(-3.0, 2.0, 5.5), tonne.global_position + Vector3(0, 1.4, 2.0))
		kam.make_current()
		await _warten(1.0)
		var t_flug := 0.75
		gm.net_muellsack_werfen(start, Vector3(0, 3.0, -4.0 / t_flug))
		await _warten(0.4)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/muellwurf.png")
		get_tree().quit()

	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
