extends Control
## Balkendiagramm der Bank-App: Ergebnis der letzten Tage, grün = Plus, rot = Minus. Wird in desktop_bank.gd gefüttert.

const PLUS := Color(0.25, 0.85, 0.6)
const MINUS := Color(1, 0.4, 0.38)
const LINIE := Color(1, 1, 1, 0.22)
const TEXT := Color(0.75, 0.79, 0.88)

var _tage: Array = []
var _werte: Array = []

func setze(tage: Array, werte: Array) -> void:
	_tage = tage
	_werte = werte
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	var unten := size.y - 28.0
	var null_y := unten * 0.5
	draw_line(Vector2(0, null_y), Vector2(size.x, null_y), LINIE, 2.0)
	if _werte.is_empty():
		return
	var hoechst := 1.0
	for w in _werte:
		hoechst = maxf(hoechst, absf(float(w)))
	var n := _werte.size()
	var platz := size.x / float(n)
	var breite := minf(platz * 0.62, 46.0)
	for i in n:
		var h := float(_werte[i]) / hoechst * (unten * 0.5 - 4.0)
		var x := platz * (float(i) + 0.5) - breite * 0.5
		draw_rect(Rect2(x, null_y - maxf(h, 0.0), breite, absf(h) + 2.0), PLUS if h >= 0.0 else MINUS)
		var tag := str(_tage[i])
		var tw := font.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		draw_string(font, Vector2(platz * (float(i) + 0.5) - tw * 0.5, size.y - 4.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, TEXT)
