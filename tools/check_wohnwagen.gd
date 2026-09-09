extends SceneTree
func _init() -> void:
	var n := (load("res://scenes/kirmes.tscn") as PackedScene).instantiate()
	var mine := 0; var deko := 0
	for c in n.find_children("*", "Node3D", true, false):
		if c is Caravan:
			if (c as Caravan).is_mine: mine += 1; print("  eigener: %s bei %s" % [c.name, (c as Node3D).position])
			else: deko += 1
	print("Wohnwagen gesamt: %d  davon eigener: %d" % [mine + deko, mine])
	n.free()
	quit()
