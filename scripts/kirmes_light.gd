class_name KirmesLight
extends OmniLight3D
## Buntes, langsam wanderndes Kirmeslicht an den Ständen und Fahrgeschäften.

@export var hue_speed := 0.12
## Wie stark die Helligkeit dabei pulsiert (Anteil der Grundhelligkeit).
@export var pulse := 0.25

var _t := 0.0
var _basis := 1.0

func _ready() -> void:
	# Grundhelligkeit ist das, was in der Szene eingestellt ist — sonst würde
	# das Skript die Einstellung jedes Frames überschreiben und alles wäre
	# gleich hell (und zusammen viel zu hell).
	_basis = light_energy
	_t = randf() * 20.0   # jeder Stand fängt woanders an

func _process(delta: float) -> void:
	_t += delta
	light_color = Color.from_hsv(fmod(_t * hue_speed, 1.0), 0.7, 1.0)
	light_energy = _basis * (1.0 + sin(_t * 1.8) * pulse)
