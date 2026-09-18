class_name Package
extends Node3D
## Geliefertes Warenpaket. Spieler nimmt es mit E auf und trägt es zum Lager.
## kind: 1 = Bier, 2 = Essen, 3 = Müllsack (zum Müllplatz vor dem Zelt, nicht ins Lager).

const Texte := preload("res://scripts/ui/texte.gd")
## Beschriftung je Sorte: WORLD_PACKAGE_1 (Bier), WORLD_PACKAGE_2 (Zutaten) in texte.csv
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
	var sack := kind == 3
	for n in ["Box", "Tape"]:
		var k := get_node_or_null(n) as Node3D
		if k:
			k.visible = not sack
	var s := get_node_or_null("Sack") as Node3D
	if s:
		s.visible = sack
	if label:
		label.text = Texte.mit_tasten("WORLD_MUELLSACK") if sack else Texte.mit_tasten("WORLD_PACKAGE_%d" % clampi(kind, 1, 2)) % amount
		label.visible = not sack   # Hinweis am Fadenkreuz reicht
	if sack:
		return
	var mesh := get_node_or_null("Box") as MeshInstance3D
	if mesh and mesh.material_override is StandardMaterial3D:
		var m := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.albedo_color = KIND_COLORS.get(kind, Color(0.6, 0.5, 0.4))
		mesh.material_override = m
