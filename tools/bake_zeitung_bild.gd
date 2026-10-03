extends SceneTree
## Zeitungsfoto für den Festkurier: Maßkrug als Rasterdruck (Halbtonpunkte in Tintenbraun,
## Strahlenkranz dahinter) mit Rahmen. Hintergrund transparent, das Papier scheint durch.
##   godot --headless --path . --script res://tools/bake_zeitung_bild.gd
## Ergebnis: assets/ui/zeitung_bild.png (420 x 340)

const B := 420
const H := 340
const RASTER := 6.0
const TINTE := Color(0.2, 0.12, 0.06)

func _init() -> void:
	var bild := Image.create(B, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in B:
			bild.set_pixel(x, y, _pixel(float(x), float(y)))
	bild.save_png(ProjectSettings.globalize_path("res://assets/ui/zeitung_bild.png"))
	print("Zeitungsbild gebacken.")
	quit()

## Helligkeit der Vorlage: 0 = Papier, 1 = volle Tinte
func _vorlage(x: float, y: float) -> float:
	var v := 0.0
	# Strahlenkranz um die Mitte
	var mitte := Vector2(210.0, 175.0)
	var w := atan2(y - mitte.y, x - mitte.x)
	v = 0.16 if int(floor((w + PI) / TAU * 28.0)) % 2 == 0 else 0.04
	var r := Vector2(x, y).distance_to(mitte)
	v *= clampf(1.2 - r / 260.0, 0.0, 1.0)
	# Schatten unter dem Krug
	var sx := (x - 200.0) / 95.0
	var sy := (y - 288.0) / 14.0
	if sx * sx + sy * sy < 1.0:
		v = 0.75
	# Henkel (Ring rechts)
	var hr := Vector2(x, y).distance_to(Vector2(268.0, 192.0))
	if hr > 30.0 and hr < 52.0 and x > 250.0:
		v = 0.6 + 0.3 * absf(hr - 41.0) / 11.0
	# Körper: Glas mit Bier, leicht nach unten schmaler
	var links := 128.0 + (y - 100.0) * 0.05
	var rechts := 272.0 - (y - 100.0) * 0.05
	if x > links and x < rechts and y > 104.0 and y < 288.0:
		var t := (x - links) / (rechts - links)
		var rund := 1.0 - pow(absf(t - 0.42) * 2.0, 2.0)   # Zylinder, Licht von links
		if y > 142.0:
			v = 0.4 + 0.5 * (1.0 - rund)           # Bier
			# aufsteigende Bläschen
			var bl := Vector2(fmod(x * 1.7 + y * 0.6, 23.0) - 11.0, fmod(y * 1.3, 29.0) - 14.0)
			if bl.length() < 3.0:
				v = 0.08
		else:
			v = 0.06 + 0.12 * (1.0 - rund)         # Schaum
		# Glanz
		if t > 0.16 and t < 0.24 and y > 160.0 and y < 266.0:
			v = 0.04
		# Rand unten: Glasboden
		if y > 270.0:
			v = 0.85
	# Schaumkrone: Wolken über dem Rand
	for k in [Vector3(150, 106, 30), Vector3(190, 98, 34), Vector3(232, 100, 32), Vector3(262, 112, 24), Vector3(136, 118, 20)]:
		var d := Vector2(x, y).distance_to(Vector2(k.x, k.y))
		if d < k.z:
			v = 0.05 + 0.18 * (d / k.z)
	return v

func _pixel(x: float, y: float) -> Color:
	# Rahmen
	var innen := minf(minf(x, B - 1.0 - x), minf(y, H - 1.0 - y))
	if innen < 3.0 or (innen > 8.0 and innen < 9.5):
		return Color(TINTE.r, TINTE.g, TINTE.b, 0.95)
	if innen < 10.0:
		return Color(0, 0, 0, 0)
	var v := _vorlage(x, y)
	# Raster um 45° gedreht
	var u := (x + y) * 0.7071
	var w := (x - y) * 0.7071
	var fu := fposmod(u, RASTER) - RASTER * 0.5
	var fw := fposmod(w, RASTER) - RASTER * 0.5
	var radius := sqrt(clampf(v, 0.0, 1.0)) * RASTER * 0.72
	var d := Vector2(fu, fw).length()
	var a := clampf(radius - d + 0.5, 0.0, 1.0)
	return Color(TINTE.r, TINTE.g, TINTE.b, a * 0.92)
