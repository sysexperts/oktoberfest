extends Node
const Spielstart := preload("res://tools/spielstart.gd")
const Schuss := preload("res://tools/schuss.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await _warten(2.0)
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._tent_stage = 2
		Game.add_money(5000)
		gm._phase = gm.Phase.SHIFT
		for r in [2, 4, 1, 3]:
			pass
		gm._broadcast_meta()
		await _warten(3.0)
		(gm._players_nodes[1] as Node3D).global_position = Vector3(0, 0, 60)
		var kam := Camera3D.new()
		gm.add_child(kam)
		var c := (gm.get_node("Bueroraum/Computer") as Node3D).global_position
		var b := (gm.get_node("Bueroraum/Computer") as Node3D).global_transform.basis.z
		kam.look_at_from_position(c + b * 2.4 + Vector3(0.0, 1.9, 0.0), c + Vector3(0, 0.5, 0)); kam.fov = 60.0
		kam.make_current()
		await _warten(2.0)
		Schuss.speichern(get_viewport(), OS.get_environment("SHOT_DIR") + "/himmel.png")
		get_tree().quit()
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
