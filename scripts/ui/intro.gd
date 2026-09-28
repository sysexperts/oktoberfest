extends CanvasLayer
## Studio-Intro beim ersten Hauptmenü: schwarz, Logo blendet ein, dann löst sich
## das Schwarz mit Unschärfe ins Menü auf. Die Menümusik läuft dabei schon
## (startet im Menü selbst). Nur einmal pro Programmstart; Klick/Taste überspringt.

static var gezeigt := false

@onready var _schwarz: ColorRect = %Schwarz
@onready var _logo: TextureRect = %Logo
@onready var _blur: ColorRect = %Blur

var _tw: Tween

func _ready() -> void:
	if gezeigt or OS.get_cmdline_user_args().has("--server"):
		queue_free()
		return
	gezeigt = true
	_logo.modulate.a = 0.0
	var mat := _blur.material as ShaderMaterial
	mat.set_shader_parameter("staerke", 1.0)
	_tw = create_tween()
	_tw.tween_interval(0.4)
	_tw.tween_property(_logo, "modulate:a", 1.0, 1.2).set_trans(Tween.TRANS_SINE)
	_tw.tween_interval(1.6)
	_tw.tween_callback(_aufloesen)

func _aufloesen() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween().set_parallel(true)
	var mat := _blur.material as ShaderMaterial
	_tw.tween_property(_logo, "modulate:a", 0.0, 0.7)
	_tw.tween_property(_logo, "scale", Vector2.ONE * 1.08, 1.4)
	_tw.tween_property(_schwarz, "color:a", 0.0, 1.1).set_delay(0.3)
	_tw.tween_method(func(v: float): mat.set_shader_parameter("staerke", v), 1.0, 0.0, 1.4).set_delay(0.3)
	_tw.chain().tween_callback(queue_free)

func _input(ev: InputEvent) -> void:
	if (ev is InputEventKey or ev is InputEventMouseButton or ev is InputEventJoypadButton) and ev.is_pressed():
		get_viewport().set_input_as_handled()
		if _schwarz.color.a >= 1.0:
			_aufloesen()
