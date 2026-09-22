extends Control
## Emote-Rad: Taste halten, mit der Maus (oder den Pfeiltasten) ein Kuchenstück
## wählen, loslassen — die Figur spielt es. Sechs Stücke wie im Entwurf:
## Winken, Tanzen, Jubel, Sitzen, Posen, Kotzen.
##
## Gezeichnet wird das Rad in _draw(), weil sechs Kuchenstücke mit Rand und
## Leuchten als Knoten nur Bastelei wären; Symbole und Beschriftungen sind
## echte Knoten (scenes/ui/emote_rad.tscn).

const Symbole := preload("res://scripts/ui/symbole.gd")

## Reihenfolge = im Uhrzeigersinn ab oben. Muss zu Player.EMOTE_* passen.
const STUECKE := [
	{"emote": 1, "symbol": "tanzen", "text": "EMOTE_TANZEN"},
	{"emote": 4, "symbol": "jubel", "text": "EMOTE_JUBEL"},
	{"emote": 6, "symbol": "sitzen", "text": "EMOTE_SITZEN"},
	{"emote": 5, "symbol": "posen", "text": "EMOTE_POSEN"},
	{"emote": 2, "symbol": "kotzen", "text": "EMOTE_KOTZEN"},
	{"emote": 3, "symbol": "winken", "text": "EMOTE_WINKEN"},
]

const AUSSEN := 250.0
const INNEN := 78.0
## Lücke zwischen zwei Stücken (Bogenmaß)
const SPALT := 0.035
const GOLD := Color(1, 0.839, 0.349)
const RAND := Color(0.58, 0.42, 0.24, 0.85)
const STUECK_AUS := Color(0.08, 0.07, 0.06, 0.92)
const STUECK_AN := Color(0.28, 0.21, 0.09, 0.96)

signal gewaehlt(emote: int)

var _offen := false
var _wahl := 0

@onready var _mitte: Control = %Mitte
@onready var _symbole: Control = %Symbole

func _ready() -> void:
	visible = false
	set_process_input(false)
	_bauen()

## Symbole und Beschriftungen als echte Knoten — je Stück ein VBox mit Bild
## und Text, auf dem Kreis verteilt.
func _bauen() -> void:
	for kind in _symbole.get_children():
		kind.queue_free()
	for i in STUECKE.size():
		var d: Dictionary = STUECKE[i]
		var spalte := VBoxContainer.new()
		spalte.name = "Stueck%d" % i
		spalte.alignment = BoxContainer.ALIGNMENT_CENTER
		spalte.add_theme_constant_override("separation", 6)
		spalte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bild := TextureRect.new()
		bild.texture = Symbole.bild(str(d["symbol"]))
		bild.custom_minimum_size = Vector2(54, 54)
		bild.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bild.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bild.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		spalte.add_child(bild)
		var text := Label.new()
		text.text = str(d["text"])
		text.add_theme_font_size_override("font_size", 19)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		spalte.add_child(text)
		_symbole.add_child(spalte)

func oeffnen() -> void:
	if _offen:
		return
	_offen = true
	visible = true
	_wahl = 0
	_symbole_setzen()
	set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Zeiger in die Mitte, damit die erste Bewegung schon zählt
	warp_mouse(size * 0.5)
	queue_redraw()

## Schließen und das gewählte Stück melden (0 = nichts gewählt).
func schliessen(spielen: bool) -> void:
	if not _offen:
		return
	_offen = false
	visible = false
	set_process_input(false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if spielen and _wahl > 0:
		gewaehlt.emit(_wahl)

func ist_offen() -> bool:
	return _offen

func _input(event: InputEvent) -> void:
	if not _offen:
		return
	if event is InputEventMouseMotion:
		_wahl_aus_zeiger((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		schliessen(true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		schliessen(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_weiter(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_weiter(1)
	elif event.is_action_pressed("ui_accept"):
		schliessen(true)
		get_viewport().set_input_as_handled()

func _weiter(richtung: int) -> void:
	var i := _stueck_index(_wahl)
	if i < 0:
		i = 0 if richtung > 0 else STUECKE.size() - 1
	else:
		i = posmod(i + richtung, STUECKE.size())
	_wahl = int(STUECKE[i]["emote"])
	queue_redraw()

## Welches Stück liegt unter dem Zeiger? In der Mitte: keins.
func _wahl_aus_zeiger(pos: Vector2) -> void:
	var zum := pos - size * 0.5
	if zum.length() < INNEN:
		if _wahl != 0:
			_wahl = 0
			queue_redraw()
		return
	# 0 = oben, dann im Uhrzeigersinn
	var winkel := fposmod(atan2(zum.x, -zum.y), TAU)
	var i := int(winkel / (TAU / float(STUECKE.size())) + 0.5) % STUECKE.size()
	var neu := int(STUECKE[i]["emote"])
	if neu != _wahl:
		_wahl = neu
		queue_redraw()

func _stueck_index(emote: int) -> int:
	for i in STUECKE.size():
		if int(STUECKE[i]["emote"]) == emote:
			return i
	return -1

func _notification(was: int) -> void:
	if was == NOTIFICATION_RESIZED:
		_symbole_setzen()
		queue_redraw()

## Symbole auf den Kreis setzen — Mitte des jeweiligen Kuchenstücks.
func _symbole_setzen() -> void:
	if _symbole == null:
		return
	var m := size * 0.5
	var r := (AUSSEN + INNEN) * 0.5
	for i in _symbole.get_child_count():
		var spalte := _symbole.get_child(i) as Control
		var winkel := TAU * float(i) / float(STUECKE.size())
		var mitte := m + Vector2(sin(winkel), -cos(winkel)) * r
		spalte.size = Vector2(150, 90)
		spalte.position = mitte - spalte.size * 0.5

func _draw() -> void:
	var m := size * 0.5
	var schritt := TAU / float(STUECKE.size())
	for i in STUECKE.size():
		var d: Dictionary = STUECKE[i]
		var an := int(d["emote"]) == _wahl
		# Von oben aus, jedes Stück mittig um seine Richtung
		var von := -PI * 0.5 + schritt * float(i) - schritt * 0.5 + SPALT
		var bis := von + schritt - SPALT * 2.0
		_stueck(m, von, bis, STUECK_AN if an else STUECK_AUS, GOLD if an else RAND, an)
	# Nabe in der Mitte
	draw_circle(m, INNEN - 12.0, Color(0.05, 0.045, 0.04, 0.95))
	draw_arc(m, INNEN - 12.0, 0.0, TAU, 64, GOLD if _wahl == 0 else RAND, 2.0, true)

func _stueck(m: Vector2, von: float, bis: float, fuellung: Color, rand: Color, leuchten: bool) -> void:
	var punkte := PackedVector2Array()
	var schritte := 24
	for i in schritte + 1:
		var w := lerpf(von, bis, float(i) / float(schritte))
		punkte.append(m + Vector2(cos(w), sin(w)) * AUSSEN)
	for i in schritte + 1:
		var w := lerpf(bis, von, float(i) / float(schritte))
		punkte.append(m + Vector2(cos(w), sin(w)) * INNEN)
	var farben := PackedColorArray()
	for i in punkte.size():
		farben.append(fuellung)
	draw_polygon(punkte, farben)
	# Rand außen herum; beim gewählten Stück dicker und golden
	punkte.append(punkte[0])
	draw_polyline(punkte, rand, 3.0 if leuchten else 1.5, true)
	if leuchten:
		draw_polyline(punkte, Color(GOLD.r, GOLD.g, GOLD.b, 0.25), 9.0, true)
