class_name OfficeDesk
extends Node3D
## Festbüro-Schreibtisch mit Beamtem. In der Pause E → Büro-Menü
## (Zelt · Lizenzen · Personal · Künstler · Ware).
## Aufbau: scenes/office_desk.tscn — der Beamte ist eine Figur (scenes/figuren/),
## sonst stünde er ohne Animation in der T-Pose.

func _ready() -> void:
	add_to_group("interactable")
	var beamter := get_node_or_null("Beamter") as Figur
	if beamter:
		beamter.stehen.call_deferred()
