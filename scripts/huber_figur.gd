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
	set_process(not runde.is_empty())

func _process(delta: float) -> void:
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
