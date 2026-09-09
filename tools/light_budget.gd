extends SceneTree
## Yardımcı araç: haritadaki tüm omni ışıkların yer düzlemine düşen toplam
## katkısını ölçer. 1.0 civarı "iyi aydınlatılmış", 3+ aşırı pozlama demek.
## Kullanım: godot --headless --path . --script res://tools/light_budget.gd

func _init() -> void:
	var n := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	var lights: Array = []
	for l in n.find_children("*", "OmniLight3D", true, false):
		var o := l as OmniLight3D
		lights.append({"p": o.global_position if o.is_inside_tree() else _world(o, n),
			"e": o.light_energy, "r": o.omni_range, "a": o.omni_attenuation,
			"n": String(o.get_parent().name)})
	print("Omni-Lichter gesamt: %d" % lights.size())
	var worst := 0.0
	var wp := Vector3.ZERO
	var sum := 0.0
	var samples := 0
	for gx in range(-40, 41, 5):
		for gz in range(-40, 41, 5):
			var p := Vector3(gx, 1.0, gz)
			var v := 0.0
			for l in lights:
				var d: float = (l["p"] as Vector3).distance_to(p)
				var r: float = l["r"]
				if d >= r:
					continue
				v += float(l["e"]) * pow(1.0 - d / r, float(l["a"]))
			sum += v
			samples += 1
			if v > worst:
				worst = v
				wp = p
	print("Mittelwert am Boden: %.2f" % (sum / float(samples)))
	print("Hellster Punkt:      %.2f bei %s" % [worst, wp])
	var names := {}
	for l in lights:
		var d: float = (l["p"] as Vector3).distance_to(wp)
		if d < float(l["r"]):
			names[l["n"]] = names.get(l["n"], 0) + 1
	print("Beteiligt: %s" % str(names))
	n.free()
	quit()

func _world(o: Node3D, root: Node) -> Vector3:
	var t := o.transform
	var p := o.get_parent()
	while p != null and p != root:
		if p is Node3D:
			t = (p as Node3D).transform * t
		p = p.get_parent()
	return t.origin
