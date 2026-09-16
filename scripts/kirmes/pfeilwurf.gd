extends Node3D
## Ballonstechen. Aufbau: scenes/kirmes/pfeilwurf.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → Blick auf die Korkwand mit 12 Ballons.
## Die Maus führt das Fadenkreuz, das leicht schwankt; Linksklick wirft einen Pfeil.
## 6 Pfeile, jeder geplatzte Ballon zählt → 0–10 Punkte → Preis vom Server.

@export var preis := 2
@export var hinweis := "HINT_PFEIL"
@export var pfeile := 6
## Punkte je Anzahl Treffer (Index = Treffer)
@export var punkte_je_treffer: Array[int] = [0, 1, 3, 4, 6, 8, 10]
## Wie weit das Fadenkreuz schwankt (m)
@export var schwanken := 0.22
## Treffer, wenn der Pfeil so nah an der Ballonmitte landet (m)
@export var trefferradius := 0.17
@export var maus_empfindlichkeit := 0.0025
@export var flugzeit := 0.32

var _spieler: Node = null
var _t := 0.0
var _ziel := Vector2.ZERO        # Mausziel auf der Wand (x, y lokal)
var _geworfen := 0
var _treffer := 0
var _flug := -1.0
var _flug_von := Vector3.ZERO
var _flug_nach := Vector3.ZERO
var _ende_in := -1.0

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _zielpunkt: Node3D = $Stand/Zielpunkt
@onready var _flugpfeil: Node3D = $Stand/Flugpfeil
@onready var _ballons: Node3D = $Stand/Ballons
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _besitzer: Node3D = $Besitzer
@onready var _wand_z: float = _zielpunkt.position.z
@onready var _mitte: Vector2 = Vector2(_zielpunkt.position.x, _zielpunkt.position.y)

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	_zielpunkt.visible = false
	_flugpfeil.visible = false
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
	_ziel = _mitte
	_geworfen = 0
	_treffer = 0
	_flug = -1.0
	_ende_in = -1.0
	for b in _ballons.get_children():
		(b as Node3D).visible = true
		(b as Node3D).scale = Vector3.ONE
	_zielpunkt.visible = true
	_kamera.current = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

## Wo das Fadenkreuz gerade steht (mit Schwanken)
func zielpunkt() -> Vector2:
	return _ziel + Vector2(sin(_t * 1.7) + 0.5 * sin(_t * 4.3 + 1.0), cos(_t * 1.3) + 0.4 * sin(_t * 3.7)) * schwanken

func _process(delta: float) -> void:
	if _spieler == null:
		return
	_t += delta
	var z := zielpunkt()
	_zielpunkt.position = Vector3(z.x, z.y, _wand_z)
	# geplatzte Ballons schrumpfen weg
	for b in _ballons.get_children():
		var n := b as Node3D
		if n.has_meta("geplatzt") and n.visible:
			n.scale = n.scale.move_toward(Vector3.ZERO, delta * 8.0)
			if n.scale.x <= 0.01:
				n.visible = false
	if _flug >= 0.0:
		_flug += delta / flugzeit
		var t := minf(_flug, 1.0)
		var p := _flug_von.lerp(_flug_nach, t) + Vector3(0, sin(t * PI) * 0.18, 0)
		_flugpfeil.position = p
		if t >= 1.0:
			_flug = -1.0
			_landen(Vector2(_flug_nach.x, _flug_nach.y))
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		zielen(Vector2(mm.relative.x, -mm.relative.y * y_dir) * maus_empfindlichkeit * Einstellungen.maus)
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		werfen()

## Fadenkreuz verschieben — auch für Tests
func zielen(d: Vector2) -> void:
	_ziel = (_ziel + d).clamp(_mitte - Vector2(2.0, 0.95), _mitte + Vector2(2.0, 0.95))

func werfen() -> void:
	if _flug >= 0.0 or _geworfen >= pfeile or _ende_in >= 0.0:
		return
	_geworfen += 1
	var z := zielpunkt()
	_flug_von = _kamera.position + Vector3(0.18, -0.25, -0.3)
	_flug_nach = Vector3(z.x, z.y, _wand_z - 0.2)
	_flugpfeil.position = _flug_von
	_flugpfeil.look_at(to_global(_flug_nach), Vector3.UP)
	_flugpfeil.visible = true
	_flug = 0.0
	_sfx("swoosh", -8.0)
	_info_neu()

func _landen(p: Vector2) -> void:
	var bester: Node3D = null
	var best_d := trefferradius
	for b in _ballons.get_children():
		var n := b as Node3D
		if n.has_meta("geplatzt"):
			continue
		var d := Vector2(n.position.x, n.position.y).distance_to(p)
		if d < best_d:
			best_d = d
			bester = n
	if bester:
		bester.set_meta("geplatzt", true)
		_treffer += 1
		_sfx("pop", -2.0)
	else:
		_sfx("klack", -6.0)
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		if _flug < 0.0:
			_flugpfeil.visible = false)
	if _geworfen >= pfeile:
		_ende_in = 1.4
	_info_neu()

func _sfx(name: String, db: float) -> void:
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder(name, "pop", db)

func punkte() -> int:
	return punkte_je_treffer[clampi(_treffer, 0, punkte_je_treffer.size() - 1)]

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("PFEIL_ANZEIGE")) % [_treffer, pfeile - _geworfen, punkte()]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_zielpunkt.visible = false
	_flugpfeil.visible = false
	_flug = -1.0
	for b in _ballons.get_children():
		b.remove_meta("geplatzt")
		(b as Node3D).visible = true
		(b as Node3D).scale = Vector3.ONE
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
