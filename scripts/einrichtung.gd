class_name Einrichtung
extends Node3D
## Kaufbarer, frei platzierbarer Gegenstand im Zelt (Lampe, Deko, Regal …).
## Welche es gibt, was sie kosten und ob sie am Boden, an der Wand oder an der
## Decke sitzen: scripts/einrichtung_katalog.gd.
## Kaufen, Tragen, Drehen und Speichern regelt der GameManager (net_buy_einrichtung,
## net_move_einrichtung, net_rotate_einrichtung, _deko_platz) — hier steht nur der Gegenstand.

const Modell := preload("res://scripts/modell_material.gd")

## Vom GameManager vergeben, auf allen Rechnern gleich
var deko_id := -1
var art := ""

func _ready() -> void:
	add_to_group("interactable")
	Modell.ohne_metall(self)

## Angesprochen wird auf Brusthöhe unter dem Gegenstand — auch bei Wand- und
## Deckendeko, die der Spieler sonst nie erreichen würde (zählt nur der Abstand am Boden).
func interact_point() -> Vector3:
	return Vector3(global_position.x, 1.0, global_position.z)
