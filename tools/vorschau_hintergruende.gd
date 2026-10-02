extends SceneTree
## Vorschau: Figuren vor zwei Hintergrund-Ideen (Festzelt mit Lichterketten, Wiesn am Abend)
## -> build/vorschau_hintergruende.png
const B := 260
const H := 316

func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var ids := [1, 2, 3, 5, 10, 12]
	var blatt := Image.create((B + 12) * ids.size() + 12, (H + 12) * 2 + 12, false, Image.FORMAT_RGBA8)
	blatt.fill(Color(0.082, 0.064, 0.052))
	for r in 2:
		for k in ids.size():
			var bg := _zelt(rng) if r == 0 else _abend(rng)
			var a := Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/avatare/figur_%d.png" % ids[k]))
			a.convert(Image.FORMAT_RGBA8)
			a.resize(236, 236, Image.INTERPOLATE_LANCZOS)
			bg.blend_rect(a, Rect2i(0, 0, 236, 236), Vector2i(12, 20))
			_namensband(bg)
			_runden(bg)
			blatt.blend_rect(bg, Rect2i(0, 0, B, H), Vector2i(12 + k * (B + 12), 12 + r * (H + 12)))
	blatt.save_png(ProjectSettings.globalize_path("res://build/vorschau_hintergruende.png"))
	quit()

func _neu() -> Image:
	return Image.create(B, H, false, Image.FORMAT_RGBA8)

func _punkt(bild: Image, x: int, y: int, c: Color) -> void:
	if x < 0 or y < 0 or x >= B or y >= H:
		return
	var u := bild.get_pixel(x, y)
	bild.set_pixel(x, y, u.lerp(Color(c.r, c.g, c.b, 1.0), c.a))

func _kreis(bild: Image, mx: float, my: float, r: float, c: Color, weich := 0.5) -> void:
	for y in range(int(my - r - 1), int(my + r + 2)):
		for x in range(int(mx - r - 1), int(mx + r + 2)):
			var d := Vector2(x - mx, y - my).length() / r
			if d <= 1.0:
				var a := c.a * clampf((1.0 - d) / weich, 0.0, 1.0)
				_punkt(bild, x, y, Color(c.r, c.g, c.b, a))

func _linie(bild: Image, a: Vector2, b: Vector2, c: Color) -> void:
	var n := int(a.distance_to(b))
	for i in n + 1:
		var p := a.lerp(b, float(i) / maxi(n, 1))
		_punkt(bild, int(p.x), int(p.y), c)

## 1) Festzelt von innen: warmes Dunkel, Lichterketten als Lichtpunkte, Bänke unten
func _zelt(rng: RandomNumberGenerator) -> Image:
	var bild := _neu()
	for y in H:
		var t := float(y) / H
		var c := Color(0.32, 0.17, 0.08).lerp(Color(0.12, 0.07, 0.04), t)
		for x in B:
			bild.set_pixel(x, y, c)
	# Zeltbahnen: weiche helle und dunkle Streifen
	for x in B:
		var s := 0.5 + 0.5 * sin(float(x) / 26.0 * PI)
		for y in range(0, 190):
			_punkt(bild, x, y, Color(1.0, 0.8, 0.5, 0.05 * s))
	# Girlanden: zwei durchhängende Bögen mit Lichtpunkten
	for bogen in 3:
		var y0 := 28.0 + bogen * 34.0
		var tief := 22.0 - bogen * 4.0
		for i in 18:
			var u := float(i) / 17.0
			var x := u * B
			var y := y0 + sin(u * PI) * tief
			_kreis(bild, x, y, rng.randf_range(7.0, 12.0), Color(1.0, 0.82, 0.45, 0.55))
			_kreis(bild, x, y, 3.0, Color(1.0, 0.97, 0.8, 0.9), 0.9)
	# ferne Lichter, unscharf
	for i in 26:
		_kreis(bild, rng.randf_range(0, B), rng.randf_range(100, 200), rng.randf_range(5.0, 14.0), Color(1.0, 0.7, 0.3, 0.14))
	# Bänke und Tische als dunkle Balken
	for y in range(200, H):
		for x in B:
			_punkt(bild, x, y, Color(0.05, 0.03, 0.02, 0.55))
	for i in 4:
		_linie(bild, Vector2(0, 205 + i * 18), Vector2(B, 205 + i * 18), Color(0.45, 0.28, 0.14, 0.35))
	return bild

## 2) Wiesn am Abend: Himmelsverlauf, Sonne, Riesenrad und Zeltdächer als Silhouette
func _abend(rng: RandomNumberGenerator) -> Image:
	var bild := _neu()
	for y in H:
		var t := clampf(float(y) / 230.0, 0.0, 1.0)
		var c := Color(0.22, 0.14, 0.38).lerp(Color(0.86, 0.36, 0.3), t).lerp(Color(1.0, 0.7, 0.3), pow(t, 3.0))
		for x in B:
			bild.set_pixel(x, y, c)
	for i in 18:
		_kreis(bild, rng.randf_range(0, B), rng.randf_range(0, 80), 1.3, Color(1, 1, 0.9, 0.7), 1.0)
	_kreis(bild, 180, 215, 70, Color(1.0, 0.85, 0.5, 0.55), 1.0)
	_kreis(bild, 180, 215, 26, Color(1.0, 0.95, 0.75, 0.9), 0.5)
	# Riesenrad
	var m := Vector2(70, 150)
	var sil := Color(0.12, 0.06, 0.16, 0.9)
	for i in 24:
		var w := TAU * i / 24.0
		_linie(bild, m, m + Vector2(cos(w), sin(w)) * 60.0, Color(sil.r, sil.g, sil.b, 0.7))
		_kreis(bild, m.x + cos(w) * 60.0, m.y + sin(w) * 60.0, 3.5, Color(1.0, 0.8, 0.4, 0.9), 0.8)
	for i in 120:
		var w := TAU * i / 120.0
		_kreis(bild, m.x + cos(w) * 60.0, m.y + sin(w) * 60.0, 1.2, sil)
	_linie(bild, m, Vector2(40, 235), sil)
	_linie(bild, m, Vector2(100, 235), sil)
	# Zeltdächer
	for dach in [[-10, 60, 215], [80, 70, 205], [170, 100, 218]]:
		for y in range(dach[2] - 40, H):
			var br: float = float(dach[1]) * clampf(float(y - (dach[2] - 40)) / 40.0, 0.0, 1.0) / 2.0
			for x in range(int(dach[0] + dach[1] / 2.0 - br), int(dach[0] + dach[1] / 2.0 + br)):
				_punkt(bild, x, y, Color(0.1, 0.05, 0.14, 1.0))
	for y in range(240, H):
		for x in B:
			_punkt(bild, x, y, Color(0.07, 0.035, 0.1, 1.0))
	return bild

func _namensband(bild: Image) -> void:
	for y in range(H - 62, H):
		for x in B:
			_punkt(bild, x, y, Color(0.03, 0.02, 0.01, 0.7))

func _runden(bild: Image) -> void:
	for y in H:
		for x in B:
			var p := Vector2(x + 0.5, y + 0.5) - Vector2(B, H) * 0.5
			var q := p.abs() - (Vector2(B, H) * 0.5 - Vector2(28, 28))
			var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - 28.0
			var c := bild.get_pixel(x, y)
			c.a = clampf(0.5 - d, 0.0, 1.0)
			bild.set_pixel(x, y, c)
