extends SceneTree
func _init() -> void:
	var ps := load("res://scenes/katalog_kirmes.tscn") as PackedScene
	if ps == null:
		print("FEHLER: Szene nicht ladbar")
		quit(1); return
	var n := ps.instantiate()
	print("OK: %d Kategorien, %d Knoten gesamt" % [n.get_child_count(), n.find_children("*", "", true, false).size()])
	n.free()
	quit()
