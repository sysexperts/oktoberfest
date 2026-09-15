extends Node3D
## Bierfass-Kegeln. Aufbau: scenes/kirmes/kegeln.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → Blick die Bahn hinunter. Maus links/rechts
## zielt, Maustaste halten lädt die Kraft, loslassen rollt die Kugel. 2 Würfe; die
## Fässchen fallen wirklich (Physik). Punkte = umgefallene Fässchen, alle 9 → 10 →
## Preis vom Server wie bei der Schießbude. Nur beim Werfer.

@export var preis := 2
@export var hinweis := "HINT_KEGELN"
@export var wuerfe := 2
## Seitlicher Zielwinkel (Grad)
@export var schwenk := 9.0
@export var maus_empfindlichkeit := 0.0018
## Rolltempo (m/s) ohne und mit voller Ladung
@export var roll_tempo := Vector2(2.2, 6.0)
@export var ladezeit := 1.0

const KUGEL := preload("res://scenes/kirmes/kegelkugel.tscn")
## Kugel zählt als durch, wenn sie so weit hinten ist oder so langsam rollt
const HINTEN_Z := -2.95

var _spieler: Node = null
var _uebrig := 0
var _laden := -1.0
var _yaw := 0.0
var _kamera_grund := Transform3D()
var _kegel: Array[RigidBody3D] = []
var _startlagen := {}
var _kugel: RigidBody3D = null
var _rollt := 0.0
var _ende_in := -1.0

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _kraft: ProgressBar = $Anzeige/Kraft
@onready var _besitzer: Node3D = $Besitzer
@onready var _wurfpunkt: Node3D = $Stand/Wurfpunkt

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_kamera_grund = _kamera.transform
	for k in $Stand/Kegel.get_children():
		var kg := k as RigidBody3D
		_kegel.append(kg)
		_startlagen[kg] = kg.transform
		kg.freeze = true
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_uebrig = wuerfe
	_laden = -1.0
	_yaw = 0.0
	_ende_in = -1.0
	_kugel_weg()
	for kg in _kegel:
		kg.freeze = true
		kg.transform = _startlagen[kg]
		kg.linear_velocity = Vector3.ZERO
		kg.angular_velocity = Vector3.ZERO
		kg.freeze = false
		kg.sleeping = true
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	if _spieler == null:
		return
	_kamera.transform = _kamera_grund * Transform3D(Basis(Vector3.UP, _yaw), Vector3.ZERO)
	if _laden >= 0.0:
		_laden = minf(1.0, _laden + delta / ladezeit)
	_kraft.value = maxf(0.0, _laden) * 100.0
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()
			return
	elif _kugel:
		_rollt += delta
		var lokal := to_local(_kugel.global_position)
		var langsam := _kugel.linear_velocity.length() < 0.15 and _rollt > 1.0
		if lokal.z < HINTEN_Z or langsam or _rollt > 6.0 or lokal.y < -0.5:
			# Fässchen noch nachfallen lassen
			if _rollt > 0.0:
				_rollt = -2.0
		if _rollt < 0.0 and _rollt + delta >= 0.0:
			_kugel_weg()
			if _uebrig <= 0 or umgefallen() >= _kegel.size():
				_ende_in = 1.0
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var sens := maus_empfindlichkeit * Einstellungen.maus
		_yaw = clampf(_yaw - mm.relative.x * sens, -deg_to_rad(schwenk), deg_to_rad(schwenk))
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or _uebrig <= 0 or _kugel != null or _ende_in >= 0.0:
		return
	if mb.pressed:
		_laden = 0.0
	elif _laden >= 0.0:
		rollen(_laden, _yaw)
		_laden = -1.0

## Kugel rollen (auch für Tests): kraft 0–1, Richtung als Winkel um die Hochachse
func rollen(kraft: float, yaw: float) -> void:
	if _spieler == null or _uebrig <= 0 or _kugel != null or _ende_in >= 0.0:
		return
	_uebrig -= 1
	_kugel = KUGEL.instantiate() as RigidBody3D
	$Stand.add_child(_kugel)
	_kugel.global_position = _wurfpunkt.global_position
	var richtung := global_transform.basis * Basis(Vector3.UP, yaw) * Vector3(0, 0, -1)
	_kugel.linear_velocity = richtung.normalized() * lerpf(roll_tempo.x, roll_tempo.y, kraft)
	_kugel.angular_velocity = global_transform.basis * Basis(Vector3.UP, yaw) * Vector3(-lerpf(roll_tempo.x, roll_tempo.y, kraft) / 0.095, 0, 0)
	_rollt = 0.001
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("wurf", "pop", -10.0)

func _kugel_weg() -> void:
	if _kugel and is_instance_valid(_kugel):
		_kugel.queue_free()
	_kugel = null
	_rollt = 0.0

## Umgefallen: deutlich gekippt oder vom Platz geschoben
func umgefallen() -> int:
	var n := 0
	for kg in _kegel:
		var start: Transform3D = _startlagen[kg]
		var oben := kg.transform.basis.y.normalized()
		if oben.dot(Vector3.UP) < 0.8 or Vector2(kg.position.x - start.origin.x, kg.position.z - start.origin.z).length() > 0.12:
			n += 1
	return n

func punkte() -> int:
	var n := umgefallen()
	return 10 if n >= _kegel.size() else n

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("KEGELN_ANZEIGE")) % [umgefallen(), _kegel.size(), _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_kamera.current = false
	_kamera.transform = _kamera_grund
	_kugel_weg()
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
