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
const AUSWAHL := {"augen": "Augen", "emotion": "Emotion", "frisur": "Frisur", "dirndl": "Dirndl", "bart": "Bart", "hut": "Hut", "brille": "Brille", "hemd": "Hemd", "jacke": "Jacke", "hose": "Hose", "schuhe": "Schuhe"}
## Farben: Schlüssel im Look → Knoten mit den Farbflecken, und woher die Farben kommen
const FARBEN := {"haut": "HautFarben", "haar": "BartFarben", "hut_farbe": "HutFarben", "brille_farbe": "BrilleFarben", "hemd_farbe": "HemdFarben", "hemd_muster": "HemdMusterFarben",
	"jacke_farbe": "JackeFarben", "jacke_muster": "JackeMusterFarben", "hose_farbe": "HoseFarben", "hose_muster": "HoseMusterFarben", "schuhe_farbe": "SchuheFarben", "schuhe_muster": "SchuheMusterFarben"}
## Zweite Farbreihe für denselben Look-Schlüssel (die Haarfarbe steht bei Männern unter Bart, bei Frauen unter Frisur)
const FARBEN_ZWEIT := {"haar": "FrisurFarben"}
## Titel der Kleidungszeilen bei Frauen (Dirndl aus Bluse, Kleid und Schürze)
const DIRNDL_TITEL := {"hemd": "CREATOR_BLUSE", "hose": "CREATOR_KLEID", "jacke": "CREATOR_SCHUERZE"}
const MANN_TITEL := {"hemd": "CREATOR_HEMD", "hose": "CREATOR_HOSE", "jacke": "CREATOR_JACKE"}
const GOLD := Color(1, 0.839, 0.349)
## Tabs: Name der Seite, Kamera (Position, Neigung in Grad). Gesicht nah, Kleidung ganzer Körper.
const TABS := [
	["Aussehen", Vector3(0, 1.22, 2.7), -3.0],
	["Kopf", Vector3(0, 1.22, 2.7), -3.0],
	["Kleidung", Vector3(0, 0.80, 3.8), -3.0],
]

var _look := {}
var _figur: Figur
var _sperre := false
var _dreh_tempo := 0.0
var _schliesst := false
## Farbflecken je Look-Schlüssel (für die Markierung der gewählten Farbe)
var _flecken := {}

func _ready() -> void:
	for art: String in AUSWAHL:
		get_node("%" + AUSWAHL[art] + "Zurueck").pressed.connect(_weiter.bind(art, -1))
		get_node("%" + AUSWAHL[art] + "Weiter").pressed.connect(_weiter.bind(art, 1))
	for schluessel: String in FARBEN:
		var palette: Array = Look.HAUTFARBEN if schluessel == "haut" else (Assets.HAARFARBEN if schluessel == "haar" else STANDARD_FARBEN)
		_flecken[schluessel] = []
		var behaelter: Array[Control] = [get_node("%" + FARBEN[schluessel]) as Control]
		if FARBEN_ZWEIT.has(schluessel):
			behaelter.append(get_node("%" + FARBEN_ZWEIT[schluessel]) as Control)
		for b: Control in behaelter:
			for c: Color in palette:
				var k := _fleck(c)
				k.pressed.connect(_farbe_gewaehlt.bind(schluessel, c))
				b.add_child(k)
				_federn(k, 1.25)
				_flecken[schluessel].append([k, c])
	for b in find_children("*", "Button", true, false):
		_federn(b as Button, 1.07)
	var gruppe := ButtonGroup.new()
	for i in TABS.size():
		var tab := get_node("%Tab" + TABS[i][0]) as Button
		tab.button_group = gruppe
		tab.pressed.connect(_tab_zeigen.bind(i))
	_tab_zeigen(0, false)
	var gruppe_g := ButtonGroup.new()
	%Maennlich.button_group = gruppe_g
	%Weiblich.button_group = gruppe_g
	%Maennlich.pressed.connect(_geschlecht_setzen.bind("m"))
	%Weiblich.pressed.connect(_geschlecht_setzen.bind("w"))
	%Zufall.pressed.connect(func() -> void: _setzen(Look.zufall(str(_look.get("geschlecht", "m")))))
	%Abbrechen.pressed.connect(_abbrechen)
	%Fertig.pressed.connect(_fertig)
	%Vorschau.gui_input.connect(_vorschau_eingabe)
	visible = false

## Knopf wächst beim Überfahren und drückt sich beim Klicken ein (Skalierung um die Mitte)
func _federn(b: Button, hover: float) -> void:
	b.resized.connect(func() -> void: b.pivot_offset = b.size / 2.0)
	b.pivot_offset = b.size / 2.0
	var ziel := func(f: float, dauer: float) -> void:
		var t := b.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(b, "scale", Vector2.ONE * f, dauer)
	b.mouse_entered.connect(func() -> void: ziel.call(hover, 0.15))
	b.mouse_exited.connect(func() -> void: ziel.call(1.0, 0.18))
	b.button_down.connect(func() -> void: ziel.call(0.92, 0.07))
	b.button_up.connect(func() -> void: ziel.call(hover if b.is_hovered() else 1.0, 0.16))

## Runder Farbfleck als Knopf; die gewählte Farbe bekommt einen goldenen Ring (_flecken_zeigen)
func _fleck(farbe: Color) -> Button:
	var k := Button.new()
	k.custom_minimum_size = Vector2(26, 26)
	k.focus_mode = Control.FOCUS_ALL
	for zustand: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		k.add_theme_stylebox_override(zustand, _fleck_stil(farbe, false, zustand == "hover" or zustand == "focus"))
	k.set_meta("farbe", farbe)
	return k

func _fleck_stil(farbe: Color, gewaehlt: bool, hell: bool) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = farbe
	st.set_corner_radius_all(13)
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

## Seite wählen und die Kamera auf Kopf oder ganzen Körper fahren
func _tab_zeigen(i: int, weich := true) -> void:
	for k in TABS.size():
		var seite := get_node("%Seite" + TABS[k][0]) as Control
		seite.visible = k == i
		if k == i and weich:
			# Zeilen nacheinander einblenden
			var zeilen := seite.get_children()
			for n in zeilen.size():
				var z := zeilen[n] as Control
				z.modulate.a = 0.0
				var t := z.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				t.tween_interval(0.05 * n)
				t.tween_property(z, "modulate:a", 1.0, 0.25)
	(get_node("%Tab" + TABS[i][0]) as Button).set_pressed_no_signal(true)
	var kam: Camera3D = %Kamera
	var ziel := Basis(Vector3.RIGHT, deg_to_rad(TABS[i][2]))
	if not weich:
		kam.position = TABS[i][1]
		kam.basis = ziel
		return
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(kam, "position", TABS[i][1], 0.5)
	t.tween_property(kam, "basis", ziel, 0.5)
	if _figur:
		# Figur dreht sich weich nach vorn
		var vorn := roundf(_figur.rotation.y / TAU) * TAU
		t.tween_property(_figur, "rotation:y", vorn, 0.5)
		_dreh_tempo = 0.0

## Pfeil links/rechts: nächsten Baustein wählen (rundherum)
func _weiter(art: String, richtung: int) -> void:
	var eintraege := Look.liste(art, str(_look["geschlecht"]))
	if eintraege.is_empty():
		return
	var i := 0
	for k in eintraege.size():
		if eintraege[k]["id"] == _look[art]:
			i = k
	var e: Dictionary = eintraege[posmod(i + richtung, eintraege.size())]
	if art == "dirndl":
		Look.dirndl_setzen(_look, e)
	else:
		_look[art] = e["id"]
		if art in Look.KLEIDER and e["szene"] != null:
			_look[art + "_farbe"] = (e["farbe"] as Color).to_html(false)
			_look[art + "_muster"] = (e["muster"] as Color).to_html(false)
	_flecken_zeigen()
	_namen_zeigen()
	_neu_bauen()
	var name_label := get_node("%" + AUSWAHL[art] + "Name") as Label
	name_label.pivot_offset = name_label.size / 2.0
	name_label.modulate.a = 0.0
	name_label.scale = Vector2.ONE * 0.9
	var t := name_label.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(name_label, "modulate:a", 1.0, 0.2)
	t.tween_property(name_label, "scale", Vector2.ONE, 0.25)

## Männlich/Weiblich: die Figur wird mit den Grunddaten des Geschlechts neu aufgebaut, Haut, Haar,
## Hut und Brille bleiben (Augen und Ausdruck gibt es je Geschlecht eigene)
func _geschlecht_setzen(g: String) -> void:
	if _sperre or g == str(_look["geschlecht"]):
		return
	var neu := Look.standard(g)
	for k: String in ["haut", "haar", "hut", "hut_farbe", "brille", "brille_farbe"]:
		neu[k] = _look[k]
	_setzen(neu)

## Zeilen je Geschlecht ein- und ausblenden und beschriften
func _geschlecht_zeigen() -> void:
	var frau := str(_look["geschlecht"]) == "w"
	%Maennlich.set_pressed_no_signal(not frau)
	%Weiblich.set_pressed_no_signal(frau)
	var kopf: Control = %SeiteKopf
	var kleid: Control = %SeiteKleidung
	kopf.get_node("Frisur").visible = frau
	kopf.get_node("Bart").visible = not frau
	kleid.get_node("Dirndl").visible = frau
	for art: String in DIRNDL_TITEL:
		var zeile := kleid.get_node(art.capitalize()) as Control
		zeile.get_node("Wahl").visible = not frau
		(zeile.get_node("Titel") as Label).text = DIRNDL_TITEL[art] if frau else MANN_TITEL[art]
	# Reihenfolge der Kleidungszeilen
	var reihe := PackedStringArray(["Dirndl", "Hemd", "Hose", "Jacke"] if frau else ["Hemd", "Jacke", "Hose", "Dirndl"])
	for n in reihe.size():
		kleid.move_child(kleid.get_node(reihe[n]), n)

func _namen_zeigen() -> void:
	# Frauen: Farbzeilen nur für Teile, die das gewählte Kleid wirklich hat (Landhauskleid ohne Schürze)
	var frau := str(_look["geschlecht"]) == "w"
	for art: String in Look.KLEIDER:
		(%SeiteKleidung.get_node(art.capitalize()) as Control).visible = art == "schuhe" or not frau or str(_look[art]) != "ohne"
	for art: String in AUSWAHL:
		var eintraege := Look.liste(art, str(_look["geschlecht"]))
		var l := get_node("%" + AUSWAHL[art] + "Name") as Label
		l.text = ""
		var id: String = str(_look.get(art, ""))
		for e: Dictionary in eintraege:
			if e["id"] == id:
				l.text = tr(e["name"])

func oeffnen(start: Dictionary) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true
	_schliesst = false
	_einblenden()
	_setzen(start)
	%Fertig.grab_focus.call_deferred()

## Fenster, Vorschau und Hintergrund blenden nacheinander ein (Skalierung um die Mitte)
func _einblenden() -> void:
	modulate.a = 1.0
	var teile: Array[Control] = [%Fenster, %VorschauRahmen]
	for n in teile.size():
		var c := teile[n]
		c.pivot_offset = c.size / 2.0
		c.modulate.a = 0.0
		c.scale = Vector2.ONE * 0.96
		var t := c.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		t.tween_property(c, "modulate:a", 1.0, 0.35).set_delay(0.08 * n)
		t.tween_property(c, "scale", Vector2.ONE, 0.45).set_delay(0.08 * n)
	%Dunkel.modulate.a = 0.0
	create_tween().tween_property(%Dunkel, "modulate:a", 1.0, 0.3)

## Ausblenden, dann `danach` aufrufen
func _ausblenden(danach: Callable) -> void:
	if _schliesst:
		return
	_schliesst = true
	var t := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	t.tween_property(self, "modulate:a", 0.0, 0.22)
	t.tween_callback(func() -> void:
		visible = false
		danach.call())

func _setzen(look: Dictionary) -> void:
	_look = Look.pruefen(look)
	_geschlecht_zeigen()
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
	_figur.scale = Vector3.ONE * 0.94
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(_figur, "scale", Vector3.ONE, 0.3)

## Die Figur steht still; nur mit der Maus drehen (mit etwas Schwung, der abklingt)
func _process(delta: float) -> void:
	if _figur and absf(_dreh_tempo) > 0.001:
		_figur.rotate_y(_dreh_tempo * delta)
		_dreh_tempo = lerpf(_dreh_tempo, 0.0, 1.0 - exp(-6.0 * delta))

func _vorschau_eingabe(ereignis: InputEvent) -> void:
	if ereignis is InputEventMouseMotion and (ereignis as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT and _figur:
		var dx := (ereignis as InputEventMouseMotion).relative.x
		_figur.rotate_y(dx * 0.012)
		_dreh_tempo = dx * 0.012 * 60.0
	elif ereignis is InputEventMouseButton and (ereignis as InputEventMouseButton).pressed:
		_dreh_tempo = 0.0

func _unhandled_input(ereignis: InputEvent) -> void:
	if visible and ereignis.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_abbrechen()

func _fertig() -> void:
	Look.speichern(_look)
	var l := _look.duplicate()
	_ausblenden(func() -> void: fertig.emit(l))

func _abbrechen() -> void:
	_ausblenden(func() -> void: abgebrochen.emit())

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
