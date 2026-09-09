class_name Lichterkette
extends Node3D
## Lauflicht für die Lichterketten: die sechs Birnenfarben leuchten versetzt
## auf und ab, sodass ein Lichtband über die Kette wandert.
##
## Die Materialien liegen in der Szene und werden von allen Ketten geteilt —
## dadurch läuft das Licht über den ganzen Platz im Gleichtakt, und es kostet
## nur sechs Materialien statt hunderter.

## Wie schnell das Licht wandert (Durchläufe pro Sekunde).
@export var tempo := 0.5
## Grundhelligkeit der Birnen.
@export var grund := 1.8
## Wie stark sie dabei auf- und abschwingen.
@export var ausschlag := 1.6

var _mats: Array[StandardMaterial3D] = []
var _t := 0.0

func _ready() -> void:
	var seen := {}
	for c in find_children("*", "MeshInstance3D", true, false):
		var m := (c as MeshInstance3D).material_override as StandardMaterial3D
		if m != null and not seen.has(m):
			seen[m] = true
			_mats.append(m)
	set_process(not _mats.is_empty())

func _process(delta: float) -> void:
	_t += delta
	for i in _mats.size():
		var phase := TAU * (_t * tempo - float(i) / float(_mats.size()))
		_mats[i].emission_energy_multiplier = grund + sin(phase) * ausschlag
