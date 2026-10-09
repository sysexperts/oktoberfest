extends SceneTree
func _init() -> void:
	var F := load("res://scripts/figuren.gd")
	var L = F.Look
	for g in ["m", "w"]:
		for art in ["jacke", "hose", "brille", "hut", "schuhe"]:
			print("LISTE %s %s: %s" % [g, art, str(L.liste(art, g).map(func(e): return e["id"]))])
	quit()
