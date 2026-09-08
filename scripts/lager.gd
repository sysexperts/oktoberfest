class_name Lager
extends Node3D
## Lagerregal. Getragenes Warenpaket hier mit E abladen → Bestand steigt.

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("lager")

## Vom GameManager gesetzt, damit der Bestand am Regal ablesbar ist.
func set_stock(bier: int, essen: int) -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "📦 LAGER\n🍺 %d · 🥨 %d\n(E: Paket abladen)" % [bier, essen]
