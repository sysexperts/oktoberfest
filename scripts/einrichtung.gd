class_name Einrichtung
extends Node3D
## Kaufbarer, frei platzierbarer Gegenstand im Zelt (Lampe, Lichterkette, Deko).
## Welche es gibt und was sie kosten: scripts/einrichtung_katalog.gd.
## Kaufen, Tragen, Drehen und Speichern regelt der GameManager (net_buy_einrichtung,
## net_move_einrichtung, net_rotate_einrichtung) — hier steht nur der Gegenstand.

## Vom GameManager vergeben, auf allen Rechnern gleich
var deko_id := -1
var art := ""

func _ready() -> void:
	add_to_group("interactable")

## Angesprochen wird auf Brusthöhe, nicht der Fußpunkt.
func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)
