class_name Ausgabe
extends Node3D
## Ausgabe an der Theke: Zapfer und Koch stellen hier fertige Krüge und Essen
## ab, Spieler und Kellner nehmen sie nur noch mit. Nur Darstellung — was
## bereitsteht, führt der GameManager (_ausgabe) und schickt es per set_inhalt.
## Aufbau: scenes/ausgabe.tscn (Krug0…, Essen0… sind vorbereitete Knoten).

const Texte := preload("res://scripts/ui/texte.gd")
## Farben wie beim Spieler (player.gd BEER_COLORS / FOOD_COLORS)
const BIER_FARBEN := {1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45)}
const ESSEN_FARBEN := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2)}

## "kind_typ" -> Anzahl, z. B. {"1_1": 3, "2_1": 1}
var inhalt := {}
var _kruege: Array[Node3D] = []
var _essen: Array[Node3D] = []

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("ausgabe")
	for c in $Kruege.get_children():
		_kruege.append(c)
	for c in $Essen.get_children():
		_essen.append(c)
	Einstellungen.geaendert.connect(_beschriften)
	set_inhalt({})

func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func set_inhalt(neu: Dictionary) -> void:
	inhalt = neu
	var k := 0
	var e := 0
	for schluessel: String in inhalt:
		var teile := schluessel.split("_")
		var art := int(teile[0])
		var typ := int(teile[1])
		for n in int(inhalt[schluessel]):
			if art == 1 and k < _kruege.size():
				_faerben(_kruege[k], BIER_FARBEN.get(typ, Color.WHITE))
				_kruege[k].visible = true
				k += 1
			elif art == 2 and e < _essen.size():
				_faerben(_essen[e], ESSEN_FARBEN.get(typ, Color.WHITE))
				_essen[e].visible = true
				e += 1
	for i in range(k, _kruege.size()):
		_kruege[i].visible = false
	for i in range(e, _essen.size()):
		_essen[i].visible = false
	_beschriften()

func anzahl(art: int) -> int:
	var n := 0
	for schluessel: String in inhalt:
		if schluessel.begins_with("%d_" % art):
			n += int(inhalt[schluessel])
	return n

func hat_fertiges() -> bool:
	return anzahl(1) + anzahl(2) > 0

func _faerben(knoten: Node3D, farbe: Color) -> void:
	var inhalt_mesh := knoten.get_node_or_null("Inhalt") as MeshInstance3D
	if inhalt_mesh == null:
		return
	var m := inhalt_mesh.material_override as StandardMaterial3D
	if m == null:
		return
	if not inhalt_mesh.has_meta("eigenes_material"):
		m = m.duplicate()
		inhalt_mesh.material_override = m
		inhalt_mesh.set_meta("eigenes_material", true)
	m.albedo_color = farbe

func _beschriften() -> void:
	var label := get_node_or_null("Label") as Label3D
	if label:
		label.text = Texte.mit_tasten("WORLD_AUSGABE") % [anzahl(1), anzahl(2)]
