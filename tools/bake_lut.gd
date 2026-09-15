extends SceneTree
## Farbtabelle für den Look „Stil“ (Look-Test C, tools/look_test.tscn):
## S-Kurve, kühle Schatten, warme Lichter, etwas mehr Sättigung.
## Ergebnis: assets/shader/farb_lut.png — 33 Schichten (Blau) untereinander, als 3D-Textur
## importiert (farb_lut.png.import) — Environment.adjustment_color_correction in main.tscn.
##   godot --headless --path . --script tools/bake_lut.gd
##   godot --headless --path . --import

const N := 33

func _init() -> void:
	var streifen := Image.create(N, N * N, false, Image.FORMAT_RGB8)
	for bi in N:
		var img := Image.create(N, N, false, Image.FORMAT_RGB8)
		for gi in N:
			for ri in N:
				var c := Vector3(ri, gi, bi) / float(N - 1)
				var l := c.dot(Vector3(0.2126, 0.7152, 0.0722))
				var s := Vector3(smoothstep(0.0, 1.0, c.x), smoothstep(0.0, 1.0, c.y), smoothstep(0.0, 1.0, c.z))
				c = c.lerp(s, 0.4)
				c *= Vector3(0.93, 0.99, 1.06).lerp(Vector3(1.06, 1.0, 0.9), smoothstep(0.15, 0.75, l))
				var l2 := c.dot(Vector3(0.2126, 0.7152, 0.0722))
				c = Vector3(l2, l2, l2).lerp(c, 1.12)
				img.set_pixel(ri, gi, Color(clampf(c.x, 0, 1), clampf(c.y, 0, 1), clampf(c.z, 0, 1)))
		streifen.blit_rect(img, Rect2i(0, 0, N, N), Vector2i(0, bi * N))
	streifen.save_png("res://assets/shader/farb_lut.png")
	print("LUT FERTIG")
	quit()
