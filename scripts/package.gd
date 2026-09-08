class_name Package
extends Node3D
## Geliefertes Warenpaket. Spieler nimmt es mit E auf und trägt es zum Lager.
## kind: 1 = Bier, 2 = Essen.

const KIND_NAMES := {1: "🍺 Bierfass", 2: "🥨 Zutaten"}
const KIND_COLORS := {1: Color(0.75, 0.55, 0.2), 2: Color(0.6, 0.45, 0.3)}

var pkg_id := -1
var kind := 1
var amount := 10

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("package")
	_refresh()

func set_info(k: int, amt: int) -> void:
	kind = k
	amount = amt
	if is_inside_tree():
		_refresh()

func _refresh() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = "%s ×%d\n(E: aufnehmen)" % [KIND_NAMES.get(kind, "Ware"), amount]
	var mesh := get_node_or_null("Box") as MeshInstance3D
	if mesh and mesh.material_override is StandardMaterial3D:
		var m := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = KIND_COLORS.get(kind, Color(0.6, 0.5, 0.4))
		mesh.material_override = m
