extends Node3D
## Hintergrund des Hauptmenüs (Plan 4.2): der Kirmesplatz mit Zelt bei Nacht,
## ein paar Besucher, und eine Kamera, die langsam ihre Kreise zieht.
## Aufbau liegt in scenes/ui/menue_hintergrund.tscn — Licht, Nebel und
## Kameraposition dort im Editor anpassen.

## Wie schnell die Kamera um den Platz fährt.
@export var grad_pro_sekunde := 2.5
## Wohin die Kamera schaut, relativ zum Drehpunkt.
@export var blickhoehe := 3.0

@onready var _drehpunkt: Node3D = $Drehpunkt
@onready var _kamera: Camera3D = $Drehpunkt/Kamera
@onready var _menge: Node = $Crowd

func _ready() -> void:
	_kamera.look_at(_drehpunkt.global_position + Vector3(0, blickhoehe, 0))
	_kamera.current = true
	_menge.set_density(1.0)
	# Nicht bei jedem Start von derselben Seite
	_drehpunkt.rotate_y(randf() * TAU)

func _process(delta: float) -> void:
	_drehpunkt.rotate_y(deg_to_rad(grad_pro_sekunde) * delta)
