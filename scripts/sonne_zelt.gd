extends DirectionalLight3D
## Sonne: Im Zelt hält das Dach die Sonne ab — der Sonnenschatten wird dort nicht gezeichnet.
## Das spart rund ein Drittel aller Zeichenaufrufe (Messung 09.10., tools/perf_aufrufe). Draußen wirft die Sonne wie gewohnt Schatten.

## Grundriss des Zelts (Wände in scenes/main.tscn), etwas kleiner, damit am Eingang noch Schatten fällt
const ZELT_MIN := Vector2(-11.5, -13.5)
const ZELT_MAX := Vector2(11.5, 10.5)

func _process(_delta: float) -> void:
	var kamera := get_viewport().get_camera_3d()
	if kamera == null:
		return
	var p := kamera.global_position
	var im_zelt := p.x > ZELT_MIN.x and p.x < ZELT_MAX.x and p.z > ZELT_MIN.y and p.z < ZELT_MAX.y and p.y < 6.0
	if shadow_enabled == im_zelt:
		shadow_enabled = not im_zelt
