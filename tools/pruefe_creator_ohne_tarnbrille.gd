extends SceneTree
func _init() -> void:
	var F := load("res://scripts/figuren.gd")
	var L = F.Look
	var m: Array = L.liste("brille", "m").map(func(e): return e["id"])
	var w: Array = L.liste("brille", "w").map(func(e): return e["id"])
	print("CREATOR Brillen m: %d, w: %d, enthält tarnbrille: %s / %s" % [m.size(), w.size(), str(m.has("tarnbrille")), str(w.has("tarnbrille"))])
	var l: Dictionary = L.pruefen({"geschlecht": "w", "brille": "tarnbrille"})
	print("CREATOR pruefen behält tarnbrille (für die Verkleidung): %s" % str(l["brille"] == "tarnbrille"))
	quit()
