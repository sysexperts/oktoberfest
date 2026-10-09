extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Mittelfinger im echten Spiel, Nahaufnahmen der Hand → SHOT_DIR/mf_nah_<n>.png
## SHOT_DIR=build/emotes godot --path . res://tools/shot_mittelfinger_nah.tscn --resolution 1280x720
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
		sp._emote_starten(7)
		await _warten(1.2)
		var sk: Skeleton3D = sp._model.skelett
		var b := sk.find_bone("RightHand")
		var cam: Camera3D = sp._cam
		# Vor, hinter und neben der Figur, jeweils nah an der Hand (Kamera jedes Bild neu setzen)
		var ansichten := [["vorn", Vector3(-0.2, 0.15, -0.9)], ["hinten", Vector3(0.1, 0.2, 0.9)], ["seite", Vector3(-0.9, 0.1, 0)]]
		for a in ansichten:
			var n := 0
			while n < 12:
				var hand := sk.global_transform * sk.get_bone_global_pose(b).origin
				cam.global_position = hand + (a[1] as Vector3)
				cam.look_at(hand + Vector3(0, 0.05, 0))
				await get_tree().process_frame
				n += 1
			get_viewport().get_texture().get_image().save_png(dir + "/mf_nah_%s.png" % a[0])
		get_tree().quit()
