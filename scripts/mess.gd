class_name Mess
extends Node3D
## Yerdeki kir (kusmuk). Oyuncu E ile temizler. Host otoriter; id ile senkron.

var mess_id := -1

@onready var _disc: MeshInstance3D = $Disc

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("mess")

## Temizlik ilerlemesi (0=temiz değil .. 1=temiz) -> görsel küçülür/solar.
func apply_progress(p: float) -> void:
	if _disc == null:
		return
	var s := lerpf(1.0, 0.25, clampf(p, 0.0, 1.0))
	_disc.scale = Vector3(s, 1.0, s)
	var m := _disc.material_override as StandardMaterial3D
	if m:
		m.albedo_color.a = lerpf(0.95, 0.3, clampf(p, 0.0, 1.0))
