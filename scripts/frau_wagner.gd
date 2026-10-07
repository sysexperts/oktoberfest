extends Node3D
## Frau Wagner vom Amt bei der Hygienekontrolle: kommt zum Zelteingang, geht ihre Runde
## (Tische, Küche, Theke) und verlässt das Zelt wieder. Nur Darstellung — das Urteil fällt
## der GameManager (Server), wenn die Runde um ist. Aufbau: scenes/frau_wagner.tscn.

const Figuren := preload("res://scripts/figuren.gd")

## Gehtempo in m/s
const TEMPO := 2.0
## Die Runde durchs Zelt (Boden y = 0,1)
const RUNDE: Array[Vector3] = [
	Vector3(0.0, 0.1, 40.0), Vector3(0.0, 0.1, 12.0), Vector3(-6.0, 0.1, 5.0), Vector3(6.0, 0.1, 5.0),
	Vector3(6.0, 0.1, -3.0), Vector3(5.0, 0.1, -9.5), Vector3(-4.0, 0.1, -9.5), Vector3(-6.0, 0.1, 0.0),
	Vector3(0.0, 0.1, 12.0), Vector3(0.0, 0.1, 40.0),
]
## Wie lange sie an Küche und Theke stehen bleibt und schaut
const SCHAU_ZEIT := 3.0
const SCHAU_PUNKTE := [5, 6]

var _figur: Figur
var _punkt := 1
var _warte := 0.0

## Gesamtdauer der Runde in Sekunden (der Server wartet so lange bis zum Urteil)
static func dauer() -> float:
	var l := 0.0
	for i in range(1, RUNDE.size()):
		l += RUNDE[i - 1].distance_to(RUNDE[i])
	return l / TEMPO + SCHAU_ZEIT * SCHAU_PUNKTE.size()

func _ready() -> void:
	add_to_group("wagner")
	_figur = Figuren.einsetzen_look(self, Figuren.look_wagner())
	_figur.gehen()
	global_position = RUNDE[0]

func _process(delta: float) -> void:
	if _punkt >= RUNDE.size():
		queue_free()
		return
	if _warte > 0.0:
		_warte -= delta
		if _warte <= 0.0:
			_figur.gehen()
		return
	var ziel := RUNDE[_punkt]
	var zu := ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.15:
		if _punkt in SCHAU_PUNKTE:
			_warte = SCHAU_ZEIT
			_figur.stehen()
		_punkt += 1
		return
	global_position += zu.normalized() * minf(TEMPO * delta, zu.length())
	rotation.y = lerp_angle(rotation.y, atan2(zu.x, zu.z), minf(1.0, 8.0 * delta))
