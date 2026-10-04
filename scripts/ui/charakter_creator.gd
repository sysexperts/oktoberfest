extends Control
## Charakter-Creator: links eine drehbare 3D-Vorschau, rechts Auswahl für Augen, Ausdruck, Bart,
## Hut und Brille plus Farben für Haut, Haar, Hut und Brille. Gebaut wird aus dem einen
## Basiskörper (scripts/charakter_look.gd) — alle Figuren teilen Körper und Skelett.
## Aufbau: scenes/ui/charakter_creator.tscn. Aufruf: oeffnen(look), dann fertig / abgebrochen abwarten.
## Das Ergebnis speichert der Creator selbst (user://charakter.cfg).

const Look := preload("res://scripts/charakter_look.gd")
const Assets := preload("res://scripts/creator_assets.gd")

signal fertig(look: Dictionary)
signal abgebrochen

const STANDARD_FARBEN := [
	Color(0.85, 0.15, 0.15), Color(0.90, 0.45, 0.10), Color(0.95, 0.80, 0.20),
	Color(0.20, 0.55, 0.30), Color(0.15, 0.55, 0.60), Color(0.15, 0.35, 0.75), Color(0.45, 0.25, 0.65),
	Color(0.90, 0.45, 0.65), Color(0.45, 0.28, 0.16), Color(0.12, 0.12, 0.13), Color(0.55, 0.55, 0.60),
	Color(0.97, 0.97, 0.97),
]
## Bausteine mit Pfeilen: Schlüssel im Look → Name der Knoten (%…Zurueck, %…Name, %…Weiter)
const AUSWAHL := {"augen": "Augen", "emotion": "Emotion", "bart": "Bart", "hut": "Hut", "brille": "Brille"}
## Farben: Schlüssel im Look → Knoten mit den Farbflecken, und woher die Farben kommen
const FARBEN := {"haut": "HautFarben", "haar": "HaarFarben", "hut_farbe": "HutFarben", "brille_farbe": "BrilleFarben"}
const GOLD := Color(1, 0.839, 0.349)

var _look := {}
var _figur: Figur
var _sperre := false
## Farbflecken je Look-Schlüssel (für die Markierung der gewählten Farbe)
var _flecken := {}

func _ready() -> void:
	for art: String in AUSWAHL:
		get_node("%" + AUSWAHL[art] + "Zurueck").pressed.connect(_weiter.bind(art, -1))
		get_node("%" + AUSWAHL[art] + "Weiter").pressed.connect(_weiter.bind(art, 1))
	for schluessel: String in FARBEN:
		var palette: Array = Look.HAUTFARBEN if schluessel == "haut" else (Assets.HAARFARBEN if schluessel == "haar" else STANDARD_FARBEN)
		_flecken[schluessel] = []
		var behaelter := get_node("%" + FARBEN[schluessel]) as Control
		for c: Color in palette:
			var k := _fleck(c)
			k.pressed.connect(_farbe_gewaehlt.bind(schluessel, c))
			behaelter.add_child(k)
			_flecken[schluessel].append([k, c])
	%Zufall.pressed.connect(func() -> void: _setzen(Look.zufall()))
	%Abbrechen.pressed.connect(_abbrechen)
	%Fertig.pressed.connect(_fertig)
	%Vorschau.gui_input.connect(_vorschau_eingabe)
	visible = false

## Runder Farbfleck als Knopf; die gewählte Farbe bekommt einen goldenen Ring (_flecken_zeigen)
func _fleck(farbe: Color) -> Button:
	var k := Button.new()
	k.custom_minimum_size = Vector2(34, 34)
	k.focus_mode = Control.FOCUS_ALL
	for zustand: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		k.add_theme_stylebox_override(zustand, _fleck_stil(farbe, false, zustand == "hover" or zustand == "focus"))
	k.set_meta("farbe", farbe)
	return k

func _fleck_stil(farbe: Color, gewaehlt: bool, hell: bool) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = farbe
	st.set_corner_radius_all(17)
	st.set_border_width_all(4 if gewaehlt else 2)
	st.border_color = GOLD if gewaehlt else (Color(1, 1, 1, 0.75) if hell else Color(0, 0, 0, 0.55))
	st.set_content_margin_all(0)
	return st

func _flecken_zeigen() -> void:
	for schluessel: String in _flecken:
		var aktuell := Color.html(str(_look[schluessel]))
		for paar: Array in _flecken[schluessel]:
			var k: Button = paar[0]
			var c: Color = paar[1]
			var gewaehlt := c.is_equal_approx(aktuell) or c.to_html(false) == str(_look[schluessel])
			for zustand: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				k.add_theme_stylebox_override(zustand, _fleck_stil(c, gewaehlt, zustand == "hover" or zustand == "focus"))

func _farbe_gewaehlt(schluessel: String, farbe: Color) -> void:
	if _sperre:
		return
	_look[schluessel] = farbe.to_html(false)
	_flecken_zeigen()
	if _figur:
		Look.faerben(_figur, _look)

## Pfeil links/rechts: nächsten Baustein wählen (rundherum)
func _weiter(art: String, richtung: int) -> void:
	var eintraege := Look.liste(art)
	var i := 0
	for k in eintraege.size():
		if eintraege[k]["id"] == _look[art]:
			i = k
	_look[art] = eintraege[posmod(i + richtung, eintraege.size())]["id"]
	_namen_zeigen()
	_neu_bauen()

func _namen_zeigen() -> void:
	for art: String in AUSWAHL:
		for e: Dictionary in Look.liste(art):
			if e["id"] == _look[art]:
				(get_node("%" + AUSWAHL[art] + "Name") as Label).text = tr(e["name"])

func oeffnen(start: Dictionary) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_setzen(start)
	%Fertig.grab_focus.call_deferred()

func _setzen(look: Dictionary) -> void:
	_look = Look.pruefen(look)
	_namen_zeigen()
	_flecken_zeigen()
	_neu_bauen()

## Figur neu aufbauen (nur bei Wechsel eines Bausteins nötig, Farben brauchen das nicht)
func _neu_bauen() -> void:
	var teller: Node3D = %Drehteller
	var winkel := 0.0
	if _figur:
		winkel = _figur.rotation.y
		_figur.queue_free()
	_figur = Look.bauen(_look)
	_figur.rotation.y = winkel
	teller.add_child(_figur)
	Look.faerben(_figur, _look)
	_figur.stehen()

func _process(delta: float) -> void:
	if visible and _figur and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_figur.rotate_y(delta * 0.5)

func _vorschau_eingabe(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion and (ereignis as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT and _figur:
		_figur.rotate_y((ereignis as InputEventMouseMotion).relative.x * 0.012)

func _unhandled_input(ereignis: InputEvent) -> void:
	if visible and ereignis.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_abbrechen()

func _fertig() -> void:
	Look.speichern(_look)
	visible = false
	fertig.emit(_look.duplicate())

func _abbrechen() -> void:
	visible = false
	abgebrochen.emit()

## Creator über einem Fenster öffnen; `danach` läuft nach Fertig und nach Abbrechen. Gibt den Creator zurück.
static func zeigen(eltern: Node, danach := Callable()) -> Control:
	var cc := (load("res://scenes/ui/charakter_creator.tscn") as PackedScene).instantiate() as Control
	eltern.add_child(cc)
	cc.oeffnen(Look.laden())
	var schluss := func(_l: Variant = null) -> void:
		if is_instance_valid(cc):
			cc.queue_free()
		if danach.is_valid():
			danach.call()
	cc.fertig.connect(schluss)
	cc.abgebrochen.connect(schluss)
	return cc
