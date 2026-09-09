extends SceneTree
func _init() -> void:
	var n := (load("res://scenes/kirmes.tscn") as PackedScene).instantiate()
	var w := n.get_node_or_null("FerrisWheel")
	if w == null:
		print("FerrisWheel FEHLT in kirmes.tscn"); quit(); return
	print("FerrisWheel gefunden, Kinder: %s" % str(w.get_children().map(func(c): return c.name)))
	var l := w.get_node_or_null("Model/FerrisWheel_Rotate/Lichter")
	print("Lichter: %s" % ("da, %d Birnen" % l.get_child_count() if l else "FEHLT"))
	if l:
		var b := l.get_child(0) as MeshInstance3D
		print("  Birne0 lokal=%s sichtbar=%s mesh=%s mat=%s" % [b.position, b.visible,
			b.mesh != null, b.material_override != null])
		if b.material_override:
			var m := b.material_override as StandardMaterial3D
			print("  emission=%s an=%s energie=%.2f" % [m.emission, m.emission_enabled, m.emission_energy_multiplier])
	n.free()
	quit()
