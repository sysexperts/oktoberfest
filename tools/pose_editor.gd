extends Node3D
## Pose-Editor für den Mittelfinger (Arm und alle Finger per Regler), Aufbau: tools/pose_editor.tscn.
## Start: F6 im Editor oder  godot --path . res://tools/pose_editor.tscn
## Die Winkel stehen in daten/mittelfinger_pose.json und gelten sofort im Spiel (Figur.mittelfinger_pose).
## "pose" = Ruhelage der Geste, "stoss" = Höhepunkt des Stoßes nach vorn; im Spiel wird dazwischen geblendet.
## Winkel: Bogenmaß, Euler XYZ relativ zur Ruhelage des Knochens.

const FIGUREN := {"Creator-Körper (basis)": "res://scenes/figuren/basis.tscn", "Bean": "res://scenes/figuren/bean.tscn"}
const KNOCHEN := ["arm_r", "unterarm_r", "hand_r", "zeige1_r", "zeige2_r", "mittel1_r", "mittel2_r", "ring1_r", "ring2_r",
	"klein1_r", "klein2_r", "daumen1_r", "daumen2_r", "arm_l", "wirbel_oben", "kopf"]
const SAETZE := ["pose", "stoss"]
const SAETZE_NAMEN := ["Bearbeite: Pose (Ruhe)", "Bearbeite: Stoß (nach vorn)"]
const DATEI := "res://daten/mittelfinger_pose.json"

@onready var _kamera: Camera3D = $Kamera
@onready var _knochen_box: VBoxContainer = %Knochen
@onready var _status: Label = $Oberflaeche/Leiste/Spalte/Status
@onready var _figur_wahl: OptionButton = $Oberflaeche/Leiste/Spalte/Optionen/FigurWahl
@onready var _satz_wahl: OptionButton = $Oberflaeche/Leiste/Spalte/Optionen/SatzWahl
@onready var _abspielen: CheckButton = $Oberflaeche/Leiste/Spalte/Optionen/Abspielen
@onready var _hand_regler: HSlider = $Oberflaeche/Leiste/Spalte/Handgroesse/Regler
@onready var _hand_wert: Label = $Oberflaeche/Leiste/Spalte/Handgroesse/Wert

var _figur: Figur
var _daten := {}
var _satz := "pose"
var _t := 0.0
# Kamera: dreht um _ziel (bei "Hand nah" folgt es der Hand)
var _yaw := 0.15
var _nick := 0.1
var _abstand := 2.4
var _ziel := Vector3(-0.1, 1.15, 0)
var _folge_hand := false

func _ready() -> void:
	_figur = $Figur
	for n: String in FIGUREN:
		_figur_wahl.add_item(n)
	for n: String in SAETZE_NAMEN:
		_satz_wahl.add_item(n)
	_figur_wahl.item_selected.connect(_figur_wechseln)
	_satz_wahl.item_selected.connect(func(i: int) -> void:
		_satz = SAETZE[i]
		_regler_setzen())
	$Oberflaeche/Leiste/Spalte/Ansichten/Vorn.pressed.connect(_ansicht.bind(0.15, 0.1, 2.4, false))
	$Oberflaeche/Leiste/Spalte/Ansichten/Hinten.pressed.connect(_ansicht.bind(PI - 0.3, 0.2, 2.8, false))
	$Oberflaeche/Leiste/Spalte/Ansichten/Seite.pressed.connect(_ansicht.bind(-PI * 0.5, 0.1, 2.4, false))
	$Oberflaeche/Leiste/Spalte/Ansichten/HandNah.pressed.connect(_ansicht.bind(0.35, 0.1, 0.55, true))
	$Oberflaeche/Leiste/Spalte/Aktionen/Speichern.pressed.connect(_speichern)
	$Oberflaeche/Leiste/Spalte/Aktionen/NeuLaden.pressed.connect(_laden)
	_hand_regler.value_changed.connect(func(v: float) -> void:
		_daten["handskala"] = v
		_hand_wert.text = "%.2f" % v)
	for b: String in KNOCHEN:
		for i in 3:
			var regler := _regler(b, i)
			regler.value_changed.connect(_regler_geaendert.bind(b, i))
	_laden()

func _regler(b: String, achse: int) -> HSlider:
	return _knochen_box.get_node("%s/%sZeile/Regler" % [b, "XYZ"[achse]]) as HSlider

func _laden() -> void:
	_daten = Figur.mittelfinger_daten(true).duplicate(true)
	# Jeder Knochen in beiden Sätzen, damit alles einstellbar ist
	for s: String in SAETZE:
		if not _daten.has(s):
			_daten[s] = {}
		for b: String in KNOCHEN:
			if not _daten[s].has(b):
				_daten[s][b] = [0.0, 0.0, 0.0]
	if not _daten.has("handskala"):
		_daten["handskala"] = 1.0
	_hand_regler.set_value_no_signal(float(_daten["handskala"]))
	_hand_wert.text = "%.2f" % float(_daten["handskala"])
	_regler_setzen()
	_status.text = "Geladen: " + DATEI

## Regler auf den Satz stellen, der gerade bearbeitet wird
func _regler_setzen() -> void:
	for b: String in KNOCHEN:
		var e: Array = _daten[_satz][b]
		for i in 3:
			_regler(b, i).set_value_no_signal(float(e[i]))
			_wert_zeigen(b, i)

func _wert_zeigen(b: String, achse: int) -> void:
	var z := _knochen_box.get_node("%s/%sZeile" % [b, "XYZ"[achse]])
	(z.get_node("Wert") as Label).text = "%.2f" % _regler(b, achse).value

func _regler_geaendert(wert: float, b: String, achse: int) -> void:
	_daten[_satz][b][achse] = wert
	_wert_zeigen(b, achse)

func _figur_wechseln(i: int) -> void:
	var pfad: String = FIGUREN.values()[i]
	_figur.queue_free()
	_figur = (load(pfad) as PackedScene).instantiate()
	add_child(_figur)

func _ansicht(yaw: float, nick: float, abstand: float, folge: bool) -> void:
	_yaw = yaw
	_nick = nick
	_abstand = abstand
	_folge_hand = folge
	if not folge:
		_ziel = Vector3(-0.1, 1.15, 0)

func _process(delta: float) -> void:
	var k := 0.0 if _satz == "pose" else 1.0
	if _abspielen.button_pressed:
		_t += delta
		k = absf(sin(_t * 4.5))
	_figur.pose_aus_daten(_daten, k)
	if _folge_hand and _figur.skelett:
		var b := _figur.skelett.find_bone("RightHand")
		if b >= 0:
			_ziel = _figur.skelett.global_transform * _figur.skelett.get_bone_global_pose(b).origin
	var richtung := Vector3(sin(_yaw) * cos(_nick), sin(_nick), cos(_yaw) * cos(_nick))
	_kamera.global_position = _ziel + richtung * _abstand
	_kamera.look_at(_ziel)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		_yaw -= event.relative.x * 0.01
		_nick = clampf(_nick + event.relative.y * 0.01, -1.4, 1.4)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_abstand = maxf(0.2, _abstand * 0.9)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_abstand = minf(6.0, _abstand * 1.1)

## Schreibt die Pose als JSON, ein Knochen pro Zeile
func _speichern() -> void:
	var zeilen: Array[String] = ['{', '\t"handskala": %s,' % str(snappedf(float(_daten["handskala"]), 0.01))]
	for s in SAETZE.size():
		var teile: Array[String] = []
		for b: String in KNOCHEN:
			var e: Array = _daten[SAETZE[s]][b]
			teile.append('\t\t"%s": [%s, %s, %s]' % [b, snappedf(float(e[0]), 0.01), snappedf(float(e[1]), 0.01), snappedf(float(e[2]), 0.01)])
		zeilen.append('\t"%s": {\n%s\n\t}%s' % [SAETZE[s], ",\n".join(teile), "," if s < SAETZE.size() - 1 else ""])
	zeilen.append('}')
	var f := FileAccess.open(DATEI, FileAccess.WRITE)
	if f == null:
		_status.text = "Speichern fehlgeschlagen: %s" % DATEI
		return
	f.store_string("\n".join(zeilen) + "\n")
	f.close()
	Figur.mittelfinger_daten(true)
	_status.text = "Gespeichert: %s (gilt im Spiel beim nächsten Emote)" % DATEI
