extends SceneTree
func _init() -> void:
	var n := (load("res://scenes/kirmes.tscn") as PackedScene).instantiate()
	# Baum aufbauen, damit global_position stimmt
	var root := Node3D.new()
	get_root().add_child(root)
	root.add_child(n)
	var hub := n.get_node("FerrisWheel/Model/FerrisWheel_Rotate") as Node3D
	print("Nabe:   %s" % hub.global_position)
	for c in hub.get_children():
		if "Cabin" in String(c.name):
			var g := (c as Node3D).global_position
			print("Gondel: %s  Abstand zur Nabe = %.2f" % [g, g.distance_to(hub.global_position)])
			break
	var l := hub.get_node("Lichter") as Node3D
	for i in [0, 14, 60]:
		var b := l.get_child(i) as Node3D
		print("%-10s %s  Abstand zur Nabe = %.2f" % [b.name, b.global_position,
			b.global_position.distance_to(hub.global_position)])
	quit()
