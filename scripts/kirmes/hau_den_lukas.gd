extends Node3D
## „Hau den Lukas" auf der Kirmes. Aufbau: scenes/kirmes/hau_den_lukas.tscn —
## gebackener Stand (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Ablauf: beim Budenbesitzer E → Server bucht ab → Blick auf den Turm, Hammer in
## der Hand. Die Kraftanzeige pendelt immer schneller; Linksklick im richtigen
## Moment schlägt zu, der Schlitten saust hoch — ganz oben klingelt die Glocke.
## 3 Schläge, der beste zählt: Punkte 0–10 → Preis vom Server. Nur beim Schläger.

@export var preis := 2
@export var hinweis := "HINT_LUKAS"
@export var schlaege := 3
## Pendel der Kraftanzeige: Schwingungen je Sekunde beim ersten und letzten Schlag
@export var pendel_tempo := Vector2(0.9, 1.6)

const SCHLITTEN_UNTEN := 0.75
const SCHLITTEN_OBEN := 5.95

var _spieler: Node = null
var _uebrig := 0
var _bester := 0.0
var _t := 0.0
var _kraft := 0.0
var _animation := false

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _hammer: Node3D = $Stand/SpielKamera/Hammer
@onready var _schlitten: Node3D = $Stand/Turm/Schlitten
@onready var _glocke: Node3D = $Stand/Turm/Kopf
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _anzeige_kraft: ProgressBar = $Anzeige/Kraft
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_hammer.visible = false
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
	_bester = 0.0
	_t = 0.0
	_animation = false
	_schlitten.position.y = SCHLITTEN_UNTEN
	_kamera.current = true
	_hammer.visible = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	if _spieler == null or _animation:
		return
	_t += delta
	var runde := float(schlaege - _uebrig) / float(maxi(1, schlaege - 1))
	var tempo := lerpf(pendel_tempo.x, pendel_tempo.y, runde)
	# Pendelt zwischen 0 und 1, oben kurz (schwer zu treffen)
	_kraft = pow(0.5 - 0.5 * cos(TAU * tempo * _t), 1.4)
	_anzeige_kraft.value = _kraft * 100.0
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if not _animation:
			_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _uebrig > 0 and not _animation:
		_schlagen(_kraft)

func _schlagen(kraft: float) -> void:
	_uebrig -= 1
	_animation = true
	_bester = maxf(_bester, kraft)
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	var tw := create_tween()
	# Hammer ausholen und runter
	tw.tween_property(_hammer, "rotation_degrees:x", -95.0, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hammer, "rotation_degrees:x", 15.0, 0.12).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		if sfx:
			sfx.play_oder("schlag", "pop", -6.0))
	# Schlitten hoch, oben Glocke
	var hoehe := lerpf(SCHLITTEN_UNTEN, SCHLITTEN_OBEN, kraft)
	tw.tween_property(_schlitten, "position:y", hoehe, 0.25 + kraft * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if kraft >= 0.97:
		tw.tween_callback(func() -> void:
			if sfx:
				sfx.play("ding")
				sfx.play("cheer"))
		tw.tween_property(_glocke, "rotation:z", 0.08, 0.06)
		tw.tween_property(_glocke, "rotation:z", -0.06, 0.1)
		tw.tween_property(_glocke, "rotation:z", 0.0, 0.15)
	tw.tween_interval(0.35)
	tw.tween_property(_schlitten, "position:y", SCHLITTEN_UNTEN, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_hammer, "rotation_degrees:x", -40.0, 0.4)
	tw.tween_callback(func() -> void:
		_animation = false
		_t = 0.0
		if _uebrig <= 0:
			_beenden())

func _punkte() -> int:
	return 10 if _bester >= 0.97 else roundi(_bester * 9.0)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("LUKAS_ANZEIGE")) % [_punkte(), _uebrig]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, _punkte())
	_anzeige.visible = false
	_hammer.visible = false
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
