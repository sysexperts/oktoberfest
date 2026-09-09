class_name Crowd
extends Node3D
## Kirmes-Besucher draußen. Läuft rein lokal auf jedem Client (kein Netz-Traffic),
## die Menge hat keinen Einfluss aufs Spiel.
##
## Die Besucher bummeln zwischen Wegpunkten auf dem Ringweg und Halteplätzen vor
## den Ständen. Sie suchen sich immer ein Ziel in der Nähe — dadurch wirkt es wie
## ein Gedränge und nicht wie eine Prozession in Reih und Glied.

const VISITOR := preload("res://scenes/visitor.tscn")

## Bei Rucklern hier runterdrehen.
@export var max_visitors := 220

var _visitors := []
var _target := 0
var _points: Array = []   # Wegpunkte + Halteplätze vor den Ständen

func _ready() -> void:
	_build_points()

func _build_points() -> void:
	_points.clear()
	# Ringweg (Mitte der Wege)
	for x in [-28.0, -21.0, -14.0, -7.0, 0.0, 7.0, 14.0, 21.0, 28.0]:
		_points.append(Vector3(x, 0.1, 19.0))
		_points.append(Vector3(x, 0.1, -22.0))
	for z in [-16.0, -9.0, -2.0, 5.0, 12.0]:
		_points.append(Vector3(22.0, 0.1, z))
		_points.append(Vector3(-22.0, 0.1, z))
	# Halteplätze direkt vor den Ständen (dort bleiben die Leute stehen)
	for x in [-31.5, -27.0, -22.5, -18.0, -13.5, -9.0, -4.5, 0.0, 4.5, 9.0, 13.5, 18.0, 22.5, 27.0, 31.5]:
		_points.append(Vector3(x, 0.1, 23.5))    # vor der Nordreihe
		_points.append(Vector3(x, 0.1, -26.5))   # vor der Südreihe
	for z in [-18.0, -13.5, -9.0, -4.5, 0.0, 4.5, 9.0, 13.5, 18.0]:
		_points.append(Vector3(26.5, 0.1, z))    # vor der Ostreihe
		_points.append(Vector3(-26.5, 0.1, z))   # vor der Westreihe

## Ein Ziel in der Nähe — so bummeln sie von Stand zu Stand statt im Kreis zu marschieren.
func next_point(from: Vector3) -> Vector3:
	if _points.is_empty():
		_build_points()
	var near := []
	for p in _points:
		var d: float = from.distance_to(p)
		if d > 6.0 and d < 20.0:
			near.append(p)
	var base: Vector3 = (near.pick_random() if not near.is_empty() else _points.pick_random()) as Vector3
	# leichter Zufallsversatz, damit nicht alle exakt denselben Punkt anlaufen
	return base + Vector3(randf_range(-1.8, 1.8), 0.0, randf_range(-1.8, 1.8))

func random_start() -> Vector3:
	if _points.is_empty():
		_build_points()
	return (_points.pick_random() as Vector3) + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))

## f: 0.0 = leer, 1.0 = volle Kirmes.
func set_density(f: float) -> void:
	_target = int(round(clampf(f, 0.0, 1.0) * float(max_visitors)))

func _process(_delta: float) -> void:
	if _visitors.size() != _target:
		_sync_step()

func _sync_step() -> void:
	var budget := 4
	while _visitors.size() < _target and budget > 0:
		var v := VISITOR.instantiate()
		add_child(v)
		v.setup(self)
		_visitors.append(v)
		budget -= 1
	while _visitors.size() > _target and budget > 0:
		var v = _visitors.pop_back()
		if is_instance_valid(v):
			v.queue_free()
		budget -= 1
