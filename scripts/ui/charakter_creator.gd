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
	Color(0.85, 0.15, 0.15), Color(0.90, 0.45, 0.10), Color(0.95, 0.80, 0.20), Color(0.30, 0.60, 0.25),
	Color(0.15, 0.50, 0.55), Color(0.15, 0.30, 0.65), Color(0.45, 0.25, 0.60), Color(0.90, 0.45, 0.65),
	Color(0.35, 0.22, 0.13), Color(0.12, 0.12, 0.13), Color(0.55, 0.55, 0.58), Color(0.95, 0.95, 0.95),
]
const AUSWAHL := {"augen": "Augen", "emotion": "Emotion", "bart": "Bart", "hut": "Hut", "brille": "Brille"}
const FARBEN := {"haut": "HautFarbe", "haar": "HaarFarbe", "hut_farbe": "HutFarbe", "brille_farbe": "BrilleFarbe"}

var _look := {}
var _figur: Figur
var _sperre := false

func _ready() -> void:
	for art: String in AUSWAHL:
		var ob := get_node("%" + AUSWAHL[art]) as OptionButton
		ob.clear()
		for e: Dictionary in Look.liste(art):
			ob.add_item(tr(e["name"]))
			ob.set_item_metadata(ob.item_count - 1, e["id"])
		ob.item_selected.connect(_auswahl_geaendert.bind(art))
	for schluessel: String in FARBEN:
		var cp := get_node("%" + FARBEN[schluessel]) as ColorPickerButton
		var presets: Array = Look.HAUTFARBEN if schluessel == "haut" else (Assets.HAARFARBEN if schluessel == "haar" else STANDARD_FARBEN)
		var picker := cp.get_picker()
		for c: Color in presets:
			picker.add_preset(c)
		picker.presets_visible = true
		picker.sampler_visible = false
		picker.color_modes_visible = false
		picker.sliders_visible = schluessel != "haut" and schluessel != "haar"
		cp.color_changed.connect(_farbe_geaendert.bind(schluessel))
	%Zufall.pressed.connect(func() -> void: _setzen(Look.zufall()))
	%Abbrechen.pressed.connect(_abbrechen)
	%Fertig.pressed.connect(_fertig)
	%Vorschau.gui_input.connect(_vorschau_eingabe)
	visible = false

func oeffnen(start: Dictionary) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_setzen(start)
	%Fertig.grab_focus.call_deferred()

func _setzen(look: Dictionary) -> void:
	_look = Look.pruefen(look)
	_sperre = true
	for art: String in AUSWAHL:
		var ob := get_node("%" + AUSWAHL[art]) as OptionButton
		for i in ob.item_count:
			if ob.get_item_metadata(i) == _look[art]:
				ob.select(i)
	for schluessel: String in FARBEN:
		(get_node("%" + FARBEN[schluessel]) as ColorPickerButton).color = Color.html(str(_look[schluessel]))
	_sperre = false
	_neu_bauen()

func _auswahl_geaendert(index: int, art: String) -> void:
	if _sperre:
		return
	var ob := get_node("%" + AUSWAHL[art]) as OptionButton
	_look[art] = ob.get_item_metadata(index)
	_neu_bauen()

func _farbe_geaendert(farbe: Color, schluessel: String) -> void:
	if _sperre:
		return
	_look[schluessel] = farbe.to_html(false)
	if _figur:
		Look.faerben(_figur, _look)

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
