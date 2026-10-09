extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Besucher und Budenbesitzer aus der Nähe (Klamotten prüfen) → SHOT_DIR/figur_besucher.png, figur_bude.png
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _warten(s: float) -> void:
		var t := 0.0
		while t < s:
			await get_tree().process_frame
			t += get_process_delta_time()
	func _blick(sp: Node3D, ziel: Node3D) -> void:
		# Kamera vorn vor der Figur (Besucher laufen in -z), Figur anhalten
		ziel.set_process(false)
		var vorn := -ziel.global_transform.basis.z
		vorn.y = 0.0
		vorn = vorn.normalized()
		sp.global_position = ziel.global_position + vorn * 2.6 + Vector3(0, 0.1, 0)
		sp.look_at(ziel.global_position + Vector3(0, 1.0, 0), Vector3.UP)
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		var kino = gm.get_node_or_null("Kino")
		if kino and kino.aktiv:
			kino.beenden()
		gm._day = 5
		gm._apply_crowd(14.0)
		await _warten(30.0)
		var sp: Node3D = gm._players_nodes.get(1)
		var dir := OS.get_environment("SHOT_DIR")
		var vs := get_tree().get_nodes_in_group("visitor")
		if not vs.is_empty():
			var v: Node3D = vs[0]
			_blick(sp, v)
			await _warten(0.8)
			get_viewport().get_texture().get_image().save_png(dir + "/figur_besucher.png")
		var bb := get_tree().get_nodes_in_group("nachtruhe")
		print("FIGUR Besucher ", vs.size(), " Budenfiguren ", bb.size())
		var ziel: Node3D = null
		for b in gm.find_children("*", "Node3D", true, false):
			if b.get_script() != null and b.get_script().resource_path.ends_with("budenbesitzer.gd"):
				ziel = b
				break
		if ziel:
			_blick(sp, ziel)
			await _warten(0.8)
			get_viewport().get_texture().get_image().save_png(dir + "/figur_bude.png")
		get_tree().quit()
