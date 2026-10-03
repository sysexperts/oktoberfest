extends CanvasLayer
## Festkalender (Taste K, am Controller Steuerkreuz unten): die 16 Tage der Saison als
## Karten mit Symbol und Ereignis (GameManager._plan) und Bankraten. Heute leuchtet und
## trägt ein „HEUTE"-Band, vergangene Tage sind blass mit Haken. Maus oder Steuerkreuz
## wählt eine Karte, unten steht dann die Beschreibung. Beim Öffnen gleitet das Fenster
## herein, die Karten kommen nacheinander, der Saisonbalken füllt sich.
## Aufbau: scenes/ui/kalender.tscn (16 Karten kalender_tag.tscn, Tag1 … Tag16).

const Texte := preload("res://scripts/ui/texte.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")

## Ereignis → [Symbol, Farbe]. Grün = gut fürs Geschäft, Rot = Ärger, Blau = besonderer Anlass,
## Gold = Stimmung/Neutral.
const GRUEN := Color(0.55, 0.93, 0.55)
const ROT := Color(1, 0.45, 0.38)
const BLAU := Color(0.55, 0.75, 1.0)
const GOLD := Color(1, 0.839, 0.349)
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

var _tween: Tween
var _auswahl: Button

@onready var _fenster: Control = %Fenster

func _ready() -> void:
	add_to_group("kalender")
	for k in %Tage.get_children():
		(k as Button).gewaehlt.connect(_detail_zeigen)

func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action("kalender") and event.is_action_pressed("kalender"):
		if visible:
			schliessen()
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			zeigen()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		schliessen()
		get_viewport().set_input_as_handled()

func schliessen() -> void:
	if not visible:
		return
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func zeigen() -> void:
	var gm := get_parent()
	var z: Dictionary = gm._hud._zustand if "_hud" in gm and gm._hud else {}
	var plan: Array = z.get("plan", [])
	var tag_heute := Wirtschaft.saison_tag(int(z.get("day", 1)))
	var saison_start := int(z.get("day", 1)) - tag_heute + 1
	var raten := {}
	var faktor: float = [0.6, 1.0, 1.3][clampi(int(gm._schwierigkeit), 0, 2)] if "_schwierigkeit" in gm else 1.0
	if int(z.get("saison_nr", 1)) == 1:
		var offen: Array = z.get("bank_naechste", [])
		for r: Array in Wirtschaft.BANK_RATEN:
			if offen.is_empty() or int(r[0]) < int(offen[0]):
				continue   # schon bezahlt
			raten[int(r[0])] = roundi(float(r[1]) * faktor / 100.0) * 100
	%Titel.text = tr("KALENDER_TITEL")
	%Legende.text = tr("KALENDER_LEGENDE")
	%FortschrittText.text = tr("KALENDER_FORTSCHRITT") % [tag_heute, Wirtschaft.SAISON_TAGE]
	var heute_karte: Button = null
	for i in 16:
		var tag := i + 1
		var karte := %Tage.get_child(i) as Button
		var ereignis := str(plan[i]) if i < plan.size() else ""
		var symbol := ""
		var farbe := GOLD
		var titel := ""
		var text := ""
		if ereignis != "" and ARTEN.has(ereignis):
			symbol = ARTEN[ereignis][0]
			farbe = ARTEN[ereignis][1]
			titel = tr("EREIGNIS_%s_TITEL" % ereignis.to_upper())
			text = tr("EREIGNIS_%s_START" % ereignis.to_upper())
		elif tag == 1:
			symbol = "fass"
			titel = tr("KALENDER_ERSTER")
			text = tr("EREIGNIS_ANSTICH_START")
		else:
			titel = ""
			text = tr("KALENDER_NORMAL")
		var extras := ""
		var extra_detail := ""
		if raten.has(tag):
			extras = tr("KALENDER_BANK") % Texte.euro(int(raten[tag]))
			extra_detail = tr("KALENDER_BANK_DETAIL") % Texte.euro(int(raten[tag]))
		karte.setzen(saison_start + i, titel, symbol, farbe, extras, tag < tag_heute, tag == tag_heute)
		karte.detail_titel = titel if titel != "" else tr("KALENDER_NORMAL_TITEL")
		karte.detail_text = text + ("\n" + extra_detail if extra_detail != "" else "")
		karte.detail_symbol = symbol
		karte.detail_farbe = farbe
		if tag == tag_heute:
			heute_karte = karte
	_auswahl = null
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if heute_karte:
		heute_karte.grab_focus()
		_detail_zeigen(heute_karte)
	_einfliegen(tag_heute)

func _detail_zeigen(karte: Button) -> void:
	if karte == _auswahl:
		return
	_auswahl = karte
	%DetailTitel.text = "%s · %s" % [tr("KALENDER_TAG") % karte.tag_nummer, karte.detail_titel]
	%DetailText.text = karte.detail_text
	var bild: Texture2D = null
	if karte.detail_symbol != "":
		bild = load("res://assets/ui/symbole/%s.svg" % karte.detail_symbol)
	%DetailSymbol.texture = bild
	%DetailSymbol.self_modulate = karte.detail_farbe

## Fenster gleitet herein, Karten kommen gestaffelt, der Balken füllt sich
func _einfliegen(tag_heute: int) -> void:
	if _tween:
		_tween.kill()
	_fenster.pivot_offset = _fenster.size * 0.5
	_fenster.scale = Vector2(0.92, 0.92)
	_fenster.modulate.a = 0.0
	%Abdunkeln.modulate.a = 0.0
	%Balken.value = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_fenster, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_fenster, "modulate:a", 1.0, 0.25)
	_tween.tween_property(%Abdunkeln, "modulate:a", 1.0, 0.3)
	_tween.tween_property(%Balken, "value", 100.0 * float(tag_heute) / float(Wirtschaft.SAISON_TAGE), 0.9)\
		.set_delay(0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in 16:
		(%Tage.get_child(i) as Button).einfliegen(0.12 + i * 0.03)
