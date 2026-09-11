class_name Artist
extends Node3D
## Künstler auf der Bühne — tanzt die ganze Schicht.
## Figur und Tanz kommen aus scripts/figuren.gd; die Figur hängt am Knotennamen
## (Artist0, Artist1 …), der bei allen Mitspielern gleich ist.

const Figuren := preload("res://scripts/figuren.gd")

var tier := 1

var _figur: Figur
var _t := 0.0

@onready var _model: Node3D = $Model
@onready var _label: Label3D = $Label

func _ready() -> void:
	add_to_group("artist")
	_figur = Figuren.einsetzen(self, Figuren.fuer_id(String(name).hash()))
	_model = _figur
	if not _figur.tanzen(randf_range(0.9, 1.1)):
		_figur.stehen()
	# leicht versetzt starten, damit nicht alle synchron zappeln
	_t = randf() * 6.0

func set_tier(t: int) -> void:
	tier = t
	if _label:
		match t:
			1: _label.text = "🎸 Straßenmusiker"
			2: _label.text = "🎺 Blaskapelle"
			_: _label.text = "⭐ Star-Act"

func _process(delta: float) -> void:
	_t += delta
	if _model:
		_model.rotation.y = sin(_t * 1.4) * 0.35
		_model.position.y = absf(sin(_t * 3.0)) * 0.08
