class_name Carryable
extends Node3D
## Taşınabilir nesnelerin temel sınıfı (bardak, tepsi vb.).
## Oyuncu tarafından alınıp bırakılabilir. "interactable" grubunda olmalı.

@export var display_name: String = "Nesne"

var _is_carried: bool = false

func _ready() -> void:
	add_to_group("interactable")

## Oyuncu bu nesneye E'ye bastığında çağrılır (uniform etkileşim arayüzü).
func interact(player: Player) -> void:
	if _is_carried:
		return
	if player.held == null:
		player.pick_up(self)

## Oyuncu bunu eline aldığında: verilen tutma noktasına bağla.
func on_carried(hold_point: Node3D) -> void:
	_is_carried = true
	reparent(hold_point, false)
	transform = Transform3D.IDENTITY

## Oyuncu bıraktığında: dünyaya geri koy.
func on_dropped(world: Node3D, at_position: Vector3) -> void:
	_is_carried = false
	reparent(world, false)
	global_position = at_position
