extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Q-Rad und alle Emotes der eigenen Figur → SHOT_DIR/emote_rad.png, emote_<n>.png
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
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		var dir := OS.get_environment("SHOT_DIR")
		var sp: Node3D = gm._players_nodes.get(1)
		sp.global_position = Vector3(0, 0.1, 18)
		sp.rotation.y = 0.0
		await _warten(2.0)
		sp._rad_oeffnen()
		await _warten(1.0)
		get_viewport().get_texture().get_image().save_png(dir + "/emote_rad.png")
		var rad = sp._emote_rad()
		if rad:
			rad.schliessen(true)
		await _warten(0.5)
		for e in [[1, "tanzen"], [4, "jubel"], [6, "sitzen"], [5, "posen"], [2, "kotzen"], [3, "winken"]]:
			sp._emote_starten(int(e[0]))
			await _warten(2.2)
			get_viewport().get_texture().get_image().save_png(dir + "/emote_%s.png" % e[1])
			sp.emote_wahl = 0
			sp._emote_until = 0.0
			await _warten(1.5)
		get_tree().quit()
