class_name Artist
extends Node3D
## Künstler auf der Bühne — Schlagersänger: hüpft im Takt, singt ins Mikrofon,
## pumpt mit der Faust, winkt, zeigt ins Publikum, dreht sich.
## Figur kommt aus scripts/figuren.gd; die Figur hängt am Knotennamen (Artist0,
## Artist1 …), der bei allen Mitspielern gleich ist. Die Bewegung ist reine
## Darstellung und läuft über die Uhr — alle Künstler tanzen im Gleichtakt.
##
## Die Pose wird ohne AnimationPlayer direkt aufs Skelett gesetzt: Arme und Beine
## zeigen auf Zielrichtungen im Figurraum. So passt sie auf alle Figuren, egal wie
## deren Ruhepose aussieht (T-Pose, A-Pose).

const Figuren := preload("res://scripts/figuren.gd")

## Tempo der Choreografie (Schlager: 120–135)
@export var bpm := 128.0
## So hoch hüpft der Künstler (Meter)
@export var sprunghoehe := 0.16
## Takte je Figur der Choreografie (Hüpfen, Winken, Zeigen, Drehen)
@export var schlaege_je_figur := 8

var tier := 1

var _figur: Figur
var _sk: Skeleton3D
## Nur der erste Künstler singt ins Mikrofon, die anderen tanzen mit
var _saenger := false
## Achsen im Skelettraum: vorn, links, oben
var _vor := Vector3.BACK
var _links := Vector3.RIGHT
var _grund_drehung := PI
var _kinder := {}

@onready var _model: Node3D = $Model
@onready var _label: Label3D = $Label
@onready var _mikro: Node3D = $Mikrofon

const GLIEDER := {
	"RightArm": "RightForeArm", "RightForeArm": "RightHand",
	"LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand",
	"RightUpLeg": "RightLeg", "RightLeg": "RightFoot",
	"LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot",
}

func _ready() -> void:
	add_to_group("artist")
	_figur = Figuren.einsetzen(self, Figuren.fuer_id(String(name).hash()))
	_model = _figur
	_saenger = String(name).ends_with("0")
	_sk = _figur.skelett
	if _sk == null:
		if not _figur.tanzen(randf_range(0.9, 1.1)):
			_figur.stehen()
		_mikro.visible = false
		return
	if _figur.anim:
		_figur.anim.active = false
	_sk.reset_bone_poses()
	for glied: String in GLIEDER:
		var i := _sk.find_bone(glied)
		var k := _sk.find_bone(GLIEDER[glied])
		if i >= 0 and k >= 0:
			_kinder[i] = k
	_achsen_bestimmen()
	_mikro.visible = _saenger

## Wohin schaut die Figur, wo ist links? Aus der Ruhepose (Kopf vorne, linke Schulter).
func _achsen_bestimmen() -> void:
	var kopf := _sk.find_bone("Head")
	var nase := _sk.find_bone("headfront")
	if kopf >= 0 and nase >= 0:
		var d := _sk.get_bone_global_rest(nase).origin - _sk.get_bone_global_rest(kopf).origin
		_vor = Vector3(0, 0, signf(d.z) if absf(d.z) > 0.0001 else 1.0)
	var la := _sk.find_bone("LeftArm")
	var ra := _sk.find_bone("RightArm")
	if la >= 0 and ra >= 0:
		var dx := _sk.get_bone_global_rest(la).origin.x - _sk.get_bone_global_rest(ra).origin.x
		_links = Vector3(signf(dx) if absf(dx) > 0.0001 else 1.0, 0, 0)
	# Die Bühne dreht den Künstler so, dass -Z zum Publikum zeigt
	_grund_drehung = PI if _vor.z > 0.0 else 0.0

func set_tier(t: int) -> void:
	tier = t
	# Stufe 0: Alleinunterhalter ohne Buchung — ohne Schild
	if _label:
		_label.visible = t > 0
	if _label and t > 0:
		var symbol: String = {1: "🎸", 2: "🎺"}.get(t, "⭐")
		_label.text = "%s %s" % [symbol, TranslationServer.translate("ACT_%d" % clampi(t, 1, 3))]

## Massenschlägerei: Band rennt über die Wegpunkte davon und verschwindet.
const FLUCHT_TEMPO := 5.0
var _flucht: Array[Vector3] = []
var _flieht := false

func fliehen(weg: Array[Vector3]) -> void:
	if _flieht:
		return
	_flieht = true
	_flucht = weg.duplicate()
	_mikro.visible = false
	if _label:
		_label.text = "😱"
		_label.visible = true
	if _sk:
		_sk.reset_bone_poses()
	_model.position = Vector3.ZERO
	_model.rotation.y = _grund_drehung
	_figur.rennen(1.2)

func flieht() -> bool:
	return _flieht

func _process(delta: float) -> void:
	if _flieht:
		_weglaufen(delta)
		return
	if _sk == null or _model == null:
		return
	var schlag := float(Time.get_ticks_msec()) / 1000.0 * bpm / 60.0
	var figur := int(schlag / float(schlaege_je_figur)) % 4
	var im_takt := fposmod(schlag, 1.0)
	var sprung := absf(sin(PI * schlag))       # 0 = Landung, 1 = oben
	var hocke := pow(1.0 - sprung, 3.0)
	var v := _vor
	var l := _links
	var o := Vector3.UP
	var ziele := {}
	var drehs := {}

	# Hüpfen, bei Figur 3 höher mit Drehung
	var hoch := sprunghoehe * (1.4 if figur == 3 else 1.0)
	_model.position.y = sprung * hoch
	var drehung := 0.0
	match figur:
		1: drehung = sin(PI * schlag * 0.5) * 0.35                       # schunkeln
		2: drehung = sin(PI * schlag * 0.25) * 0.45                      # ins Publikum zeigen
		3: drehung = TAU * fposmod(schlag / 4.0, 1.0)                     # Drehung über 4 Schläge
	_model.rotation.y = _grund_drehung + drehung
	_model.position.x = sin(PI * schlag * 0.5) * 0.18 if figur == 1 else 0.0

	# Beine: beim Landen in die Hocke
	for seite: float in [-1.0, 1.0]:
		var name_s := "Left" if seite > 0.0 else "Right"
		var schritt := l * seite * 0.12
		ziele[name_s + "UpLeg"] = -o + v * 0.5 * hocke + schritt
		ziele[name_s + "Leg"] = -o - v * 0.45 * hocke + schritt * 0.5

	# Oberkörper wippt, Kopf nickt im Takt
	drehs["Spine02"] = Quaternion(v, sin(PI * schlag * 0.5) * 0.12) * Quaternion(l, 0.08 * hocke)
	drehs["Head"] = Quaternion(l, -0.18 * sin(TAU * im_takt))

	# Rechter Arm: Mikrofon am Mund (Sänger) oder mittanzen
	var r := -l
	if _saenger:
		ziele["RightArm"] = (-o * 0.8 + v * 0.55 + r * 0.25)
		ziele["RightForeArm"] = (o * 0.8 + v * 0.3 + l * 0.55)
	var links_arm: Vector3
	var links_unter: Vector3
	match figur:
		0:
			# Faust pumpen: oben auf dem Schlag, dann vor die Brust
			var p := 0.5 + 0.5 * cos(TAU * im_takt)
			links_arm = (o + l * 0.35).lerp(l * 0.7 + v * 0.5 - o * 0.2, 1.0 - p)
			links_unter = (o + v * 0.1).lerp(o + v * 0.6 - l * 0.3, 1.0 - p)
		1:
			# Winken über dem Kopf
			links_arm = o + l * 0.45
			links_unter = o + l * sin(PI * schlag) * 0.9
		2:
			# Ins Publikum zeigen, von links nach rechts
			links_arm = v + o * 0.35 + l * (0.25 + sin(PI * schlag * 0.25) * 0.6)
			links_unter = links_arm
		_:
			# Arm ausbreiten beim Drehen
			links_arm = l + o * 0.5
			links_unter = l + o * 0.7
	ziele["LeftArm"] = links_arm
	ziele["LeftForeArm"] = links_unter
	if not _saenger:
		# Mittänzer: rechter Arm spiegelt den linken
		ziele["RightArm"] = Vector3(-links_arm.x, links_arm.y, links_arm.z)
		ziele["RightForeArm"] = Vector3(-links_unter.x, links_unter.y, links_unter.z)
		if figur == 1:
			# Klatschen über dem Kopf statt winken
			var zu := 0.5 + 0.5 * cos(TAU * im_takt)
			ziele["LeftForeArm"] = o + r * 0.5 * zu + l * 0.2
			ziele["RightForeArm"] = o + l * 0.5 * zu + r * 0.2
	_pose_setzen(ziele, drehs)
	if _saenger:
		_mikro_nachfuehren()

func _weglaufen(delta: float) -> void:
	if _flucht.is_empty():
		queue_free()
		return
	var ziel := _flucht[0]
	var zu := ziel - global_position
	var flach := Vector3(zu.x, 0.0, zu.z)
	if flach.length() < 0.3:
		_flucht.pop_front()
		return
	var schritt := minf(FLUCHT_TEMPO * delta, flach.length())
	# Von der Bühne herunter: Höhe anteilig mit
	global_position += Vector3(flach.x, 0.0, flach.z).normalized() * schritt
	global_position.y += (ziel.y - global_position.y) * (schritt / flach.length())
	rotation.y = atan2(-flach.x, -flach.z)

## Setzt die Pose: drehs = zusätzliche Drehung im Figurraum, ziele = Richtung, in die
## ein Glied (Knochen → Kindknochen) zeigen soll. Kinder erben die Drehung.
func _pose_setzen(ziele: Dictionary, drehs: Dictionary) -> void:
	var n := _sk.get_bone_count()
	var glob: Array[Transform3D] = []
	glob.resize(n)
	for i in n:
		var rest := _sk.get_bone_rest(i)
		var eltern := _sk.get_bone_parent(i)
		var eltern_g: Transform3D = glob[eltern] if eltern >= 0 else Transform3D()
		var g := eltern_g * rest
		var knochen := _sk.get_bone_name(i)
		var geaendert := false
		if drehs.has(knochen):
			g.basis = Basis(drehs[knochen] as Quaternion) * g.basis
			geaendert = true
		if ziele.has(knochen) and _kinder.has(i):
			var richtung := (g.basis * _sk.get_bone_rest(_kinder[i]).origin).normalized()
			var ziel := (ziele[knochen] as Vector3).normalized()
			if richtung.length() > 0.5 and richtung.dot(ziel) < 0.9999:
				g.basis = Basis(Quaternion(richtung, ziel)) * g.basis
				geaendert = true
		glob[i] = g
		if geaendert:
			_sk.set_bone_pose_rotation(i, (eltern_g.basis.inverse() * g.basis).get_rotation_quaternion())
		else:
			_sk.set_bone_pose_rotation(i, rest.basis.get_rotation_quaternion())

## Mikrofon in die rechte Hand, mit dem Kopf zum Mund
func _mikro_nachfuehren() -> void:
	var hand := _sk.find_bone("RightHand")
	var kopf := _sk.find_bone("headfront")
	if hand < 0 or kopf < 0:
		return
	var p_hand := _sk.global_transform * _sk.get_bone_global_pose(hand).origin
	var p_mund := _sk.global_transform * _sk.get_bone_global_pose(kopf).origin
	var y := (p_mund - p_hand).normalized()
	if y.length() < 0.5:
		return
	var x := y.cross(Vector3.UP).normalized() if absf(y.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
	var z := x.cross(y).normalized()
	_mikro.global_transform = Transform3D(Basis(x, y, z), p_hand)
