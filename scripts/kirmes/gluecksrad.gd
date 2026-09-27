extends Node3D
## Glücksrad — reines Glücksspiel. Aufbau: scenes/kirmes/gluecksrad.tscn — gebackener
## Stand (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige mit vier Einsatzknöpfen.
##
## Beim Budenbesitzer E → Blick aufs Rad. Einsatz wählen (1/10/100/1.000 €) → der
## Server zieht ihn ab, würfelt das Feld und bucht den Gewinn (GameManager.
## net_gluecksrad_setzen). Hier dreht das Rad nur noch sichtbar dorthin — der Spieler
## hat keinen Einfluss, darum lässt sich nichts ausnutzen. Esc beendet.

## Eintritt kostet nichts, bezahlt wird je Drehung
@export var preis := 0
@export var hinweis := "HINT_GLUECKSRAD"
## So lange (s) dreht das Rad bis zum Ergebnis
@export var drehdauer := 3.2
## Volle Umdrehungen bis zum Ziel
@export var umdrehungen := 4

## Markiert den Stand für den Server: abgerechnet wird je Einsatz, nicht nach Treffern
const Texte := preload("res://scripts/ui/texte.gd")

var glueckspiel := true

## Faktor ×10 je Feld im Uhrzeigersinn ab oben (tools/bake_kirmes_spiele.gd, RAD_WERTE;
## GameManager.GLUECK_FELDER)
const WERTE := [0, 20, 10, 0, 15, 10, 0, 50, 0, 10, 20, 0, 10, 0, 10, 0]
const FELD := TAU / 16.0
const EINSAETZE := [1, 10, 100, 1000]

enum { WARTET, DREHT, ZEIGT }

var _spieler: Node = null
var _winkel := 0.0
var _zustand := WARTET
var _start := 0.0
var _ziel := 0.0
var _t := 0.0
var _zeigen := 0.0
var _einsatz := 0
var _gewinn := 0

@onready var _rad: Node3D = $Stand/Rad
@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _ergebnis: Label = $Anzeige/Ergebnis
@onready var _knoepfe: Array[Button] = [$Anzeige/Einsaetze/Einsatz1, $Anzeige/Einsaetze/Einsatz10,
	$Anzeige/Einsaetze/Einsatz100, $Anzeige/Einsaetze/Einsatz1000]
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position
	for i in _knoepfe.size():
		_knoepfe[i].pressed.connect(setzen.bind(EINSAETZE[i]))

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_zustand = WARTET
	_kamera.current = true
	_anzeige.visible = true
	_ergebnis.visible = false
	# Maus frei für die Einsatzknöpfe
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_knoepfe_frei(true)
	_knoepfe[0].grab_focus.call_deferred()
	_info.text = tr("GLUECKSRAD_SETZEN")

## Einsatz wählen → Server entscheidet (GameManager.net_gluecksrad_setzen)
func setzen(einsatz: int) -> void:
	if _spieler == null or _zustand == DREHT:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_gluecksrad_setzen"):
		_knoepfe_frei(false)
		welt.net_gluecksrad_setzen.rpc_id(1, einsatz)
		# Kommt keine Antwort (kein Geld), Knöpfe nach kurzer Zeit wieder frei
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			if _zustand != DREHT and _spieler != null:
				_knoepfe_frei(true))

## Antwort vom Server: auf dieses Feld drehen
func drehen_auf(feld: int, einsatz: int, gewinn: int) -> void:
	if _spieler == null:
		return
	_einsatz = einsatz
	_gewinn = gewinn
	_ergebnis.visible = false
	_knoepfe_frei(false)
	# Ziel: nächster Winkel mit diesem Feld oben, plus volle Umdrehungen
	var basis := feld * FELD
	var ziel := basis + TAU * ceilf((_winkel - basis) / TAU)
	_start = _winkel
	_ziel = ziel + TAU * umdrehungen
	_t = 0.0
	_zustand = DREHT
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("klick", "pop", -10.0)

func _process(delta: float) -> void:
	if _spieler == null or _zustand == WARTET:
		# Ohne Spieler bzw. vor dem Einsatz dreht es gemächlich — lockt Besucher an
		_winkel += delta * 0.35
		_rad.rotation.z = _winkel
		return
	match _zustand:
		DREHT:
			_t = minf(1.0, _t + delta / drehdauer)
			# weich auslaufen
			_winkel = lerpf(_start, _ziel, 1.0 - pow(1.0 - _t, 3.0))
			if _t >= 1.0:
				_winkel = fmod(_ziel, TAU)
				_ergebnis_zeigen()
		ZEIGT:
			_zeigen -= delta
			if _zeigen <= 0.0:
				_zustand = WARTET
				_ergebnis.visible = false
	_rad.rotation.z = _winkel

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	# Zifferntasten 1–4 als Abkürzung
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode >= KEY_1 and k.keycode <= KEY_4:
		setzen(EINSAETZE[k.keycode - KEY_1])

## Feld unter dem Zeiger
func feld_oben() -> int:
	return posmod(roundi(_winkel / FELD), WERTE.size())

func _ergebnis_zeigen() -> void:
	_zustand = ZEIGT
	_zeigen = 1.6
	var faktor: int = WERTE[feld_oben()]
	if _gewinn > _einsatz:
		var f := str(faktor / 10) if faktor % 10 == 0 else "%d,%d" % [faktor / 10, faktor % 10]
		_ergebnis.text = tr("GLUECKSRAD_GEWINN") % [f, Texte.euro(_gewinn - _einsatz)]
	elif _gewinn == _einsatz:
		_ergebnis.text = tr("GLUECKSRAD_ZURUECK")
	else:
		_ergebnis.text = tr("GLUECKSRAD_VERLOREN") % Texte.euro(_einsatz)
	_ergebnis.visible = true
	_knoepfe_frei(true)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		if faktor >= 20:
			sfx.play("ding")
			sfx.play_oder("cheer", "pop", -6.0)
		else:
			sfx.play_oder("pop", "pop", -8.0)

func _knoepfe_frei(an: bool) -> void:
	for i in _knoepfe.size():
		_knoepfe[i].disabled = not an or Game.money < int(EINSAETZE[i])

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, 0)
	_anzeige.visible = false
	_kamera.current = false
	_zustand = WARTET
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
