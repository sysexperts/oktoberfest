extends SceneTree
## Zerlegt assets/ui/sloptoberfest_logo.png in zusammenhängende Teile (Alpha > 20)
## → assets/ui/logo/teil_<n>.png plus Position im Original (logo_teile.txt).
func _init() -> void:
	var img := Image.load_from_file("res://assets/ui/sloptoberfest_logo.png")
	var w := img.get_width()
	var h := img.get_height()
	var marke := PackedInt32Array()
	marke.resize(w * h)
	var teile := []
	for y in h:
		for x in w:
			var i := y * w + x
			if marke[i] != 0 or img.get_pixel(x, y).a < 0.08:
				continue
			var id := teile.size() + 1
			var box := Rect2i(x, y, 1, 1)
			var stapel := [i]
			marke[i] = id
			var n := 0
			while not stapel.is_empty():
				var j: int = stapel.pop_back()
				var px := j % w
				var py := j / w
				n += 1
				box = box.expand(Vector2i(px, py))
				for d in [[1,0],[-1,0],[0,1],[0,-1]]:
					var nx: int = px + d[0]
					var ny: int = py + d[1]
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var k := ny * w + nx
					if marke[k] == 0 and img.get_pixel(nx, ny).a >= 0.08:
						marke[k] = id
						stapel.append(k)
			teile.append({"id": id, "box": box, "n": n})
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/ui/logo"))
	var liste := ""
	var nr := 0
	for t in teile:
		if t.n < 2000:
			continue
		var b: Rect2i = t.box
		b.size += Vector2i.ONE
		var aus := Image.create(b.size.x, b.size.y, false, Image.FORMAT_RGBA8)
		for y in range(b.position.y, b.end.y):
			for x in range(b.position.x, b.end.x):
				if marke[y * w + x] == t.id:
					aus.set_pixel(x - b.position.x, y - b.position.y, img.get_pixel(x, y))
		aus.save_png("res://assets/ui/logo/teil_%d.png" % nr)
		liste += "teil_%d %d %d %d %d\n" % [nr, b.position.x, b.position.y, b.size.x, b.size.y]
		nr += 1
	print(liste)
	quit()
