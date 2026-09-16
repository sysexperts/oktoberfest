extends Node3D
## Hau den Maulwurf. Aufbau: scenes/kirmes/maulwurf.tscn — gebackener Stand
## (tools/bake_kirmes_spiele.gd), Budenbesitzer, Anzeige.
##
## Beim Budenbesitzer E → Server bucht ab → Blick von oben auf den Tisch mit 9 Löchern.
## Maulwürfe schauen kurz heraus, mit der Zeit schneller. Mit der Maus aufs Loch
## klicken haut zu. Treffer in der Spielzeit → 0–10 Punkte → Preis vom Server.

@export var preis := 2
@export var hinweis := "HINT_MAULWURF"
@export var spielzeit := 25.0
## So viele Treffer ergeben 10 Punkte
@export var treffer_fuer_zehn := 34
## Zeit zwischen zwei Maulwürfen (Anfang → Ende)
@export var takt_anfang := 0.85
@export var takt_ende := 0.42
## So lange bleibt ein Maulwurf oben (Anfang → Ende)
@export var oben_anfang := 0.95
@export var oben_ende := 0.5
## Klick trifft ein Loch, wenn er so nah an der Mitte liegt (m)
@export var lochradius := 0.28

const HOCH := 0.3

var _spieler: Node = null
var _t := 0.0
var _treffer := 0
var _naechster := 0.0
var _oben := {}          # Index -> verbleibende Zeit oben
var _gehauen := {}       # Index -> Zeit seit Treffer (Maulwurf taucht benommen ab)
var _ende_in := -1.0
var _schlag := -1.0
var _schlag_ziel := Vector3.ZERO

@onready var _kamera: Camera3D = $Stand/SpielKamera
@onready var _maeuse: Node3D = $Stand/Maulwuerfe
@onready var _hammer: Node3D = $Stand/Hammer
@onready var _hammer_ruhe: Vector3 = _hammer.position
@onready var _lampen: Array[Node] = []
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _zeit: ProgressBar = $Anzeige/Zeit
@onready var _besitzer: Node3D = $Besitzer

func _ready() -> void:
	add_to_group("kirmes_spiel")
	_anzeige.visible = false
	for i in 10:
		_lampen.append(get_node("Stand/Lampe%d" % i))
	_lampen_setzen(0)
	_besitzer.position = ($Stand/BesitzerMitte as Node3D).position
	for m in _maeuse.get_children():
		(m.get_node("Koerper") as Node3D).position.y = -HOCH

func laeuft() -> bool:
	return _spieler != null

func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Stand/BesitzerMitte as Node3D).position, ($Stand/BesitzerSeite as Node3D).position)

func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_t = 0.0
	_treffer = 0
	_naechster = 0.8
	_oben.clear()
	_gehauen.clear()
	_ende_in = -1.0
	_schlag = -1.0
	_kamera.current = true
	_anzeige.visible = true
	# Zum Zielen braucht es den Mauszeiger
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_info_neu()

func _process(delta: float) -> void:
	# Maulwürfe fahren auch nach dem Spiel noch sanft zurück
	for i in _maeuse.get_child_count():
		var k := _maeuse.get_child(i).get_node("Koerper") as Node3D
		var soll := 0.0 if _oben.has(i) else -HOCH
		k.position.y = move_toward(k.position.y, soll, delta * (3.5 if soll == 0.0 else 2.0))
		k.rotation.z = sin(_t * 12.0) * 0.25 if _gehauen.has(i) else 0.0
	_hammer_bewegen(delta)
	if _spieler == null:
		return
	_t += delta
	if _ende_in >= 0.0:
		_ende_in -= delta
		if _ende_in < 0.0:
			_beenden()
		return
	var fortschritt := clampf(_t / spielzeit, 0.0, 1.0)
	for i: int in _oben.keys():
		_oben[i] -= delta
		if _oben[i] <= 0.0:
			_oben.erase(i)
	for i: int in _gehauen.keys():
		_gehauen[i] += delta
		if _gehauen[i] > 0.5:
			_gehauen.erase(i)
	_naechster -= delta
	if _naechster <= 0.0:
		_naechster = lerpf(takt_anfang, takt_ende, fortschritt) * randf_range(0.7, 1.2)
		var frei: Array[int] = []
		for i in _maeuse.get_child_count():
			if not _oben.has(i) and not _gehauen.has(i):
				frei.append(i)
		if not frei.is_empty():
			_oben[frei.pick_random()] = lerpf(oben_anfang, oben_ende, fortschritt)
	_zeit.value = (1.0 - fortschritt) * 100.0
	if _t >= spielzeit:
		_oben.clear()
		_ende_in = 1.2
		_sfx("cheer" if punkte() >= 7 else "pop", -6.0)
	_info_neu()

func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var i := loch_bei(mb.position)
		if i >= 0:
			hauen(i)

## Welches Loch liegt unter dieser Bildschirmstelle? (-1: keins)
func loch_bei(bildschirm: Vector2) -> int:
	var von := _kamera.project_ray_origin(bildschirm)
	var dir := _kamera.project_ray_normal(bildschirm)
	var tisch_y := (_maeuse.get_child(0) as Node3D).global_position.y
	if absf(dir.y) < 0.01:
		return -1
	var p := von + dir * ((tisch_y - von.y) / dir.y)
	var bester := -1
	var best_d := lochradius
	for i in _maeuse.get_child_count():
		var d := ((_maeuse.get_child(i) as Node3D).global_position - p).length()
		if d < best_d:
			best_d = d
			bester = i
	return bester

## Auf Loch i hauen — auch für Tests
func hauen(i: int) -> void:
	if _spieler == null or _ende_in >= 0.0 or _schlag >= 0.0:
		return
	_schlag = 0.0
	_schlag_ziel = (_maeuse.get_child(i) as Node3D).position
	if _oben.has(i) and not _gehauen.has(i):
		_oben.erase(i)
		_gehauen[i] = 0.0
		_treffer += 1
		_sfx("pop", -2.0)
		_lampen_setzen(punkte())
	else:
		_sfx("klack", -8.0)
	_info_neu()

func ist_oben(i: int) -> bool:
	return _oben.has(i) and not _gehauen.has(i)

func _hammer_bewegen(delta: float) -> void:
	if _schlag < 0.0:
		_hammer.position = _hammer.position.move_toward(_hammer_ruhe, delta * 4.0)
		_hammer.rotation.x = move_toward(_hammer.rotation.x, 0.0, delta * 6.0)
		return
	_schlag += delta / 0.22
	var t := minf(_schlag, 1.0)
	# Hammer fährt übers Loch und klappt nach vorn herunter
	_hammer.position = _hammer_ruhe.lerp(_schlag_ziel + Vector3(0, 0.05, 0.62), minf(t * 2.0, 1.0))
	_hammer.rotation.x = -sin(t * PI) * 1.3
	if t >= 1.0:
		_schlag = -1.0

func _lampen_setzen(n: int) -> void:
	for i in _lampen.size():
		(_lampen[i] as Node3D).visible = i < n

func _sfx(name: String, db: float) -> void:
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder(name, "pop", db)

func punkte() -> int:
	return clampi(_treffer * 10 / treffer_fuer_zehn, 0, 10)

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("MAULWURF_ANZEIGE")) % [_treffer, maxf(0.0, spielzeit - _t), punkte()]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, punkte())
	_anzeige.visible = false
	_oben.clear()
	_gehauen.clear()
	_lampen_setzen(0)
	_kamera.current = false
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
