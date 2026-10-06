extends Control
## Fünf gezeichnete Sterne für die Bewertung (Social-App). wert = 0 bis 5, ganze Sterne gefüllt, ein Rest wird anteilig gefüllt.

const VOLL := Color(1, 0.84, 0.35)
const LEER := Color(1, 1, 1, 0.22)

var wert := 0.0

func setze(neuer_wert: float) -> void:
	wert = clampf(neuer_wert, 0.0, 5.0)
	queue_redraw()

func _stern(mitte: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + TAU * float(i) / 10.0
		var rr := r if i % 2 == 0 else r * 0.45
		p.append(mitte + Vector2(cos(a), sin(a)) * rr)
	return p

func _draw() -> void:
	var h := size.y
	var r := h * 0.5
	var abstand := minf((size.x - h) / 4.0, h * 1.15)
	for i in 5:
		var mitte := Vector2(r + abstand * float(i), r)
		draw_colored_polygon(_stern(mitte, r), LEER)
		var anteil := clampf(wert - float(i), 0.0, 1.0)
		if anteil <= 0.0:
			continue
		if anteil >= 1.0:
			draw_colored_polygon(_stern(mitte, r), VOLL)
		else:
			# Teilstern: Sternpunkte links der Schnittlinie
			var schnitt := mitte.x - r + 2.0 * r * anteil
			var punkte := PackedVector2Array()
			var ganz := _stern(mitte, r)
			for j in ganz.size():
				var a := ganz[j]
				var b := ganz[(j + 1) % ganz.size()]
				if a.x <= schnitt:
					punkte.append(a)
				if (a.x <= schnitt) != (b.x <= schnitt):
					var t := (schnitt - a.x) / (b.x - a.x)
					punkte.append(a.lerp(b, t))
			if punkte.size() >= 3 and not Geometry2D.triangulate_polygon(punkte).is_empty():
				draw_colored_polygon(punkte, VOLL)
