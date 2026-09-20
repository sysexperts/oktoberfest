extends SceneTree
## Baut das Wiesn-Theme (Holz, halbtransparent, Gold als Akzent) und speichert es
## nach assets/ui/menue_theme.tres. Danach ist es eine ganz normale Theme-Ressource
## und im Editor bearbeitbar — der Generator ist nur da, damit die vielen
## StyleBoxen konsistent bleiben und nicht von Hand gepflegt werden müssen.
##
##   Godot.exe --headless --script tools/theme_bauen.gd
##
## Runde Ecken, dezente Ränder, Gold nur als Akzent. Die Flächen tragen die
## Gliederung, nicht dicke Rahmen — das wirkt ruhiger als Rahmen auf Rahmen.

const ZIEL := "res://assets/ui/menue_theme.tres"

const HOLZ := Color(0.185, 0.132, 0.092, 0.88)
const HOLZ_HOVER := Color(0.29, 0.203, 0.132, 0.94)
const TAFEL := Color(0.105, 0.081, 0.065, 0.96)
const FELD := Color(0.145, 0.112, 0.088, 0.75)
const TIEF := Color(0.07, 0.054, 0.043, 0.92)
const RAND := Color(0.58, 0.42, 0.24, 0.55)
const RAND_LEISE := Color(0.58, 0.42, 0.24, 0.28)
const GOLD := Color(1, 0.839, 0.349)
const GOLD_HELL := Color(1, 0.906, 0.604)
const TEXT := Color(0.96, 0.93, 0.89)
const TEXT_LEISE := Color(0.72, 0.67, 0.61)
const TEXT_AUS := Color(0.48, 0.44, 0.4)

func _init() -> void:
	var t := Theme.new()
	t.default_font_size = 18

	# ---------------------------------------------------------------- Knöpfe
	_knopf(t, "Button", 16, 30.0, 12.0)
	_knopf(t, "OptionButton", 12, 18.0, 10.0)
	_knopf(t, "MenuButton", 12, 18.0, 10.0)
	for typ in ["Button", "OptionButton", "MenuButton"]:
		t.set_color("font_color", typ, TEXT)
		t.set_color("font_hover_color", typ, Color(1, 0.98, 0.9))
		t.set_color("font_focus_color", typ, Color(1, 0.98, 0.9))
		t.set_color("font_pressed_color", typ, Color(0.14, 0.09, 0.03))
		t.set_color("font_disabled_color", typ, TEXT_AUS)
		t.set_color("font_shadow_color", typ, Color(0, 0, 0, 0.75))
		t.set_color("icon_normal_color", typ, Color(1, 1, 1))
		t.set_color("icon_pressed_color", typ, Color(1, 1, 1))
		t.set_constant("shadow_offset_x", typ, 1)
		t.set_constant("shadow_offset_y", typ, 2)
		t.set_constant("shadow_outline_size", typ, 2)
	t.set_font_size("font_size", "Button", 20)
	t.set_font_size("font_size", "OptionButton", 17)

	# Symbolknöpfe oben rechts im Hauptmenü — kleinere Fase, schmale Ränder
	t.set_type_variation("EckKnopf", "Button")
	_knopf(t, "EckKnopf", 18, 12.0, 12.0)

	# Kategorien links in den Einstellungen: flach statt Kasten, die aktive
	# bekommt einen goldenen Balken am linken Rand statt einer Füllung.
	t.set_type_variation("Kategorie", "Button")
	t.set_stylebox("normal", "Kategorie", _kasten(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 12, 20.0, 10.0))
	t.set_stylebox("hover", "Kategorie", _kasten(Color(0.185, 0.132, 0.092, 0.5), Color(0, 0, 0, 0), 0, 12, 20.0, 10.0))
	t.set_stylebox("focus", "Kategorie", _kasten(Color(0, 0, 0, 0), RAND, 1, 12, 20.0, 10.0))
	t.set_stylebox("pressed", "Kategorie", _balken(GOLD, Color(0.185, 0.132, 0.092, 0.72), 12))
	t.set_stylebox("disabled", "Kategorie", _kasten(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 12, 20.0, 10.0))
	t.set_color("font_color", "Kategorie", TEXT_LEISE)
	t.set_color("font_hover_color", "Kategorie", TEXT)
	t.set_color("font_pressed_color", "Kategorie", GOLD)
	t.set_color("font_focus_color", "Kategorie", TEXT)
	t.set_font_size("font_size", "Kategorie", 21)

	# ---------------------------------------------------------------- Flächen
	t.set_stylebox("panel", "PanelContainer", _kasten(TAFEL, RAND_LEISE, 1, 24, 30.0, 26.0))
	t.set_stylebox("panel", "Panel", _kasten(TAFEL, RAND_LEISE, 1, 24, 30.0, 26.0))
	t.set_stylebox("panel", "PopupMenu", _kasten(TAFEL, RAND, 1, 14, 8.0, 8.0))
	t.set_stylebox("hover", "PopupMenu", _kasten(HOLZ_HOVER, Color(0, 0, 0, 0), 0, 10, 10.0, 6.0))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", Color(1, 0.98, 0.9))

	# ---------------------------------------------------------------- Reiter
	# Reiter als runde Pillen, der aktive gefüllt — das trägt die Gliederung,
	# darum kommt der Inhaltsbereich mit einem ganz leisen Rand aus.
	t.set_stylebox("panel", "TabContainer", _kasten(FELD, RAND_LEISE, 1, 18, 16.0, 16.0))
	t.set_stylebox("tab_selected", "TabContainer", _kasten(GOLD, Color(0, 0, 0, 0), 0, 20, 26.0, 11.0))
	t.set_stylebox("tab_hovered", "TabContainer", _kasten(HOLZ_HOVER, Color(0, 0, 0, 0), 0, 20, 26.0, 11.0))
	t.set_stylebox("tab_unselected", "TabContainer", _kasten(Color(0.145, 0.112, 0.088, 0.55), Color(0, 0, 0, 0), 0, 20, 26.0, 11.0))
	t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())
	t.set_color("font_selected_color", "TabContainer", Color(0.16, 0.11, 0.04))
	t.set_color("font_hovered_color", "TabContainer", Color(1, 0.98, 0.9))
	t.set_color("font_unselected_color", "TabContainer", TEXT_LEISE)
	t.set_font_size("font_size", "TabContainer", 18)
	t.set_constant("side_margin", "TabContainer", 0)

	# ---------------------------------------------------------------- Regler
	# Die senkrechten Ränder geben der Rinne ihre Dicke — ohne sie ist sie
	# hauchdünn und man sieht nur den Griff.
	t.set_stylebox("slider", "HSlider", _kasten(TIEF, RAND_LEISE, 1, 5, 0.0, 5.0))
	t.set_stylebox("grabber_area", "HSlider", _kasten(GOLD, Color(0, 0, 0, 0), 0, 5, 0.0, 5.0))
	t.set_stylebox("grabber_area_highlight", "HSlider", _kasten(GOLD_HELL, Color(0, 0, 0, 0), 0, 5, 0.0, 5.0))
	t.set_icon("grabber", "HSlider", load("res://assets/ui/regler_knopf.svg"))
	t.set_icon("grabber_highlight", "HSlider", load("res://assets/ui/regler_knopf.svg"))

	# ---------------------------------------------------------------- Schalter
	t.set_icon("checked", "CheckButton", load("res://assets/ui/schalter_an.svg"))
	# Holz-Varianten: schalter_aus.svg ist lila und passt nicht zum Rest. Das alte
	# theme.tres nutzt weiter die Originale, deshalb eigene Dateien statt Umfärben.
	t.set_icon("unchecked", "CheckButton", load("res://assets/ui/schalter_aus_holz.svg"))
	t.set_icon("checked_disabled", "CheckButton", load("res://assets/ui/schalter_gesperrt_holz.svg"))
	t.set_icon("unchecked_disabled", "CheckButton", load("res://assets/ui/schalter_gesperrt_holz.svg"))
	t.set_icon("checked", "CheckBox", load("res://assets/ui/haken_an.svg"))
	t.set_icon("unchecked", "CheckBox", load("res://assets/ui/haken_aus.svg"))
	for typ in ["CheckButton", "CheckBox"]:
		t.set_stylebox("normal", typ, StyleBoxEmpty.new())
		t.set_stylebox("hover", typ, StyleBoxEmpty.new())
		t.set_stylebox("pressed", typ, StyleBoxEmpty.new())
		t.set_stylebox("focus", typ, StyleBoxEmpty.new())
		t.set_stylebox("disabled", typ, StyleBoxEmpty.new())
		t.set_color("font_color", typ, TEXT)
		t.set_color("font_hover_color", typ, Color(1, 0.98, 0.9))

	# ---------------------------------------------------------------- Eingaben
	t.set_stylebox("normal", "LineEdit", _kasten(TIEF, RAND_LEISE, 1, 12, 14.0, 10.0))
	t.set_stylebox("focus", "LineEdit", _kasten(Color(0, 0, 0, 0), GOLD, 2, 12, 14.0, 10.0))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_AUS)
	t.set_color("caret_color", "LineEdit", GOLD)

	# ---------------------------------------------------------------- Balken
	t.set_stylebox("background", "ProgressBar", _kasten(TIEF, RAND_LEISE, 1, 11, 0.0, 0.0))
	t.set_stylebox("fill", "ProgressBar", _kasten(GOLD, Color(0, 0, 0, 0), 0, 11, 0.0, 0.0))
	t.set_color("font_color", "ProgressBar", TEXT)

	# ---------------------------------------------------------------- Rollbalken
	t.set_stylebox("scroll", "VScrollBar", _kasten(TIEF, Color(0, 0, 0, 0), 0, 6, 0.0, 0.0))
	t.set_stylebox("grabber", "VScrollBar", _kasten(RAND, Color(0, 0, 0, 0), 0, 6, 0.0, 0.0))
	t.set_stylebox("grabber_highlight", "VScrollBar", _kasten(GOLD, Color(0, 0, 0, 0), 0, 6, 0.0, 0.0))
	t.set_stylebox("grabber_pressed", "VScrollBar", _kasten(GOLD_HELL, Color(0, 0, 0, 0), 0, 6, 0.0, 0.0))

	# ---------------------------------------------------------------- Schrift
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_constant("shadow_outline_size", "Label", 3)
	t.set_stylebox("separator", "HSeparator", _linie())

	var fehler := ResourceSaver.save(t, ZIEL)
	print("Theme gespeichert: %s (Fehler %d)" % [ZIEL, fehler])
	quit()

func _kasten(fuellung: Color, rand: Color, randbreite: int, radius: int, rand_x: float, rand_y: float) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fuellung
	s.border_color = rand
	s.set_border_width_all(randbreite)
	s.set_corner_radius_all(radius)
	s.corner_detail = 12  # weich gerundet statt gerader Fase
	s.content_margin_left = rand_x
	s.content_margin_right = rand_x
	s.content_margin_top = rand_y
	s.content_margin_bottom = rand_y
	return s

## Ruhezustand mit dünnem, leisem Rand; Gold kommt erst bei Hover und Fokus dazu
func _knopf(t: Theme, typ: String, radius: int, rand_x: float, rand_y: float) -> void:
	t.set_stylebox("normal", typ, _kasten(HOLZ, RAND, 1, radius, rand_x, rand_y))
	t.set_stylebox("hover", typ, _kasten(HOLZ_HOVER, GOLD, 2, radius, rand_x, rand_y))
	t.set_stylebox("pressed", typ, _kasten(GOLD, Color(0, 0, 0, 0), 0, radius, rand_x, rand_y))
	t.set_stylebox("focus", typ, _kasten(Color(0, 0, 0, 0), GOLD, 2, radius, rand_x, rand_y))
	t.set_stylebox("disabled", typ, _kasten(Color(HOLZ.r, HOLZ.g, HOLZ.b, 0.4), RAND_LEISE, 1, radius, rand_x, rand_y))

## Fläche mit farbigem Balken nur am linken Rand — markiert die aktive Zeile
func _balken(balkenfarbe: Color, fuellung: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fuellung
	s.border_color = balkenfarbe
	s.border_width_left = 4
	s.set_corner_radius_all(radius)
	s.corner_detail = 12
	s.content_margin_left = 20.0
	s.content_margin_right = 20.0
	s.content_margin_top = 10.0
	s.content_margin_bottom = 10.0
	return s

func _linie() -> StyleBoxLine:
	var l := StyleBoxLine.new()
	l.color = RAND_LEISE
	l.thickness = 2
	return l
