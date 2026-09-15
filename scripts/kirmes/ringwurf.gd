extends Node3D
## Ringwerfen auf Maßkrüge. Aufbau: scenes/kirmes/ringwurf.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Ablauf: beim Budenbesitzer E → Server bucht ab → Blick über die Theke.
## Maus zielt, linke Maustaste halten lädt die Wurfkraft, loslassen wirft einen Ring
## im Bogen. Fällt er über einen Krug, bleibt er dort hängen. 5 Ringe, jeder Treffer
## 2 Punkte (0–10) → Preis vom Server wie bei der Schießbude. Nur beim Werfer.

@export var preis := 2
@export var hinweis := "HINT_RINGWURF"
@export var ringe := 5
@export var schwenk := Vector2(22.0, 14.0)
@export var maus_empfindlichkeit := 0.0022
## Abwurftempo (m/s) ohne und mit voller Ladung
@export var wurf_tempo := Vector2(3.5, 8.0)
@export var ladezeit := 1.1
## Wie weit die Ringmitte neben der Krugmitte liegen darf
@export var trefferradius := 0.1

const RING := preload("res://scenes/kirmes/wurfring.tscn")
const SCHWERKRAFT := 9.8
const FARBEN := [Color(0.85, 0.15, 0.12), Color(0.15, 0.35, 0.8), Color(0.95, 0.75, 0.25)]

var _spieler: Node = null
var _uebrig := 0
var _treffer := 0
var _laden := -1.0
var _warten := 0.0
var _yaw := 0.0
var _pitch := 0.0
var _kamera_grund := Transform3D()
var _ziele: Array[Node3D] = []
var _ringe: Array[Node3D] = []
## Fliegender Ring: Knoten, Geschwindigkeit (global)
var _flug: Node3D = null
var _flug_v := Vector3.ZERO
## Wo der letzte Ring gelandet ist (lokal, für tools/test_minispiel.tscn)
var letzte_landung := Vector3.ZERO

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
	for z in $Stand/Krugziele.get_children():
		_ziele.append(z as Node3D)
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_uebrig = ringe
	_treffer = 0
	_laden = -1.0
	_warten = 0.0
	_yaw = 0.0
	_pitch = 0.0
	_flug = null
	for r in _ringe:
		if is_instance_valid(r):
			r.queue_free()
	_ringe.clear()
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
	if _flug:
		_fliegen(delta)
	elif _uebrig <= 0:
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
	if mb == null or mb.button_index != MOUSE_BUTTON_LEFT or _uebrig <= 0 or _flug != null:
		return
	if mb.pressed:
		_laden = 0.0
	elif _laden >= 0.0:
		werfen(_laden)
		_laden = -1.0

## Wirft einen Ring in Blickrichtung (auch für Tests aufrufbar).
func werfen(kraft: float) -> void:
	if _uebrig <= 0 or _flug != null:
		return
	_uebrig -= 1
	var ring := RING.instantiate() as Node3D
	$Stand.add_child(ring)
	var mi := ring.get_node("Ring") as MeshInstance3D
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FARBEN[_uebrig % FARBEN.size()]
	mat.roughness = 0.5
	mi.material_override = mat
	var basis := _kamera.global_transform.basis
	var vorn := -basis.z
	ring.global_position = _kamera.global_position + vorn * 0.45 - basis.y * 0.25
	# Leicht nach oben abwerfen, damit der Ring im Bogen von oben auf die Krüge fällt
	_flug_v = (vorn + Vector3.UP * 0.55).normalized() * lerpf(wurf_tempo.x, wurf_tempo.y, kraft)
	_flug = ring
	_ringe.append(ring)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("wurf", "pop", -14.0)

func _fliegen(delta: float) -> void:
	var vorher := _flug.global_position
	_flug_v.y -= SCHWERKRAFT * delta
	var nachher := vorher + _flug_v * delta
	_flug.global_position = nachher
	_flug.rotate_y(delta * 9.0)
	# Treffer: Ring sinkt durch die Höhe eines Krugrands, Mitte nah genug an der Krugachse
	if _flug_v.y < 0.0:
		for z in _ziele:
			var zp := z.global_position
			if vorher.y >= zp.y and nachher.y < zp.y:
				var t := (vorher.y - zp.y) / maxf(0.0001, vorher.y - nachher.y)
				var p := vorher.lerp(nachher, t)
				if Vector2(p.x - zp.x, p.z - zp.z).length() <= trefferradius:
					_landen(zp - Vector3(0, 0.12, 0), true)
					return
	# Daneben: auf Theke, Stufe oder Boden gelandet (grob) oder hinten raus
	var lokal := to_local(nachher)
	var auf_theke := lokal.z > -0.2 and lokal.z < 0.3 and lokal.y < 1.24 and absf(lokal.x) < 2.6
	if lokal.y < 0.25 or lokal.z < -3.0 or auf_theke or _auf_stufe(lokal):
		_landen(nachher, false)

func _auf_stufe(lokal: Vector3) -> bool:
	var hoehen := [0.9, 1.2, 1.5]
	for i in 3:
		var z := -1.3 - i * 0.55
		if absf(lokal.z - z) < 0.25 and absf(lokal.x) < (3.6 - i * 0.4) / 2.0 and lokal.y < hoehen[i] + 0.03:
			return true
	return false

func _landen(ort: Vector3, treffer: bool) -> void:
	letzte_landung = to_local(ort)
	_flug.global_position = ort
	_flug.rotation = Vector3.ZERO if treffer else Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	_flug = null
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if treffer:
		_treffer += 1
		if sfx:
			sfx.play_oder("ding", "pop", -8.0)
	if _uebrig <= 0:
		_warten = 1.2

func punkte() -> int:
	return mini(10, _treffer * 2)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("RINGWURF_ANZEIGE")) % [_treffer, _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_kamera.current = false
	_kamera.transform = _kamera_grund
	_flug = null
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
