class_name BeerTable
extends Node3D
## Bira masası (tisch + 2 bank) — 6 koltuk. Sadece mobilya + koltuk noktaları.
## Misafir/sipariş mantığı GameManager + Customer(guest) içinde.

var idx := -1

func _ready() -> void:
	add_to_group("beertable")
	add_to_group("interactable")

## Koltukların dünya konumları.
func seat_points() -> Array:
	var arr := []
	for c in $Seats.get_children():
		if c is Node3D:
			arr.append((c as Node3D).global_position)
	return arr
