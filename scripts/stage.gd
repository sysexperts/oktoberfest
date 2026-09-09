class_name Stage
extends Node3D
## Bühne im Festzelt. Das Discolicht läuft immer (auch ohne gebuchten Künstler).
## Die Künstler selbst setzt der GameManager auf die Plätze unter "Plaetze".

const COLORS := [
	Color(1.0, 0.2, 0.3), Color(0.2, 0.5, 1.0), Color(0.3, 1.0, 0.4),
	Color(1.0, 0.9, 0.2), Color(0.8, 0.3, 1.0)
]

var _lights: Array = []
var _base_x: Array = []
var _t := 0.0
var _active := true

func _ready() -> void:
	add_to_group("stage")
	var holder := get_node_or_null("Lichter")
	if holder:
		for c in holder.get_children():
			if c is OmniLight3D:
				_lights.append(c)
				_base_x.append((c as OmniLight3D).position.x)

func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	for i in _lights.size():
		var l := _lights[i] as OmniLight3D
		var phase: float = _t * 1.6 + float(i) * 1.3
		var idx: int = int(phase) % COLORS.size()
		var nxt: int = (idx + 1) % COLORS.size()
		var f: float = phase - floor(phase)
		l.light_color = (COLORS[idx] as Color).lerp(COLORS[nxt] as Color, f)
		l.light_energy = 2.2 + sin(_t * 4.0 + float(i)) * 1.3
		l.position.x = float(_base_x[i]) + sin(_t * 1.1 + float(i)) * 1.4

## Weltpositionen der Künstlerplätze.
func artist_points() -> Array:
	var arr := []
	var n := get_node_or_null("Plaetze")
	if n:
		for c in n.get_children():
			if c is Node3D:
				arr.append((c as Node3D).global_position)
	return arr

## Licht nur an, solange das Zelt offen ist. Nach 22:00 ist Feierabend.
func set_active(on: bool) -> void:
	if _active == on:
		return
	_active = on
	for l in _lights:
		(l as OmniLight3D).visible = on
