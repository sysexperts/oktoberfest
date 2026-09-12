extends Node3D
## Wurzel für Szenen mit Meshy-Modellen (Kochtheke, Büroraum …): nimmt beim
## Start den gebackenen Metallic-Anteil heraus, sonst wirken sie im Zelt dunkel.
## Siehe scripts/modell_material.gd.

const Modell := preload("res://scripts/modell_material.gd")

func _ready() -> void:
	Modell.ohne_metall(self)
