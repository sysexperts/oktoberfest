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
