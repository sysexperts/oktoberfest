class_name Crowd
extends Node3D
## Verwaltet die Kirmes-Besucher draußen. Läuft rein lokal auf jedem Client:
## Die Menge hat keinen Einfluss aufs Spiel, deshalb wird nichts übers Netz gesendet.
## Dichte kommt aus der Uhrzeit — morgens leer, abends voll.

const VISITOR := preload("res://scenes/visitor.tscn")

## Wie viele Besucher bei voller Auslastung. Bei Rucklern hier runterdrehen.
@export var max_visitors := 24

var _visitors := []
var _target := 0

## f: 0.0 = leer, 1.0 = volle Kirmes.
func set_density(f: float) -> void:
	var want := int(round(clampf(f, 0.0, 1.0) * float(max_visitors)))
	if want == _target:
		return
	_target = want
	_sync()

func _sync() -> void:
	while _visitors.size() < _target:
		var v := VISITOR.instantiate()
		add_child(v)
		v.setup(Callable(self, "random_point"), random_point())
		_visitors.append(v)
	while _visitors.size() > _target:
		var v = _visitors.pop_back()
		if is_instance_valid(v):
			v.queue_free()

## Zufälliger Punkt auf dem Ringweg rund ums Zelt.
func random_point() -> Vector3:
	match randi() % 4:
		0:
			return Vector3(randf_range(-30.0, 30.0), 0.1, randf_range(15.0, 23.0))
		1:
			return Vector3(randf_range(-30.0, 30.0), 0.1, randf_range(-26.0, -18.0))
		2:
			return Vector3(randf_range(-26.0, -18.0), 0.1, randf_range(-22.0, 19.0))
		_:
			return Vector3(randf_range(18.0, 26.0), 0.1, randf_range(-22.0, 19.0))
