extends SceneTree
## Hintergrund der Figurenkarten (Figurenwahl, Lobby): Festzelt von innen mit Lichterketten,
## Lichtschein hinter dem Kopf, dunklerer Streifen für den Namen.
##   godot --headless --path . --script res://tools/bake_figurkarte.gd
const B := 260
const H := 316
const R := 28.0

func _init() -> void:
	_karte("res://assets/ui/karte_ruhe.png", 1.0, 0.0, Color(1, 0.92, 0.75, 0.22))
	_karte("res://assets/ui/karte_hover.png", 1.3, 0.0, Color(1, 0.92, 0.75, 0.6))
	_karte("res://assets/ui/karte_gewaehlt.png", 1.45, 1.0, Color(1, 0.84, 0.35, 1.0))
	quit()

func _karte(pfad: String, hell: float, dick: float, rand: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var bild := _zelt(rng)
	for y in H:
		for x in B:
			var a := _rundung(x, y)
			var c := bild.get_pixel(x, y)
			if y > H - 62:
				c = c.lerp(Color(0.03, 0.02, 0.01), 0.6)
			c = Color(minf(c.r * hell, 1.0), minf(c.g * hell, 1.0), minf(c.b * hell, 1.0), a)
			var innen := _innenabstand(x, y)
			var breite := 2.0 + dick * 3.0
			if innen < breite:
				c = c.lerp(Color(rand.r, rand.g, rand.b, 1.0), rand.a * clampf(breite - innen, 0.0, 1.0))
			bild.set_pixel(x, y, c)
	bild.save_png(ProjectSettings.globalize_path(pfad))

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
	var bild := Image.create(B, H, false, Image.FORMAT_RGBA8)
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


## Deckkraft in einem Rechteck mit runden Ecken (weiche Kante)
func _rundung(x: int, y: int) -> float:
	return clampf(_innenabstand(x, y) + 0.5, 0.0, 1.0)

## Abstand zum Rand nach innen (negativ außerhalb)
func _innenabstand(x: int, y: int) -> float:
	var p := Vector2(x + 0.5, y + 0.5) - Vector2(B, H) * 0.5
	var q := p.abs() - (Vector2(B, H) * 0.5 - Vector2(R, R))
	var aussen := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()
	return -(aussen + minf(maxf(q.x, q.y), 0.0) - R)
