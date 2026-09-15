extends Node3D
## Dosenwerfen auf der Kirmes. Aufbau: scenes/kirmes/dosenwurf.tscn — gebackener
## Pavillon (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Ablauf: beim Budenbesitzer E → Server bucht ab → Blick über die Theke.
## Maus zielt, linke Maustaste halten lädt die Wurfkraft, loslassen wirft.
## 3 Bälle; die Dosen fallen wirklich um (Physik). Punkte 0–10 = Anteil umgeworfener
## Dosen → Preis vom Server (wie bei der Schießbude). Nur beim Werfer.

@export var preis := 2
@export var hinweis := "HINT_DOSENWURF"
@export var baelle := 3
@export var schwenk := Vector2(30.0, 18.0)
@export var maus_empfindlichkeit := 0.0022
## Wurfgeschwindigkeit (m/s) ohne und mit voller Ladung
@export var wurf_tempo := Vector2(5.5, 12.0)
## Sekunden, bis die volle Kraft geladen ist
@export var ladezeit := 1.0

const BALL := preload("res://scenes/kirmes/wurfball.tscn")

var _spieler: Node = null
var _uebrig := 0
var _laden := -1.0
var _warten := 0.0
var _yaw := 0.0
var _pitch := 0.0
var _kamera_grund := Transform3D()
var _dosen: Array[RigidBody3D] = []
var _startlagen := {}
var _baelle: Array[Node] = []

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _kraft: ProgressBar = $Anzeige/Kraft
@onready var _fadenkreuz: Control = $Anzeige/Fadenkreuz
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_kamera_grund = _kamera.transform
	for d in $Stand/Dosen.get_children():
		_dosen.append(d as RigidBody3D)
		_startlagen[d] = (d as Node3D).transform
		(d as RigidBody3D).freeze = true
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_uebrig = baelle
	_laden = -1.0
	_warten = 0.0
	_yaw = 0.0
	_pitch = 0.0
	for b in _baelle:
		if is_instance_valid(b):
			b.queue_free()
	_baelle.clear()
	# Dosen neu aufstellen, Physik an
	for d in _dosen:
		d.freeze = true
		d.transform = _startlagen[d]
		d.linear_velocity = Vector3.ZERO
		d.angular_velocity = Vector3.ZERO
		d.freeze = false
		d.sleeping = true
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	if _spieler == null:
		return
	_kamera.transform = _kamera_grund * Transform3D(Basis.from_euler(Vector3(_pitch, _yaw, 0.0)), Vector3.ZERO)
	_fadenkreuz.position = get_viewport().get_visible_rect().size / 2.0 - _fadenkreuz.size / 2.0
	if _laden >= 0.0:
		_laden = minf(1.0, _laden + delta / ladezeit)
	_kraft.value = maxf(0.0, _laden) * 100.0
	if _uebrig <= 0:
		_warten -= delta
		if _warten <= 0.0:
			_beenden()
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var sens := maus_empfindlichkeit * Einstellungen.maus
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		_yaw = clampf(_yaw - mm.relative.x * sens, -deg_to_rad(schwenk.x), deg_to_rad(schwenk.x))
		_pitch = clampf(_pitch - mm.relative.y * sens * y_dir, -deg_to_rad(schwenk.y), deg_to_rad(schwenk.y))
		return
	var mb := event as InputEventMouseButton
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or _uebrig <= 0:
		return
	if mb.pressed:
		_laden = 0.0
	elif _laden >= 0.0:
		_werfen(_laden)
		_laden = -1.0

func _werfen(kraft: float) -> void:
	_uebrig -= 1
	var ball := BALL.instantiate() as RigidBody3D
	$Stand.add_child(ball)
	var vorn := -_kamera.global_transform.basis.z
	ball.global_position = _kamera.global_position + vorn * 0.5 + Vector3(0.15, -0.2, 0)
	ball.linear_velocity = vorn * lerpf(wurf_tempo.x, wurf_tempo.y, kraft) + Vector3.UP * 1.2
	ball.angular_velocity = Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	_baelle.append(ball)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("wurf", "pop", -12.0)
	if _uebrig <= 0:
		_warten = 3.0   # Dosen noch fallen lassen, dann zählen

## Umgeworfen: deutlich unter die Startlage gefallen oder vom Platz geschoben.
func _umgeworfen() -> int:
	var n := 0
	for d in _dosen:
		var start: Transform3D = _startlagen[d]
		if d.position.y < start.origin.y - 0.1 or Vector2(d.position.x - start.origin.x, d.position.z - start.origin.z).length() > 0.2:
			n += 1
	return n

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("DOSENWURF_ANZEIGE")) % [_umgeworfen(), _dosen.size(), _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var punkte := roundi(10.0 * float(_umgeworfen()) / float(maxi(1, _dosen.size())))
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte)
	_anzeige.visible = false
	_kamera.current = false
	_kamera.transform = _kamera_grund
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
