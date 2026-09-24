class_name Braustation
extends Node3D
## Gefäß im Braukeller: Maischbottich (schritt 1) und Sudkessel (schritt 2).
## Die Brauschritte selbst kommen als nächstes; hier steht bis dahin nur das
## Gefäß mit seinem Ansprechpunkt, damit Modell, Kollision und Position stehen.
##
## Rezept: Malz + Wasser (Bottich) → Kochen + Hopfen (Kessel) → Hefe (Gärfass).

## 1 = Maischbottich, 2 = Sudkessel
@export var schritt := 1

func _ready() -> void:
	add_to_group("braustation")

## Angesprochen wird am oberen Rand des Gefäßes, nicht am Boden
func interact_point() -> Vector3:
	var p := get_node_or_null("Ansprechpunkt") as Node3D
	return p.global_position if p else global_position
