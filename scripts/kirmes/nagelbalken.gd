extends Node3D
## Nagelbalken. Aufbau: scenes/kirmes/nagelbalken.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → Blick auf den Nagel im Baumstamm, Hammer
## in der Hand. Die Kraftanzeige pendelt, der Hammer wackelt seitlich über dem Nagel.
## Linksklick schlägt: Kraft × Treffgenauigkeit treibt den Nagel ein, ein schiefer
## kräftiger Schlag verbiegt ihn. Punkte: mit 1–2 Schlägen versenkt 10, mit 3 8,
## 4 6, 5 4; nicht versenkt bis 3 → Preis vom Server wie bei der Schießbude.

@export var preis := 2
@export var hinweis := "HINT_NAGEL"
@export var schlaege := 5
## Schwingungen je Sekunde: Kraftpendel und seitliches Wackeln
@export var pendel_tempo := 1.0
@export var wackel_tempo := 1.55
## So weit schaut der Nagel anfangs heraus (m)
@export var nagel_laenge := 0.11

const PUNKTE_NACH_SCHLAEGEN := [10, 10, 7, 4, 2]
const WACKELN := 0.11

var _spieler: Node = null
var _uebrig := 0
var _tiefe := 0.0
var _krumm := false
var _t := 0.0
var _kraft := 0.0
var _zielen := 0.0
var _animation := false
var _ende_in := -1.0
var _nagel_grund := Vector3.ZERO
var _hammer_grund := Transform3D()

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _hammer: Node3D = $Stand/SpielKamera/Hammer
@onready var _nagel: Node3D = $Stand/Stamm/Nagel
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _kraft_balken: ProgressBar = $Anzeige/Kraft
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_hammer.visible = false
	_nagel_grund = _nagel.position
	_hammer_grund = _hammer.transform
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_uebrig = schlaege
	_tiefe = 0.0
	_krumm = false
	_t = randf() * 3.0
	_animation = false
	_ende_in = -1.0
	_nagel.position = _nagel_grund
	_nagel.rotation = Vector3.ZERO
	_hammer.transform = _hammer_grund
	_hammer.visible = true
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	if _spieler == null:
		return
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()
		return
	# Pendel und Wackeln laufen auch während des Schlags weiter — sonst könnte man
	# direkt danach mit den eingefrorenen guten Werten gleich noch einmal schlagen
	_t += delta
	_kraft = pow(0.5 - 0.5 * cos(TAU * pendel_tempo * _t), 1.3)
	_zielen = sin(TAU * wackel_tempo * _t + 0.7)
	if not _animation:
		_hammer.transform = Transform3D(_hammer_grund.basis, _hammer_grund.origin + Vector3(_zielen * WACKELN, 0, 0))
	_kraft_balken.value = _kraft * 100.0
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not _animation:
			_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		schlagen()

## Treffgenauigkeit 0–1 (1 = Hammer genau über dem Nagel)
func genauigkeit() -> float:
	return 1.0 - absf(_zielen)

## Zuschlagen mit der aktuellen Kraft und Lage (auch für Tests)
func schlagen() -> void:
	if _spieler == null or _animation or _uebrig <= 0 or _ende_in >= 0.0:
		return
	var kraft := _kraft
	var genau := genauigkeit()
	_uebrig -= 1
	_animation = true
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	var tw := create_tween()
	tw.tween_property(_hammer, "rotation_degrees:x", _hammer.rotation_degrees.x + 40.0, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hammer, "rotation_degrees:x", _hammer.rotation_degrees.x - 35.0, 0.09).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if genau < 0.3 and kraft > 0.45:
			_krumm = true
			_nagel.rotation_degrees = Vector3(0, 0, 55.0 * (1.0 if _zielen > 0.0 else -1.0))
			if sfx:
				sfx.play_oder("pop", "pop", -2.0)
		else:
			# Genauigkeit zählt stark: nur saubere, volle Schläge treiben den Nagel weit rein
			_tiefe = minf(1.0, _tiefe + pow(kraft, 1.4) * pow(genau, 2.4) * 0.72)
			_nagel.position = _nagel_grund - Vector3(0, _tiefe * nagel_laenge, 0)
			if sfx:
				sfx.play_oder("schlag", "pop", -6.0)
				if _tiefe >= 1.0:
					sfx.play("ding"))
	tw.tween_interval(0.25)
	tw.tween_property(_hammer, "transform", _hammer_grund, 0.25)
	tw.tween_callback(func() -> void:
		_animation = false
		if _tiefe >= 1.0 or _krumm or _uebrig <= 0:
			_ende_in = 1.0)

func punkte() -> int:
	if _tiefe >= 1.0 and not _krumm:
		return PUNKTE_NACH_SCHLAEGEN[clampi(schlaege - _uebrig - 1, 0, PUNKTE_NACH_SCHLAEGEN.size() - 1)]
	return floori(_tiefe * 3.0)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("NAGEL_ANZEIGE")) % [roundi(_tiefe * 100.0), _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_hammer.visible = false
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
