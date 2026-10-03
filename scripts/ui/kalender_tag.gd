extends Button
## Eine Tageskarte im Festkalender (scenes/ui/kalender_tag.tscn): Tagesnummer, Symbol und
## Name des Ereignisses, Bankrate, Haken bei vergangenen Tagen, „HEUTE"-Band mit Leuchten
## beim aktuellen Tag. Beim Überfahren (oder Anwählen mit dem Steuerkreuz) hebt sich der
## Inhalt und der Kalender zeigt unten die Beschreibung (Signal gewaehlt).

signal gewaehlt(karte: Button)

const Symbole := preload("res://scripts/ui/symbole.gd")
const HOVER_ZOOM := 1.07

## Beschreibung für die Detailzeile, setzt der Kalender
var detail_titel := ""
var detail_text := ""
var detail_symbol := ""
var detail_farbe := Color.WHITE
var tag_nummer := 0

var _heute := false
var _tween: Tween
var _puls: Tween

@onready var _inhalt: Control = %Inhalt

func _ready() -> void:
	mouse_entered.connect(_an.bind(true))
	mouse_exited.connect(_an.bind(false))
	focus_entered.connect(_an.bind(true))
	focus_exited.connect(_an.bind(false))
	resized.connect(func() -> void: _inhalt.pivot_offset = _inhalt.size * 0.5)
	_inhalt.pivot_offset = _inhalt.size * 0.5

## Karte füllen. symbol "" = kein Ereignis.
func setzen(nummer: int, titel: String, symbol: String, farbe: Color, extras: String, vergangen: bool, heute: bool) -> void:
	tag_nummer = nummer
	_heute = heute
	%Nummer.text = str(nummer)
	%Titel.text = titel
	%Titel.add_theme_font_size_override("font_size", 13 if titel.length() > 11 else 15)
	%Extras.text = extras
	var bild: Texture2D = Symbole.bild(symbol) if symbol != "" else null
	%Symbol.texture = bild
	%Symbol.self_modulate = farbe
	%Streifen.color = Color(farbe.r, farbe.g, farbe.b, 0.9 if symbol != "" else 0.25)
	%Haken.visible = vergangen
	%HeuteBand.visible = heute
	%Leuchten.visible = heute
	_inhalt.modulate = Color(1, 1, 1, 0.5 if vergangen else 1.0)
	if _puls:
		_puls.kill()
	if heute:
		%Leuchten.modulate.a = 1.0
		_puls = create_tween().set_loops()
		_puls.tween_property(%Leuchten, "modulate:a", 0.35, 0.9).set_trans(Tween.TRANS_SINE)
		_puls.tween_property(%Leuchten, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)

## Kommt beim Öffnen gestaffelt von unten herein
func einfliegen(verzoegerung: float) -> void:
	var ziel_a: float = _inhalt.modulate.a
	_inhalt.position.y = 26.0
	_inhalt.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_inhalt, "position:y", 0.0, 0.4).set_delay(verzoegerung).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_inhalt, "modulate:a", ziel_a, 0.3).set_delay(verzoegerung)

func _an(an: bool) -> void:
	if an:
		gewaehlt.emit(self)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_inhalt, "scale", Vector2.ONE * (HOVER_ZOOM if an else 1.0), 0.18)
	_tween.tween_property(_inhalt, "position:y", -4.0 if an else 0.0, 0.18)
