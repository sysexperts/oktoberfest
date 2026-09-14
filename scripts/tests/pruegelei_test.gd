extends Node3D
## Testszene Prügelei — zum Anschauen, ohne das Spiel zu spielen.
## Öffnen: scenes/tests/pruegelei_test.tscn im Editor, F6.
##
## Steuerung:
##   Rechte Maustaste halten + Maus: umsehen · W/A/S/D: bewegen
##   1: Einzelstreit · M: Massenschlägerei (füllt auf 24 Gäste auf, ~30 s)
##   R: alles zurücksetzen
##   E drücken (nahe an einem Gast): packen — E gedrückt halten lädt die Wurfkraft,
##   loslassen wirft ihn (mehrere Meter, prallt an Wand und Tisch ab)
##
## Mit "-- --demo" läuft ein fester Ablauf und speichert Bilder unter tools/pruegel_*.png;
## zusammen mit --write-movie entsteht ein Video (tools/render_pruegelei.sh).

const Figuren := preload("res://scripts/figuren.gd")
const RAUFBOLD := preload("res://scenes/pruegel/raufbold.tscn")
const MASSENSCHLAEGEREI := preload("res://scenes/pruegel/massenschlaegerei.tscn")
const LADEZEIT := 1.1
const WURF_MIN := Vector2(5.0, 2.5)    # waagerecht, senkrecht bei kurzem Druck
const WURF_MAX := Vector2(16.0, 6.5)   # bei voller Ladung
const MASSEN_GAESTE := 24

@onready var _gaeste: Node3D = %Gaeste
@onready var _kamera: Camera3D = %Kamera
@onready var _kraft: ProgressBar = %Wurfkraft
@onready var _ausgang: Marker3D = %Ausgang

var _startlagen := {}
var _zusatz: Array[Node3D] = []
var _gepackt: Node3D
var _ladung := 0.0
var _e_gedrueckt := false
var _yaw := 0.0
var _pitch := -0.35
var _demo := false
## Im Demo-Ablauf „drückt" das Skript die E-Taste
var _demo_e := false
var _schlaegerei: Node3D

func _ready() -> void:
	var i := 0
	for g in _gaeste.get_children():
		_gast_einrichten(g, i)
		_startlagen[g] = g.global_transform
		i += 1
	_yaw = _kamera.rotation.y
	_pitch = _kamera.rotation.x
	_kraft.visible = false
	_demo = OS.get_cmdline_user_args().has("--demo")
	if _demo:
		%Hilfe.visible = false
		_demo_ablauf()

func _gast_einrichten(g: Node3D, i: int) -> void:
	g.figur_setzen(Figuren.ALLE[i % Figuren.ALLE.size()])
	g.flucht_ziel = _ausgang.global_position + Vector3(randf_range(-2.0, 2.0), 0, randf_range(0.0, 2.5))

# ------------------------------------------------------------ Steuerung
func _unhandled_input(event: InputEvent) -> void:
	if _demo:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * 0.004
		_pitch = clampf(_pitch - mm.relative.y * 0.004, -1.4, 1.2)
		_kamera.rotation = Vector3(_pitch, _yaw, 0.0)
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		match k.keycode:
			KEY_1:
				einzelstreit()
			KEY_M:
				massenschlaegerei()
			KEY_R:
				zuruecksetzen()

func _process(delta: float) -> void:
	if not _demo:
		var richtung := Vector3.ZERO
		if Input.is_physical_key_pressed(KEY_W):
			richtung -= _kamera.global_transform.basis.z
		if Input.is_physical_key_pressed(KEY_S):
			richtung += _kamera.global_transform.basis.z
		if Input.is_physical_key_pressed(KEY_A):
			richtung -= _kamera.global_transform.basis.x
		if Input.is_physical_key_pressed(KEY_D):
			richtung += _kamera.global_transform.basis.x
		richtung.y = 0.0
		if richtung.length() > 0.01:
			_kamera.global_position += richtung.normalized() * 6.0 * delta
	var e := _demo_e if _demo else Input.is_physical_key_pressed(KEY_E)
	if e and not _e_gedrueckt:
		_versuche_packen()
	elif e and _gepackt:
		_ladung = minf(1.0, _ladung + delta / LADEZEIT)
	elif not e and _e_gedrueckt and _gepackt:
		_werfen()
	_e_gedrueckt = e
	if _gepackt:
		# Vor der Kamera hochgehalten, beim Laden weiter nach hinten ausgeholt
		var vorn := -_kamera.global_transform.basis.z
		vorn.y = 0.0
		vorn = vorn.normalized()
		var ort := _kamera.global_position + vorn * lerpf(1.5, 1.0, _ladung)
		_gepackt.global_position = Vector3(ort.x, lerpf(0.35, 0.75, _ladung), ort.z)
		_gepackt.rotation.y = atan2(vorn.x, vorn.z)
		_gepackt.get_node("Kipper").rotation.z = sin(Time.get_ticks_msec() * 0.02) * 0.15
	_kraft.visible = _gepackt != null
	_kraft.value = _ladung * 100.0

func _alle_gaeste() -> Array:
	return _gaeste.get_children()

func _versuche_packen() -> void:
	var bester: Node3D = null
	var beste_d := 4.5
	var vorn := -_kamera.global_transform.basis.z
	vorn.y = 0.0
	for g in _alle_gaeste():
		var zu: Vector3 = g.global_position - _kamera.global_position
		zu.y = 0.0
		var d := zu.length()
		if d < beste_d and vorn.normalized().dot(zu.normalized()) > 0.4:
			beste_d = d
			bester = g
	if bester and bester.packen():
		_gepackt = bester
		_ladung = 0.0

func _werfen() -> void:
	var vorn := -_kamera.global_transform.basis.z
	vorn.y = 0.0
	var kraft := WURF_MIN.lerp(WURF_MAX, _ladung)
	_gepackt.get_node("Kipper").rotation = Vector3.ZERO
	_gepackt.werfen(vorn.normalized() * kraft.x + Vector3.UP * kraft.y)
	_gepackt = null
	_ladung = 0.0

# ------------------------------------------------------------ Streit
func einzelstreit() -> void:
	var frei: Array = _alle_gaeste().filter(func(g: Node3D) -> bool: return g.ist_frei())
	if frei.size() < 2:
		return
	var a: Node3D = frei.pick_random()
	frei.erase(a)
	frei.sort_custom(func(x: Node3D, y: Node3D) -> bool:
		return x.global_position.distance_to(a.global_position) < y.global_position.distance_to(a.global_position))
	a.streit_mit(frei[0])

## Füllt auf MASSEN_GAESTE auf (Gäste strömen von den Seiten herein) und startet
## die Massenschlägerei in der Mitte.
func massenschlaegerei() -> void:
	if _schlaegerei and is_instance_valid(_schlaegerei) and _schlaegerei.laeuft():
		return
	var i := _alle_gaeste().size()
	while _alle_gaeste().size() < MASSEN_GAESTE:
		var g := RAUFBOLD.instantiate()
		_gaeste.add_child(g)
		var winkel := randf() * TAU
		g.global_position = Vector3(cos(winkel) * randf_range(2.5, 6.5), 0.0, sin(winkel) * randf_range(2.0, 4.5))
		g.rotation.y = randf() * TAU
		_gast_einrichten(g, i)
		_zusatz.append(g)
		i += 1
	_schlaegerei = MASSENSCHLAEGEREI.instantiate()
	add_child(_schlaegerei)
	_schlaegerei.starten(_alle_gaeste(), Vector3(0.0, 0.0, 0.5), MASSEN_GAESTE)

func zuruecksetzen() -> void:
	if _schlaegerei and is_instance_valid(_schlaegerei):
		_schlaegerei.beenden()
	for g in _zusatz:
		if is_instance_valid(g):
			g.queue_free()
	_zusatz.clear()
	for g in _startlagen.keys():
		g.schlaegerei = null
		g.gegner = null
		g._setze(g.Zustand.RUHIG)
		g.global_transform = _startlagen[g]
		g.get_node("Kipper").rotation = Vector3.ZERO
		g.get_node("Kipper").position = Vector3.ZERO
	_gepackt = null

# ------------------------------------------------------------ Demo-Ablauf (Video)
func _demo_ablauf() -> void:
	var g := _alle_gaeste()
	# 1 Einzelstreit aus der Nähe
	_kamera_auf(Vector3(-1.0, 2.1, 4.8), Vector3(-2.0, 0.9, 0.0))
	await _warte(0.8)
	g[0].streit_mit(g[1])
	await _warte(2.0)
	_foto("pruegel_1_streit")
	await _warte(4.5)
	_foto("pruegel_2_ko")
	# 2 Massenschlägerei (~30 s): erst weit, dann nah dran, dann von oben
	zuruecksetzen()
	_kamera_auf(Vector3(0.0, 5.5, 9.5), Vector3(0.0, 0.3, 0.5))
	await _warte(0.5)
	massenschlaegerei()
	await _warte(4.0)
	_foto("pruegel_3_masse_start")
	await _warte(5.0)
	_foto("pruegel_4_masse_voll")
	_kamera_auf(Vector3(3.0, 1.9, 4.0), Vector3(0.0, 0.8, 0.5))
	await _warte(7.0)
	_foto("pruegel_5_masse_nah")
	_kamera_auf(Vector3(-4.0, 9.0, 5.0), Vector3(0.0, 0.0, 0.5))
	await _warte(7.0)
	_foto("pruegel_6_masse_oben")
	_kamera_auf(Vector3(0.0, 5.5, 9.5), Vector3(0.0, 0.3, 0.5))
	await _warte(8.0)
	_foto("pruegel_7_masse_ende")
	# 3 Rauswurf: packen, laden, gegen die Wand werfen
	zuruecksetzen()
	await _warte(0.5)
	var opfer: Node3D = g[2]
	var hinter := opfer.global_position + Vector3(0.0, 1.6, 2.2)
	_kamera_auf(hinter, opfer.global_position + Vector3(0.0, 0.9, -6.0))
	await _warte(0.3)
	_demo_e = true
	await _warte(LADEZEIT + 0.3)
	_demo_e = false
	await _warte(0.2)
	_kamera_auf(hinter + Vector3(4.5, 1.5, -1.0), opfer.global_position + Vector3(0.0, 0.8, -4.0))
	await _warte(0.3)
	_foto("pruegel_8_flug")
	await _warte(3.0)
	get_tree().quit()

func _kamera_auf(ort: Vector3, ziel: Vector3) -> void:
	_kamera.global_position = ort
	_kamera.look_at(ziel)

func _warte(s: float) -> void:
	await get_tree().create_timer(s).timeout

func _foto(name_bild: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://tools/%s.png" % name_bild)
	print("  gespeichert: ", name_bild)
