extends RefCounted
## Gibt den bestehenden Fenstern (Festbüro, Zeltcomputer) im Computer-Desktop den klassischen Look der neuen Apps:
## helle Flächen, graue Knöpfe, dunkle Schrift, blaue Überschriften. Läuft über den ganzen Teilbaum und markiert
## fertige Knoten (Meta "klassisch"), neu entstandene Zeilen werden beim nächsten Durchlauf nachgezogen.
## Übergangslösung: später bekommen die Apps eigene klassische Szenen. Kein class_name, per preload einbinden.

const TEXT := Color(0.1, 0.1, 0.12)
const BLAU := Color(0.11, 0.29, 0.66)
const SCHRIFT_FAKTOR := 1.2

static var _stile := {}

static func _flach(id: String, bg: Color, rand: Color, radius := 0, rand_breite := 1, rand_an := true, ml := 10.0, mo := 6.0) -> StyleBoxFlat:
	if _stile.has(id):
		return _stile[id]
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if rand_an:
		s.set_border_width_all(rand_breite)
		s.border_color = rand
	s.set_corner_radius_all(radius)
	s.content_margin_left = ml
	s.content_margin_right = ml
	s.content_margin_top = mo
	s.content_margin_bottom = mo
	_stile[id] = s
	return s

static func anwenden(wurzel: Node) -> void:
	_knoten(wurzel)
	for n in wurzel.find_children("*", "", true, false):
		_knoten(n)

static func _hell(c: Color) -> bool:
	return c.v > 0.55

static func _goldig(c: Color) -> bool:
	return c.r > 0.75 and c.b < 0.55 and c.r > c.b + 0.25

static func _knoten(n: Node) -> void:
	if n.has_meta("klassisch") or not n is Control:
		return
	n.set_meta("klassisch", true)
	var c := n as Control
	# Hintergründe
	if c is PanelContainer or c is Panel:
		var alt := c.get_theme_stylebox("panel") as StyleBoxFlat
		if c.has_theme_stylebox_override("panel"):
			var bg: Color = alt.bg_color if alt != null else Color(0.1, 0.1, 0.1, 1)
			if bg.a >= 0.9 and not _hell(bg):
				c.add_theme_stylebox_override("panel", _flach("rahmen", Color(0.925, 0.918, 0.894), Color(0, 0, 0, 0), 0, 0, false, 14.0, 12.0))
			else:
				c.add_theme_stylebox_override("panel", _flach("karte", Color(1, 1, 1), Color(0.55, 0.62, 0.76), 0, 1, true, 14.0, 10.0))
	elif c is HSeparator or c is VSeparator:
		c.add_theme_stylebox_override("separator", _flach("linie", Color(0.7, 0.72, 0.78), Color(0, 0, 0, 0), 0, 0, false, 0.0, 0.0))
	# Knöpfe
	if c is BaseButton and not (c is OptionButton):
		_knopf(c)
	# Schrift
	if c is Label or c is RichTextLabel or c is BaseButton:
		_schrift(c)

static func _knopf(c: Control) -> void:
	var ruhe := _flach("k_ruhe", Color(0.96, 0.955, 0.93), Color(0.38, 0.44, 0.6), 3, 1, true, 12.0, 6.0)
	var hover := _flach("k_hover", Color(1, 0.97, 0.84), Color(0.88, 0.62, 0.14), 3, 1, true, 12.0, 6.0)
	var druck := _flach("k_druck", Color(0.84, 0.83, 0.79), Color(0.3, 0.36, 0.52), 3, 1, true, 12.0, 6.0)
	var aus := _flach("k_aus", Color(0.9, 0.9, 0.88), Color(0.72, 0.74, 0.8), 3, 1, true, 12.0, 6.0)
	var hat := false
	for z: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		if c.has_theme_stylebox_override(z):
			hat = true
	if not hat:
		return
	# Auswahl-Knöpfe (Seitenleiste): gewählter Zustand deutlich blau
	c.add_theme_stylebox_override("normal", ruhe)
	c.add_theme_stylebox_override("hover", hover)
	c.add_theme_stylebox_override("pressed", druck)
	c.add_theme_stylebox_override("disabled", aus)
	c.add_theme_stylebox_override("focus", hover)

static func _schrift(c: Control) -> void:
	for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color", "default_color"]:
		if c.has_theme_color_override(k):
			var f := c.get_theme_color(k)
			if k == "font_disabled_color":
				c.add_theme_color_override(k, Color(0.55, 0.55, 0.58))
			elif _hell(f):
				c.add_theme_color_override(k, BLAU if _goldig(f) else TEXT)
	for k: String in ["font_size", "normal_font_size"]:
		if c.has_theme_font_size_override(k):
			c.add_theme_font_size_override(k, int(round(c.get_theme_font_size(k) * SCHRIFT_FAKTOR)))
