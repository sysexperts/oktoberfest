class_name Muellplatz
extends Node3D
## Große Mülltonne vor dem Zelt (Tutorial „Putze das Zelt"): Spieler werfen
## getragene Säcke hier hinein (E), morgens holt die Müllabfuhr sie ab.
## Modell: tools/bake_muelltonne.gd → assets/dreck/muelltonne(_deckel).tres.
## Füllstand = Anzahl (GameManager.net_muell_abgeben / _muellplatz_zeigen): je
## voller, desto weiter steht der Deckel auf und desto mehr Säcke lugen aus dem
## Spalt. Gestapelt wird nichts mehr — daher auch kein Stapel, der verrutscht.

## So weit klappt der Deckel beim Einwerfen auf
const DECKEL_AUF := -1.15
## So weit steht er je eingeworfenem Sack offen (bis zu drei)
const DECKEL_JE_SACK := -0.085
const WURF_DAUER := 0.45

@onready var _saecke: Node3D = $Saecke
@onready var _gelenk: Node3D = $DeckelGelenk
@onready var _wurfsack: MeshInstance3D = $Wurfsack

var _wurf: Tween
var _voll := 0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("muellplatz")
	anzahl_setzen(0)

## Angesprochen wird die Tonne auf Griffhöhe vor dem Deckel.
func interact_point() -> Vector3:
	return global_position + Vector3(0, 1.0, 0)

func anzahl_setzen(n: int) -> void:
	var saecke := _saecke.get_children()
	for i in saecke.size():
		(saecke[i] as Node3D).visible = i < n
	_voll = mini(n, saecke.size())
	if _wurf == null or not _wurf.is_valid():
		_gelenk.rotation.x = _ruhe_winkel()

## Deckelstellung, wenn gerade nichts geworfen wird.
func _ruhe_winkel() -> float:
	return DECKEL_JE_SACK * float(_voll)

## Ein Sack fliegt in die Tonne: Deckel auf, Sack im Bogen hinein, Deckel zu.
## Läuft bei jedem Spieler (GameManager._net_muell_geworfen).
func einwerfen() -> void:
	if _wurf and _wurf.is_valid():
		_wurf.kill()
	var start := Vector3(0, 0.9, 1.5)
	var ziel := Vector3(0, 1.15, 0.05)
	_wurfsack.scale = Vector3(0.34, 0.34, 0.34)
	_wurfsack.position = start
	_wurfsack.visible = true
	_wurf = create_tween()
	_wurf.tween_property(_gelenk, "rotation:x", DECKEL_AUF, 0.12)
	# Bogen: erst hoch über den Rand, dann hinein
	_wurf.parallel().tween_property(_wurfsack, "position", Vector3(0, 1.75, 0.75), WURF_DAUER * 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_wurf.parallel().tween_property(_wurfsack, "rotation:x", -2.2, WURF_DAUER)
	_wurf.chain().tween_property(_wurfsack, "position", ziel, WURF_DAUER * 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_wurf.parallel().tween_property(_wurfsack, "scale", Vector3(0.2, 0.2, 0.2), WURF_DAUER * 0.45)
	_wurf.chain().tween_callback(func() -> void: _wurfsack.visible = false)
	_wurf.tween_property(_gelenk, "rotation:x", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
