extends Node3D
## Leibwächter eines Influencers (SloptanaBlack88): zwei Security-Männer, die neben dem Tisch des Stars stehen und
## ihn im Blick haben. Rein zur Zierde, keine Interaktion. Der GameManager stellt sie auf (_leibwaechter_stellen).
## Aufbau: scenes/leibwaechter.tscn. Bewusst ohne class_name.

const Figuren := preload("res://scripts/figuren.gd")

var lw_id := 0

func _ready() -> void:
	var f := Figuren.einsetzen_beruf(self, 9100 + lw_id, "security")
	f.stehen()
