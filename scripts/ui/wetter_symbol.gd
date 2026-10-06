extends Control
## Wettersymbol der Wetter-App, gezeichnet: "sonne", "wolkig" oder "regen". Wird in desktop_wetter.gd und wetter_tag.gd gesetzt.

const SONNE := Color(1, 0.84, 0.3)
const WOLKE := Color(0.95, 0.97, 1.0)
const WOLKE_REGEN := Color(0.7, 0.76, 0.88)
const TROPFEN := Color(0.45, 0.75, 1.0)

var art := "sonne"

func setze(neue_art: String) -> void:
	art = neue_art
	queue_redraw()

func _draw() -> void:
	var s := minf(size.x, size.y)
	var m := size / 2.0
	match art:
		"sonne":
			_sonne(m, s * 0.5)
		"wolkig":
			_sonne(m + Vector2(s * 0.12, -s * 0.12), s * 0.38)
			_wolke(m + Vector2(-s * 0.04, s * 0.1), s * 0.8, WOLKE)
		"regen":
			_wolke(m + Vector2(0, -s * 0.08), s * 0.82, WOLKE_REGEN)
			for i in 3:
				var x := m.x - s * 0.2 + s * 0.2 * float(i)
				draw_line(Vector2(x + s * 0.05, m.y + s * 0.22), Vector2(x - s * 0.03, m.y + s * 0.42), TROPFEN, maxf(2.0, s * 0.05), true)

func _sonne(mitte: Vector2, r: float) -> void:
	draw_circle(mitte, r * 0.5, SONNE)
	for i in 8:
		var a := TAU * float(i) / 8.0
		draw_line(mitte + Vector2(cos(a), sin(a)) * r * 0.66, mitte + Vector2(cos(a), sin(a)) * r * 0.92, SONNE, maxf(2.0, r * 0.1), true)

func _wolke(mitte: Vector2, breite: float, farbe: Color) -> void:
	var h := breite * 0.4
	draw_circle(mitte + Vector2(-breite * 0.2, 0), h * 0.5, farbe)
	draw_circle(mitte + Vector2(breite * 0.02, -h * 0.2), h * 0.62, farbe)
	draw_circle(mitte + Vector2(breite * 0.24, h * 0.02), h * 0.46, farbe)
	draw_rect(Rect2(mitte + Vector2(-breite * 0.2, 0), Vector2(breite * 0.44, h * 0.5)), farbe)
