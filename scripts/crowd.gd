class_name Crowd
extends Node3D
## Verwaltet die Kirmes-Besucher draußen. Läuft rein lokal auf jedem Client:
## Die Menge hat keinen Einfluss aufs Spiel, deshalb wird nichts übers Netz gesendet.
## Dichte kommt aus der Uhrzeit — morgens leer, abends voll.
##
## Die Besucher folgen einem geschlossenen Rundweg um das Zelt herum. Vorher liefen
## sie geradlinig zu Zufallspunkten und schnitten dabei quer durchs Zelt.

const VISITOR := preload("res://scenes/visitor.tscn")

## Wie viele Besucher bei voller Auslastung. Bei Rucklern hier runterdrehen.
@export var max_visitors := 220

var _visitors := []
var _target := 0
var _ring: Array = []

func _ready() -> void:
	_build_ring()

## Wegpunkte auf dem Ringweg (Mitte der Wege), gegen den Uhrzeigersinn.
func _build_ring() -> void:
	_ring.clear()
	# Nordseite (z = 19), West → Ost
	for x in [-22.0, -15.0, -8.0, 0.0, 8.0, 15.0, 22.0]:
		_ring.append(Vector3(x, 0.1, 19.0))
	# Ostseite (x = 22), Nord → Süd
	for z in [12.0, 5.0, -2.0, -9.0, -16.0, -22.0]:
		_ring.append(Vector3(22.0, 0.1, z))
	# Südseite (z = -22), Ost → West
	for x in [15.0, 8.0, 0.0, -8.0, -15.0, -22.0]:
		_ring.append(Vector3(x, 0.1, -22.0))
	# Westseite (x = -22), Süd → Nord
	for z in [-16.0, -9.0, -2.0, 5.0, 12.0]:
		_ring.append(Vector3(-22.0, 0.1, z))

## f: 0.0 = leer, 1.0 = volle Kirmes.
func set_density(f: float) -> void:
	_target = int(round(clampf(f, 0.0, 1.0) * float(max_visitors)))

func _process(_delta: float) -> void:
	# Nach und nach auf die Zielzahl gehen — sonst ruckelt es beim Spawnen.
	if _visitors.size() != _target:
		_sync_step()

func _sync_step() -> void:
	if _ring.is_empty():
		_build_ring()
	var budget := 4
	while _visitors.size() < _target and budget > 0:
		var v := VISITOR.instantiate()
		add_child(v)
		v.set_route(_ring, randi() % _ring.size(), 1 if randf() < 0.5 else -1)
		_visitors.append(v)
		budget -= 1
	while _visitors.size() > _target and budget > 0:
		var v = _visitors.pop_back()
		if is_instance_valid(v):
			v.queue_free()
		budget -= 1
