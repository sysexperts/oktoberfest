class_name Transportfass
extends Node3D
## Tragbares Fass: unten am Gärfass füllen, hochtragen, oben ins Thekenfass
## umfüllen. Kapazität wie ein Thekenfass, damit eine Fuhre genau reicht.

const KAPAZITAET := 50

var inhalt := 0

@onready var _schild: Label3D = $Fuellstand

func _ready() -> void:
	add_to_group("transportfass")
	_beschriften()

func setze_inhalt(wert: int) -> void:
	inhalt = clampi(wert, 0, KAPAZITAET)
	_beschriften()

func _beschriften() -> void:
	if _schild:
		_schild.text = "%d/%d" % [inhalt, KAPAZITAET]
		_schild.visible = inhalt > 0

func interact_point() -> Vector3:
	var p := get_node_or_null("Ansprechpunkt") as Node3D
	return p.global_position if p else global_position
