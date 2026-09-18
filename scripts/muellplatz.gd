class_name Muellplatz
extends Node3D
## Abholplatz für Müllsäcke vor dem Zelt (Tutorial „Putze das Zelt"): Spieler
## stellen getragene Säcke hier ab (E), morgens holt die Müllabfuhr sie ab.
## Sichtbare Säcke = Anzahl (GameManager.net_muell_abgeben / _muellplatz_zeigen).

@onready var _saecke: Node3D = $Saecke

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("muellplatz")
	anzahl_setzen(0)

func interact_point() -> Vector3:
	return global_position + Vector3(0, 0.6, 0)

func anzahl_setzen(n: int) -> void:
	var saecke := _saecke.get_children()
	for i in saecke.size():
		(saecke[i] as Node3D).visible = i < n
