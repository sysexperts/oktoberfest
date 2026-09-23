@tool
class_name Ring
extends ColorRect
## Ringanzeige in der Leiste (assets/shader/ui_ring.gdshader): 0 … 100 Prozent
## als Bogen um ein Symbol. Ersetzt die früheren Balken — ein Ring braucht keine
## Beschriftung daneben und bleibt auch klein lesbar.
##
## Es ist ein ColorRect, weil ein nackter Control nichts zeichnet und der
## Shader damit nie liefe — die Farbe des Rechtecks selbst ist egal.
##
## Der Wert wird nicht sprunghaft gesetzt: `setze` lässt den Bogen hinübergleiten
## (scripts/hud.gd ruft das), `wert` setzt ihn sofort.

## Ab hier gilt der Wert als schlecht und der Ring färbt sich um
@export var warnung_unter := 40.0
@export var farbe_gut := Color(1, 0.839, 0.349)
@export var farbe_warnung := Color(1, 0.42, 0.35)

@export_range(0.0, 100.0) var wert := 75.0:
	set(v):
		wert = clampf(v, 0.0, 100.0)
		_anwenden()

func _ready() -> void:
	_anwenden()

func _anwenden() -> void:
	var m := material as ShaderMaterial
	if m == null:
		return
	m.set_shader_parameter("wert", wert / 100.0)
	m.set_shader_parameter("farbe", farbe_warnung if wert <= warnung_unter else farbe_gut)

## Gleitet auf den neuen Wert; gibt den Tween zurück, damit der Aufrufer einen
## alten Lauf abbrechen kann.
func gleiten(ziel: float, dauer := 0.5) -> Tween:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: wert = v, wert, clampf(ziel, 0.0, 100.0), dauer) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return tw
