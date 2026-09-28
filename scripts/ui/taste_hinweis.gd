extends Node3D
## Kleines Tastensymbol über einem anvisierten Gegenstand: Kreis mit der Taste
## (Tastatur, z. B. „E") oder das Knopfbild des Controllers. Nur sichtbar,
## solange der Spieler nah genug dran ist und das Ziel die Umrandung hat.

@export var aktion := "interact"

@onready var _kreis: Sprite3D = $Kreis
@onready var _taste: Label3D = $Taste
@onready var _knopf: Sprite3D = $Knopf

func _ready() -> void:
	visible = false

func zeigen(an: bool) -> void:
	visible = an
	if not an:
		return
	var glyph := Einstellungen.glyph_pfad(aktion)
	var pad := glyph != ""
	_kreis.visible = not pad
	_taste.visible = not pad
	_knopf.visible = pad
	if pad:
		_knopf.texture = load(glyph)
	else:
		_taste.text = Einstellungen.tasten_name(aktion)
