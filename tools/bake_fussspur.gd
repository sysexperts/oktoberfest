extends SceneTree
## Zeichnet die Fußspuren-Textur fürs Zelt: vier Schuhabdrücke im Wechsel links und
## rechts, matschbraun, mit weichem Rand. Raus kommt assets/dreck/fussspur.png.
## Aufruf: godot --headless --path . --script res://tools/bake_fussspur.gd
## Danach einmal importieren: godot --headless --path . --import

const GROESSE := 512
const AUSGABE := "res://assets/dreck/fussspur.png"
const FARBE := Color(0.1, 0.06, 0.03)

func _init() -> void:
	var bild := Image.create(GROESSE, GROESSE, false, Image.FORMAT_RGBA8)
	bild.fill(Color(FARBE, 0.0))
	# Spur von unten nach oben, leicht schräg; links und rechts abwechselnd
	var schritte := [
		[Vector2(215, 395), -0.10, true], [Vector2(295, 300), 0.04, false],
		[Vector2(222, 205), -0.06, true], [Vector2(292, 112), 0.08, false],
	]
	for s: Array in schritte:
		_abdruck(bild, s[0], s[1], s[2])
	bild.save_png(ProjectSettings.globalize_path(AUSGABE))
	print("gespeichert: ", AUSGABE)
	quit()

## Ein Schuhabdruck: Sohle (Ellipse) vorn, Absatz (kleinere Ellipse) hinten, leicht
## nach innen gedreht. Zeichnet mit weichem Rand und ungleichmäßiger Deckkraft.
func _abdruck(bild: Image, mitte: Vector2, winkel: float, links: bool) -> void:
	var dreh := winkel + (0.12 if links else -0.12)
	var rs := Vector2(30, 58)   # Sohle
	var rh := Vector2(22, 26)   # Absatz
	var os := Vector2(0, -26)
	var oh := Vector2(0, 56)
	for y in range(int(mitte.y) - 120, int(mitte.y) + 120):
		for x in range(int(mitte.x) - 80, int(mitte.x) + 80):
			if x < 0 or y < 0 or x >= GROESSE or y >= GROESSE:
				continue
			var p := (Vector2(x, y) - mitte).rotated(-dreh)
			var d := minf(_ellipse(p - os, rs), _ellipse(p - oh, rh))
			if d >= 1.0:
				continue
			var kante := 1.0 - smoothstep(0.7, 1.0, d)
			# Körnung: Matsch deckt nicht überall gleich
			var korn := 0.86 + 0.14 * sin(float(x) * 0.13 + 0.7) * sin(float(y) * 0.11 + 1.3)
			var a := clampf(kante * 0.95 * korn, 0.0, 1.0)
			var alt := bild.get_pixel(x, y)
			if a > alt.a:
				bild.set_pixel(x, y, Color(FARBE, a))

## < 1 innerhalb der Ellipse mit Halbachsen r
func _ellipse(p: Vector2, r: Vector2) -> float:
	return sqrt((p.x / r.x) * (p.x / r.x) + (p.y / r.y) * (p.y / r.y))
