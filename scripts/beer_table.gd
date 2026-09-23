class_name BeerTable
extends Node3D
## Bira masası (tisch + 2 bank) — 6 koltuk. Sadece mobilya + koltuk noktaları.
## Misafir/sipariş mantığı GameManager + Customer(guest) içinde.

var idx := -1

func _ready() -> void:
	add_to_group("beertable")
	add_to_group("interactable")

## An- und ausschalten. Wichtig: die Kollision muss mit — in Godot haengt die
## Physik nicht an der Sichtbarkeit. Nur `visible = false` liess den
## Kollisionskoerper stehen, und im Zelt standen dann bis zu 20 unsichtbare
## Tische im Weg (Fund 23.09.).
func aktiv_setzen(an: bool) -> void:
	visible = an
	var form := get_node_or_null("Kollision/Form") as CollisionShape3D
	if form:
		form.disabled = not an

## Koltukların dünya konumları.
func seat_points() -> Array:
	var arr := []
	for c in $Seats.get_children():
		if c is Node3D:
			arr.append((c as Node3D).global_position)
	return arr
