extends Control
## Eine Meldung im Stapel unter der Aufgabenkarte am rechten Rand: kein Kasten, nur ein
## weicher dunkler Verlauf hinter rechtsbündigem Text und ein Farbstrich am Rand.
## Gleitet von rechts herein und wieder hinaus.
## Zahlen, Beträge und Spielbegriffe sind in der Randfarbe hervorgehoben.
## Aufbau: scenes/ui/meldung.tscn.

## Randfarbe je Art: 0 Info (Gold), 1 Problem (Rot), 2 Erfolg (Grün)
const FARBEN := [Color(1, 0.839, 0.349), Color(1, 0.42, 0.35), Color(0.55, 0.93, 0.55)]
const TEXTFARBE := Color(0.9, 0.87, 0.8)
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
	%Text.text = "[right]" + _auszeichnen(text, farbe) + "[/right]"
	%Strich.color = Color(farbe.r, farbe.g, farbe.b, 0.9)
	modulate.a = 0.0
	_panel.position.x = 60.0
	_passen.call_deferred()
	# Hinein: gleitet von rechts, Balken läuft ab
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.25)
	tw.parallel().tween_property(_panel, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Hinaus: nach der Dauer wieder nach rechts weg
	tw.tween_interval(dauer)
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
		aus += "[color=#%s]%s[/color]" % [hex, _maskiert(m.get_string().replace(" ", "00a0"))]
		pos = m.get_end()
	aus += _maskiert(text.substr(pos)) + "[/color]"
	return aus

func _maskiert(t: String) -> String:
	return t.replace("[", "[lb]")

func text() -> String:
	return _roh
