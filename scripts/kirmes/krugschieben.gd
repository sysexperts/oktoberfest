extends Node3D
## Krugschieben. Aufbau: scenes/kirmes/krugschieben.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → man steht am langen Schanktisch.
## Die Kraftanzeige pendelt; Linksklick schiebt den Maßkrug los. Er rutscht aus und
## bleibt in einem der Felder stehen (1/2/3 Punkte) — zu fest, und er fällt hinten
## herunter. 5 Versuche, Summe 0–15 → 0–10 Punkte → Preis vom Server.

@export var preis := 2
@export var hinweis := "HINT_KRUG"
@export var versuche := 5
## Anfangstempo bei voller Kraft (m/s)
@export var tempo_max := 4.2
## Bremsung durch Reibung (m/s²)
@export var reibung := 1.6
## So schnell pendelt die Kraftanzeige (je Sekunde, wird mit jedem Versuch schneller)
@export var pendel := 0.55
## Punktfelder: [Mitte z, Tiefe, Punkte] — wie im gebackenen Stand
@export var felder: Array = [[-1.85, 0.6, 1], [-2.375, 0.45, 2], [-2.75, 0.3, 3]]

var _spieler: Node = null
var _kraft := 0.0
var _kraft_dir := 1.0
var _versuch := 0
var _summe := 0
var _tempo := -1.0
var _reibung_jetzt := 1.6
var _faellt := 0.0
var _zeigen := -1.0
var _ende_in := -1.0
var _letzte := ""

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _krug: Node3D = $Stand/Krug
@onready var _start: Vector3 = ($Stand/KrugStart as Node3D).position
@onready var _kante: float = ($Stand/Tischende as Node3D).position.z
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _kraftbalken: ProgressBar = $Anzeige/Kraft
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
	_versuch = 0
	_summe = 0
	_letzte = ""
	_ende_in = -1.0
	_bereit()
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _bereit() -> void:
	_tempo = -1.0
	_faellt = 0.0
	_zeigen = -1.0
	_kraft = 0.0
	_kraft_dir = 1.0
	_krug.position = _start
	_krug.rotation = Vector3(0, PI / 2.0, 0)
	_krug.visible = true

func _process(delta: float) -> void:
	if _spieler == null:
		return
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()
		return
	if _tempo < 0.0 and _zeigen < 0.0:
		# Kraft pendelt 0 → 1 → 0, mit jedem Versuch etwas schneller
		_kraft += _kraft_dir * delta * pendel * (1.0 + _versuch * 0.12)
		if _kraft >= 1.0:
			_kraft = 1.0
			_kraft_dir = -1.0
		elif _kraft <= 0.0:
			_kraft = 0.0
			_kraft_dir = 1.0
		_kraftbalken.value = _kraft * 100.0
	elif _tempo >= 0.0:
		_krug.position.z -= _tempo * delta
		_tempo = maxf(0.0, _tempo - _reibung_jetzt * delta)
		if _krug.position.z < _kante:
			# über die Kante: fällt in den Korb
			_faellt += delta
			_krug.position.y -= delta * (2.0 + _faellt * 9.0)
			_krug.rotation.x += delta * 5.0
			if _faellt > 0.5:
				_wertung(0)
		elif _tempo <= 0.0:
			_wertung(feld_punkte(_krug.position.z))
	else:
		_zeigen -= delta
		if _zeigen < 0.0:
			if _versuch >= versuche:
				_ende_in = 0.6
			else:
				_bereit()
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		schieben()

## Krug mit der aktuellen Kraft losschieben — auch für Tests
func schieben() -> void:
	if _spieler == null or _tempo >= 0.0 or _zeigen >= 0.0 or _ende_in >= 0.0:
		return
	_tempo = maxf(0.05, _kraft) * tempo_max
	# Tisch ist nicht überall gleich glatt
	_reibung_jetzt = reibung * randf_range(0.97, 1.03)
	_sfx("swoosh", -6.0)

## Wie viele Punkte bringt ein Krug, der bei z (lokal) steht?
func feld_punkte(z: float) -> int:
	var beste := 0
	for f: Array in felder:
		if absf(z - float(f[0])) <= float(f[1]) / 2.0:
			beste = maxi(beste, int(f[2]))
	return beste

## Kraft, mit der der Krug genau bei z stehen bleibt (ohne Streuung) — für Tests
func kraft_fuer(z: float) -> float:
	var weg := _start.z - z
	return sqrt(2.0 * reibung * weg) / tempo_max

func _wertung(p: int) -> void:
	_tempo = -1.0
	_versuch += 1
	_summe += p
	_letzte = String(TranslationServer.translate("KRUG_FELD")) % p if p > 0 else String(TranslationServer.translate("KRUG_DANEBEN"))
	_krug.visible = _faellt == 0.0
	_zeigen = 1.2
	_sfx("cheer" if p == 3 else ("pop" if p > 0 else "klack"), -6.0)

func _sfx(name: String, db: float) -> void:
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder(name, "pop", db)

func punkte() -> int:
	return clampi(roundi(_summe * 10.0 / (versuche * 3.0)), 0, 10)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("KRUG_ANZEIGE")) % [mini(_versuch + 1, versuche), versuche, _summe, punkte(), _letzte]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_tempo = -1.0
	_krug.position = _start
	_krug.rotation = Vector3(0, PI / 2.0, 0)
	_krug.visible = true
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
