class_name Lieferwagen
extends Node3D
## Brauerei-Lieferwagen. Fahrt und Halt steuert der Server (GameManager,
## _update_delivery), hier nur das Sichtbare, bei jedem Spieler lokal: Räder
## drehen, Staub hinter den Hinterrädern, Staubwolke beim Abladen und
## Kirmesbesucher, die im Weg stehen, fliegen im hohen Bogen weg.
## Aufbau: scenes/delivery_van.tscn (gebacken mit tools/bake_lieferwagen.gd).

const STAUB := preload("res://scenes/effekte/staub.tscn")
const RAD_RADIUS := 0.42
## Halbe Breite / Länge der Trefferfläche (Wagen zeigt nach +Z)
const HALB := Vector2(1.3, 2.9)

@onready var _raeder: Array[Node3D] = [$Raeder/VL, $Raeder/VR, $Raeder/HL, $Raeder/HR]

var _letzte := Vector3.ZERO
var _tempo := Vector3.ZERO
var _staub_t := 0.0

func _ready() -> void:
	add_to_group("lieferwagen")
	_letzte = global_position

func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	var weg := global_position - _letzte
	_letzte = global_position
	_tempo = _tempo.lerp(weg / delta, clampf(delta * 8.0, 0.0, 1.0))
	var vorwaerts := weg.dot(global_transform.basis.z)
	for r in _raeder:
		r.rotation.x += vorwaerts / RAD_RADIUS
	var v := _tempo.length()
	if v > 2.5:
		_staub_t -= delta
		if _staub_t <= 0.0:
			_staub_t = 0.18
			for seite in [-0.9, 0.9]:
				_staub(to_global(Vector3(seite, 0.0, -1.9)), 0.25)
		_umfahren()

## Kirmesbesucher und der eigene Spieler werden weggeschleudert (Visitor/Player.geschleudert)
func _umfahren() -> void:
	var vorn := global_transform.basis.z
	for sp in get_tree().get_nodes_in_group("player"):
		if not sp.get("_is_local") or not sp.has_method("geschleudert") or sp.wird_geschleudert():
			continue
		var q: Vector3 = to_local((sp as Node3D).global_position)
		if absf(q.x) > HALB.x + 0.3 or absf(q.z) > HALB.y or absf(q.y) > 1.5:
			continue
		var wucht_s := clampf(_tempo.length(), 3.0, 10.0)
		var seite_s := global_transform.basis.x * signf(q.x if absf(q.x) > 0.05 else 1.0)
		sp.geschleudert(vorn * wucht_s * 0.8 + seite_s * wucht_s * 0.7 + Vector3.UP * (5.0 + wucht_s * 0.3))
		_staub((sp as Node3D).global_position, 0.8, "aufprall")
	for b in get_tree().get_nodes_in_group("visitor"):
		var p: Vector3 = to_local((b as Node3D).global_position)
		if absf(p.x) > HALB.x or absf(p.z) > HALB.y or absf(p.y) > 1.5:
			continue
		if not b.has_method("geschleudert") or b.fliegt():
			continue
		var seite := global_transform.basis.x * signf(p.x if absf(p.x) > 0.05 else randf_range(-1, 1))
		var wucht := clampf(_tempo.length(), 3.0, 10.0)
		b.geschleudert(vorn * wucht * 0.9 + seite * wucht * 0.6 + Vector3.UP * (4.0 + wucht * 0.35))
		_staub((b as Node3D).global_position, 0.8, "aufprall")

## Beim Abladen: Staubwolke an der linken Seite (dort landen die Pakete)
func abladen() -> void:
	for i in 3:
		_staub(to_global(Vector3(-1.6 - i * 0.6, 0.0, -1.0 + i * 0.8)), 1.2, "" if i else "aufprall")

func _staub(ort: Vector3, staerke: float, ton := "") -> void:
	var s := STAUB.instantiate()
	get_tree().current_scene.add_child(s)
	s.global_position = Vector3(ort.x, 0.05, ort.z)
	s.ausloesen(staerke, ton)
