extends SceneTree
## Hintergrund der Figurenkarten (Figurenwahl, Lobby): warmes Braun mit feinem Punktraster,
## Lichtschein hinter dem Kopf, dunklerer Streifen für den Namen.
##   godot --headless --path . --script res://tools/bake_figurkarte.gd
const B := 260
const H := 316
const R := 28.0

func _init() -> void:
	_karte("res://assets/ui/karte_ruhe.png", 1.0, 0.0, Color(1, 0.92, 0.75, 0.22))
	_karte("res://assets/ui/karte_hover.png", 1.35, 0.0, Color(1, 0.92, 0.75, 0.6))
	_karte("res://assets/ui/karte_gewaehlt.png", 1.5, 1.0, Color(1, 0.84, 0.35, 1.0))
	quit()

func _karte(pfad: String, hell: float, dick: float, rand: Color) -> void:
	var bild := Image.create(B, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in B:
			var a := _rundung(x, y)
			if a <= 0.0:
				continue
			var t := float(y) / H
			var c := Color(0.24, 0.16, 0.1).lerp(Color(0.1, 0.07, 0.05), t)
			# feines Punktraster wie geprägtes Leder
			var rx := fposmod(float(x), 14.0) - 7.0
			var ry := fposmod(float(y), 14.0) - 7.0
			c = c.lerp(Color(1.0, 0.84, 0.5), clampf(1.6 - Vector2(rx, ry).length() * 0.5, 0.0, 1.0) * 0.1)
			# warmer Lichtschein hinter dem Kopf
			var d := Vector2(x - B * 0.5, y - H * 0.36).length() / (B * 0.58)
			c = c.lerp(Color(0.95, 0.62, 0.25), clampf(1.0 - d, 0.0, 1.0) * 0.55)
			# Namensstreifen
			if y > H - 62:
				c = c.lerp(Color(0.04, 0.025, 0.015), 0.6)
			c = Color(minf(c.r * hell, 1.0), minf(c.g * hell, 1.0), minf(c.b * hell, 1.0), a)
			# Rand
			var innen := _innenabstand(x, y)
			var breite := 2.0 + dick * 3.0
			if innen < breite:
				c = c.lerp(Color(rand.r, rand.g, rand.b, 1.0), rand.a * clampf(breite - innen, 0.0, 1.0))
			bild.set_pixel(x, y, c)
	bild.save_png(ProjectSettings.globalize_path(pfad))

## Deckkraft in einem Rechteck mit runden Ecken (weiche Kante)
func _rundung(x: int, y: int) -> float:
	return clampf(_innenabstand(x, y) + 0.5, 0.0, 1.0)

## Abstand zum Rand nach innen (negativ außerhalb)
func _innenabstand(x: int, y: int) -> float:
	var p := Vector2(x + 0.5, y + 0.5) - Vector2(B, H) * 0.5
	var q := p.abs() - (Vector2(B, H) * 0.5 - Vector2(R, R))
	var aussen := Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()
	return -(aussen + minf(maxf(q.x, q.y), 0.0) - R)
