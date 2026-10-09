extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Budenbesitzer aus der Nähe: Teile, Sichtbarkeit, Sichtweiten → SHOT_DIR/bb_vorn.png, bb_hinten.png
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
		await _warten(5.0)
		var sp: Node3D = gm._players_nodes.get(1)
		var nah: Node3D = null
		var d0 := 1e9
		for b in get_tree().get_nodes_in_group("nachtruhe"):
			if b is Node3D and b.name == "Figur":
				var d := (b as Node3D).global_position.distance_to(Vector3(0, 0, 25))
				if d < d0:
					d0 = d
					nah = b
		if nah == null:
			print("BB keiner gefunden")
			get_tree().quit()
			return
		print("BB nächster: ", nah.get_path(), " Abstand ", d0)
		var figur: Node = nah
		print("BB Figur: ", figur.name, " ", figur.get_class(), " sichtbar ", figur.is_visible_in_tree())
		for m in figur.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			print("BB  %-28s sichtbar %s  Sicht-Ende %.0f  Material %s" % [mi.name, mi.is_visible_in_tree(), mi.visibility_range_end, mi.get_active_material(0)])
		var dir := OS.get_environment("SHOT_DIR")
		var zentrum: Vector3 = (figur as Node3D).global_position + Vector3(0, 1.0, 0)
		for seite in [["vorn", 1.0], ["hinten", -1.0]]:
			var z := (figur as Node3D).global_transform.basis.z * float(seite[1])
			z.y = 0.0
			sp.global_position = (figur as Node3D).global_position + z.normalized() * 3.0 + Vector3(0, 0.1, 0)
			sp.look_at(zentrum, Vector3.UP)
			await _warten(1.0)
			get_viewport().get_texture().get_image().save_png(dir + "/bb_%s.png" % seite[0])
		get_tree().quit()
