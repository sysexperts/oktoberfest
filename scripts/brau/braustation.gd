class_name Braustation
extends Node3D
## Gefäß im Braukeller: Maischbottich (schritt 1) und Sudkessel (schritt 2).
##
## Rezept: Malz + Wasser im Bottich rühren → im Kessel kochen, Hopfen kommt bei
## 60 % dazu → mit Hefe ins Gärfass. Gerechnet wird beim Server
## (GameManager.net_brauen), hier steht die Anzeige am Gefäß.

## 1 = Maischbottich, 2 = Sudkessel
@export var schritt := 1

var fortschritt := 0.0
var fertig := false

@onready var _schild: Label3D = $Anzeige

func _ready() -> void:
	add_to_group("braustation")
	add_to_group("interactable")
	_beschriften()

func setze_fortschritt(wert: float, ist_fertig: bool) -> void:
	fortschritt = clampf(wert, 0.0, 1.0)
	fertig = ist_fertig
	_beschriften()

func _beschriften() -> void:
	if _schild == null:
		return
	if fertig:
		_schild.text = tr("BRAU_FERTIG")
		_schild.modulate = Color(0.6, 0.95, 0.5)
		return
	if fortschritt <= 0.0:
		_schild.text = ""
		return
	_schild.text = "%d %%" % int(round(fortschritt * 100.0))
	_schild.modulate = Color(1, 0.86, 0.5)

## Angesprochen wird am oberen Rand des Gefäßes, nicht am Boden
func interact_point() -> Vector3:
	var p := get_node_or_null("Ansprechpunkt") as Node3D
	return p.global_position if p else global_position
