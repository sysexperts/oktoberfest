class_name Kellertuer
extends Node3D
## Tür zum Braukeller. Sie ist verschlossen, bis das Festzelt einmal ausgebaut
## ist (Zeltstufe 2) — vorher gehört der Keller noch der Brauerei.
##
## Zustand liegt beim Server (GameManager: _keller_offen), geöffnet wird über
## net_keller_oeffnen. Hier steckt nur das Türblatt: Kollision an, wenn zu,
## Blatt gedreht, wenn offen.

## Winkel des offenen Türblatts
const OFFEN_GRAD := 96.0
const DREH_DAUER := 0.7

@onready var _blatt: Node3D = $Blatt
@onready var _riegel: CollisionShape3D = $Kollision/Form

var _offen := false

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("kellertuer")
	_blatt.rotation.y = 0.0
	_riegel.disabled = false

## Vom GameManager gesetzt: ist der Keller freigeschaltet und die Tür auf?
func setze_offen(offen: bool, sofort := false) -> void:
	if offen == _offen and not sofort:
		return
	_offen = offen
	_riegel.disabled = offen
	var ziel := deg_to_rad(OFFEN_GRAD) if offen else 0.0
	if sofort:
		_blatt.rotation.y = ziel
		return
	create_tween().tween_property(_blatt, "rotation:y", ziel, DREH_DAUER) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func ist_offen() -> bool:
	return _offen

## Angesprochen wird am Türblatt auf Brusthöhe
func interact_point() -> Vector3:
	return $Ansprechpunkt.global_position
