extends Node3D
## Abgelegter Gegenstand am Boden: Krug (mit Füllstand und Sorte) oder Teller.
## Wer etwas in der Hand hat und E ins Leere drückt, legt es hier ab — vorher war
## es einfach weg (Test 13.09.). Mit leeren Händen E: wieder aufheben.
## Verwaltet vom GameManager (net_ablegen, net_aufheben). Aufbau: scenes/abgelegt.tscn.
## Ohne class_name (neue Klassennamen brauchen auf dem Server eine Neuindizierung).

const BIER_FARBEN := {0: Color(0.95, 0.65, 0.05), 1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45), 4: Color(0.75, 0.35, 0.08)}

var ablage_id := -1
## 1 = Krug, 2 = Teller (wie Player.carry_state)
var art := 1
var typ := 0
var fuellung := 1.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("abgelegt")
	_zeigen()

func setzen(a: int, t: int, f: float) -> void:
	art = a
	typ = t
	fuellung = f
	if is_inside_tree():
		_zeigen()

func ist_abgelegt() -> bool:
	return true

## Angesprochen wird der Gegenstand, nicht der Boden darunter.
func interact_point() -> Vector3:
	return global_position + Vector3(0, 0.15, 0)

func _zeigen() -> void:
	var krug := %Krug
	var teller := %Teller
	krug.visible = art == 1
	teller.visible = art == 2
	if art == 1:
		krug.fuellung = fuellung
		krug.farbe = BIER_FARBEN.get(typ, BIER_FARBEN[0])
	elif art == 2:
		teller.sorte = clampi(typ, 1, 3)
