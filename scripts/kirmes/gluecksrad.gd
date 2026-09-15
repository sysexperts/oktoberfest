extends Node3D
## Glücksrad mit Timing. Aufbau: scenes/kirmes/gluecksrad.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → Blick aufs Rad. Das Rad dreht; Linksklick
## zieht die Bremse, danach läuft es noch gut eine Runde nach (etwas Zufall). Wer
## vorausdenkt, landet oben auf der 10. 2 Drehungen, die zweite schneller; das beste Feld
## zählt (0–10) → Preis vom Server wie bei der Schießbude.

## Etwas teurer: auch blindes Klicken trifft ab und zu die 10 (Teddy 20 €)
@export var preis := 3
@export var hinweis := "HINT_GLUECKSRAD"
@export var drehungen := 2
## Drehtempo (rad/s) bei der ersten und letzten Drehung
@export var tempo := Vector2(4.5, 7.5)
## So weit (rad) läuft das Rad nach dem Klick noch, ± Zufall
@export var bremsweg := 8.5
@export var bremsweg_zufall := 0.35

## Feldwerte im Uhrzeigersinn ab oben (tools/bake_kirmes_spiele.gd, RAD_WERTE)
const WERTE := [1, 2, 0, 1, 5, 0, 1, 2, 10, 0, 1, 3, 0, 2, 1, 0]
const FELD := TAU / 16.0

enum { DREHT, BREMST, ZEIGT }

var _spieler: Node = null
var _uebrig := 0
var _bester := 0
var _winkel := 0.0
var _zustand := DREHT
var _brems_start := 0.0
var _brems_weg := 0.0
var _brems_dauer := 1.0
var _brems_t := 0.0
var _zeigen := 0.0

@onready var _rad: Node3D = $Stand/Rad
@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _ergebnis: Label = $Anzeige/Ergebnis
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_uebrig = drehungen
	_bester = 0
	_zustand = DREHT
	_kamera.current = true
	_anzeige.visible = true
	_ergebnis.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

## Tempo der laufenden Drehung
func runde_tempo() -> float:
	return lerpf(tempo.x, tempo.y, float(drehungen - _uebrig) / float(maxi(1, drehungen - 1)))

func _process(delta: float) -> void:
	if _spieler == null:
		# Ohne Spieler dreht es gemächlich — lockt Besucher an
		_winkel += delta * 0.35
		_rad.rotation.z = _winkel
		return
	match _zustand:
		DREHT:
			_winkel += delta * runde_tempo()
		BREMST:
			_brems_t = minf(1.0, _brems_t + delta / _brems_dauer)
			# gleichmäßig bremsen: Weg = Tempo·t − ½·a·t²
			_winkel = _brems_start + _brems_weg * (1.0 - pow(1.0 - _brems_t, 2.0))
			if _brems_t >= 1.0:
				_ergebnis_zeigen()
		ZEIGT:
			_zeigen -= delta
			if _zeigen <= 0.0:
				if _uebrig <= 0:
					_beenden()
					return
				_zustand = DREHT
				_ergebnis.visible = false
	_rad.rotation.z = _winkel
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		anhalten()

## Bremse ziehen (auch für Tests)
func anhalten() -> void:
	if _spieler == null or _zustand != DREHT or _uebrig <= 0:
		return
	var v := runde_tempo()
	_uebrig -= 1
	_zustand = BREMST
	_brems_start = _winkel
	_brems_weg = bremsweg + randf_range(-bremsweg_zufall, bremsweg_zufall)
	# Bremsdauer so, dass das Rad ohne Ruck vom Drehtempo aus abbremst
	_brems_dauer = 2.0 * _brems_weg / v
	_brems_t = 0.0
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("klick", "pop", -10.0)

## Feld unter dem Zeiger
func feld_oben() -> int:
	return posmod(roundi(_winkel / FELD), WERTE.size())

func _ergebnis_zeigen() -> void:
	var wert: int = WERTE[feld_oben()]
	_bester = maxi(_bester, wert)
	_zustand = ZEIGT
	_zeigen = 1.4
	_ergebnis.text = String(TranslationServer.translate("GLUECKSRAD_FELD")) % wert
	_ergebnis.visible = true
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		if wert >= 5:
			sfx.play("ding")
			sfx.play_oder("cheer", "pop", -6.0)
		else:
			sfx.play_oder("pop", "pop", -8.0)

func punkte() -> int:
	return mini(10, _bester)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("GLUECKSRAD_ANZEIGE")) % [_bester, _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_kamera.current = false
	_zustand = DREHT
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
