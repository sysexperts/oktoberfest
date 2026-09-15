extends Node3D
## Spielbare Schießbude auf der Kirmes. Aufbau: scenes/kirmes/schiessstand.tscn —
## gebackene Bude (tools/bake_schiessstand.gd), Budenbesitzer, Anzeige.
##
## Ablauf: beim Budenbesitzer E → der Server bucht ab (GameManager.net_schiessen_bezahlen)
## und schickt den Besitzer zur Kasse → Blick über das Gewehr an der Theke.
## Gezielt wird mit dem Gewehr: die Maus schwenkt Blick und Gewehr, geschossen wird
## dorthin, wo Kimme und Korn gerade hinzeigen (Fadenkreuz in der Bildmitte).
## Das Gewehr wackelt mit dem Atem; Leertaste halten = Luft anhalten, ruhiger zielen,
## danach kurz mehr Wackeln. 10 Schuss, Treffer an den Server → Preis.
## Das Schießen läuft nur beim Schützen; den Besitzer sehen alle weggehen.

@export var schuss := 10
@export var zeit := 30.0
## Wie schnell die Figuren wandern (m/s): untere (Enten) und obere Reihe (Scheiben)
@export var tempo_reihen := Vector2(0.8, -1.2)
## Wie weit man schwenken kann (Grad): seitlich, hoch/runter
@export var schwenk := Vector2(38.0, 22.0)
## Mausempfindlichkeit beim Zielen (wird mit der Einstellung „Maus" multipliziert)
@export var maus_empfindlichkeit := 0.0022
## Atemwackeln in Grad
@export var wackeln := 1.4
## Sekunden Luft anhalten, bis die Luft ausgeht
@export var luft_dauer := 3.0
## Wackeln beim Luftanhalten (Anteil) und danach, wenn die Luft ausgegangen ist
@export var ruhig_anteil := 0.15
@export var ausser_atem_anteil := 1.8

var _spieler: Node = null
var _treffer := 0
var _uebrig := 0
var _rest := 0.0
var _ziele: Array[Node3D] = []
var _unten := {}
var _t := 0.0
var _luft := 1.0
var _ausser_atem := 0.0
var _faktor := 1.0
var _rueckstoss := 0.0
var _yaw := 0.0
var _pitch := 0.0
var _kamera_grund := Transform3D()

@onready var _kamera: Camera3D = $Bude/SpielKamera
@onready var _gewehr: Node3D = $Bude/SpielKamera/Gewehr
@onready var _anzeige: CanvasLayer = $Anzeige
@onready var _info: Label = $Anzeige/Info
@onready var _fadenkreuz: Control = $Anzeige/Fadenkreuz
@onready var _luftbalken: ProgressBar = $Anzeige/Luft
@onready var _besitzer: Node3D = $Besitzer
@onready var _glocke: Node3D = $Bude/Kulisse/Zielbahnen/Glocke

const BAHN_HALB := 2.95
const GEWEHR_ORT := Vector3(0.13, -0.19, -0.5)
## So weit vor der Kamera treffen sich Visierlinie und Fadenkreuz
const VISIER_WEITE := 5.0

func _ready() -> void:
	add_to_group("schiessstand")
	_anzeige.visible = false
	_gewehr.visible = false
	_kamera_grund = _kamera.transform
	for reihe in [$Bude/Kulisse/Zielbahnen/Reihe0, $Bude/Kulisse/Zielbahnen/Reihe1]:
		for z in reihe.get_children():
			_ziele.append(z as Node3D)
	_ziele.append(_glocke)
	_besitzer.position = ($Bude/BesitzerMitte as Node3D).position

func laeuft() -> bool:
	return _spieler != null

## Alle Mitspieler (GameManager._net_bude_besetzt): Besitzer geht zur Kasse / zurück.
func besetzt_setzen(an: bool) -> void:
	_besitzer.besetzt_setzen(an, ($Bude/BesitzerMitte as Node3D).position, ($Bude/BesitzerSeite as Node3D).position)

## Beim Schützen, nachdem bezahlt ist.
func spiel_starten(spieler: Node) -> void:
	if _spieler != null:
		return
	_spieler = spieler
	_treffer = 0
	_uebrig = schuss
	_rest = zeit
	_luft = 1.0
	_ausser_atem = 0.0
	_yaw = 0.0
	_pitch = 0.0
	_unten.clear()
	for z in _ziele:
		z.rotation.x = 0.0
	_kamera.current = true
	_gewehr.visible = true
	_anzeige.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_info_neu()

func _process(delta: float) -> void:
	_t += delta
	for z in _ziele:
		if z == _glocke:
			continue
		var reihe := 0 if z.get_parent().name == "Reihe0" else 1
		z.position.x += tempo_reihen[reihe] * delta
		if z.position.x > BAHN_HALB:
			z.position.x -= BAHN_HALB * 2.0
		elif z.position.x < -BAHN_HALB:
			z.position.x += BAHN_HALB * 2.0
		# Enten schaukeln auf den Wellen
		if reihe == 0:
			z.position.y = sin(_t * 3.0 + z.position.x * 2.0) * 0.04
	for z in _unten.keys():
		_unten[z] = float(_unten[z]) - delta
		if float(_unten[z]) <= 0.0:
			_unten.erase(z)
			create_tween().tween_property(z, "rotation:x", 0.0, 0.25)
	if _spieler == null:
		return
	_zielen(delta)
	_rest -= delta
	_info_neu()
	if _rest <= 0.0 or (_uebrig <= 0 and _unten.is_empty()):
		_beenden()

## Blick und Gewehr schwenken, Atemwackeln drauf. Leertaste halten beruhigt,
## bis die Luft ausgeht.
func _zielen(delta: float) -> void:
	var halten := Input.is_action_pressed("springen") and _ausser_atem <= 0.0 and _luft > 0.0
	var ziel_faktor := 1.0
	if halten:
		_luft = maxf(0.0, _luft - delta / luft_dauer)
		ziel_faktor = ruhig_anteil
		if _luft <= 0.0:
			_ausser_atem = 1.6
	else:
		_luft = minf(1.0, _luft + delta / (luft_dauer * 0.9))
	if _ausser_atem > 0.0:
		_ausser_atem -= delta
		ziel_faktor = ausser_atem_anteil
	_faktor = lerpf(_faktor, ziel_faktor, clampf(delta * 6.0, 0.0, 1.0))
	var atem := Vector2(sin(_t * 1.1) * 0.55 + sin(_t * 2.7 + 1.3) * 0.25 + sin(_t * 4.3) * 0.08,
		sin(_t * 1.6) * 0.8 + sin(_t * 3.1 + 0.7) * 0.2) * deg_to_rad(wackeln) * _faktor
	_rueckstoss = move_toward(_rueckstoss, 0.0, delta * 4.0)
	var hoch := _pitch + atem.y + _rueckstoss * 0.03
	_kamera.transform = _kamera_grund * Transform3D(Basis.from_euler(Vector3(hoch, _yaw + atem.x, 0.0)), Vector3.ZERO)
	# Gewehr sitzt fest vor dem Auge und zeigt auf das Fadenkreuz; Rückstoß nach hinten
	_gewehr.position = GEWEHR_ORT + Vector3(0, _rueckstoss * 0.015, _rueckstoss * 0.07)
	_gewehr.look_at(_kamera.global_transform * Vector3(0, 0, -VISIER_WEITE), _kamera.global_transform.basis.y)
	_gewehr.rotate_object_local(Vector3.RIGHT, _rueckstoss * 0.1)
	var mitte := get_viewport().get_visible_rect().size / 2.0
	_fadenkreuz.position = mitte - _fadenkreuz.size / 2.0
	_luftbalken.value = _luft * 100.0
	_luftbalken.modulate = Color(1, 0.5, 0.45) if _ausser_atem > 0.0 else Color.WHITE

## Eingaben während des Spiels (player.gd reicht sie weiter).
func eingabe(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_beenden()
		return
	var mm := event as InputEventMouseMotion
	if mm:
		var sens := maus_empfindlichkeit * Einstellungen.maus
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		_yaw = clampf(_yaw - mm.relative.x * sens, -deg_to_rad(schwenk.x), deg_to_rad(schwenk.x))
		_pitch = clampf(_pitch - mm.relative.y * sens * y_dir, -deg_to_rad(schwenk.y), deg_to_rad(schwenk.y))
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _uebrig > 0:
		_schiessen()

## Schuss entlang der Visierlinie (Bildmitte, mit dem Wackeln des Augenblicks).
func _schiessen() -> void:
	_uebrig -= 1
	_rueckstoss = 1.0
	var start := _kamera.global_position
	var richtung := -_kamera.global_transform.basis.z.normalized()
	var bester: Node3D = null
	var beste_t := INF
	for z in _ziele:
		if _unten.has(z):
			continue
		var mitte := z.global_transform * (Vector3(0, -0.14, 0.05) if z == _glocke else Vector3(0, 0.15, 0))
		var radius := 0.09 if z == _glocke else 0.17
		var t := (mitte - start).dot(richtung)
		if t <= 0.0:
			continue
		if (start + richtung * t).distance_to(mitte) < radius and t < beste_t:
			beste_t = t
			bester = z
	var sfx = get_tree().current_scene.get_node_or_null("Sfx")
	if sfx:
		sfx.play_oder("schuss", "pop", -10.0)
	if bester == _glocke:
		# Glocke: zählt doppelt
		_treffer = mini(schuss, _treffer + 2)
		var tw := create_tween()
		tw.tween_property(_glocke, "rotation:z", 0.4, 0.08)
		tw.tween_property(_glocke, "rotation:z", -0.3, 0.12)
		tw.tween_property(_glocke, "rotation:z", 0.0, 0.2)
		if sfx:
			sfx.play("ding")
	elif bester:
		_treffer += 1
		_unten[bester] = 1.4
		create_tween().tween_property(bester, "rotation:x", -PI / 2.0, 0.12)
	_info_neu()

func _info_neu() -> void:
	_info.text = String(TranslationServer.translate("SCHIESS_ANZEIGE")) % [_treffer, _uebrig, maxi(0, ceili(_rest))]

func _beenden() -> void:
	if _spieler == null:
		return
	var welt := get_tree().current_scene
	if welt and welt.has_method("net_schiessen_ende"):
		welt.net_schiessen_ende.rpc_id(1, _treffer)
	_anzeige.visible = false
	_gewehr.visible = false
	_kamera.current = false
	_kamera.transform = _kamera_grund
	if _spieler.has_method("minispiel_beendet"):
		_spieler.minispiel_beendet()
	_spieler = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
