extends Node3D
## Budenbesitzer der Schießbude: steht hinter der Theke, kassiert (E beim Spieler)
## und geht zur Kasse in der Ecke, solange geschossen wird — damit ihn niemand
## trifft. Figur fest aus der Figurenliste, damit alle Mitspieler denselben sehen.

const Figuren := preload("res://scripts/figuren.gd")
const TEMPO := 1.6

## Welche Figur (Index in Figuren.ALLE)
@export var figur_nr := 1

var bude: Node = null
var _figur: Figur
var _ziel := Vector3.ZERO
var _geht := false
var _besetzt := false

func _ready() -> void:
	add_to_group("interactable")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()
	bude = get_parent()

## Für player.gd
func ist_budenbesitzer() -> bool:
	return true

func interact_point() -> Vector3:
	return global_position + global_transform.basis.z * 0.9 + Vector3(0, 1.0, 0)

## true: zur Kasse gehen (es wird geschossen), false: zurück in die Mitte.
func besetzt_setzen(an: bool, mitte: Vector3, seite: Vector3) -> void:
	_besetzt = an
	_ziel = seite if an else mitte
	_geht = true
	_figur.gehen()

func _process(delta: float) -> void:
	if not _geht:
		return
	var zu := _ziel - position
	zu.y = 0.0
	if zu.length() < 0.05:
		position = Vector3(_ziel.x, position.y, _ziel.z)
		_geht = false
		_figur.stehen()
		# Mitte: zum Schützen schauen; Kasse: zu den Zielen, damit er zuschaut
		rotation.y = 0.0 if not _besetzt else deg_to_rad(-150.0)
		return
	position += zu.normalized() * minf(TEMPO * delta, zu.length())
	rotation.y = atan2(zu.x, zu.z)
