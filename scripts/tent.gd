@tool
extends Node3D
## Oktoberfest çadırı — modüler floor/wall/roof modellerini döşer.
## @export parametreleri inspector'dan ayarlanabilir; "Rebuild" ile yeniden kurulur.
## Üretilen karolar owner=null olduğu için sahneye KAYDEDİLMEZ (dosya şişmez).

@export var tent_scale := 2.0 : set = _set_scale
@export var roof_scale := 2.7      # çatı parçaları daha büyük -> daha az sayıda
@export var wall_overlap := 0.82
@export var roof_overlap := 0.9
@export var x0 := -12.0
@export var x1 := 12.0
@export var z0 := -14.0
@export var z1 := 11.0
@export var wall_lanterns := true
@export var ceiling_lanterns := true
## Editörde bunu işaretle -> yeniden kurar (parametre değişikliklerini görmek için).
@export var rebuild := false : set = _set_rebuild

func _set_scale(v: float) -> void:
	tent_scale = v
	if Engine.is_editor_hint():
		_build()

func _set_rebuild(_v: bool) -> void:
	rebuild = false
	_build()

func _ready() -> void:
	if Engine.is_editor_hint():
		_build()
	elif not Net.dedicated:
		_build()

func _clear() -> void:
	for c in get_children():
		remove_child(c)
		c.free()

func _build() -> void:
	_clear()
	var S := tent_scale
	var floor_ps := load("res://assets/models/floor.glb")
	var wall_ps := load("res://assets/models/wall.glb")
	var roof_ps := load("res://assets/models/roof.glb")

	# Zemin
	var fs := 1.903 * S * 0.98
	var y_floor := -0.096 * S
	var x := x0
	while x <= x1 + 0.01:
		var z := z0
		while z <= z1 + 0.01:
			_spawn(floor_ps, Vector3(x, y_floor, z), S, 0.0)
			z += fs
		x += fs

	# Duvarlar + fener ışıkları
	var ws := 1.489 * S * wall_overlap
	var y_wall := 0.951 * S
	var lamp_y := y_wall + 0.55 * S
	var inw := 0.5
	var li := 0
	x = x0
	while x <= x1 + 0.01:
		_spawn(wall_ps, Vector3(x, y_wall, z0), S, 0.0)
		_spawn(wall_ps, Vector3(x, y_wall, z1), S, 180.0)
		if wall_lanterns and li % 2 == 0:
			_lantern(Vector3(x, lamp_y, z0 + inw), 6.5, 2.2)
			_lantern(Vector3(x, lamp_y, z1 - inw), 6.5, 2.2)
		li += 1
		x += ws
	var z2 := z0
	while z2 <= z1 + 0.01:
		_spawn(wall_ps, Vector3(x0, y_wall, z2), S, 90.0)
		_spawn(wall_ps, Vector3(x1, y_wall, z2), S, -90.0)
		if wall_lanterns and li % 2 == 0:
			_lantern(Vector3(x0 + inw, lamp_y, z2), 6.5, 2.2)
			_lantern(Vector3(x1 - inw, lamp_y, z2), 6.5, 2.2)
		li += 1
		z2 += ws

	# Çatı — daha büyük parçalar, daha az sayı (roof_scale)
	var rss := roof_scale
	var rsx := 1.445 * rss * roof_overlap
	var rsz := 1.917 * rss * roof_overlap
	var y_roof := 1.9 * S + 0.35 * rss
	x = x0 - 1.5
	while x <= x1 + 1.5:
		var z3 := z0 - 1.5
		while z3 <= z1 + 1.5:
			_spawn(roof_ps, Vector3(x, y_roof, z3), rss, 0.0)
			z3 += rsz
		x += rsx

	# İç mekan asılı fenerler (parlayan ampul + ışık)
	if ceiling_lanterns:
		var ceil_y := 1.9 * S - 0.4
		for hx in [-6.0, 0.0, 6.0]:
			for hz in [-8.0, -3.0, 2.0, 7.0]:
				_hanging(Vector3(hx, ceil_y, hz))

func _spawn(ps: PackedScene, pos: Vector3, s: float, rot_y: float) -> void:
	var m: Node3D = ps.instantiate()
	m.position = pos
	m.scale = Vector3(s, s, s)
	m.rotation_degrees.y = rot_y
	add_child(m)

func _lantern(pos: Vector3, rng: float, energy: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1.0, 0.80, 0.48)
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.5
	l.shadow_enabled = false
	add_child(l)

func _hanging(pos: Vector3) -> void:
	var bulb := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.12
	sph.height = 0.24
	bulb.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.55)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.78, 0.45)
	mat.emission_energy_multiplier = 4.0
	bulb.material_override = mat
	bulb.position = pos
	add_child(bulb)
	_lantern(pos, 9.0, 2.6)
