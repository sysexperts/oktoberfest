extends Node3D
## Maßkrugstemmen. Aufbau: scenes/kirmes/stemmen.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → man steht auf der Bühne, der volle Krug
## am ausgestreckten Arm. Der Arm sinkt und zittert immer stärker; die Maus (hoch/
## runter) hält ihn waagrecht. Ist er zu lange zu weit weg, kippt er → Ende.
## Je 4 Sekunden 1 Punkt (0–10) → Preis vom Server wie bei der Schießbude.

@export var preis := 2
@export var hinweis := "HINT_STEMMEN"
@export var sekunden_je_punkt := 4.0
## Ab dieser Abweichung (Grad) ist der Arm außerhalb
@export var grenze := 15.0
## So lange darf er außerhalb sein, bevor er kippt
@export var gnadenzeit := 0.35
## Grad je Mauspixel
@export var maus_empfindlichkeit := 0.05

var _spieler: Node = null
var _t := 0.0
var _winkel := 0.0
var _ausserhalb := 0.0
var _gehalten := 0.0
var _ende_in := -1.0
var _gekippt := false
var _ruck_in := 2.0

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _arm: Node3D = $Stand/SpielKamera/Arm
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _lage: ProgressBar = $Anzeige/Lage
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_arm.visible = false
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_t = 0.0
	_winkel = 0.0
	_ausserhalb = 0.0
	_gehalten = 0.0
	_ende_in = -1.0
	_gekippt = false
	_arm.rotation = Vector3.ZERO
	_arm.visible = true
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	if _spieler == null:
		return
	if _ende_in >= 0.0:
		_ende_in -= delta
		# gekippt: Arm fällt; geschafft: Krug hoch zum Prosit
		var ziel := -70.0 if _gekippt else 35.0
		_arm.rotation_degrees.x = move_toward(_arm.rotation_degrees.x, ziel, delta * 140.0)
		if _ende_in < 0.0:
			_beenden()
		return
	_t += delta
	# Der Krug zieht immer stärker nach unten, dazu wachsendes Zittern
	var sinken := 3.5 + _t * 0.45
	var zittern := (1.5 + _t * 0.22) * (sin(_t * 7.3) + 0.6 * sin(_t * 3.1 + 1.0) + 0.4 * sin(_t * 13.7 + 2.0))
	_winkel += (zittern * 3.5 - sinken) * delta
	# Ab und zu gibt der Arm ruckartig nach — mit der Zeit öfter und stärker
	_ruck_in -= delta
	if _ruck_in <= 0.0:
		_ruck_in = randf_range(1.5, 4.0) / (1.0 + _t * 0.03)
		_winkel += (3.0 + _t * 0.15) * (-1.0 if randf() < 0.7 else 1.0)
	if absf(_winkel) > grenze:
		_ausserhalb += delta
	else:
		_ausserhalb = 0.0
		_gehalten = _t
	if _ausserhalb > gnadenzeit:
		_gekippt = true
		_ende_in = 1.3
		_sfx("pop", -4.0)
	elif punkte() >= 10:
		_ende_in = 1.3
		_sfx("cheer", -6.0)
	_arm.rotation_degrees = Vector3(_winkel, 0.0, sin(_t * 9.0) * minf(4.0, _t * 0.12))
	_lage.value = clampf(50.0 + _winkel / (grenze * 2.0) * 100.0, 0.0, 100.0)
	var a := absf(_winkel) / grenze
	_lage.modulate = Color(0.45, 1.0, 0.45) if a < 0.6 else (Color(1.0, 0.85, 0.3) if a < 1.0 else Color(1.0, 0.35, 0.3))
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm and _ende_in < 0.0:
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		heben(-mm.relative.y * maus_empfindlichkeit * Einstellungen.maus * y_dir)

## Arm um grad anheben (negativ senkt) — auch für Tests
func heben(grad: float) -> void:
	_winkel += grad

func _sfx(name: String, db: float) -> void:
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder(name, "pop", db)

func punkte() -> int:
	return clampi(floori(_gehalten / sekunden_je_punkt), 0, 10)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("STEMMEN_ANZEIGE")) % [_gehalten, punkte()]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_arm.visible = false
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
