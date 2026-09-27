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
## Konzertstrahler (Knoten "Strahler"): Lichtkegel, die schwenken — nur solange
## jemand auf der Bühne steht
var _strahler: Array[Node3D] = []
var _kegel_stoff: Array[ShaderMaterial] = []
var _band_da := false
var _band_pruef := 0.0

func _ready() -> void:
	add_to_group("stage")
	var modell := get_node_or_null("Modell")
	if modell:
		preload("res://scripts/modell_material.gd").ohne_metall(modell)
	var holder := get_node_or_null("Lichter")
	if holder:
		for c in holder.get_children():
			if c is OmniLight3D:
				_lights.append(c)
				_base_x.append((c as OmniLight3D).position.x)
	var strahler := get_node_or_null("Strahler")
	if strahler:
		for c in strahler.get_children():
			_strahler.append(c)
			# Jeder Kegel bekommt ein eigenes Material, damit er eigene Farben hat
			var kegel := c.get_node_or_null("Kegel") as MeshInstance3D
			var stoff := (kegel.get_surface_override_material(0) as ShaderMaterial).duplicate() as ShaderMaterial
			kegel.set_surface_override_material(0, stoff)
			_kegel_stoff.append(stoff)

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
	_strahler_bewegen(delta)

func _strahler_bewegen(delta: float) -> void:
	if _strahler.is_empty():
		return
	_band_pruef -= delta
	if _band_pruef <= 0.0:
		_band_pruef = 0.5
		_band_da = false
		for a in get_tree().get_nodes_in_group("artist"):
			if not a.has_method("flieht") or not a.flieht():
				_band_da = true
				break
		($Strahler as Node3D).visible = _band_da and _active
	if not _band_da:
		return
	for i in _strahler.size():
		var s := _strahler[i]
		# Paare schwenken gegenläufig, dazu langsames Nicken ins Publikum
		var richtung := 1.0 if i % 2 == 0 else -1.0
		s.rotation = Vector3(-0.55 + sin(_t * 1.3 + i * 0.7) * 0.22, PI + richtung * sin(_t * 0.9 + i * 0.4) * 0.55, 0.0)
		var phase: float = _t * 0.8 + float(i) * 0.9
		var idx: int = int(phase) % COLORS.size()
		var farbe := (COLORS[idx] as Color).lerp(COLORS[(idx + 1) % COLORS.size()] as Color, phase - floor(phase))
		(s.get_node("Licht") as SpotLight3D).light_color = farbe
		_kegel_stoff[i].set_shader_parameter("farbe", Color(farbe.r, farbe.g, farbe.b, 0.8 + 0.2 * sin(_t * 6.0 + i)))

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
	if has_node("Strahler"):
		($Strahler as Node3D).visible = on and _band_da
