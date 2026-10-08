extends Node3D
## Mülleimer an der Kochstelle: Verbranntes (und sonstiges Essen) mit E wegwerfen.
## Das Werfen selbst erledigt der Spieler (scripts/player.gd, ist_muell). Aufbau: scenes/muell_eimer.tscn.

func _ready() -> void:
	add_to_group("interactable")

func ist_muell() -> bool:
	return true

func interact_point() -> Vector3:
	return global_position + Vector3(0, 0.6, 0)
