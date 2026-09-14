extends Node3D
## Ein Gast, der sich prügeln kann — Ablauf und Aussehen der Schlägerei.
## Zustände: ruhig → hingehen → Kampf (Deckung, Schläge, Treffer) → K.o. (umfallen,
## Staub, liegen) → aufstehen → flüchten. Spieler können ihn packen (zappelt),
## E halten lädt die Wurfkraft, loslassen wirft ihn mehrere Meter; er prallt an
## Wänden und Tischen ab, schlägt auf, bleibt liegen und haut ab.
##
## Aufbau: scenes/pruegel/raufbold.tscn — Kipper (dreht beim Umfallen und im Flug)
## mit Model (Figur). Kampfbewegungen: scripts/pruegel/kampf_pose.gd.
## Wird in der Testszene scenes/tests/pruegelei_test.tscn benutzt und später von
## customer.gd für Streit-Ereignisse im Zelt.

signal umgehauen(raufbold: Node3D)
signal gelandet(raufbold: Node3D)

const Figuren := preload("res://scripts/figuren.gd")
const KampfPose := preload("res://scripts/pruegel/kampf_pose.gd")
const STAUB := preload("res://scenes/effekte/staub.tscn")

enum Zustand { RUHIG, HINGEHEN, KAMPF, KO, LIEGT, AUFSTEHEN, FLUCHT, GEPACKT, FLIEGT }

const KAMPF_ABSTAND := 0.95
const SCHLAG_DAUER := 0.42
const SCHLAG_TREFFPUNKT := 0.3      # Anteil der Schlagdauer, an dem die Faust vorn ist
const TREFFER_DAUER := 0.4
const GEHEN := 1.6
const RENNEN := 5.2
const SCHWERKRAFT := 20.0
const LIEGEN := 1.8

var zustand := Zustand.RUHIG
var gegner: Node3D
var ausdauer := 3
## Wohin er nach dem K.o. oder Rauswurf flüchtet (leer = bleibt stehen)
var flucht_ziel := Vector3.INF

var _figur: Figur
var _pose: Node
var _t := 0.0
var _schlag_warten := 0.5
var _schlag := -1.0          # -1 = kein Schlag, sonst 0 … 1 Verlauf
var _schlag_rechts := true
var _getroffen := false
var _treffer := 0.0
var _flug := Vector3.ZERO
var _dreh := Vector3.ZERO
var _aufprall_gezaehlt := 0
var _anim := ""
var _kipp_start := Vector3.ZERO

@onready var _kipper: Node3D = $Kipper

func _ready() -> void:
	_figur = $Kipper/Model as Figur
	_pose_einbauen()

## Andere Figur einsetzen (Bean, Charakter 2 oder 3).
func figur_setzen(szene: PackedScene) -> void:
	_figur = Figuren.einsetzen(_kipper, szene)
	_pose = null
	_pose_einbauen()

func _pose_einbauen() -> void:
	if _figur == null or _figur.skelett == null or _pose != null:
		return
	# Zur Laufzeit: die Figur steht erst jetzt fest, das Skelett steckt im Modell
	_pose = KampfPose.new()
	_figur.skelett.add_child(_pose)

func ist_frei() -> bool:
	return zustand == Zustand.RUHIG

func kaempft() -> bool:
	return zustand == Zustand.HINGEHEN or zustand == Zustand.KAMPF

## Streit anfangen — beide gehen aufeinander los.
func streit_mit(anderer: Node3D) -> void:
	if anderer == null or anderer == self:
		return
	gegner = anderer
	ausdauer = randi_range(2, 4)
	_setze(Zustand.HINGEHEN)
	if anderer.has_method("streit_mit") and not anderer.kaempft():
		anderer.gegner = self
		anderer.ausdauer = randi_range(2, 4)
		anderer._setze(Zustand.HINGEHEN)

func _setze(neu: Zustand) -> void:
	zustand = neu
	_t = 0.0

func _process(delta: float) -> void:
	_t += delta
	match zustand:
		Zustand.RUHIG:
			_anim_setzen("stehen")
			_haltung(0.0, delta)
		Zustand.HINGEHEN:
			_hingehen(delta)
		Zustand.KAMPF:
			_kampf(delta)
		Zustand.KO:
			_haltung(0.0, delta * 3.0)
		Zustand.LIEGT:
			if _t > LIEGEN:
				_aufstehen()
		Zustand.AUFSTEHEN:
			pass
		Zustand.FLUCHT:
			_fluechten(delta)
		Zustand.GEPACKT:
			_anim_setzen("rennen")
			_pose_wert("zappeln", 1.0)
			_pose_wert("haltung", 0.0)
		Zustand.FLIEGT:
			_fliegen(delta)
	# Treffer-Reaktion klingt ab
	_treffer = move_toward(_treffer, 0.0, delta / TREFFER_DAUER)
	_pose_wert("treffer", sin(_treffer * PI) * 1.0)
	if zustand != Zustand.GEPACKT and zustand != Zustand.FLIEGT:
		_pose_wert("zappeln", move_toward(_pose_get("zappeln"), 0.0, delta * 3.0))
	if _figur and _anim == "stehen":
		_figur.pose_auffrischen()

# ------------------------------------------------------------ Kampf
func _hingehen(delta: float) -> void:
	if not _gegner_da():
		_setze(Zustand.RUHIG)
		return
	var zu: Vector3 = gegner.global_position - global_position
	zu.y = 0.0
	_blick(zu, delta)
	_haltung(0.6, delta)
	if zu.length() <= KAMPF_ABSTAND + 0.05:
		_setze(Zustand.KAMPF)
		_schlag_warten = randf_range(0.2, 0.6)
		return
	_anim_setzen("gehen")
	global_position += zu.normalized() * minf(GEHEN * 1.4 * delta, zu.length() - KAMPF_ABSTAND)

func _kampf(delta: float) -> void:
	if not _gegner_da():
		_setze(Zustand.RUHIG)
		return
	var zu: Vector3 = gegner.global_position - global_position
	zu.y = 0.0
	_blick(zu, delta)
	_haltung(1.0, delta)
	_anim_setzen("stehen")
	# Tänzeln: seitlich hin und her, Abstand halten
	var seite := Vector3(-zu.z, 0.0, zu.x).normalized()
	global_position += seite * sin(_t * 3.1 + float(get_instance_id() % 7)) * 0.35 * delta
	if zu.length() > KAMPF_ABSTAND + 0.15:
		global_position += zu.normalized() * 0.8 * delta
	elif zu.length() < KAMPF_ABSTAND - 0.2:
		global_position -= zu.normalized() * 0.8 * delta
	# Schlag
	if _schlag < 0.0:
		_schlag_warten -= delta
		if _schlag_warten <= 0.0 and _treffer <= 0.05:
			_schlag = 0.0
			_getroffen = false
			_schlag_rechts = not _schlag_rechts if randf() < 0.75 else _schlag_rechts
	else:
		_schlag += delta / SCHLAG_DAUER
		var aus := _schlag / SCHLAG_TREFFPUNKT if _schlag < SCHLAG_TREFFPUNKT else 1.0 - (_schlag - SCHLAG_TREFFPUNKT) / (1.0 - SCHLAG_TREFFPUNKT)
		aus = clampf(aus, 0.0, 1.0)
		_pose_wert("schlag_rechts" if _schlag_rechts else "schlag_links", aus)
		# Ausfallschritt mit dem Schlag
		_kipper.position = Vector3(0.0, 0.0, 0.0) + (-_kipper.basis.z) * 0.0
		if not _getroffen and _schlag >= SCHLAG_TREFFPUNKT:
			_getroffen = true
			if zu.length() < KAMPF_ABSTAND + 0.45 and gegner.has_method("treffer_abbekommen"):
				gegner.treffer_abbekommen(self)
		if _schlag >= 1.0:
			_schlag = -1.0
			_pose_wert("schlag_rechts", 0.0)
			_pose_wert("schlag_links", 0.0)
			_schlag_warten = randf_range(0.25, 0.8)

## Vom Gegner getroffen: Kopf fliegt zurück, kleiner Rückstoß, Staub, Knall.
func treffer_abbekommen(von: Node3D) -> void:
	if not kaempft():
		return
	_treffer = 1.0
	var weg: Vector3 = global_position - von.global_position
	weg.y = 0.0
	global_position += weg.normalized() * 0.22
	ausdauer -= 1
	_staub(global_position + Vector3(0, 0.05, 0), 0.45, "schlag")
	if ausdauer <= 0:
		_umfallen(weg.normalized())

func _umfallen(richtung: Vector3) -> void:
	_setze(Zustand.KO)
	_pose_wert("schlag_rechts", 0.0)
	_pose_wert("schlag_links", 0.0)
	# Nach hinten umkippen (weg vom Schläger)
	_blick(-richtung, 1.0, true)
	var tw := create_tween()
	tw.tween_property(_kipper, "rotation:x", deg_to_rad(84.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_kipper, "position:y", 0.12, 0.45)
	tw.tween_callback(func() -> void:
		_staub(global_position + richtung * 0.9, 1.1, "ko")
		_setze(Zustand.LIEGT)
		umgehauen.emit(self))
	if gegner and gegner.has_method("kaempft") and gegner.kaempft():
		gegner.gegner = null

func _aufstehen() -> void:
	_setze(Zustand.AUFSTEHEN)
	var tw := create_tween()
	tw.tween_property(_kipper, "rotation", Vector3.ZERO, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_kipper, "position", Vector3.ZERO, 0.7)
	tw.tween_callback(func() -> void:
		gegner = null
		_setze(Zustand.FLUCHT if flucht_ziel != Vector3.INF else Zustand.RUHIG))

func _fluechten(delta: float) -> void:
	var zu := flucht_ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.3:
		_setze(Zustand.RUHIG)
		return
	_anim_setzen("rennen")
	_blick(zu, delta * 2.0)
	global_position += zu.normalized() * minf(RENNEN * delta, zu.length())

# ------------------------------------------------------------ Packen und Werfen
func packen() -> bool:
	if zustand == Zustand.FLIEGT or zustand == Zustand.GEPACKT:
		return false
	if gegner and gegner.has_method("kaempft") and gegner.kaempft():
		gegner.gegner = null
		gegner._setze(Zustand.RUHIG)
	gegner = null
	_kipper.rotation = Vector3.ZERO
	_kipper.position = Vector3.ZERO
	_setze(Zustand.GEPACKT)
	return true

## Wurf mit Geschwindigkeit (m/s). Dreht sich im Flug, prallt ab, schlägt auf.
func werfen(geschwindigkeit: Vector3) -> void:
	_setze(Zustand.FLIEGT)
	_flug = geschwindigkeit
	_aufprall_gezaehlt = 0
	_dreh = Vector3(randf_range(5.0, 9.0), randf_range(-3.0, 3.0), randf_range(-4.0, 4.0))

func _fliegen(delta: float) -> void:
	_pose_wert("zappeln", 1.0)
	_flug.y -= SCHWERKRAFT * delta
	var von := global_position + Vector3(0, 0.8, 0)
	var schritt := _flug * delta
	# Anprall an Wand/Tisch: Strahl von der Körpermitte in Flugrichtung
	var raum := get_world_3d().direct_space_state
	var abfrage := PhysicsRayQueryParameters3D.create(von, von + schritt + schritt.normalized() * 0.35)
	var treffer := raum.intersect_ray(abfrage)
	if not treffer.is_empty() and _flug.length() > 1.5:
		var normale: Vector3 = treffer.normal
		_flug = _flug.bounce(normale) * 0.35
		global_position = (treffer.position as Vector3) - Vector3(0, 0.8, 0) + normale * 0.4
		_aufprall_gezaehlt += 1
		_dreh = Vector3(randf_range(-10.0, 10.0), randf_range(-4.0, 4.0), randf_range(-10.0, 10.0))
		_staub(treffer.position, 1.2, "aufprall")
		return
	global_position += schritt
	_kipper.rotation += _dreh * delta
	# Boden
	if global_position.y <= 0.0 and _flug.y < 0.0:
		global_position.y = 0.0
		var tempo := Vector2(_flug.x, _flug.z).length()
		_staub(global_position, clampf(0.6 + tempo * 0.12, 0.6, 1.5), "aufprall")
		if tempo > 5.0 and _aufprall_gezaehlt < 2:
			# Einmal über den Boden hüpfen
			_flug = Vector3(_flug.x * 0.45, absf(_flug.y) * 0.3, _flug.z * 0.45)
			_aufprall_gezaehlt += 1
			return
		_liegen_bleiben()

func _liegen_bleiben() -> void:
	_flug = Vector3.ZERO
	var yaw := _kipper.global_rotation.y
	global_rotation.y = yaw
	_kipper.rotation = Vector3(deg_to_rad(84.0), 0.0, 0.0)
	_kipper.position = Vector3(0, 0.12, 0)
	_setze(Zustand.LIEGT)
	gelandet.emit(self)

# ------------------------------------------------------------ Hilfen
func _gegner_da() -> bool:
	return gegner != null and is_instance_valid(gegner) and gegner.has_method("kaempft") and gegner.kaempft()

## Blickrichtung (Wurzel schaut nach -Z wie customer.gd)
func _blick(richtung: Vector3, delta: float, sofort := false) -> void:
	if richtung.length() < 0.01:
		return
	var ziel := atan2(-richtung.x, -richtung.z)
	rotation.y = ziel if sofort else lerp_angle(rotation.y, ziel, clampf(delta * 8.0, 0.0, 1.0))

func _haltung(ziel: float, delta: float) -> void:
	_pose_wert("haltung", move_toward(_pose_get("haltung"), ziel, delta * 4.0))

func _anim_setzen(was: String) -> void:
	if _figur == null or _figur.anim == null or _anim == was:
		return
	_anim = was
	match was:
		"gehen":
			_figur.gehen(1.2)
		"rennen":
			_figur.rennen(1.3)
		_:
			_figur.stehen()

func _pose_wert(name_wert: String, wert: float) -> void:
	if _pose:
		_pose.set(name_wert, wert)

func _pose_get(name_wert: String) -> float:
	return float(_pose.get(name_wert)) if _pose else 0.0

func _staub(ort: Vector3, staerke: float, ton: String) -> void:
	var s := STAUB.instantiate()
	get_tree().current_scene.add_child(s)
	s.global_position = Vector3(ort.x, maxf(0.02, ort.y), ort.z)
	s.ausloesen(staerke, ton)
