@tool
class_name EssenTeller
extends Node3D
## Teller mit Essen: 1 Brezn, 2 Würstl, 3 Hendl (Modelle aus assets/models).
## Aufbau in scenes/essen_teller.tscn — dort sitzen die drei Modelle als Kinder,
## sichtbar ist nur die gewählte Sorte. Ursprung = Unterseite des Tellers.

const Modell := preload("res://scripts/modell_material.gd")

@export_range(1, 3) var sorte := 1:
	set(v):
		sorte = clampi(v, 1, 3)
		_anwenden()

func _ready() -> void:
	Modell.ohne_metall(self)
	_anwenden()

func _anwenden() -> void:
	if not is_node_ready():
		return
	$Brezn.visible = sorte == 1
	$Wuerstl.visible = sorte == 2
	$Hendl.visible = sorte == 3
