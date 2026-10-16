extends Node3D
## Eine Figur in Konrads Zelt (Personal oder Gast). Nur zur Kulisse: steht, oder geht eine feste Runde
## (`runde`, Punkte relativ zu dieser Figur, Boden y = 0). Aussehen aus `beruf` ("kellner", "zapfer", "koch")
## oder, leer, als Gast aus `nr`. Aufbau: scenes/huber_figur.tscn, in scenes/huber_zelt.tscn platziert.

const Figuren := preload("res://scripts/figuren.gd")

@export var beruf := ""
@export var nr := 0
@export var runde: Array[Vector3] = []
@export var tempo := 1.2
## Wie lange die Figur an jedem Punkt der Runde stehen bleibt
@export var pause := 2.0
## Konrads Zelt wächst mit der Geschichte: diese Figur ist erst ab diesem Kapitel da
@export var ab_kapitel := 1
## Bleibt bei einer Sabotage im Zelt stehen (Personal und Gäste im Casino rennen nicht hinaus)
@export var bleibt := false

var _figur: Figur
var _start: Vector3
var _punkt := 0
var _warte := 0.0

func _ready() -> void:
	if beruf == "":
		_figur = Figuren.einsetzen_npc(self, 5000 + nr, 77)
	else:
		_figur = Figuren.einsetzen_beruf(self, 5000 + nr, beruf)
	_start = position
	_warte = randf_range(0.0, pause)
	_figur.stehen()
	set_process(true)

## Sabotage-Erfolg (GameManager._net_huber_leer): ein Teil der Gäste rennt zum Ausgang und ist dann weg.
## 0 = da, 1 = rennt, 2 = draußen. Am nächsten Tag stehen alle wieder an ihrem Platz.
const AUSGANG_Z := 11.0   # lokal im Zelt: so weit vorn liegt der Eingang
const FLUCHT_TEMPO := 4.8
var _flucht := 0

func _flucht_pruefen() -> void:
	if beruf != "" or bleibt:
		return
	var welt := get_tree().current_scene
	var zelt := get_tree().get_first_node_in_group("huber_zelt") as Node3D
	if zelt == null or not welt.has_method("konrad_leute_da"):
		return
	var heute := int(zelt.get_meta("leer_tag", -1)) == int(welt.get("_day"))
	if heute:
		var jetzt := Time.get_ticks_msec() / 1000.0
		var ab := float(zelt.get_meta("leer_zeit", 0.0)) + _gehwert * 3.0
		if _flucht == 0 and _gehwert < float(zelt.get_meta("leer_anteil", 0.0)) and jetzt >= ab:
			_flucht = 1
			_figur.rennen()
	elif _flucht != 0:
		_flucht = 0
		position = _start
		_punkt = 0
		_warte = randf_range(0.0, pause)
		_figur.stehen()

func _process(delta: float) -> void:
	_lod_t -= delta
	if _lod_t <= 0.0:
		_lod_t = randf_range(0.4, 0.8)
		_flucht_pruefen()
		_lod()
	if _flucht == 1:
		_hinauslaufen(delta)
		return
	if _flucht == 2:
		return
	if runde.is_empty():
		return
	if _warte > 0.0:
		_warte -= delta
		if _warte <= 0.0:
			_figur.gehen()
		return
	var ziel: Vector3 = _start + runde[_punkt]
	var zu := ziel - position
	zu.y = 0.0
	if zu.length() < 0.1:
		_punkt = (_punkt + 1) % runde.size()
		_warte = pause
		_figur.stehen()
		return
	position += zu.normalized() * minf(tempo * delta, zu.length())
	rotation.y = lerp_angle(rotation.y, atan2(zu.x, zu.z), minf(1.0, 8.0 * delta))

## Zum Ausgang rennen (im Raum des Elternknotens), vorn verschwinden
func _hinauslaufen(delta: float) -> void:
	var zelt := get_tree().get_first_node_in_group("huber_zelt") as Node3D
	var eltern := get_parent() as Node3D
	if zelt == null or eltern == null:
		_flucht = 2
		return
	var ziel := eltern.to_local(zelt.to_global(Vector3(0.0, 0.0, AUSGANG_Z)))
	var zu := ziel - position
	zu.y = 0.0
	if zu.length() < 0.9:
		_flucht = 2
		_figur.visible = false
		return
	position += zu.normalized() * minf(FLUCHT_TEMPO * delta, zu.length())
	rotation.y = lerp_angle(rotation.y, atan2(zu.x, zu.z), minf(1.0, 10.0 * delta))

## Leistung: weit weg wird die Animation angehalten, noch weiter weg wird die Figur nicht gezeichnet
## (wie bei den Budenbesitzern, scripts/kirmes/budenbesitzer.gd). 22 Figuren in Konrads Zelt kosteten rund 900 Zeichenaufrufe.
const LOD_ANIMATION := 25.0
const LOD_SICHTBAR := 50.0
var _lod_t := randf() * 0.5
var _nah := true
## Zufallswert: ab welchem Leerstand dieser Gast Konrads Zelt verlässt (Sabotage-Erfolg)
var _gehwert := randf()

func _lod() -> void:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null or _figur == null:
		return
	var abstand := global_position.distance_to(kamera.global_position)
	var welt := get_tree().current_scene
	var hud: Object = welt.get("_hud")
	var z: Dictionary = hud.get("_zustand") if hud != null else {}
	var kapitel := int((z.get("story", {}) as Dictionary).get("kapitel", 1))
	var weg := _flucht == 2
	var da: bool = not welt.has_method("konrad_leute_da") or welt.konrad_leute_da()
	_figur.visible = abstand < LOD_SICHTBAR and kapitel >= ab_kapitel and not weg and da
	var nah := abstand < LOD_ANIMATION
	if nah == _nah or _figur.anim == null:
		return
	_nah = nah
	_figur.ferne = not nah
	if nah:
		_figur.anim.active = true
	else:
		_figur.anim.advance(0.0)
		_figur.anim.active = false
