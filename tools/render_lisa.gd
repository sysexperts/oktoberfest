extends Node
## Lisa sitzend im echten Zelt fotografieren. VORSCHAU=pfad_%s.png
const Spielstart := preload("res://tools/spielstart.gd")
const Figuren := preload("res://scripts/figuren.gd")
const LISA := preload("res://scenes/figuren/charakter3.tscn")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm = await Spielstart.starten(self)
		if gm == null:
			return
		for i in 40: await get_tree().process_frame
		gm.set_process(false)
		gm.get_node("HUD").visible = false
		gm._tent_stage = 2; gm._active_count = 8; gm._apply_tent(); gm._rebuild_seats()
		# einige Gäste setzen, alle als Lisa
		var gezeigt: Array = []
		for k in 4:
			var vor: int = gm._guest_next
			gm._spawn_guest()
			var g: Dictionary = gm._guest_sim[vor]
			var ziel: Vector3 = gm._platz_pos_fuer(vor, int(g.seat))
			var kn: Node3D = gm._guests[vor]
			Figuren.einsetzen(kn, LISA)
			kn._figur = kn.get_node("Model")
			kn._model = kn._figur
			kn._anim = kn._figur.anim
			kn.set_net(ziel, float(gm._seats[int(g.seat)].yaw))
			kn.global_position = ziel
			kn._enter_sit()
			gezeigt.append(kn)
		for i in 60: await get_tree().process_frame
		var ziel_k: Node3D = gezeigt[0]
		var c := Camera3D.new(); gm.add_child(c); c.current = true
		for a in [["vorn", Vector3(0, 1.3, 2.2)], ["seite", Vector3(2.2, 1.2, 0.3)]]:
			c.global_position = ziel_k.global_position + a[1]
			c.look_at(ziel_k.global_position + Vector3(0, 0.7, 0))
			for i in 10: await get_tree().process_frame
			get_viewport().get_texture().get_image().save_png(OS.get_environment("VORSCHAU") % a[0])
		get_tree().quit()
