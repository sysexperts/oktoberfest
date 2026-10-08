class_name Staff
extends Node3D
## Angestellter (Koch / Kellner / Reinigung). Nur Darstellung —
## die Logik läuft serverseitig im GameManager (_staff_sim).

const ROLE_COLORS := {1: Color(0.95, 0.6, 0.2), 2: Color(0.3, 0.7, 1.0), 3: Color(0.4, 0.9, 0.5), 4: Color(1.0, 0.85, 0.3), 5: Color(0.95, 0.85, 0.15), 6: Color(0.85, 0.6, 0.25)}
## Symbol je Beruf (assets/ui/symbole, scripts/ui/symbole.gd)
const ROLE_SYMBOLE := {1: "koch", 2: "bier", 3: "besen", 4: "fass", 5: "stern", 6: "pokal"}
const Symbole := preload("res://scripts/ui/symbole.gd")
const ROLE_KEYS := {1: "STAFF_COOK", 2: "STAFF_WAITER", 3: "STAFF_CLEANER", 4: "STAFF_TAPSTER", 5: "STAFF_SECURITY", 6: "STAFF_BRAEUMEISTER"}
const Figuren := preload("res://scripts/figuren.gd")
## Versatz, damit Personal und Gäste mit gleicher Nummer nicht gleich aussehen
const FIGUR_VERSATZ := 1000

## Die Figuren schauen nicht in Godots Standardrichtung. Bei Rückwärtslaufen
## hier auf 0 oder 180 stellen.
@export var model_yaw_offset := 180.0

var staff_id := -1
var role := 2
var level := 1
var carrying := 0
var staff_name := ""

var _net_pos: Vector3
var _net_yaw := 0.0
var _figur: Figur
var _anim: AnimationPlayer
var _walking := false
var _last := Vector3.ZERO
var _mug_nodes: Array = []
var _idle_jitter := 0.0
var _jitter_t := 0.0
var _bob := 0.0
var _model_base_y := 0.0
var _idle_motion: IdleMotion
var _zapf_t := 0.0
var _zapft := false

@onready var _model: Node3D = $Model
@onready var _label: Label3D = $Label

static func role_name(r: int) -> String:
	return String(TranslationServer.translate(ROLE_KEYS.get(r, "?")))

func _ready() -> void:
	add_to_group("staff")
	_net_pos = position
	_last = position
	# Figur aus der ID: alle Mitspieler sehen denselben Angestellten
	_figur = Figuren.einsetzen_beruf(self, staff_id + FIGUR_VERSATZ, Figuren.BERUF_ROLLE.get(role, "kellner"))
	_model = _figur
	_anim = _figur.anim
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	_model_base_y = _model.position.y
	_set_standing()
	_collect_mugs()
	_tablett_anheften()
	if _figur.braucht_idle_bewegung():
		_setup_idle_motion()
	_refresh_label()

## Stehen: echte Stehanimation der Figur, beim Bean die eingefrorene Laufpose.
func _set_standing() -> void:
	if _anim == null:
		return
	_figur.stehen()
	_walking = false

func _set_walking() -> void:
	if _anim == null:
		return
	_figur.gehen()
	_walking = true

const TRAGE_HALTUNG := preload("res://assets/trage_haltung.tres")

## Tablett am Oberkörper-Knochen festmachen (wie das Fass beim Spieler): es wippt
## beim Gehen mit, statt vor dem Bauch zu schweben. Lage aus trage_haltung.tres,
## eingestellt in scenes/werkzeuge/tablett_haltung.tscn.
func _tablett_anheften() -> void:
	var tablett := get_node_or_null("Tablett") as Node3D
	if tablett == null or _figur == null or _figur.skelett == null:
		return
	var sk := _figur.skelett
	var b := -1
	for n: String in Figur.KNOCHEN_NAMEN["wirbel_oben"]:
		b = sk.find_bone(n)
		if b >= 0:
			break
	if b < 0:
		tablett.transform = TRAGE_HALTUNG.tablett
		return
	var halter := BoneAttachment3D.new()
	halter.name = "TablettHalter"
	sk.add_child(halter)
	halter.bone_name = sk.get_bone_name(b)
	var knochen := (global_transform.affine_inverse() * sk.global_transform) * sk.get_bone_global_rest(b)
	tablett.reparent(halter, false)
	tablett.transform = knochen.affine_inverse() * TRAGE_HALTUNG.tablett

## Die Maßkrüge stehen als echte Knoten auf dem Tablett in staff.tscn.
func _collect_mugs() -> void:
	var holder := get_node_or_null("Tablett/Kruege")
	if holder == null:
		return
	for c in holder.get_children():
		_mug_nodes.append(c)

func set_net(pos: Vector3, yaw: float) -> void:
	# Feierabend: das Personal ist heim (Host setzt y weit unter den Boden), morgens läuft es vom Eingang herein
	var da := pos.y > -20.0
	if da and not visible:
		position = pos
	visible = da
	_net_pos = pos
	_net_yaw = yaw

func set_info(r: int, lv: int) -> void:
	role = r
	level = lv
	_refresh_label()

## Name des Mitarbeiters (kommt vom Host, GameManager._net_staff_namen)
func set_staff_name(n: String) -> void:
	if staff_name == n:
		return
	staff_name = n
	_refresh_label()

## Wie viele Bestellungen der Kellner gerade trägt.
## 1-2 Krüge landen in den Händen, der Rest als Traube vor dem Bauch.
func set_carrying(n: int) -> void:
	if carrying == n:
		return
	carrying = n
	# Tablett vor dem Körper: Kellner mit Krügen, Koch mit einem Teller
	var koch := role == 1
	var tablett := find_child("Tablett", true, false) as Node3D
	if _figur:
		_figur.trage_pose(n > 0, 2)
	if tablett:
		tablett.visible = n > 0
		(tablett.get_node("Teller") as Node3D).visible = koch and n > 0
	for i in _mug_nodes.size():
		(_mug_nodes[i] as Node3D).visible = not koch and i < n
	_refresh_label()
func _refresh_label() -> void:
	if _label == null:
		return
	# Über dem Kopf: immer der Name, darüber das Symbol des Berufs
	_label.text = staff_name if staff_name != "" else Staff.role_name(role)
	_label.modulate = ROLE_COLORS.get(role, Color.WHITE)
	var symbol := get_node_or_null("Beruf") as Sprite3D
	if symbol:
		symbol.texture = Symbole.bild(str(ROLE_SYMBOLE.get(role, "person")))
		symbol.modulate = ROLE_COLORS.get(role, Color.WHITE)

func _process(delta: float) -> void:
	var t := clampf(delta * 10.0, 0.0, 1.0)
	position = position.lerp(_net_pos, t)
	rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	var spd := (position - _last).length() / maxf(delta, 0.001)
	_last = position
	if _idle_motion:
		_idle_motion.idle = spd <= 0.4
	if spd > 0.4:
		if _zapft:
			_zapft = false
			_figur.pose_loesen()
		_set_walking()
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
		_model.position.y = _model_base_y
	else:
		if _walking:
			_set_standing()
		if role == 4 and carrying > 0:
			# Mit vollem Krug an der Theke: stillstehen, bis er abgestellt ist
			if _zapft:
				_zapft = false
				_figur.pose_loesen()
		elif role == 4:
			# Zapfer: am Hahn stehen heißt zapfen (kein Modell bringt die Animation mit)
			_zapf_t += delta
			_figur.zapf_pose(_zapf_t)
			_zapft = true
			return
		_figur.pose_auffrischen()   # Skelett aktualisieren, damit die Idle-Bewegung greift
		# im Stehen leicht umschauen und atmen, damit er nicht erstarrt wirkt
		_jitter_t -= delta
		if _jitter_t <= 0.0:
			_jitter_t = randf_range(2.0, 5.0)
			_idle_jitter = randf_range(-0.35, 0.35)
		_model.rotation.y = lerp_angle(_model.rotation.y,
			deg_to_rad(model_yaw_offset) + _idle_jitter, clampf(delta * 1.5, 0.0, 1.0))



## Organische Stehbewegung (Atmen, Gewicht verlagern, Kopf drehen) — nur für
## Figuren ohne echte Stehanimation.
func _setup_idle_motion() -> void:
	if _figur.skelett == null:
		return
	_idle_motion = IdleMotion.new()
	_idle_motion.name = "IdleMotion"
	_figur.skelett.add_child(_idle_motion)

## Für Tests: welche Figur dieser Angestellte hat.
func figur() -> Figur:
	return _figur
