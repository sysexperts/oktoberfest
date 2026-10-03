extends SceneTree
## Kalenderblatt für den Festkalender (scenes/ui/kalender.tscn) im Look des Festkuriers
## (siehe bake_zeitung.gd): vergilbtes Papier mit Körnung und Knicken, oben und unten ein
## blau-weißes Rautenband, Schlagschatten.
##   godot --headless --path . --script res://tools/bake_kalender.gd
## Ergebnis: assets/ui/kalender_blatt.png (B x H, 2x der Anzeigegröße 1168 x 648)

const B := 2336
const H := 1296
const RAND := 48.0
const BAND_H := 44.0
const RAUTE := 44.0

var _fein := FastNoiseLite.new()
var _grob := FastNoiseLite.new()
var _kante := FastNoiseLite.new()

func _init() -> void:
	_fein.seed = 5
	_fein.frequency = 0.9
	_grob.seed = 12
	_grob.frequency = 0.005
	_grob.fractal_octaves = 4
	_kante.seed = 33
	_kante.frequency = 0.03
	var bild := Image.create(B, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in B:
			bild.set_pixel(x, y, _pixel(float(x), float(y)))
	bild.save_png(ProjectSettings.globalize_path("res://assets/ui/kalender_blatt.png"))
	print("Kalenderblatt gebacken.")
	quit()

func _abstand(x: float, y: float) -> float:
	var q := Vector2(absf(x - B * 0.5), absf(y - H * 0.5)) - (Vector2(B, H) * 0.5 - Vector2(RAND, RAND))
	var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)
	return d + _kante.get_noise_2d(x, y) * 4.0

func _pixel(x: float, y: float) -> Color:
	var d := _abstand(x, y)
	if d > 0.0:
		var ds := _abstand(x - 14.0, y - 22.0)
		var a := clampf(1.0 - ds / 36.0, 0.0, 1.0)
		return Color(0.02, 0.01, 0.0, a * a * 0.55)
	var korn := _fein.get_noise_2d(x, y) * 0.03
	var fleck := _grob.get_noise_2d(x, y)
	var c := Color(0.95, 0.91, 0.8).lerp(Color(0.88, 0.8, 0.62), clampf(fleck * 0.8 + 0.3, 0.0, 1.0) * 0.45)
	c = Color(c.r + korn, c.g + korn, c.b + korn * 1.2)
	var t := clampf(-d / 90.0, 0.0, 1.0)
	c = c.lerp(c * Color(0.78, 0.68, 0.5), pow(1.0 - t, 2.4) * 0.8)

	# Knick in der Mitte (senkrecht) wie bei einem gefalteten Plakat — dezent
	var k := exp(-pow((x - B * 0.5) / 2.5, 2.0)) * 0.08
	c = Color(c.r - k, c.g - k, c.b - k)
	# Rautenbänder oben und unten
	var band_oben := RAND + 52.0
	var band_unten := H - RAND - BAND_H - 52.0
	for band_y in [band_oben, band_unten]:
		var band := _raute(x, y, band_y)
		if band >= 0.0:
			var tinte := Color(0.14, 0.33, 0.66) if band > 0.5 else Color(0.97, 0.94, 0.86)
			var druck2 := 0.88 + _fein.get_noise_2d(x * 1.7, y * 1.7) * 0.15
			c = c.lerp(tinte * Color(druck2, druck2, druck2, 1.0), 0.9 if band > 0.5 else 0.75)
		for yy in [band_y - 5.0, band_y + BAND_H + 5.0]:
			if absf(y - yy) < 1.2 and x > RAND + 40.0 and x < B - RAND - 40.0:
				c = c.lerp(Color(0.25, 0.16, 0.08), 0.8)
	c.a = clampf(1.0 - (d + 1.0), 0.0, 1.0)
	return c

func _raute(x: float, y: float, oben: float) -> float:
	if y < oben or y > oben + BAND_H or x < RAND + 56.0 or x > B - RAND - 56.0:
		return -1.0
	var u := (x - RAND - 56.0) / RAUTE
	var v := (y - oben) / BAND_H
	var fx := u - floorf(u)
	var in_raute := absf(fx - 0.5) + absf(v - 0.5) < 0.5
	var gerade := int(floorf(u)) % 2 == 0
	if in_raute:
		return 1.0 if gerade else 0.0
	return 0.0 if gerade else 1.0
