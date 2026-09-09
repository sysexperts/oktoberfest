class_name Caravan
extends Node3D
## Wohnwagen. Nur DEIN Wohnwagen (is_mine = true) ist benutzbar:
## Molada etkileş → uyu → gün başlar (net_sleep). Diğerleri sadece dekor.

## Editörden kapatılabilir: false ise sadece dekor (etkileşim yok).
@export var is_mine := true

func _ready() -> void:
	if is_mine:
		add_to_group("interactable")
	var label := get_node_or_null("Label") as Label3D
	if label and not is_mine:
		label.visible = false

## Ansprechpunkt an der Tür statt in der Wagenmitte — sonst muss man
## praktisch im Wohnwagen stehen, um schlafen zu können.
func interact_point() -> Vector3:
	return global_position + global_transform.basis.z * 1.1
