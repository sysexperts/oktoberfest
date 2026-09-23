class_name Visitor
extends Node3D
## Kirmes-Besucher. Bummelt von Stand zu Stand, bleibt davor stehen, geht weiter.
## Läuft immer in Blickrichtung — dadurch nie rückwärts oder seitlich schlurfend.
## Jeder Besucher bekommt zufällig eine Figur aus scripts/figuren.gd.

const Figuren := preload("res://scripts/figuren.gd")
const LOD_DIST := 42.0      # weiter weg: Animation aus (Leistung)
const TURN_SPEED := 6.0
## So viele Besucher feiern beim Stehenbleiben statt nur dazustehen.
const DANCE_CHANCE := 0.08
## So viele machen stattdessen eine Extra-Bewegung (Kopf kratzen …), wenn die Figur eine hat.
const EXTRA_CHANCE := 0.12
## So weit voraus schaut ein Besucher nach Hindernissen. Vorher lief er einfach
## gerade durch Buden, Bänke und Zäune hindurch.
## Geprüft wird nicht mit einem Strahl, sondern mit dem eigenen Körper ein Stück
## voraus: ein Strahl aus der Körpermitte geht an Zaunpfosten und Tischbeinen
## vorbei, während die Schulter dagegen läuft (Messung: 42 von 200 Besuchern
## steckten mit Strahlprüfung noch in etwas drin).
const SICHT := 0.6
## So dick und hoch ist ein Besucher
const KOERPER_RADIUS := 0.4
const KOERPER_HOEHE := 1.5
## So oft wird geschaut (gestaffelt, damit nicht alle im selben Bild abfragen)
const BLICK_NAH := 0.2
const BLICK_FERN := 0.5
## So lange gilt eine gefundene Ausweichrichtung weiter
const WEICHE_DAUER := 0.5
## Kommt er so lange nicht vorbei, sucht er sich ein neues Ziel
const FEST_ZEIT := 3.0

## Die Figuren schauen nicht in Godots Standardrichtung.
@export var model_yaw_offset := 180.0

var speed := 1.5

var _crowd: Node = null
var _tgt := Vector3.ZERO
var _pause := 0.0
var _figur: Figur
var _state := ""        # "walk", "stand", "dance" oder "extra"
var _lod_timer := 0.0
var _far := false
var _jitter_t := 0.0
var _jitter := 0.0
var _base_y := 0.0
var _walk_speed := 1.0
var _idle_motion: IdleMotion
var _blick_t := 0.0     # nächste Hindernisabfrage
var _weiche := Vector3.ZERO   # Ausweichrichtung (leer = geradeaus)
var _weiche_t := 0.0
var _fest := 0.0        # wie lange er schon gegen etwas drückt
var _probe: PhysicsShapeQueryParameters3D = null
var _eng: PhysicsShapeQueryParameters3D = null

@onready var _model: Node3D = $Model

func _ready() -> void:
	add_to_group("visitor")
	# Draußen läuft alles nur lokal — Zufall reicht, niemand muss dieselbe Figur sehen
	_figur = Figuren.einsetzen(self, Figuren.zufaellig())
	_model = _figur
	speed = randf_range(1.1, 2.0)
	_walk_speed = randf_range(0.85, 1.15)
	_model.rotation.y = deg_to_rad(model_yaw_offset)
	_base_y = _model.position.y
	_go_walk()
	if _figur.braucht_idle_bewegung():
		_setup_idle_motion()

func setup(crowd: Node) -> void:
	_crowd = crowd
	position = crowd.random_start()
	_tgt = crowd.next_point(position)
	var d := _tgt - position
	d.y = 0
	if d.length() > 0.01:
		rotation.y = atan2(-d.x, -d.z)

func _go_walk() -> void:
	if _state == "walk":
		return
	_figur.gehen(_walk_speed)
	_state = "walk"

func _go_stand() -> void:
	if _state == "stand":
		return
	_figur.stehen()
	_state = "stand"

func _go_dance() -> void:
	if _state == "dance":
		return
	if _figur.tanzen(randf_range(0.8, 1.1)):
		_state = "dance"
	else:
		_go_stand()

func _go_extra() -> void:
	if _figur.extra():
		_state = "extra"
	else:
		_go_stand()

func _process(delta: float) -> void:
	if _flug_t >= 0.0:
		_fliegen(delta)
		return
	_update_lod(delta)
	if _crowd == null:
		return
	if _pause > 0.0:
		_pause -= delta
		_idle_look(delta)
		return
	var to := _tgt - position
	to.y = 0
	if to.length() < 0.7:
		_pause = randf_range(1.5, 6.0)
		var wurf := randf()
		if wurf < DANCE_CHANCE:
			_go_dance()
		elif wurf < DANCE_CHANCE + EXTRA_CHANCE:
			_go_extra()
		else:
			_go_stand()
		_tgt = _crowd.next_point(position)
		return
	var dir := _laufrichtung(to.normalized(), delta)
	var want := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * TURN_SPEED, 0.0, 1.0))
	var fwd := -global_transform.basis.z
	fwd.y = 0
	fwd = fwd.normalized()
	# Beim Ausweichen muss er erst herumsein: die Drehung läuft weich, sonst
	# schiebt die alte Blickrichtung ihn noch ein Stück in die Bude hinein.
	if fwd.dot(dir) > (0.8 if _weiche != Vector3.ZERO else 0.25):
		position += fwd * speed * delta
	_go_walk()
	if _idle_motion:
		_idle_motion.idle = false
	_model.rotation.y = lerp_angle(_model.rotation.y, deg_to_rad(model_yaw_offset), clampf(delta * 5.0, 0.0, 1.0))
	_model.position.y = _base_y

# ------------------------------------------------------------ Hindernisse
## Führt der Weg in eine Bude, Bank oder einen Zaun? Dann daran entlang statt
## hindurch. Gefragt wird dieselbe Kollision, an der auch der Spieler hängen
## bleibt — damit gilt es automatisch für alles Gebaute, auch für später
## hingestellte Teile aus dem Baumodus.
func _laufrichtung(zum_ziel: Vector3, delta: float) -> Vector3:
	_weiche_t -= delta
	_blick_t -= delta
	if _blick_t <= 0.0:
		_blick_t = randf_range(0.7, 1.3) * (BLICK_FERN if _far else BLICK_NAH)
		if _steckt_fest():
			# Steht mitten in etwas drin (hineingeschoben, Bude nachträglich
			# darüber gebaut): in die erste freie Richtung hinaus. Zum nächsten
			# Wegpunkt zu laufen half nicht — der liegt oft hinter dem Hindernis.
			var raus := _raus()
			if raus != Vector3.ZERO:
				_weiche = raus
				_weiche_t = WEICHE_DAUER
				return _weiche
		_weiche = _freier_weg(zum_ziel)
		if _weiche == zum_ziel:
			_weiche = Vector3.ZERO
			_fest = 0.0
		else:
			_weiche_t = WEICHE_DAUER
			_fest += _blick_t
			if _fest > FEST_ZEIT:
				# Steckt in einer Ecke: neues Ziel, sonst schiebt er dort ewig
				_fest = 0.0
				if _crowd:
					_tgt = _crowd.next_point(position)
	if _weiche_t > 0.0 and _weiche != Vector3.ZERO:
		return _weiche
	return zum_ziel

## Geradeaus, wenn dort Platz ist — sonst an der Fläche entlang, notfalls zur
## anderen Seite. Bleibt nur die Wand, dreht er um.
func _freier_weg(zum_ziel: Vector3) -> Vector3:
	if _platz(zum_ziel):
		return zum_ziel
	var entlang := _entlang(zum_ziel)
	if entlang != Vector3.ZERO and _platz(entlang):
		return entlang
	if entlang != Vector3.ZERO and _platz(-entlang):
		return -entlang
	return -zum_ziel

## Steckt er wirklich in etwas drin? Enger gefragt als der Vorausblick: dicht
## vor einer Bude zu stehen ist gewollt, im Tisch zu stehen nicht.
func _steckt_fest() -> bool:
	var raum := _raum()
	if raum == null:
		return false
	if _eng == null:
		var form := CapsuleShape3D.new()
		form.radius = KOERPER_RADIUS * 0.55
		form.height = KOERPER_HOEHE
		_eng = PhysicsShapeQueryParameters3D.new()
		_eng.shape = form
		_eng.collide_with_areas = false
	_eng.transform = Transform3D(Basis.IDENTITY,
		global_position + Vector3(0, 0.15 + KOERPER_HOEHE * 0.5, 0))
	return not raum.intersect_shape(_eng, 1).is_empty()

## Erste Richtung, in der wieder Platz ist (Vector3.ZERO = ringsum zu).
func _raus() -> Vector3:
	for winkel in [0.0, 90.0, 180.0, 270.0, 45.0, 135.0, 225.0, 315.0]:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(winkel))
		if _platz(dir):
			return dir
	return Vector3.ZERO

## Hat der Körper ein Stück voraus in dieser Richtung Platz?
func _platz(dir: Vector3) -> bool:
	var raum := _raum()
	if raum == null:
		return true
	if _probe == null:
		var form := CapsuleShape3D.new()
		form.radius = KOERPER_RADIUS
		form.height = KOERPER_HOEHE
		_probe = PhysicsShapeQueryParameters3D.new()
		_probe.shape = form
		_probe.collide_with_areas = false
	var ziel := global_position + dir * SICHT + Vector3(0, 0.15 + KOERPER_HOEHE * 0.5, 0)
	_probe.transform = Transform3D(Basis.IDENTITY, ziel)
	return raum.intersect_shape(_probe, 1).is_empty()

## Richtung an der getroffenen Fläche entlang (Vector3.ZERO = nichts getroffen)
func _entlang(dir: Vector3) -> Vector3:
	var raum := _raum()
	if raum == null:
		return Vector3.ZERO
	var start := global_position + Vector3(0, 0.9, 0)
	var abf := PhysicsRayQueryParameters3D.create(start, start + dir * (SICHT + KOERPER_RADIUS))
	abf.collide_with_areas = false
	var treffer := raum.intersect_ray(abf)
	if treffer.is_empty():
		# Nichts vor der Nase, aber der Körper passt nicht: einfach seitlich
		return Vector3(-dir.z, 0.0, dir.x)
	var n: Vector3 = treffer.normal
	n.y = 0.0
	if n.length() < 0.01:
		return Vector3(-dir.z, 0.0, dir.x)
	n = n.normalized()
	var seite := dir - n * dir.dot(n)
	seite.y = 0.0
	if seite.length() < 0.15:
		# frontal davor: seitlich ausweichen, sonst bleibt die Richtung stehen
		seite = Vector3(-n.z, 0.0, n.x)
	return seite.normalized()

func _raum() -> PhysicsDirectSpaceState3D:
	var welt := get_world_3d()
	return welt.direct_space_state if welt else null

## Beim Stehen leicht umschauen und atmen — nur wenn er nicht gerade feiert.
func _idle_look(delta: float) -> void:
	if _idle_motion:
		_idle_motion.idle = true
	if _state == "stand":
		_figur.pose_auffrischen()   # nur beim Standbild-Modell nötig
	if _state == "dance" or _state == "extra":
		return
	_jitter_t -= delta
	if _jitter_t <= 0.0:
		_jitter_t = randf_range(2.0, 5.0)
		_jitter = randf_range(-0.5, 0.5)
	_model.rotation.y = lerp_angle(_model.rotation.y,
		deg_to_rad(model_yaw_offset) + _jitter, clampf(delta * 1.5, 0.0, 1.0))

func _update_lod(delta: float) -> void:
	_lod_timer -= delta
	if _lod_timer > 0.0:
		return
	_lod_timer = randf_range(0.4, 0.8)
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var far := global_position.distance_to(cam.global_position) > LOD_DIST
	if far == _far:
		return
	_far = far
	var anim := _figur.anim
	if anim:
		if far:
			anim.advance(0.0)      # aktuelle Pose einfrieren, sonst T-Pose
			anim.active = false
		else:
			anim.active = true

## Organische Stehbewegung — nur für Figuren ohne echte Stehanimation.
func _setup_idle_motion() -> void:
	if _figur.skelett == null:
		return
	_idle_motion = IdleMotion.new()
	_idle_motion.name = "IdleMotion"
	_figur.skelett.add_child(_idle_motion)

# ------------------------------------------------------------ Umgefahren
## Vom Lieferwagen erwischt (scripts/lieferwagen.gd): fliegt im Bogen und dreht
## sich, bleibt kurz liegen, rappelt sich auf und bummelt weiter.
const SCHWERKRAFT := 20.0
var _flug := Vector3.ZERO
var _flug_t := -1.0
var _dreh := Vector3.ZERO
var _liegt := 0.0

func fliegt() -> bool:
	return _flug_t >= 0.0

func geschleudert(tempo: Vector3) -> void:
	_flug = tempo
	_flug_t = 0.0
	_liegt = 0.0
	_dreh = Vector3(randf_range(6.0, 10.0), randf_range(-3.0, 3.0), randf_range(-5.0, 5.0))
	_figur.rennen(1.6)

func _fliegen(delta: float) -> void:
	_flug_t += delta
	if _liegt > 0.0:
		_liegt -= delta
		if _liegt <= 0.0:
			# aufstehen und weiter
			_model.rotation = Vector3(0, deg_to_rad(model_yaw_offset), 0)
			_model.position.y = _base_y
			position.y = 0.0
			_flug_t = -1.0
			_state = ""
			_pause = 0.0
			_go_walk()
		return
	_flug.y -= SCHWERKRAFT * delta
	position += _flug * delta
	_model.rotation += _dreh * delta
	if position.y <= 0.0 and _flug.y < 0.0:
		position.y = 0.0
		var tempo := Vector2(_flug.x, _flug.z).length()
		if tempo > 4.0:
			# einmal aufhüpfen
			_flug = Vector3(_flug.x * 0.4, absf(_flug.y) * 0.3, _flug.z * 0.4)
			return
		# liegen bleiben (flach auf dem Rücken)
		_model.rotation = Vector3(-PI / 2, _model.rotation.y, 0)
		_model.position.y = _base_y + 0.2
		_figur.stehen()
		_liegt = 2.5
