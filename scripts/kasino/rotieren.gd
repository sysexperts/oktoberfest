extends Node3D
## Dreht den Knoten langsam um die Hochachse (Kronleuchter im Casino)
@export var grad_pro_sekunde := 14.0

func _process(delta: float) -> void:
	rotation_degrees.y += grad_pro_sekunde * delta
