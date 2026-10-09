extends Node
const Spielstart := preload("res://tools/spielstart.gd")
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await get_tree().create_timer(2.0).timeout
		var c: Node3D = get_tree().get_first_node_in_group("casino")
		var z: Node3D = get_tree().get_first_node_in_group("huber_zelt")
		var box := AABB()
		var erst := true
		for m in c.find_children("*", "MeshInstance3D", true, false):
			var mi := m as MeshInstance3D
			var ab := mi.global_transform * mi.get_aabb()
			box = ab if erst else box.merge(ab)
			erst = false
		print("CASINO Mitte %s, Fläche x %.1f..%.1f  z %.1f..%.1f  (Zelt bei %s)" % [str(c.global_position), box.position.x, box.end.x, box.position.z, box.end.z, str(z.global_position)])
		get_tree().quit()
