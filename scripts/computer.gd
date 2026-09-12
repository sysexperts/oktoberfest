class_name Computer
extends Node3D
## Zelt-Computer auf dem Schreibtisch im Büroraum (scenes/bueroraum.tscn).
## Öffnet Bierpreis, Warenbestellung und Bilanz — die Logik steht im GameManager.

const Modell := preload("res://scripts/modell_material.gd")

func _ready() -> void:
	add_to_group("interactable")
	Modell.ohne_metall(self)

## Angesprochen wird der Bildschirm, nicht der Fußpunkt.
func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)
