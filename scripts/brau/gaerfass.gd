class_name Gaerfass
extends Node3D
## Liegendes Lagerfass im Braukeller. Hier gärt der Sud fünf Minuten, danach
## kann man das Bier ins Transportfass abfüllen.
##
## Zustände: leer · gärt (mit Restzeit) · fertig (mit Menge). Der Server führt
## sie, hier wird nur angezeigt.

enum { LEER, GAERT, FERTIG }

var zustand := LEER
var rest := 0.0
var menge := 0

@onready var _schild: Label3D = $Sorte

func _ready() -> void:
	add_to_group("gaerfass")
	_beschriften()

func setze(neu_zustand: int, neu_rest: float, neu_menge: int) -> void:
	zustand = neu_zustand
	rest = neu_rest
	menge = neu_menge
	_beschriften()

func _beschriften() -> void:
	if _schild == null:
		return
	match zustand:
		GAERT:
			_schild.text = "%d:%02d" % [int(rest) / 60, int(rest) % 60]
			_schild.modulate = Color(1, 0.78, 0.35)
		FERTIG:
			_schild.text = "%d" % menge
			_schild.modulate = Color(0.6, 0.95, 0.5)
		_:
			_schild.text = "—"
			_schild.modulate = Color(0.8, 0.78, 0.72)

func interact_point() -> Vector3:
	var p := get_node_or_null("Ansprechpunkt") as Node3D
	return p.global_position if p else global_position
