extends Control
## Eine Meldung im Stapel am rechten Bildrand. Gleitet von rechts herein, bleibt eine
## Weile (ein dünner Balken unten läuft dabei ab) und gleitet wieder hinaus.
## Zahlen, Beträge und Spielbegriffe sind in der Randfarbe hervorgehoben.
## Aufbau: scenes/ui/meldung.tscn.

## Randfarbe je Art: 0 Info (Gold), 1 Problem (Rot), 2 Erfolg (Grün)
const FARBEN := [Color(1, 0.839, 0.349), Color(1, 0.42, 0.35), Color(0.55, 0.93, 0.55)]
const TEXTFARBE := Color(0.96, 0.92, 0.85)
## Spielbegriffe, die auffallen sollen (Deutsch, Englisch, Türkisch)
const BEGRIFFE := ["Sauberkeit", "Hygiene", "Geduld", "Stimmung", "Lager", "Festbüro", "Tagesziel", "Schicht",
	"Müll", "Dreck", "Fußspuren", "Bier", "Hendl", "Brezn", "Würstl", "Ware", "Personal", "Gäste", "Klo",
	"cleanliness", "patience", "mood", "stock", "fair office", "daily goal", "shift", "trash", "dirt",
	"footprints", "beer", "chicken", "pretzel", "sausage", "staff", "guests", "toilet",
	"temizlik", "sabır", "çadır", "bira", "tavuk", "çöp", "misafir"]

## Sekunden sichtbar — Test 13.09.: 4,5 s waren zu kurz zum Lesen
@export var dauer := 7.5

static var _regex: RegEx

var _roh := ""

@onready var _panel: PanelContainer = %Panel

func zeige(text: String, art: int) -> void:
	_roh = text
	var farbe: Color = FARBEN[clampi(art, 0, FARBEN.size() - 1)]
	%Text.text = _auszeichnen(text, farbe)
	var stil := _panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	stil.border_color = farbe
	_panel.add_theme_stylebox_override("panel", stil)
	var leiste := (%Leiste.get_theme_stylebox("fill") as StyleBoxFlat).duplicate() as StyleBoxFlat
	leiste.bg_color = Color(farbe.r, farbe.g, farbe.b, 0.8)
	%Leiste.add_theme_stylebox_override("fill", leiste)
	modulate.a = 0.0
	_panel.position.x = 80.0
	_passen.call_deferred()
	# Hinein: gleitet von rechts, Balken läuft ab
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_panel, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(%Leiste, "value", 0.0, dauer)
	# Hinaus: nach der Dauer wieder nach rechts weg
	tw.tween_interval(0.0)
	tw.tween_property(_panel, "position:x", 90.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)

## Das Panel liegt frei im Stapel-Platz (damit es seitlich gleiten kann) — der Platz
## muss deshalb so hoch sein wie das Panel.
func _passen() -> void:
	_panel.size = Vector2(size.x, 0.0)
	custom_minimum_size.y = _panel.get_combined_minimum_size().y

func _process(_delta: float) -> void:
	# Text bricht um, wenn das Panel seine Breite hat: Höhe nachführen
	var h := _panel.get_combined_minimum_size().y
	if absf(custom_minimum_size.y - h) > 0.5:
		custom_minimum_size.y = h
	if _panel.size.y != h or _panel.size.x != size.x:
		_panel.size = Vector2(size.x, h)

func _auszeichnen(text: String, farbe: Color) -> String:
	if _regex == null:
		_regex = RegEx.new()
		_regex.compile(r"(?i)(\d[\d.,]*\s?(?:€|%|Uhr)?|\b(?:" + "|".join(BEGRIFFE) + r")\b)")
	var hex := farbe.to_html(false)
	var aus := "[color=#%s]" % TEXTFARBE.to_html(false)
	var pos := 0
	for m in _regex.search_all(text):
		aus += _maskiert(text.substr(pos, m.get_start() - pos))
		aus += "[color=#%s]%s[/color]" % [hex, _maskiert(m.get_string())]
		pos = m.get_end()
	aus += _maskiert(text.substr(pos)) + "[/color]"
	return aus

func _maskiert(t: String) -> String:
	return t.replace("[", "[lb]")

func text() -> String:
	return _roh
