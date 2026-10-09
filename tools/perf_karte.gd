extends Node
const Spielstart := preload("res://tools/spielstart.gd")
## Woraus besteht die Karte? Zählt Knoten und Meshes je Szenendatei der Platzierungen unter Kirmes/Karte.
func _ready() -> void:
	get_tree().root.add_child.call_deferred(Lauf.new())
class Lauf extends Node:
	func _ready() -> void:
		var gm := await Spielstart.starten(self)
		if gm == null:
			return
		await get_tree().create_timer(3.0).timeout
		var karte := gm.get_node("Kirmes/Karte")
		var je := {}
		for k in karte.get_children():
			var pfad: String = k.scene_file_path if k.scene_file_path != "" else k.name
			var m := k.find_children("*", "MeshInstance3D", true, false).size()
			var n := k.find_children("*", "", true, false).size() + 1
			if not je.has(pfad):
				je[pfad] = [0, 0, 0]
			je[pfad][0] += 1
			je[pfad][1] += n
			je[pfad][2] += m
		var liste := []
		for p in je.keys():
			liste.append([je[p][2], je[p][1], je[p][0], p])
		liste.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		print("KARTE direkte Kinder: ", karte.get_child_count())
		for e in liste.slice(0, 25):
			print("KARTE %6d Meshes %6d Knoten %4d Stück  %s" % [e[0], e[1], e[2], e[3]])
		get_tree().quit()
