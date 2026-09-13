extends SubViewportContainer
## Drehende 3D-Vorschau einer Spielerfigur für den Warteraum.
## Aufbau: scenes/ui/figur_vorschau.tscn — Kamera, Licht und Drehteller im Editor.
## Gewählt: die Figur tanzt, sonst steht sie und dreht sich langsam.

const Figuren := preload("res://scripts/figuren.gd")
const DREH_TEMPO := 0.6

@export var figur := 0:
	set(v):
		figur = v
		if is_node_ready():
			_einsetzen()

var gewaehlt := false:
	set(v):
		if gewaehlt == v:
			return
		gewaehlt = v
		_animation()

var _figur: Figur

func _ready() -> void:
	_einsetzen()

func _einsetzen() -> void:
	var teller: Node3D = %Drehteller
	for k in teller.get_children():
		k.queue_free()
	_figur = Figuren.ALLE[posmod(figur, Figuren.ALLE.size())].instantiate() as Figur
	teller.add_child(_figur)
	_animation.call_deferred()

func _animation() -> void:
	if _figur == null or _figur.anim == null:
		return
	if gewaehlt and _figur.tanzen(1.0):
		return
	_figur.stehen()

func _process(delta: float) -> void:
	(%Drehteller as Node3D).rotate_y(delta * (DREH_TEMPO * 2.5 if gewaehlt else DREH_TEMPO))
	if _figur:
		_figur.pose_auffrischen()
