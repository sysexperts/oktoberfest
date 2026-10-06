extends Control
## Kalender-App des Desktops: heute und die nächsten 15 Tage als Karten mit Ereignis (Plan aus dem HUD-Zustand), heute hervorgehoben. Unten steht die Beschreibung der angewählten Karte. Löst den alten Festkalender (Taste K) ab.
## Aufbau: scenes/ui/desktop_kalender.tscn, eine Karte ist scenes/ui/kalender_karte.tscn.

const Wirtschaft := preload("res://scripts/wirtschaft.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")
const ANZEIGE_TAGE := 16
const KARTE := preload("res://scenes/ui/kalender_karte.tscn")

## Farben: Grün = gut fürs Geschäft, Rot = Ärger, Blau = besonderer Anlass, Gold = Stimmung
const GRUEN := Color(0.55, 0.93, 0.55)
const ROT := Color(1, 0.45, 0.38)
const BLAU := Color(0.55, 0.75, 1.0)
const GOLD := Color(1, 0.839, 0.349)
## Ereignis → [Symbol, Farbe]
const ARTEN := {
	"anstich": ["fass", GOLD],
	"tracht": ["fahne", BLAU],
	"familie": ["leute", GRUEN],
	"italiener": ["wagen", GOLD],
	"finale": ["pokal", GOLD],
	"regen": ["info", BLAU],
	"bus": ["wagen", GOLD],
	"kontrolle": ["besen", ROT],
	"happy": ["bier", GRUEN],
	"fass": ["fass", ROT],
	"prosit": ["musik", GOLD],
	"promi": ["stern", GRUEN],
}

var _gm: Node
var _hud: Node
var _stand := ""
var _auswahl: Button

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_stand = ""
	_pruefen()

func _process(_delta: float) -> void:
	if visible:
		_pruefen()

func _pruefen() -> void:
	var z: Dictionary = _hud.get("_zustand") if _hud != null else {}
	var stand := "%s|%s" % [z.get("day", 1), z.get("plan", [])]
	if stand == _stand:
		return
	_stand = stand
	_anzeigen(z)

func _anzeigen(z: Dictionary) -> void:
	var plan: Array = z.get("plan", [])
	var heute := int(z.get("day", 1))
	for k in %Tage.get_children():
		k.queue_free()
	_auswahl = null
	var heute_karte: Button = null
	# Es gibt keine feste Saison mehr: gezeigt wird heute und die nächsten Tage, der Plan wiederholt sich
	for i in ANZEIGE_TAGE:
		var tag := heute + i
		var idx := Wirtschaft.saison_tag(tag) - 1
		var ereignis := str(plan[idx]) if idx < plan.size() else ""
		var symbol := ""
		var farbe := GOLD
		var titel := ""
		var text := tr("KALENDER_NORMAL")
		if ereignis != "" and ARTEN.has(ereignis):
			symbol = ARTEN[ereignis][0]
			farbe = ARTEN[ereignis][1]
			titel = tr("EREIGNIS_%s_TITEL" % ereignis.to_upper())
			text = tr("EREIGNIS_%s_START" % ereignis.to_upper())
		elif tag == 1:
			symbol = "fass"
			titel = tr("KALENDER_ERSTER")
			text = tr("EREIGNIS_ANSTICH_START")
		var karte := KARTE.instantiate() as Button
		%Tage.add_child(karte)
		karte.gewaehlt.connect(_detail_zeigen)
		karte.setzen(tag, titel, symbol, farbe, false, i == 0)
		karte.detail_titel = titel if titel != "" else tr("KALENDER_NORMAL_TITEL")
		karte.detail_text = text
		karte.detail_symbol = symbol
		karte.detail_farbe = farbe
		if i == 0:
			heute_karte = karte
	if heute_karte:
		_detail_zeigen(heute_karte)

func _detail_zeigen(karte: Button) -> void:
	if karte == _auswahl:
		return
	_auswahl = karte
	%DetailTitel.text = "%s · %s" % [tr("KALENDER_TAG") % karte.tag_nummer, karte.detail_titel]
	%DetailText.text = karte.detail_text
	%DetailSymbol.texture = Symbole.bild(karte.detail_symbol) if karte.detail_symbol != "" else null
	%DetailSymbol.self_modulate = karte.detail_farbe
