extends Node3D
## Hubers Saboteur: schleicht vom Zelteingang an der Lager-Seite vorbei hinter
## die Theke (Fass) bzw. in die Zeltmitte (Stinkbombe). Gäste gehen nie hinter
## die Theke — wer ihn sieht und mit E erwischt (GameManager.net_saboteur_fangen),
## verhindert die Sabotage. Läuft bei allen gleich: Weg und Tempo vom Server,
## Position aus der vergangenen Zeit. Aufbau: scenes/saboteur.tscn.

const Figuren := preload("res://scripts/figuren.gd")
const TEMPO := 1.6
const FLUCHT_TEMPO := 5.0

var _weg: Array[Vector3] = []
var _t := 0.0
var _flieht := false
var _figur: Figur

func _ready() -> void:
	add_to_group("saboteur")
	add_to_group("interactable")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[2 % Figuren.ALLE.size()])
	_figur.gehen(0.8)

func ist_saboteur() -> bool:
	return not _flieht

func interact_point() -> Vector3:
	return global_position

func starten(weg: Array) -> void:
	_weg.clear()
	for p in weg:
		_weg.append(p)
	global_position = _weg[0]

## Wie lange er bis zum Ziel braucht
static func dauer(weg: Array) -> float:
	var l := 0.0
	for i in weg.size() - 1:
		l += (weg[i] as Vector3).distance_to(weg[i + 1])
	return l / TEMPO

## Erwischt oder fertig: rennt zum Eingang raus und verschwindet
func fliehen() -> void:
	_flieht = true
	remove_from_group("interactable")
	_figur.rennen(1.5)
	_weg = [global_position, Vector3(-10, 0, 0), Vector3(-6, 0, 6), Vector3(0, 0, 16)]
	_t = 0.0

func _process(delta: float) -> void:
	_t += delta
	var weg := _t * (FLUCHT_TEMPO if _flieht else TEMPO)
	for i in _weg.size() - 1:
		var s := _weg[i].distance_to(_weg[i + 1])
		if weg <= s:
			var p := _weg[i].lerp(_weg[i + 1], weg / maxf(s, 0.01))
			global_position = p
			var r := _weg[i + 1] - _weg[i]
			rotation.y = atan2(r.x, r.z)
			return
		weg -= s
	global_position = _weg[-1]
	if _flieht:
		queue_free()
	else:
		_figur.stehen()
