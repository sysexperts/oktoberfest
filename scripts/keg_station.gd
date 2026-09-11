class_name KegStation
extends Node3D
## Fıçı istasyonu. Her fıçının bir bira tipi var (editörden beer_type ile ayarlanır).
## Dolum mantığı Player içinde.

# 1 = Helles, 2 = Weizen, 3 = Radler, 4 = Festbier
const BEER_NAMES := {1: "Helles", 2: "Weizen", 3: "Radler", 4: "Festbier"}
const BEER_COLORS := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45), 4: Color(0.75, 0.35, 0.08)}

@export var beer_type := 1

const Texte := preload("res://scripts/ui/texte.gd")

func _ready() -> void:
	add_to_group("interactable")
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.modulate = BEER_COLORS.get(beer_type, Color.WHITE)
		Einstellungen.geaendert.connect(_beschriften)
		_beschriften()
	var mesh := get_node_or_null("Mesh") as MeshInstance3D
	if mesh and mesh.material_override is StandardMaterial3D:
		var m := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = (BEER_COLORS.get(beer_type, Color(0.45, 0.3, 0.15)) as Color).darkened(0.3)
		mesh.material_override = m

## Name der Sorte in der Spielsprache, mit der aktuell belegten Taste.
func _beschriften() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = Texte.mit_tasten("WORLD_KEG_%d" % clampi(beer_type, 1, 4))
