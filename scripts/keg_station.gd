class_name KegStation
extends Node3D
## Fıçı istasyonu. Her fıçının bir bira tipi var (editörden beer_type ile ayarlanır).
## Dolum mantığı Player içinde.

# 1 = Helles, 2 = Weizen, 3 = Radler
const BEER_NAMES := {1: "Helles", 2: "Weizen", 3: "Radler"}
const BEER_COLORS := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45)}

@export var beer_type := 1

func _ready() -> void:
	add_to_group("interactable")
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "%s (E)" % BEER_NAMES.get(beer_type, "Bira")
		label.modulate = BEER_COLORS.get(beer_type, Color.WHITE)
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh and mesh.material_override is StandardMaterial3D:
		var m := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = (BEER_COLORS.get(beer_type, Color(0.45, 0.3, 0.15)) as Color).darkened(0.3)
		mesh.material_override = m
