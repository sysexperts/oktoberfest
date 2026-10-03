extends Control
## Füllt freie Spaltenhöhe in der Zeitung mit „Blindtext": graue Balken wie gesetzte
## Zeilen, mit Absätzen und kürzeren Schlusszeilen. Nur Optik, damit das Blatt voll
## wie eine echte Zeitung wirkt. Reihenfolge ist je Spalte (seed) fest.

@export var seed_wert := 1
@export var farbe := Color(0.3, 0.2, 0.1, 0.38)
const ZEILE := 4.0
const ABSTAND := 7.0

func _ready() -> void:
	resized.connect(queue_redraw)

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_wert
	var y := 2.0
	var absatz_in := rng.randi_range(3, 5)
	while y + ZEILE < size.y:
		var ende := absatz_in <= 0
		var breite := size.x * (rng.randf_range(0.35, 0.7) if ende else 1.0)
		draw_rect(Rect2(0.0, y, breite, ZEILE), farbe)
		y += ZEILE + ABSTAND
		absatz_in -= 1
		if ende:
			y += ABSTAND
			absatz_in = rng.randi_range(3, 6)
