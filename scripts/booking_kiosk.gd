class_name BookingKiosk
extends Node3D
## Buchungskiosk: Zelt buchen/upgraden + Tisch kaufen. Molada etkileşilir.
## Mantık GameManager'da (net_book_tent / net_buy_table / net_upgrade_tent).

func _ready() -> void:
	add_to_group("interactable")
