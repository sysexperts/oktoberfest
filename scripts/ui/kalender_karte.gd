extends Button
## Eine Tageskarte in der Kalender-App (scenes/ui/kalender_karte.tscn): Tagesnummer, Symbol, Ereignisname, Haken bei vergangenen Tagen,
## hervorgehobener Rand beim heutigen Tag. Überfahren, Anwählen oder Klicken meldet die Karte (Signal gewaehlt), die App zeigt unten Details.

signal gewaehlt(karte: Button)

const Symbole := preload("res://scripts/ui/symbole.gd")
const HEUTE := preload("res://scenes/ui/kalender_heute.tres")

## Beschreibung für die Detailzeile, setzt die App
var detail_titel := ""
var detail_text := ""
var detail_symbol := ""
var detail_farbe := Color.WHITE
var tag_nummer := 0

func _ready() -> void:
	mouse_entered.connect(func() -> void: gewaehlt.emit(self))
	focus_entered.connect(func() -> void: gewaehlt.emit(self))
	pressed.connect(func() -> void: gewaehlt.emit(self))

## Karte füllen. symbol "" = kein Ereignis.
func setzen(nummer: int, titel: String, symbol: String, farbe: Color, vergangen: bool, heute: bool) -> void:
	tag_nummer = nummer
	%Nummer.text = str(nummer)
	%Titel.text = titel
	%Titel.visible = titel != ""
	%Symbol.texture = Symbole.bild(symbol) if symbol != "" else null
	%Symbol.self_modulate = farbe
	%Haken.visible = vergangen
	%Heute.visible = heute
	%Zeile.modulate = Color(1, 1, 1, 0.5 if vergangen else 1.0)
	if heute:
		add_theme_stylebox_override("normal", HEUTE)
