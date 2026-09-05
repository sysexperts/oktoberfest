class_name FoodStation
extends Node3D
## Yemek hazırlama istasyonu (Mutfak). E basılı tut -> yemek hazırla.
## 1 = Pretzel, 2 = Sosis. Mantık Player içinde.

const FOOD_NAMES := {1: "Pretzel", 2: "Sosis"}
const FOOD_COLORS := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2)}

@export var food_type := 1

func _ready() -> void:
	add_to_group("interactable")
	var l := get_node_or_null("Label") as Label3D
	if l:
		l.text = "%s (E tut)" % FOOD_NAMES.get(food_type, "Yemek")
		l.modulate = FOOD_COLORS.get(food_type, Color.WHITE)
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh and mesh.material_override is StandardMaterial3D:
		var m := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = (FOOD_COLORS.get(food_type, Color(0.5, 0.4, 0.3)) as Color).darkened(0.2)
		mesh.material_override = m
