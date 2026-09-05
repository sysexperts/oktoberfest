class_name Computer
extends Node3D
## Vardiya bilgisayarı. Mola fazında E ile rol seçilir (Mutfak/Temizlik/Garson).
## Görsel sahnede; rol mantığı GameManager'da.

func _ready() -> void:
	add_to_group("interactable")
