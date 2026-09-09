extends SceneTree
func _init() -> void:
	for p in ["res://scenes/kirmes.tscn", "res://scenes/main.tscn"]:
		var ps := load(p) as PackedScene
		if ps == null:
			print("FEHLER: %s nicht ladbar" % p); continue
		var n := ps.instantiate()
		print("OK %s -> %d Knoten" % [p, n.find_children("*", "", true, false).size()])
		n.free()
	for p in ["res://scenes/props/riesenrad.tscn","res://scenes/props/karussell.tscn",
			"res://scenes/props/topspin.tscn","res://scenes/props/schiffschaukel.tscn",
			"res://scenes/props/raketen.tscn","res://scenes/props/turm.tscn","res://scenes/props/wave.tscn"]:
		var ps := load(p) as PackedScene
		var n := ps.instantiate()
		var f := n as Fahrgeschaeft
		var t := n.get_node_or_null(f.teil)
		print("%-38s teil=%s" % [p.get_file(), "GEFUNDEN" if t else "!! FEHLT: " + String(f.teil)])
		n.free()
	quit()
