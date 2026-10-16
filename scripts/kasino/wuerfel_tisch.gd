extends Node3D
## Würfel auf dem Würfeltisch im Casino (scenes/kasino/auflage_wuerfel.tscn): zeigt nach jedem Wurf die gefallenen Augen.
## Das Fenster scripts/ui/casino_wuerfel.gd meldet den Wurf, wenn die Würfel auf der Bahn liegen.

func _ready() -> void:
	add_to_group("wuerfel_tisch")

func setze(a: int, b: int) -> void:
	var augen := [a, b]
	for i in 2:
		var w := get_node("Wuerfel%d" % i) as Node3D
		(w.get_node("Augen") as Sprite3D).texture = load("res://assets/casino/wuerfel_%d.png" % clampi(int(augen[i]), 1, 6))
		var tw := create_tween()
		tw.tween_property(w, "rotation:y", randf_range(-1.5, 1.5), 0.3)
