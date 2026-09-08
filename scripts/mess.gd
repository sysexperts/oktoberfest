class_name Mess
extends Node3D
## Yerdeki kir (kusmuk). Oyuncu E ile temizler. Host otoriter; id ile senkron.

var mess_id := -1
var kind := 0    # 0 = Erbrochenes, 1 = Urin (E6)

@onready var _disc: MeshInstance3D = $Disc

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mess")
	_apply_kind()

func set_kind(k: int) -> void:
	kind = k
	if is_inside_tree():
		_apply_kind()

func _apply_kind() -> void:
	if _disc == null:
		return
	var m := _disc.material_override as StandardMaterial3D
	if m == null:
		return
	var dup := m.duplicate() as StandardMaterial3D
	if kind == 1:
		dup.albedo_color = Color(0.85, 0.82, 0.35, 0.9)   # Urin: gelblich
		_disc.scale = Vector3(1.3, 1.0, 1.3)
	_disc.material_override = dup

## Temizlik ilerlemesi (0=temiz değil .. 1=temiz) -> görsel küçülür/solar.
func apply_progress(p: float) -> void:
	if _disc == null:
		return
	var s := lerpf(1.0, 0.25, clampf(p, 0.0, 1.0))
	_disc.scale = Vector3(s, 1.0, s)
	var m := _disc.material_override as StandardMaterial3D
	if m:
		m.albedo_color.a = lerpf(0.95, 0.3, clampf(p, 0.0, 1.0))
