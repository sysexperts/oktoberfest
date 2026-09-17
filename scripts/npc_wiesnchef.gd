extends Node3D
## Der Wiesnchef: steht am Kirmestor und wartet, nach der Einleitung
## (scripts/ui/kino.gd) läuft er zum Zelteingang voraus — das ist die erste
## Mission. Läuft bei jedem Spieler lokal dieselbe Strecke, deshalb braucht es
## kein Netz: alle sehen ihn an derselben Stelle.
##
## Die Figur steckt als Kind „Model" in der Szene (siehe scripts/figur.gd).

const Figuren := preload("res://scripts/figuren.gd")
const TEMPO := 1.55

## Welche Figur (Index in Figuren.ALLE)
@export var figur_nr := 2
## Strecke vom Tor über die Nordallee zum Zelteingang
@export var weg: Array[Vector3] = [
	Vector3(0.5, 0, 70.0),
	Vector3(0.0, 0, 58.0),
	Vector3(0.0, 0, 40.0),
	Vector3(0.0, 0, 26.0),
	Vector3(2.5, 0, 18.5),
	Vector3(3.6, 0, 15.6),
]

var _figur: Figur
var _punkt := -1
var _blick := 0.0   # Blickrichtung am Tor: nach Norden, zu den Spielern

func _ready() -> void:
	add_to_group("wiesnchef")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()
	rotation.y = _blick

## Vor und während der Einleitung: am Tor stehen, Blick zu den Spielern (Norden).
## Die Figurenmodelle schauen bei Drehung 0 nach +Z (wie budenbesitzer.interact_point).
func warten() -> void:
	_punkt = -1
	_figur.stehen()
	rotation.y = 0.0

## Nach der Einleitung: zum Zelteingang vorlaufen
func losgehen() -> void:
	if _punkt >= 0:
		return
	_punkt = 0
	_figur.gehen()

## true, sobald er am Zelt angekommen ist
func angekommen() -> bool:
	return _punkt >= weg.size()

func _process(delta: float) -> void:
	if _punkt < 0 or _punkt >= weg.size():
		return
	var ziel: Vector3 = weg[_punkt]
	var zu := ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.25:
		_punkt += 1
		if _punkt >= weg.size():
			_figur.stehen()
			# am Eingang den nachkommenden Spielern zuwenden (Norden)
			rotation.y = 0.0
		return
	global_position += zu.normalized() * minf(TEMPO * delta, zu.length())
	rotation.y = atan2(zu.x, zu.z)

## Beim Reden gestikulieren (Einleitung): eine Steh-Extraanimation, danach wieder stehen.
func geste() -> void:
	if _punkt >= 0 or _figur == null:
		return
	if not _figur.extra():
		return
	get_tree().create_timer(2.6).timeout.connect(func() -> void:
		if _punkt < 0 and is_instance_valid(_figur):
			_figur.stehen())
