extends Node3D
## Spielautomat im Casino (scenes/kasino/slot.tscn): drei Walzen mit Symbolen. Der Server würfelt (GameManager.net_slot),
## hier laufen die Walzen bei allen Spielern los und bleiben nacheinander auf dem Ergebnis stehen.

const SYMBOLE: Array[Texture2D] = [
	preload("res://assets/ui/symbole/bier.svg"), preload("res://assets/ui/symbole/brezn.svg"),
	preload("res://assets/ui/symbole/zitrone.svg"), preload("res://assets/ui/symbole/stern.svg"),
	preload("res://assets/ui/symbole/pokal.svg"), preload("res://assets/ui/symbole/geld.svg"),
]

var _lauf := 0.0
var _stopp := [0.0, 0.0, 0.0]
var _ziel := [0, 0, 0]
var _takt := 0.0

@onready var _walzen: Array[Sprite3D] = [$Walzen/Walze0, $Walzen/Walze1, $Walzen/Walze2]

func _ready() -> void:
	add_to_group("slot")
	set_process(false)
	for i in _walzen.size():
		_walzen[i].texture = SYMBOLE[i * 2 % SYMBOLE.size()]

## Walzen starten, sie halten nacheinander nach 1,2 / 1,8 / 2,4 Sekunden
func drehen(ergebnis: Array) -> void:
	_ziel = ergebnis
	_lauf = 0.0
	_stopp = [1.2, 1.8, 2.4]
	set_process(true)
	var hebel := get_node_or_null("Hebel") as Node3D
	if hebel:
		var t := create_tween()
		t.tween_property(hebel, "rotation:x", 0.9, 0.18)
		t.tween_property(hebel, "rotation:x", 0.0, 0.35)

func _process(delta: float) -> void:
	_lauf += delta
	_takt -= delta
	var fertig := true
	for i in _walzen.size():
		if _lauf >= float(_stopp[i]):
			_walzen[i].texture = SYMBOLE[clampi(int(_ziel[i]), 0, SYMBOLE.size() - 1)]
		else:
			fertig = false
			if _takt <= 0.0:
				_walzen[i].texture = SYMBOLE[randi() % SYMBOLE.size()]
	if _takt <= 0.0:
		_takt = 0.07
	if fertig:
		set_process(false)
