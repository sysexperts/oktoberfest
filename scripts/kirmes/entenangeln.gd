extends Node3D
## Entenangeln. Aufbau: scenes/kirmes/entenangeln.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Die Gummienten ziehen immer im Kreis (auch ohne Spieler). Beim Budenbesitzer E →
## Server bucht ab → Blick von oben aufs Becken. Die Maus führt die Angelspitze,
## Maustaste halten senkt den Haken. Hängt die Öse einer Ente am Haken, zieht
## Loslassen sie heraus. 3 Enten in 30 Sekunden; Wert je Ente 1–3, alle drei
## gefangen +1 → Punkte 0–10 → Preis vom Server wie bei der Schießbude.

@export var preis := 2
@export var hinweis := "HINT_ENTEN"
@export var faenge := 3
@export var zeit := 25.0
## Winkelgeschwindigkeit der Enten (rad/s)
@export var enten_tempo := 0.45
## Abstand Haken ↔ Öse (m), der noch fängt
@export var fangradius := 0.095
@export var maus_empfindlichkeit := 0.0028

const SPITZE_HOEHE := 1.05
const HAKEN_OBEN := 0.3
const HAKEN_UNTEN := 0.97
const OESE := 0.235

var _spieler: Node = null
var _zeit_rest := 0.0
var _gefangen := 0
var _wert := 0
var _ziel := Vector2(0.0, 1.2)
var _senken := false
var _tiefe := 0.0
var _am_haken: Node3D = null
var _ende_in := -1.0
var _t := 0.0
var _enten: Array[Node3D] = []
var _winkel := {}       # Ente -> Startwinkel
var _radius := {}       # Ente -> Kreisradius
var _raus := {}         # Ente -> true, solange sie im Korb liegt
## Letzter Hakenort im Becken-Raum (für tools/test_minispiel.tscn)
var haken_ort := Vector3.ZERO

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _zeitbalken: ProgressBar = $Anzeige/Zeit
@onready var _besitzer: Node3D = $Besitzer
@onready var _becken: Node3D = $Stand/Becken
@onready var _griff: Node3D = $Stand/Becken/Angel/Griff
@onready var _rute: Node3D = $Stand/Becken/Angel/Rute
@onready var _schnur: Node3D = $Stand/Becken/Angel/Schnur
@onready var _haken: Node3D = $Stand/Becken/Angel/Haken
@onready var _korb: Node3D = $Stand/Fangkorb

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	for e in $Stand/Becken/Enten.get_children():
		var ente := e as Node3D
		_enten.append(ente)
		_winkel[ente] = atan2(ente.position.x, ente.position.z)
		_radius[ente] = Vector2(ente.position.x, ente.position.z).length()
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position
	_angel_zeigen()

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_zeit_rest = zeit
	_gefangen = 0
	_wert = 0
	_ziel = Vector2(0.0, 1.2)
	_senken = false
	_tiefe = 0.0
	_am_haken = null
	_ende_in = -1.0
	_raus.clear()
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	_t += delta
	_enten_schwimmen()
	if _spieler == null:
		return
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()
			return
	else:
		_zeit_rest = maxf(0.0, _zeit_rest - delta)
		if _zeit_rest <= 0.0 and _am_haken == null:
			_ende_in = 0.6
	_tiefe = move_toward(_tiefe, 1.0 if _senken else 0.0, delta * (3.5 if _senken else 2.2))
	_angel_zeigen()
	if _am_haken == null and _tiefe > 0.85 and _ende_in < 0.0:
		for ente in _enten:
			if _raus.has(ente):
				continue
			var oese := ente.position + Vector3(0, OESE, 0)
			if Vector2(oese.x - haken_ort.x, oese.z - haken_ort.z).length() <= fangradius:
				_am_haken = ente
				_raus[ente] = true
				var sfx = get_tree().current_scene.get_node_or_null("Sfx")
				if sfx:
					sfx.play_oder("ding", "pop", -10.0)
				break
	if _am_haken:
		_am_haken.position = haken_ort - Vector3(0, OESE + 0.03, 0)
		if _tiefe < 0.05:
			_fang_fertig()
	_zeitbalken.value = 100.0 * _zeit_rest / zeit
	_info_neu()

func _enten_schwimmen() -> void:
	for i in _enten.size():
		var ente := _enten[i]
		if _raus.has(ente):
			continue
		var a: float = _winkel[ente] + _t * enten_tempo
		var r: float = _radius[ente]
		ente.position = Vector3(sin(a) * r, 0.015 * sin(_t * 3.0 + i), cos(a) * r)
		ente.rotation = Vector3(0.05 * sin(_t * 2.0 + i), a + PI / 2.0, 0.05 * cos(_t * 2.3 + i))

## Rute vom Griff zur Spitze, Schnur von der Spitze zum Haken.
func _angel_zeigen() -> void:
	var spitze := Vector3(_ziel.x, SPITZE_HOEHE, _ziel.y)
	haken_ort = spitze - Vector3(0, lerpf(HAKEN_OBEN, HAKEN_UNTEN, _tiefe), 0)
	_strecken(_rute, _griff.position, spitze)
	_strecken(_schnur, spitze, spitze + Vector3(0, -1.0, 0), (spitze - haken_ort).length())
	_haken.position = haken_ort

## Knoten mit Y-Achse von a nach b ausrichten und auf die Länge strecken.
func _strecken(n: Node3D, a: Vector3, b: Vector3, laenge := -1.0) -> void:
	var d := b - a
	var l := d.length() if laenge < 0.0 else laenge
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD)
	if x.length_squared() < 0.0001:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(y).normalized()
	n.transform = Transform3D(Basis(x, y * maxf(0.001, l), z), a)

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var sens := maus_empfindlichkeit * Einstellungen.maus
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		ziel_setzen(_ziel + Vector2(mm.relative.x * sens, mm.relative.y * sens * y_dir))
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT:
		_senken = mb.pressed

## Angelspitze im Becken setzen (auch für Tests)
func ziel_setzen(p: Vector2) -> void:
	_ziel = p.limit_length(1.65)

func senken_setzen(an: bool) -> void:
	_senken = an

func _fang_fertig() -> void:
	var ente := _am_haken
	_am_haken = null
	_gefangen += 1
	_wert += int(ente.get_meta("wert", 1))
	var korb := _becken.to_local(_korb.global_position)
	ente.position = korb + Vector3((_gefangen - 2) * 0.12, 0.02 + _gefangen * 0.02, 0.0)
	ente.rotation = Vector3(0, randf() * TAU, 0)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("cheer", "pop", -12.0)
	if _gefangen >= faenge:
		_ende_in = 1.2

func punkte() -> int:
	return mini(10, _wert + (1 if _gefangen >= faenge else 0))

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("ENTEN_ANZEIGE")) % [_gefangen, faenge, punkte(), ceili(_zeit_rest)]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_kamera.current = false
	_am_haken = null
	_senken = false
	_tiefe = 0.0
	_raus.clear()
	_ziel = Vector2(0.0, 1.2)
	_angel_zeigen()
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
