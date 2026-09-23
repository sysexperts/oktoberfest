@tool
extends ColorRect
## Milchglas hinter einem UI-Feld: verwischt das Spielbild dahinter und
## schneidet die Ecken rund ab (assets/shader/ui_glas.gdshader).
##
## Als erstes Kind in einen PanelContainer legen — es wird vor dem Stilrahmen,
## aber hinter dem Inhalt gezeichnet. Der Shader braucht die Knotengröße als
## Uniform, weil ein Canvas-Shader sie nicht selbst kennt; das hält dieses
## Skript nach, auch wenn das Feld mit seinem Inhalt wächst.
##
## Der Radius muss zum Stilrahmen des Feldes passen, sonst schauen an den Ecken
## Reste heraus.

@export var radius := 18.0:
	set(v):
		radius = v
		_anwenden()

func _ready() -> void:
	resized.connect(_anwenden)
	_anwenden()

func _anwenden() -> void:
	var m := material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("groesse", size)
	m.set_shader_parameter("radius", radius)
