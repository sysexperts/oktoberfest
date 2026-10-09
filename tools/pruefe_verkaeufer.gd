extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Welche Kleidungsstücke haben die Verkäufer-Figuren der Buden (Gruppe nachtruhe)?
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await get_tree().create_timer(3.0).timeout
		var ohne := 0
		var gesamt := 0
		for f in get_tree().get_nodes_in_group("nachtruhe"):
			var namen := []
			for m in (f as Node).find_children("*", "MeshInstance3D", true, false):
				var n := String(m.name)
				if n.begins_with("hemd") or n.begins_with("jacke") or n.begins_with("hose") or n.begins_with("kleid") or n.begins_with("dirndl") or n.begins_with("schuerze") or n.begins_with("bluse") or n.begins_with("rock"):
					if (m as MeshInstance3D).visible:
						namen.append(n)
			gesamt += 1
			if gesamt <= 3:
				var alle := []
				for m2 in (f as Node).find_children("*", "MeshInstance3D", true, false):
					alle.append("%s:%s" % [m2.name, m2.visible])
				print("VKALLE ", (f as Node).get_path(), " sichtbar ", (f as Node3D).visible, " im Baum ", (f as Node3D).is_visible_in_tree(), " ", alle)
			if namen.is_empty():
				ohne += 1
			if gesamt <= 12 or namen.is_empty() and ohne <= 12:
				print("VK %-40s %s" % [(f as Node).get_path().get_concatenated_names().right(30), str(namen)])
		print("VK gesamt %d, ohne sichtbare Kleidung %d" % [gesamt, ohne])
		get_tree().quit()
