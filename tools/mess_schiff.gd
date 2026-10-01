extends Node
## Gibt Lage und Größe der Teile der Schiffschaukel aus — um die Schwingachse zu finden.
func _ready() -> void:
	var s := (load("res://scenes/props/schiffschaukel.tscn") as PackedScene).instantiate()
	s.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(s)
	await get_tree().process_frame
	_zeige(s, 0)
	print("TEIL ", s.teil, " Rest ", (s.get_node(s.teil) as Node3D).transform)
	get_tree().quit()

func _zeige(n: Node, tiefe: int) -> void:
	if n is Node3D and tiefe < 5:
		var t := n as Node3D
		var box := ""
		if n is MeshInstance3D:
			var a := (n as MeshInstance3D).get_aabb()
			var g := t.global_transform * a
			box = " Welt-AABB pos %s größe %s" % [g.position, g.size]
		print("  ".repeat(tiefe), n.name, " ", n.get_class(), " pos ", t.position, " rot° ", t.rotation_degrees, box)
	for c in n.get_children():
		_zeige(c, tiefe + 1)
