extends Control
## Emote-Rad: Taste halten, mit der Maus (oder den Pfeiltasten / dem Stick) ein Stück wählen, loslassen — die Figur
## spielt es. Grundstücke: Jubel, Sitzen, Posen, Kotzen, Winken; dazu die in der Animationen-Ansicht ausgesuchten
## Clips (daten/emote_clips.json, Namen sind Übersetzungsschlüssel, z. B. EMOTE_TANZEN).
##
## Gezeichnet wird das Rad in _draw() (Glas-Ringstücke mit Farbverlauf und Leuchten, das gewählte Stück wächst nach außen),
## Symbole und Beschriftungen sind echte Knoten (scenes/ui/emote_rad.tscn). Die Symbole sind Piktogramme aus
## assets/ui/emote (Phosphor Icons, MIT, Lizenz dort), jedes auf einer Scheibe in der Farbe des Emotes.

const Symbole := preload("res://scripts/ui/symbole.gd")
const EmoteClips := preload("res://scripts/emote_clips.gd")

## Reihenfolge = im Uhrzeigersinn ab oben. Muss zu Player.EMOTE_* passen.
const BASIS := [
	{"emote": 4, "symbol": "jubel", "text": "EMOTE_JUBEL"},
	{"emote": 6, "symbol": "sitzen", "text": "EMOTE_SITZEN"},
	{"emote": 5, "symbol": "posen", "text": "EMOTE_POSEN"},
	{"emote": 2, "symbol": "kotzen", "text": "EMOTE_KOTZEN"},
	{"emote": 3, "symbol": "winken", "text": "EMOTE_WINKEN"},
]

## Farbe je Symbol (Scheibe, Rand, Leuchten)
const AKZENT := {
	"jubel": Color(1.0, 0.78, 0.25), "trinken": Color(1.0, 0.64, 0.18), "tanzen": Color(1.0, 0.45, 0.78),
	"sitzen": Color(0.38, 0.7, 1.0), "posen": Color(0.72, 0.52, 1.0), "winken": Color(0.3, 0.86, 0.9),
	"sad": Color(0.45, 0.55, 0.98), "kotzen": Color(0.55, 0.86, 0.35), "abwenden": Color(1.0, 0.45, 0.3),
	"catwalk": Color(0.96, 0.36, 0.62),
}
const AKZENT_STANDARD := Color(1.0, 0.84, 0.35)

const AUSSEN := 262.0
const INNEN := 104.0
## Lücke zwischen zwei Stücken (Bogenmaß)
const SPALT := 0.03
## So weit wächst das gewählte Stück nach außen
const WACHSEN := 14.0
const SCHEIBE := 36.0
const GLAS := Color(0.07, 0.07, 0.1, 0.8)
const GLAS_RAND := Color(1, 1, 1, 0.13)

## Grundstücke plus die ausgesuchten Clips
var STUECKE: Array = BASIS.duplicate()

signal gewaehlt(emote: int)

var _offen := false
var _wahl := 0
var _angezeigt := -1
var _hov: Array[float] = []

@onready var _mitte: Control = %Mitte
@onready var _symbole: Control = %Symbole

func _ready() -> void:
	visible = false
	set_process_input(false)
	_stuecke_laden()
	_bauen()

static func icon(name: String) -> Texture2D:
	var pfad := "res://assets/ui/emote/%s.svg" % name
	if ResourceLoader.exists(pfad):
		return load(pfad)
	return Symbole.bild(name)

static func akzent(name: String) -> Color:
	return AKZENT.get(name, AKZENT_STANDARD)

func _stuecke_laden() -> void:
	STUECKE = BASIS.duplicate()
	var clips := EmoteClips.laden()
	for i in clips.size():
		var c: Dictionary = clips[i]
		STUECKE.append({"emote": EmoteClips.nummer(i), "symbol": str(c.get("symbol", "tanzen")), "text": str(c.get("name", c.get("clip", "?")))})

## Symbole und Beschriftungen als echte Knoten — je Stück ein VBox mit Piktogramm und Name
func _bauen() -> void:
	for kind in _symbole.get_children():
		_symbole.remove_child(kind)
		kind.queue_free()
	_hov.clear()
	for i in STUECKE.size():
		_hov.append(0.0)
		var d: Dictionary = STUECKE[i]
		var spalte := VBoxContainer.new()
		spalte.name = "Stueck%d" % i
		spalte.alignment = BoxContainer.ALIGNMENT_BEGIN
		spalte.add_theme_constant_override("separation", 26)
		spalte.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bild := TextureRect.new()
		bild.name = "Bild"
		bild.texture = icon(str(d["symbol"]))
		bild.custom_minimum_size = Vector2(60, 60)
		bild.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bild.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bild.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		bild.pivot_offset = Vector2(30, 30)
		bild.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spalte.add_child(bild)
		var text := Label.new()
		text.name = "Name"
		text.text = tr(str(d["text"]))
		text.add_theme_font_size_override("font_size", 17)
		text.add_theme_color_override("font_color", Color(0.86, 0.84, 0.8))
		text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		text.add_theme_constant_override("outline_size", 5)
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.visible = false   # der Name steht groß in der Nabe
		spalte.add_child(text)
		_symbole.add_child(spalte)

func oeffnen() -> void:
	if _offen:
		return
	_offen = true
	visible = true
	_wahl = 0
	_angezeigt = -1
	# Ausgesuchte Clips jedes Mal neu lesen: Änderungen aus der Animationen-Ansicht gelten sofort
	_stuecke_laden()
	_bauen()
	_symbole_setzen()
	_mitte_aktualisieren()
	set_process_input(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Zeiger in die Mitte, damit die erste Bewegung schon zählt
	warp_mouse(size * 0.5)
	# Aufklappen: das Rad wächst sanft aus der Mitte
	pivot_offset = size * 0.5
	scale = Vector2(0.86, 0.86)
	modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.1)
	queue_redraw()

## Schließen und das gewählte Stück melden (0 = nichts gewählt).
func schliessen(spielen: bool) -> void:
	if not _offen:
		return
	_offen = false
	visible = false
	scale = Vector2.ONE
	modulate.a = 1.0
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
		# Solange der Stick zeigt, bestimmt er die Wahl — der mitgeschobene
		# Zeiger steckt anfangs noch in der Nabe und würde sie wieder löschen.
		if _stick().length() < STICK_AB:
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
		# Das Steuerkreuz liegt auch auf Hilfe, Kalender und Kostüm
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		_weiter(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		schliessen(true)
		get_viewport().set_input_as_handled()

## Am Controller: der rechte Stick zeigt direkt auf ein Stück.
const STICK_AB := 0.5

func _stick() -> Vector2:
	if not InputMap.has_action("blick_links"):
		return Vector2.ZERO
	return Input.get_vector("blick_links", "blick_rechts", "blick_hoch", "blick_runter")

func _process(delta: float) -> void:
	if not _offen:
		return
	# Gewähltes Stück wächst weich nach außen, die anderen schrumpfen zurück
	var neu_zeichnen := false
	for i in STUECKE.size():
		var ziel := 1.0 if int(STUECKE[i]["emote"]) == _wahl else 0.0
		var alt := _hov[i]
		_hov[i] = move_toward(alt, ziel, delta * 9.0)
		if _hov[i] != alt:
			neu_zeichnen = true
	if neu_zeichnen:
		_symbole_setzen()
		queue_redraw()
	if _wahl != _angezeigt:
		_mitte_aktualisieren()
	var s := _stick()
	if s.length() < STICK_AB:
		return
	# 0 = oben, dann im Uhrzeigersinn — wie _wahl_aus_zeiger
	var winkel := fposmod(atan2(s.x, -s.y), TAU)
	var i := int(winkel / (TAU / float(STUECKE.size())) + 0.5) % STUECKE.size()
	var neu := int(STUECKE[i]["emote"])
	if neu != _wahl:
		_wahl = neu

func _weiter(richtung: int) -> void:
	var i := _stueck_index(_wahl)
	if i < 0:
		i = 0 if richtung > 0 else STUECKE.size() - 1
	else:
		i = posmod(i + richtung, STUECKE.size())
	_wahl = int(STUECKE[i]["emote"])

## Welches Stück liegt unter dem Zeiger? In der Mitte: keins.
func _wahl_aus_zeiger(pos: Vector2) -> void:
	var zum := (pos - pivot_offset) / scale.x + pivot_offset - size * 0.5
	if zum.length() < INNEN - 10.0:
		_wahl = 0
		return
	# 0 = oben, dann im Uhrzeigersinn
	var winkel := fposmod(atan2(zum.x, -zum.y), TAU)
	var i := int(winkel / (TAU / float(STUECKE.size())) + 0.5) % STUECKE.size()
	_wahl = int(STUECKE[i]["emote"])

func _stueck_index(emote: int) -> int:
	for i in STUECKE.size():
		if int(STUECKE[i]["emote"]) == emote:
			return i
	return -1

func _notification(was: int) -> void:
	if was == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		_symbole_setzen()
		queue_redraw()

## Symbole auf den Kreis setzen — Mitte des jeweiligen Stücks (das gewählte sitzt weiter außen und ist größer).
func _symbole_setzen() -> void:
	if _symbole == null:
		return
	var m := size * 0.5
	var r := (AUSSEN + INNEN) * 0.5
	for i in _symbole.get_child_count():
		var spalte := _symbole.get_child(i) as Control
		var h := _hov[i] if i < _hov.size() else 0.0
		var winkel := TAU * float(i) / float(STUECKE.size())
		var mitte := m + Vector2(sin(winkel), -cos(winkel)) * (r + WACHSEN * h)
		spalte.size = Vector2(150, 96)
		spalte.position = mitte - Vector2(75, 30)
		var bild := spalte.get_node_or_null("Bild") as Control
		if bild:
			bild.scale = Vector2.ONE * (1.0 + 0.22 * h)
		var name := spalte.get_node_or_null("Name") as Label
		if name:
			name.modulate.a = 0.62 + 0.38 * h

## Nabe: zeigt das gewählte Emote groß (oder den Titel, solange nichts gewählt ist)
func _mitte_aktualisieren() -> void:
	_angezeigt = _wahl
	var bild := _mitte.get_node("Symbol") as TextureRect
	var titel := _mitte.get_node("Titel") as Label
	var i := _stueck_index(_wahl)
	if i < 0:
		bild.texture = Symbole.bild("maus")
		bild.modulate = Color(1, 0.84, 0.35)
		bild.custom_minimum_size = Vector2(30, 30)
		titel.text = ""   # Text erst beim Darüberfahren
	else:
		var d: Dictionary = STUECKE[i]
		bild.texture = icon(str(d["symbol"]))
		bild.modulate = Color.WHITE
		bild.custom_minimum_size = Vector2(64, 64)
		titel.text = tr(str(d["text"]))
		titel.add_theme_font_size_override("font_size", 22)
	queue_redraw()

func _draw() -> void:
	var m := size * 0.5
	var schritt := TAU / float(STUECKE.size())
	for i in STUECKE.size():
		var d: Dictionary = STUECKE[i]
		var h := _hov[i] if i < _hov.size() else 0.0
		var farbe := akzent(str(d["symbol"]))
		# Von oben aus, jedes Stück mittig um seine Richtung
		var von := -PI * 0.5 + schritt * float(i) - schritt * 0.5 + SPALT
		var bis := von + schritt - SPALT * 2.0
		_stueck(m, von, bis, farbe, h)
		# Scheibe unter dem Piktogramm
		var w := -PI * 0.5 + schritt * float(i)
		var r := (AUSSEN + INNEN) * 0.5 + WACHSEN * h
		var c := m + Vector2(cos(w), sin(w)) * r
		var rs := SCHEIBE * (1.0 + 0.2 * h)
		draw_circle(c, rs + 5.0, Color(farbe.r, farbe.g, farbe.b, 0.10 + 0.2 * h))
		draw_circle(c, rs, farbe.darkened(0.55).lerp(farbe, h * 0.85))
		draw_arc(c, rs, 0.0, TAU, 48, Color(1, 1, 1, 0.22 + 0.4 * h), 2.0, true)
	# Nabe in der Mitte
	var akt := _stueck_index(_wahl)
	var nabe := akzent(str(STUECKE[akt]["symbol"])) if akt >= 0 else AKZENT_STANDARD
	draw_circle(m, INNEN - 14.0, Color(0.05, 0.05, 0.07, 0.94))
	draw_arc(m, INNEN - 14.0, 0.0, TAU, 72, Color(nabe.r, nabe.g, nabe.b, 0.9 if akt >= 0 else 0.45), 3.0, true)
	if akt >= 0:
		draw_arc(m, INNEN - 6.0, 0.0, TAU, 72, Color(nabe.r, nabe.g, nabe.b, 0.18), 10.0, true)

func _stueck(m: Vector2, von: float, bis: float, farbe: Color, h: float) -> void:
	var innen := INNEN + 4.0 * h
	var aussen := AUSSEN + WACHSEN * h
	var punkte := PackedVector2Array()
	var farben := PackedColorArray()
	var schritte := 28
	# Glas innen dunkel, außen heller; gewählt: Verlauf in der Farbe des Emotes
	var c_innen := GLAS.lerp(Color(farbe.r * 0.45, farbe.g * 0.45, farbe.b * 0.45, 0.92), h)
	var c_aussen := Color(GLAS.r + 0.05, GLAS.g + 0.05, GLAS.b + 0.07, 0.72).lerp(Color(farbe.r * 0.85, farbe.g * 0.85, farbe.b * 0.85, 0.95), h)
	for i in schritte + 1:
		var w := lerpf(von, bis, float(i) / float(schritte))
		punkte.append(m + Vector2(cos(w), sin(w)) * aussen)
		farben.append(c_aussen)
	for i in schritte + 1:
		var w := lerpf(bis, von, float(i) / float(schritte))
		punkte.append(m + Vector2(cos(w), sin(w)) * innen)
		farben.append(c_innen)
	draw_polygon(punkte, farben)
	punkte.append(punkte[0])
	if h > 0.02:
		draw_polyline(punkte, Color(farbe.r, farbe.g, farbe.b, 0.22 * h), 12.0, true)
	draw_polyline(punkte, GLAS_RAND.lerp(Color(farbe.r, farbe.g, farbe.b, 0.95), h), 1.5 + 1.5 * h, true)
