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

func _process(delta: float) -> void:
	_lod_t -= delta
	if _lod_t <= 0.0:
		_lod_t = randf_range(0.4, 0.8)
		_lod()
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
	var weg := false
	if beruf == "":
		var zelt := get_tree().get_first_node_in_group("huber_zelt")
		if zelt != null and int(zelt.get_meta("leer_tag", -1)) == int(welt.get("_day")):
			weg = _gehwert < float(zelt.get_meta("leer_anteil", 0.0))
	_figur.visible = abstand < LOD_SICHTBAR and kapitel >= ab_kapitel and not weg
	var nah := abstand < LOD_ANIMATION
	if nah == _nah or _figur.anim == null:
		return
	_nah = nah
	if nah:
		_figur.anim.active = true
	else:
		_figur.anim.advance(0.0)
		_figur.anim.active = false
