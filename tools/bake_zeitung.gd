extends SceneTree
## Zeitungsblatt für den Festkurier (scenes/ui/zeitung.tscn): vergilbtes Papier mit
## Körnung, dunklen Rändern, Faltkniffen, unregelmäßiger Kante, Schlagschatten und
## einem blau-weißen Rautenband oben und unten.
##   godot --headless --path . --script res://tools/bake_zeitung.gd
## Ergebnis: assets/ui/zeitung_blatt.png (B x H, 2x der Anzeigegröße 840 x 640)

const B := 1760
const H := 1360
const RAND := 48.0       # so weit liegt die Papierkante vom Bildrand (Platz für den Schatten)
const BAND_Y := 100.0    # Oberkante des oberen Rautenbands
const BAND_H := 40.0
const RAUTE := 40.0

var _fein := FastNoiseLite.new()
var _grob := FastNoiseLite.new()
var _kante := FastNoiseLite.new()

func _init() -> void:
	_fein.seed = 3
	_fein.frequency = 0.9
	_grob.seed = 8
	_grob.frequency = 0.006
	_grob.fractal_octaves = 4
	_kante.seed = 21
	_kante.frequency = 0.03
	var bild := Image.create(B, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in B:
			bild.set_pixel(x, y, _pixel(float(x), float(y)))
	bild.save_png(ProjectSettings.globalize_path("res://assets/ui/zeitung_blatt.png"))
	print("Zeitungsblatt gebacken.")
	quit()

## Abstand zur Papierkante (negativ = auf dem Papier), Kante leicht wellig
func _abstand(x: float, y: float) -> float:
	var q := Vector2(absf(x - B * 0.5), absf(y - H * 0.5)) - (Vector2(B, H) * 0.5 - Vector2(RAND, RAND))
	var d := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)
	return d + _kante.get_noise_2d(x, y) * 7.0

func _pixel(x: float, y: float) -> Color:
	var d := _abstand(x, y)
	if d > 0.0:
		# Schatten: nach unten rechts versetzt, weich
		var ds := _abstand(x - 14.0, y - 20.0)
		var a := clampf(1.0 - ds / 34.0, 0.0, 1.0)
		return Color(0.02, 0.01, 0.0, a * a * 0.55)
	# Papier
	var korn := _fein.get_noise_2d(x, y) * 0.035
	var fleck := _grob.get_noise_2d(x, y)
	var c := Color(0.94, 0.89, 0.76).lerp(Color(0.86, 0.76, 0.56), clampf(fleck * 0.9 + 0.35, 0.0, 1.0) * 0.55)
	c = Color(c.r + korn, c.g + korn, c.b + korn * 1.2)
	# Ränder dunkler und gelber
	var t := clampf(-d / 110.0, 0.0, 1.0)
	c = c.lerp(c * Color(0.74, 0.64, 0.46), pow(1.0 - t, 2.2) * 0.9)
	# Faltkniffe: waagerecht und senkrecht durch die Mitte, mit hellem Saum
	var k := 0.0
	for pos in [Vector2(x - B * 0.5, 0.0), Vector2(y - H * 0.5, 0.0)]:
		var e := absf((pos as Vector2).x)
		k += exp(-pow(e / 2.5, 2.0)) * 0.16 - exp(-pow((e - 7.0) / 5.0, 2.0)) * 0.05
	c = Color(c.r - k, c.g - k, c.b - k)
	# Rautenband oben und unten (Tinte: leicht verwaschen, vom Papier durchschimmernd)
	var band := _raute(x, y, BAND_Y)
	if band < 0.0:
		band = _raute(x, y, H - BAND_Y - BAND_H)
	if band >= 0.0:
		var tinte := Color(0.14, 0.33, 0.66) if band > 0.5 else Color(0.97, 0.94, 0.86)
		var druck := 0.88 + _fein.get_noise_2d(x * 1.7, y * 1.7) * 0.15
		c = c.lerp(tinte * Color(druck, druck, druck, 1.0), 0.9 if band > 0.5 else 0.75)
	# Haarlinien um das Band
	for by in [BAND_Y, H - BAND_Y - BAND_H]:
		for yy in [by - 5.0, by + BAND_H + 5.0]:
			if absf(y - yy) < 1.2 and x > RAND + 40.0 and x < B - RAND - 40.0:
				c = c.lerp(Color(0.25, 0.16, 0.08), 0.8)
	c.a = clampf(1.0 - (d + 1.0), 0.0, 1.0)
	return c

## -1: nicht im Band; sonst 0 (Papierfarbe) oder 1 (blau), nach Rautenmuster
func _raute(x: float, y: float, oben: float) -> float:
	if y < oben or y > oben + BAND_H or x < RAND + 56.0 or x > B - RAND - 56.0:
		return -1.0
	var u := (x - RAND - 56.0) / RAUTE
	var v := (y - oben) / BAND_H
	# Rauten: |fraktionaler Teil - 0.5| + |v - 0.5| < 0.5
	var fx := u - floorf(u)
	var in_raute := absf(fx - 0.5) + absf(v - 0.5) * 1.0 < 0.5
	var gerade := int(floorf(u)) % 2 == 0
	if in_raute:
		return 1.0 if gerade else 0.0
	return 0.0 if gerade else 1.0
