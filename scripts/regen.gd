extends Node3D
## Regen (Tagesereignis): Tropfen fallen rund um die Kamera. Im Zelt blendet
## der Regen aus — das Dach hält dicht. Aufbau: scenes/regen.tscn.

## Grundriss des Zelts (Wände in scenes/main.tscn)
const ZELT_MIN := Vector2(-12.3, -14.3)
const ZELT_MAX := Vector2(12.3, 11.3)

@onready var _tropfen: GPUParticles3D = $Tropfen

func _ready() -> void:
	setze(false)

func setze(an: bool) -> void:
	visible = an
	_tropfen.emitting = an

func _process(_delta: float) -> void:
	if not visible:
		return
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var p := kamera.global_position
	global_position = p + Vector3(0, 7.0, 0)
	var im_zelt := p.x > ZELT_MIN.x and p.x < ZELT_MAX.x and p.z > ZELT_MIN.y and p.z < ZELT_MAX.y
	_tropfen.visible = not im_zelt
