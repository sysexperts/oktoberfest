class_name Player
extends CharacterBody3D
const KoopDaten := preload("res://scripts/koop_daten.gd")
## Ağ-farkında oyuncu (FPS). Görsel yapı player.tscn'de gerçek düğümlerdir.
## Yerel oyuncu (authority) girdi işler + durum yayınlar; uzaklar senkron görünür.

const SPEED := 4.0
const SPRINT_SPEED := 7.0
const ACCEL := 12.0
const INTERACT_RANGE := 3.0
const FACING_DOT := 0.35
const MOUSE_SENS := 0.0025
const PITCH_LIMIT := deg_to_rad(85.0)
const EYE_HEIGHT := 1.35
const FILL_RATE := 0.6
## Volle Krüge auf einmal (1 in der Hand + Rest als extra_kruege) — Spaß-Plan 2.3
const MAX_KRUEGE := 3
## Jeder zusätzliche Krug macht so viel langsamer
const TRAG_BREMSE := 0.12
## Absprunggeschwindigkeit (Schwerkraft 20 → gut 0,9 m hoch)
const SPRUNG_TEMPO := 6.0
var _war_in_luft := false

# 1 Helles, 2 Weizen, 3 Radler
const BEER_COLORS := {0: Color(0.95, 0.65, 0.05), 1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45), 4: Color(0.75, 0.35, 0.08), 5: Color(0.7, 0.88, 1.0)}
# Yemek: 1 Pretzel, 2 Sosis
const FOOD_COLORS := {1: Color(0.72, 0.45, 0.15), 2: Color(0.8, 0.3, 0.2), 3: Color(0.9, 0.6, 0.25)}
# Kostüm renkleri (C ile değiştir)
const COSTUME_COLORS := [Color(0.85,0.2,0.2), Color(0.2,0.45,0.85), Color(0.2,0.7,0.3), Color(0.7,0.3,0.8), Color(0.95,0.85,0.2), Color(0.95,0.95,0.95)]

# Ağ ile senkronlanan durum
var carry_pkg_kind := 0  # taşınan paketin türü (1 Bier, 2 Zutaten); 0 = yok
var carry_pkg_amount := 0
var carry_state := 0     # 0 = boş el, 1 = bardak, 2 = yemek, 3 = paket
var carry_fill := 0.0    # 0..1
var carry_type := 0      # 0 boş, 1 Helles, 2 Weizen, 3 Radler, 4 Festbier, 5 Wasser
const WASSER := 5
## Weitere volle Krüge (Biersorten), zusätzlich zum Krug in der Hand
var extra_kruege: Array[int] = []
var emote := 0           # 0 nichts, sonst EMOTE_* (senkron)
## Zuletzt im Rad gewähltes Emote (nur lokal; emote trägt es dann ins Netz)
var emote_wahl := 0
var costume := 0         # kostüm rengi indeksi (senkron)
var _applied_costume := -1
var _emote_until := 0.0
var _letzter_ping := 0   # ms — höchstens ein Ping alle 0,6 s
var _sfx_node: Node
var _sfx_cd := 0.0

var _is_local := false
var _world: Node
var _current_target: Node3D = null
var _highlight_ring: MeshInstance3D
var _pitch := 0.0
const Figuren := preload("res://scripts/figuren.gd")
var _cur_anim := ""
## Einleitung: bis wann eine Geste läuft, die die Laufanimation nicht überschreiben darf
var _geste_bis := 0.0
var _last_anim_pos: Vector3
var _net_pos: Vector3
var _net_yaw: float

@onready var _model: Node3D = $Model
@onready var _head: Node3D = $Head
@onready var _cam: Camera3D = $Head/Camera3D
@onready var _hold_point: Node3D = $Head/HoldPoint
@onready var _carry_glass: Krug = $Head/HoldPoint/CarryGlass
## Kiste, wenn ein Paket getragen wird
@onready var _carry_food: MeshInstance3D = $Head/HoldPoint/CarryFood
@onready var _carry_teller: EssenTeller = $Head/HoldPoint/CarryTeller
@onready var _carry_sack: Node3D = get_node_or_null("Head/HoldPoint/CarrySack")
@onready var _extra_nodes: Array[Krug] = [$Head/HoldPoint/ExtraKrug1, $Head/HoldPoint/ExtraKrug2]
@onready var _emote_label: Label3D = $Emote
@onready var _namensschild: Label3D = $Namensschild
## Besen beim Fegen (nur solange man putzt, schwingt hin und her)
@onready var _besen: Node3D = get_node_or_null("Besen")
## Strahl aus dem Mund beim Würgen (scenes/effekte/kotzstrahl.tscn)
@onready var _kotzstrahl: GPUParticles3D = $Kotzstrahl
var _fegt_bis := 0.0
## Abteilung, die dieser Spieler leitet ("" = keine) — aus der Lobby (GameManager._spieler_info)

func _ready() -> void:
	add_to_group("player")
	_world = get_tree().current_scene
	# Authority'yi düğüm adından türet (ad = peer_id). Zamanlamadan bağımsız.
	var auth := name.to_int()
	set_multiplayer_authority(auth)
	_is_local = (auth == multiplayer.get_unique_id())
	_net_pos = global_position
	_net_yaw = rotation.y

	# Kendi modelini gizle (FPS), kameranı aç; uzak oyuncularda tersi
	_model.visible = not _is_local
	_cam.current = _is_local
	costume = int(abs(auth)) % COSTUME_COLORS.size()  # kimliğe göre başlangıç rengi
	_apply_costume()
	if not _is_local:
		# Bei Mitspielern in Handhöhe (relativ zum Kopf) — vorher schwebte der Krug
		# über dem Kopf (Test 13.09.)
		_hold_point.position = Vector3(0.3, -0.32, -0.45)
	# Neue Tasten auch mit älterer .exe: deren Einstellungen-Autoload kennt sie nicht
	for aktion: String in {"springen": KEY_SPACE, "trinken": KEY_G}:
		if not InputMap.has_action(aktion):
			InputMap.add_action(aktion)
			var ev := InputEventKey.new()
			ev.physical_keycode = {"springen": KEY_SPACE, "trinken": KEY_G}[aktion]
			InputMap.action_add_event(aktion, ev)

	# Animationen über die Figur (scripts/figur.gd) — jede Figur benennt sie anders
	_last_anim_pos = global_position

	_namensschild.visible = false
	if _is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_make_highlight_ring()
		_sfx_node = _world.get_node_or_null("Sfx")
		if not Net.solo:
			if not KoopDaten.lobby_wahl.is_empty() and _world.has_method("net_lobby_setzen"):
				# Aus dem Warteraum (Einladungscode): Name und Figur stehen schon fest
				var w := KoopDaten.lobby_wahl
				_world.net_lobby_setzen.rpc_id(1, str(w.get("name", "")), costume, int(w.get("figur", 0)), str(w.get("id", "")))
			elif _world.has_method("open_lobby_ui"):
				# Direkt beigetreten (IP, offizieller Server): Lobby-Fenster im Spiel
				_world.call_deferred("open_lobby_ui")

## Name, Farbe und Figur aus der Lobby (vom Server an alle).
func set_info(spielername: String, farbe: int, figur: int = 0) -> void:
	costume = clampi(farbe, 0, COSTUME_COLORS.size() - 1)
	_apply_costume()
	_figur_setzen(figur)
	if _is_local:
		return
	_namensschild.text = spielername
	_namensschild.visible = spielername != ""

func _sfx(name: String) -> void:
	if _sfx_node:
		_sfx_node.play(name)

func _sfx_loop(name: String) -> void:
	# sürekli aksiyonlarda kısılmış çalma
	if _sfx_cd <= 0.0:
		_sfx_cd = 0.22
		_sfx(name)

func _make_highlight_ring() -> void:
	_highlight_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.35
	ring.outer_radius = 0.5
	_highlight_ring.mesh = ring
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.9, 0.2)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.8, 0.1)
	_highlight_ring.material_override = mat
	_highlight_ring.visible = false
	_world.add_child.call_deferred(_highlight_ring)

## Laufendes Kirmes-Minispiel (Schießbude) — bekommt alle Eingaben
var minispiel: Node = null
var _minispiel_bude: Node = null

## Vom GameManager, nachdem die Runde bezahlt ist.
func schiessen_starten() -> void:
	if _minispiel_bude and is_instance_valid(_minispiel_bude) and _minispiel_bude.has_method("spiel_starten"):
		minispiel = _minispiel_bude
		_minispiel_bude.spiel_starten(self)

func minispiel_beendet() -> void:
	minispiel = null
	_cam.current = true

func _unhandled_input(event: InputEvent) -> void:
	if not _is_local:
		return
	if minispiel != null and is_instance_valid(minispiel):
		minispiel.eingabe(event)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		var sens := MOUSE_SENS * Einstellungen.maus
		var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
		rotate_y(-mm.relative.x * sens)
		_pitch = clampf(_pitch - mm.relative.y * sens * y_dir, -PITCH_LIMIT, PITCH_LIMIT)
		_head.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		var hud := _world.get_node_or_null("HUD")
		if hud and hud.has_method("is_rent_open") and hud.is_rent_open():
			hud.close_rent()
		elif hud and hud.has_method("is_vote_open") and hud.is_vote_open():
			hud.close_vote()
		elif hud and hud.has_method("is_lobby_open") and hud.is_lobby_open():
			hud.close_lobby()
		elif hud and hud.has_method("is_computer_open") and hud.is_computer_open():
			hud.close_computer()
		elif hud and hud.has_method("is_popup_open") and hud.is_popup_open():
			hud.close_popup()
		elif hud and hud.has_method("is_booking_open") and hud.is_booking_open():
			hud.close_booking()
		else:
			# Nichts anderes offen — Pausemenue. Ist es offen, faengt es ESC selbst ab.
			var pause := _world.get_node_or_null("PauseMenu")
			if pause and pause.has_method("oeffnen"):
				pause.oeffnen()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Beim Tippen des Zeltnamens sind Q, C, R … Buchstaben
	if _tippt():
		return
	# Prost-Geste — Taste in den Einstellungen umbelegbar (Aktion "emote")
	if event.is_action_pressed("emote") and not event.is_echo():
		# Wer eine Lampe/Deko oder einen Tisch trägt, dreht ihn stattdessen
		if _world.has_method("haelt_einrichtung") and _world.haelt_einrichtung(name.to_int()):
			_world.net_rotate_einrichtung.rpc_id(1)
		elif _world.has_method("haelt_tisch") and _world.haelt_tisch(name.to_int()):
			_world.net_rotate_table.rpc_id(1)
		elif _world.has_method("haelt_lager") and _world.haelt_lager(name.to_int()):
			_world.net_rotate_lager.rpc_id(1)
		else:
			# Sonst das Emote-Rad öffnen: halten, aussuchen, loslassen
			_rad_oeffnen()
	if event.is_action_released("emote"):
		var rad := _emote_rad()
		if rad and rad.ist_offen():
			rad.schliessen(true)
	# Kostümfarbe wechseln — Aktion "costume"
	if event.is_action_pressed("costume") and not event.is_echo():
		# Wer eine Lampe/Deko trägt, verkauft sie stattdessen
		if _world.has_method("haelt_einrichtung") and _world.haelt_einrichtung(name.to_int()):
			_world.net_sell_einrichtung.rpc_id(1)
		else:
			costume = (costume + 1) % COSTUME_COLORS.size()
			_apply_costume()
	# Ping: Mitspielern etwas zeigen (Gast, Pfütze, Paket …) — Aktion "ping"
	if event.is_action_pressed("ping") and not event.is_echo():
		var jetzt := Time.get_ticks_msec()
		if jetzt - _letzter_ping > 600:
			_letzter_ping = jetzt
			var ziel := global_position - global_transform.basis.z * 5.0
			var art := 0
			if _current_target:
				ziel = _current_target.global_position
				if _current_target is Customer:
					art = 1
				elif _current_target is Mess:
					art = 2
				elif _current_target is Package:
					art = 3
			_world.net_ping.rpc_id(1, ziel, art)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## Umschauen mit dem rechten Stick. Anders als die Maus liefert ein Stick keine
## Ereignisse, sondern eine gehaltene Auslenkung — deshalb hier je Bild statt in
## _unhandled_input.
func _pad_blick(delta: float) -> void:
	if _tippt() or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	var dreh := Input.get_axis("blick_links", "blick_rechts")
	var neigung := Input.get_axis("blick_hoch", "blick_runter")
	if absf(dreh) < 0.01 and absf(neigung) < 0.01:
		return
	var tempo := Einstellungen.PAD_BLICK_TEMPO * Einstellungen.maus * delta
	var y_dir := -1.0 if Einstellungen.maus_y_umkehren else 1.0
	rotate_y(-dreh * tempo)
	_pitch = clampf(_pitch - neigung * tempo * y_dir, -PITCH_LIMIT, PITCH_LIMIT)
	_head.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	if _is_local:
		_pad_blick(delta)
		_sfx_cd -= delta
		if _kotz_t > 0.0:
			_kotzen(delta)
		_handle_movement(delta)
		_update_target()
		if _kotz_t > 0.0:
			# Kein Ziel beim Würgen: sonst stünde „Putzen (E)" da, obwohl gerade
			# nichts geht
			_current_target = null
		_update_hint()
		_update_krug_anzeige()
		if not _tippt() and _kotz_t <= 0.0:
			_handle_interaction(delta)
		_trinken(delta)
		if _kotz_t > 0.0:
			emote = EMOTE_KOTZEN
		elif emote_laeuft():
			# Losgehen bricht das Emote ab — man steht ja mittendrin
			if Vector2(velocity.x, velocity.z).length() > 0.6:
				_emote_until = 0.0
				emote = 0
			else:
				emote = emote_wahl
		else:
			emote = 0
		_kamera_aussen(emote != 0, delta)
		_push_state.rpc(global_position, rotation.y, carry_state, carry_fill, carry_pkg_kind if carry_state == 3 else carry_type, emote, costume, PackedByteArray(extra_kruege))
	else:
		var t := clampf(delta * 12.0, 0.0, 1.0)
		global_position = global_position.lerp(_net_pos, t)
		rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	_update_carry_visual()
	_besen_zeigen()
	_update_animation(delta)

## Figur aus dem Warteraum einsetzen (scripts/figuren.gd), Animationen neu starten.
func _figur_setzen(nr: int) -> void:
	var szene: PackedScene = Figuren.ALLE[posmod(nr, Figuren.ALLE.size())]
	var neu := Figuren.einsetzen(self, szene)
	if neu == _model:
		return
	_model = neu
	_model.visible = not _is_local
	_cur_anim = ""

func _update_animation(delta: float) -> void:
	var figur := _model as Figur
	if figur == null or figur.anim == null:
		return
	# Geste aus der Einleitung ausspielen lassen
	if Time.get_ticks_msec() / 1000.0 < _geste_bis:
		return
	if _cur_anim == "geste":
		_cur_anim = ""
	# Sprung: in der Luft nach vorn lehnen, bei der Landung zurück
	var in_luft := global_position.y > 0.35
	var w := clampf(delta * 6.0, 0.0, 1.0)
	_model.rotation.x = lerpf(_model.rotation.x, -0.35 if in_luft else 0.0, w)
	# Sprung: in der Luft gestreckt, bei der Landung kurz gestaucht
	var ziel_skala := Vector3(0.94, 1.1, 0.94) if in_luft else Vector3.ONE
	if _war_in_luft and not in_luft:
		_model.scale = Vector3(1.1, 0.85, 1.1)
	_war_in_luft = in_luft
	_model.scale = _model.scale.lerp(ziel_skala, w)
	_emote_label.visible = emote != 0
	# Übergeben: gewürgt wird mit gestellten Knochen (Figur.kotz_pose), weil kein
	# Modell dafür eine Animation mitbringt. Der Takt läuft hier mit, damit auch
	# Mitspieler ihn sehen — die kennen nur emote, nicht _kotz_t.
	if emote == EMOTE_KOTZEN:
		_emote_label.text = "🤮"
		_emote_label.modulate = Color(0.6, 0.9, 0.4)
		_kotz_anim_t += delta
		var h := kotz_heftig(_kotz_anim_t)
		figur.kotz_pose(h)
		# Es kommt aus dem Mund, solange gewürgt wird (scenes/effekte/kotzstrahl.tscn).
		# Die Schwälle macht der Explosiveness-Wert der Szene, nicht dieser Takt —
		# ein- und ausschalten je Stoß hat die Brocken wieder weggeräumt.
		if not _strahl_an:
			_strahl_an = true
			_kotzstrahl.emitting = true
			_kotzstrahl.restart()
		_cur_anim = "kotzen"
		return
	if _cur_anim == "kotzen":
		_kotz_anim_t = 0.0
		_kotzstrahl.emitting = false
		_strahl_an = false
		figur.kotz_pose_loesen()
		_cur_anim = ""
	# Die übrigen Emotes aus dem Rad (scenes/ui/emote_rad.tscn). Tanzen und Sitzen
	# haben echte Animationen, der Rest wird über Knochen gestellt — dafür bringt
	# kein Modell etwas mit.
	if emote != 0:
		_emote_anim_t += delta
		_emote_label.visible = emote == EMOTE_JUBEL
		_emote_label.text = "Prost! 🍻"
		_emote_label.modulate = Color(1, 1, 1)
		match emote:
			EMOTE_TANZEN:
				if _cur_anim != "tanzen":
					# Ohne Tanz stehen bleiben — sonst bliebe die Figur in der T-Pose
					if not figur.tanzen():
						figur.stehen()
					_cur_anim = "tanzen"
			EMOTE_SITZEN:
				if _cur_anim != "sitzen":
					if figur.kann_sitzen():
						figur.sitzen()
					else:
						figur.sitz_pose()
					_cur_anim = "sitzen"
			EMOTE_WINKEN:
				figur.winke_pose(_emote_anim_t)
				_cur_anim = "pose"
			EMOTE_JUBEL:
				figur.jubel_pose(_emote_anim_t)
				_cur_anim = "pose"
			EMOTE_POSEN:
				figur.posen_pose(_emote_anim_t)
				_cur_anim = "pose"
		return
	if _cur_anim == "pose" or _cur_anim == "sitzen":
		figur.pose_loesen()
		_cur_anim = ""
	_emote_anim_t = 0.0
	var spd: float
	if _is_local:
		spd = Vector2(velocity.x, velocity.z).length()
	else:
		spd = (global_position - _last_anim_pos).length() / maxf(delta, 0.0001)
	_last_anim_pos = global_position
	var want := "stehen"
	if spd > 5.5:
		want = "rennen"
	elif spd > 0.4:
		want = "gehen"
	if want != _cur_anim:
		match want:
			"rennen":
				figur.rennen()
			"gehen":
				figur.gehen()
			_:
				figur.stehen()
		_cur_anim = want
	if want == "stehen":
		figur.pose_auffrischen()

@rpc("authority", "unreliable_ordered")
func _push_state(pos: Vector3, yaw: float, cstate: int, cfill: float, ctype: int, em: int, cost: int, extra: PackedByteArray) -> void:
	_net_pos = pos
	_net_yaw = yaw
	carry_state = cstate
	carry_fill = cfill
	# Beim Paket steht in ctype die Paketsorte (Müllsack = 3 sieht man dann als Sack)
	if cstate == 3:
		carry_pkg_kind = ctype
	else:
		carry_type = ctype
	extra_kruege.clear()
	for sorte in extra:
		extra_kruege.append(int(sorte))
	emote = em
	costume = cost
	_apply_costume()

func _apply_costume() -> void:
	if costume == _applied_costume or _namensschild == null:
		return
	_applied_costume = costume
	# Spielerfarbe zeigt das Namensschild (der Schal-Ring sah nicht gut aus)
	_namensschild.modulate = COSTUME_COLORS[costume % COSTUME_COLORS.size()].lerp(Color.WHITE, 0.25)

## Tippt der Spieler gerade in ein Textfeld (Zeltname)? Dann zählen W/A/S/D, E, Q …
## als Buchstaben, nicht als Steuerung — Input liest die Tasten sonst trotzdem.
func _tippt() -> bool:
	if minispiel != null and is_instance_valid(minispiel):
		return true   # Schießbude: nicht laufen, nichts anderes anfassen
	var hud := _world.get_node_or_null("HUD") if _world else null
	if hud == null:
		return false
	# Auch während der Abstimmung: Maus ist frei, Tasten sollen nichts auslösen
	return (hud.has_method("is_rent_open") and hud.is_rent_open()) \
		or (hud.has_method("is_vote_open") and hud.is_vote_open()) \
		or (hud.has_method("is_lobby_open") and hud.is_lobby_open())

func _handle_movement(delta: float) -> void:
	if _geschleudert():
		return
	# Auf dem Arm eines Mitspielers: keine eigene Bewegung, nur zappeln
	if wird_getragen():
		velocity = Vector3.ZERO
		_head.rotation.z = sin(float(Time.get_ticks_msec()) * 0.013) * 0.12
		return
	# Beim Übergeben bleibt man stehen — gehen geht erst wieder danach
	if _kotz_t > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, ACCEL * delta * SPEED)
		velocity.z = move_toward(velocity.z, 0.0, ACCEL * delta * SPEED)
		if not is_on_floor():
			velocity.y -= 20.0 * delta
		elif velocity.y <= 0.0:
			velocity.y = 0.0
		move_and_slide()
		return
	var input_dir := Vector2.ZERO if _tippt() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis.x * input_dir.x) + (transform.basis.z * input_dir.y)
	dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	# Rausch: die Laufrichtung zieht zur Seite
	if promille > 0.05 and dir != Vector3.ZERO:
		dir = dir.rotated(Vector3.UP, sin(_rausch_t * 0.8) * 0.22 * promille)
	# Springen (Leertaste) — nur vom Boden aus
	if not _tippt() and InputMap.has_action("springen") and Input.is_action_just_pressed("springen") and is_on_floor():
		# Ohne Klang — der Piepston beim Springen nervte im Koop (v210)
		velocity.y = SPRUNG_TEMPO
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	speed *= 1.0 - TRAG_BREMSE * float(extra_kruege.size())   # mehrere Krüge bremsen
	speed *= tempo_faktor   # z. B. 10 Maß beim Wettschleppen (scripts/wettschleppen.gd)
	if dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta * speed)
		velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta * speed)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCEL * delta * speed)
		velocity.z = move_toward(velocity.z, 0, ACCEL * delta * speed)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	elif velocity.y <= 0.0:
		# Nur beim Stehen/Landen nullen — sonst schluckte das den Absprung im
		# selben Bild und Springen ging nie (Feedback 14.09.)
		velocity.y = 0.0
	move_and_slide()
	_schritte(delta)

var _schritt_t := 0.0

## Schrittgeräusch im Takt der Bewegung, beim Rennen schneller.
## Stumm, solange assets/audio/sfx/schritte fehlt.
func _schritte(delta: float) -> void:
	var tempo := Vector2(velocity.x, velocity.z).length()
	if not is_on_floor() or tempo < 1.0:
		_schritt_t = 0.0
		return
	_schritt_t -= delta
	if _schritt_t <= 0.0:
		_schritt_t = 0.32 if tempo > 5.0 else 0.45
		if _sfx_node:
			_sfx_node.play("schritte", -14.0)

func _update_target() -> void:
	var best: Node3D = null
	var best_score := -1.0
	var forward := -global_transform.basis.z
	var origin := global_position + Vector3(0, EYE_HEIGHT * 0.5, 0)
	# Nichts durch die Zeltwand greifen: drinnen nur Drinnenes, draußen nur Draußenes
	var ich_drin: bool = _world.has_method("im_zelt") and _world.im_zelt(global_position)
	# Abdeckplanen im Tutorial decken Möbel zu — die sind solange tabu
	var planen: Array[Mess] = []
	for m in get_tree().get_nodes_in_group("mess"):
		if m is Mess and (m as Mess).ist_plane():
			planen.append(m)
	for node in get_tree().get_nodes_in_group("interactable"):
		var n3 := node as Node3D
		if n3 == null or not n3.is_visible_in_tree():
			continue
		if _world.has_method("im_zelt") and _world.im_zelt(n3.global_position) != ich_drin:
			continue
		# Emporen: nichts durch den Emporenboden hindurch (oben ↔ unten)
		if ich_drin and (global_position.y > 1.8) != (n3.global_position.y > 3.3 and absf(n3.global_position.x) > 7.7):
			continue
		# Verschiebbares Möbel unter einer Plane: solange sie daliegt, gehört der
		# Griff der Plane. Sonst stand am Regal immer „Regal bewegen" statt
		# „Plane abziehen" (Feedback Tutorial).
		if (n3 is Lager or n3 is Einrichtung or n3 is BeerTable) and _unter_plane(planen, n3.global_position):
			continue
		# Objekte dürfen einen eigenen Ansprechpunkt melden (z. B. Wohnwagen-Tür)
		var ipos: Vector3 = n3.global_position
		if n3 is Mess and (n3 as Mess).ist_plane():
			ipos = (n3 as Mess).naechster_punkt(origin)
		elif n3.has_method("interact_point"):
			ipos = n3.interact_point()
		var to: Vector3 = ipos - origin
		to.y = 0
		var dist := to.length()
		if dist > INTERACT_RANGE:
			continue
		var facing := forward.dot(to.normalized()) if dist > 0.01 else 1.0
		if facing < FACING_DOT:
			continue
		var s := facing / maxf(dist, 0.1)
		if s > best_score:
			best_score = s
			best = n3
	_current_target = best
	_update_highlight()

## Liegt über dieser Stelle noch eine Abdeckplane?
func _unter_plane(planen: Array[Mess], pos: Vector3) -> bool:
	for m in planen:
		if m.deckt(pos):
			return true
	return false

## Hinweis am Fadenkreuz — nur neu setzen, wenn er sich ändert.
var _hint_key := "-"

## Füllstandsanzeige über dem Fadenkreuz — nur neu setzen, wenn sie sich ändert.
var _krug_gezeigt := -1.0
var _war_voll := false

## Krug in der Hand: Füllstand anzeigen, beim Vollwerden einmal melden.
## Vorher sah man den Fortschritt nur am Bier im Krug — zu wenig, um zu merken,
## wann man abgeben kann.
func _update_krug_anzeige() -> void:
	var zeigen := carry_state == 1 and carry_type != 0
	var wert := carry_fill if zeigen else -1.0
	var voll := zeigen and carry_fill >= 0.999
	if voll and not _war_voll and _sfx_node:
		# kurzer Ton: fertig, ab zum Gast (ohne eigene Datei das Ding-Signal)
		_sfx_node.play_oder("krug_voll", "ding", -6.0)
	_war_voll = voll
	if is_equal_approx(wert, _krug_gezeigt):
		return
	_krug_gezeigt = wert
	var hud := _world.get_node_or_null("HUD")
	if hud and hud.has_method("set_krug"):
		hud.set_krug(carry_fill, zeigen)

func _update_hint() -> void:
	var key := ""
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and minispiel == null:
		key = _hint_for(_current_target)
	if key == _hint_key:
		return
	_hint_key = key
	var hud := _world.get_node_or_null("HUD")
	if hud and hud.has_method("set_hint"):
		hud.set_hint(key)

## Was E beim Ziel *jetzt* bewirkt — muss zu _handle_interaction passen.
func _hint_for(t: Node3D) -> String:
	if t == null:
		# Nichts im Blick, aber etwas in der Hand: trinken oder abstellen
		if carry_state == 1 and carry_fill > 0.0 and carry_type > 0:
			return "HINT_HAND_KRUG"
		return "HINT_HAND_ABLEGEN" if carry_state != 0 or not extra_kruege.is_empty() else ""
	if t.has_method("ist_abgelegt"):
		return "HINT_AUFHEBEN" if carry_state == 0 else ""
	if t is Braustation:
		var st: Dictionary = _world.brau_stand(int((t as Braustation).schritt)) if _world.has_method("brau_stand") else {}
		if bool(st.get("fertig", false)):
			# Bottich fertig: weiter zum Kessel. Kessel fertig: ins Gärfass.
			return "HINT_BRAU_WEITER" if int((t as Braustation).schritt) == 1 else "HINT_BRAU_INS_FASS"
		if not bool(st.get("bereit", true)):
			return "HINT_BRAU_ERST_MAISCHE"
		if int(st.get("zutat", 0)) <= 0:
			return "HINT_BRAU_MALZ_FEHLT" if int((t as Braustation).schritt) == 1 else "HINT_BRAU_HOPFEN_FEHLT"
		return "HINT_BRAU_RUEHREN" if int((t as Braustation).schritt) == 1 else "HINT_BRAU_KOCHEN"
	if t is Gaerfass:
		var idx: int = _world.gaerfass_index(t) if _world.has_method("gaerfass_index") else -1
		var fass: Dictionary = _world.gaerfass_stand(idx) if _world.has_method("gaerfass_stand") else {}
		match int(fass.get("zustand", 0)):
			1:
				return "HINT_GAERT"
			2:
				return "HINT_GAERFASS_FERTIG"
			_:
				if _world.has_method("sud_fertig") and _world.sud_fertig():
					return "HINT_GAERFASS_FUELLEN"
				return "HINT_GAERFASS_LEER"
	if t is Kellertuer:
		# Zu: sagen, woran es liegt. Offen: die Tür braucht keinen Hinweis.
		if (t as Kellertuer).ist_offen():
			return ""
		return "HINT_KELLER_ZU"
	if t.has_method("ist_eroeffnung"):
		return "HINT_ZELT_EROEFFNEN"
	if t.has_method("ist_saboteur"):
		return "HINT_SABOTEUR" if t.ist_saboteur() else ""
	if t.has_method("ist_huber"):
		return "HINT_HUBER"
	if t.has_method("ist_wiesnchef"):
		return "HINT_WIESNCHEF" if t.ansprechbar() else ""
	if t.has_method("ist_raufbold"):
		if traegt_raufbold:
			return "HINT_WERFEN"
		return "HINT_PACKEN" if t.ist_raufbold() else ""
	if t.has_method("ist_budenbesitzer"):
		if t.bude == null or t.bude.laeuft() or carry_state != 0:
			return ""
		return str(t.bude.hinweis) if "hinweis" in t.bude else "HINT_SCHIESSSTAND"
	var geschlossen: bool = _world.has_method("in_intermission") and _world.in_intermission()
	if t is Customer:
		var g := t as Customer
		# Wasser für Angetrunkene, Bierleichen heimbringen
		if carry_state == 1 and carry_type == WASSER and carry_fill >= 0.999:
			return "HINT_WASSER_GEBEN" if g.rausch_stufe >= 1 else ""
		if g.rausch_stufe == 3 and carry_state == 0 and extra_kruege.is_empty():
			return "HINT_HEIMBRINGEN"
		if g.order_state != 1:
			return ""
		if not (_has_ready() or not extra_kruege.is_empty()):
			# Halb voller Krug: bisher stand hier gar nichts und man rätselte,
			# warum das Abgeben nicht geht
			if carry_state == 1 and carry_fill > 0.0 and carry_fill < 0.999:
				return "HINT_KRUG_NICHT_VOLL"
			return ""
		var passt := (_has_ready() and g.can_serve(_carry_kind(), carry_type)) \
			or (g.order_kind == 1 and extra_kruege.has(g.order_type))
		return "HINT_SERVE" if passt else "HINT_WRONG_ORDER"
	if t is Ausgabe:
		# Von hinten mit vollem Krug: abstellen (Fässer stehen hinten am Regal)
		if _has_full_mug() and carry_type != WASSER and hinter_der_theke(t):
			return "HINT_AUSGABE_PUT"
		if carry_state != 0 and not kann_weiteren_krug():
			return ""
		return "HINT_AUSGABE_TAKE" if (t as Ausgabe).hat_fertiges() else "HINT_AUSGABE_EMPTY"
	if t is Einrichtung:
		if not geschlossen:
			return ""
		var traegt: bool = _world.has_method("haelt_einrichtung") and _world.haelt_einrichtung(name.to_int())
		return "HINT_PLACE_DECO" if traegt else "HINT_MOVE_DECO"
	if t is BeerTable:
		if not geschlossen:
			return ""
		var traegt_tisch: bool = _world.has_method("haelt_tisch") and _world.haelt_tisch(name.to_int())
		return "HINT_PLACE_TABLE" if traegt_tisch else "HINT_MOVE_TABLE"
	if t is MugDispenser:
		if carry_state == 0:
			return "HINT_TAKE_MUG"
		return "HINT_TAKE_ANOTHER" if kann_weiteren_krug() else ""
	if t is KegStation:
		if carry_state == 1 and carry_fill < 1.0:
			return "HINT_TAP"
		if _has_full_mug():
			return "HINT_KRUG_VOLL"
		return "HINT_NEED_MUG" if carry_state == 0 else ""
	if t is FoodStation:
		var ft := (t as FoodStation).food_type
		var kocht := carry_state == 2 and carry_type == ft and carry_fill < 1.0
		return "HINT_COOK" if carry_state == 0 or kocht else ""
	if t is Computer:
		return "HINT_COMPUTER"
	if t is Package:
		return "HINT_PICKUP" if carry_state == 0 else ""
	if t is Muellplatz:
		return "HINT_MUELL_ABSTELLEN" if carry_state == 3 and carry_pkg_kind == 3 else ""
	if t is Lager:
		if carry_state == 3 and carry_pkg_kind == 3:
			return "HINT_MUELL_NICHT_LAGER"
		if carry_state == 3:
			return "HINT_STORE"
		if geschlossen and carry_state == 0:
			var traegt_regal: bool = _world.has_method("haelt_lager") and _world.haelt_lager(name.to_int())
			return "HINT_PLACE_LAGER" if traegt_regal else "HINT_MOVE_LAGER"
		return "HINT_STORAGE"
	if t is ZeltVermietung:
		return "HINT_RENT_TENT"
	if t is OfficeDesk or t is BookingKiosk:
		return "HINT_OFFICE" if geschlossen else "HINT_OFFICE_SHIFT"
	if t is Caravan:
		return "HINT_SLEEP" if geschlossen else "HINT_SLEEP_SHIFT"
	if t is Mess and t.ist_plane():
		return "HINT_PLANE"
	if t is Mess and t.ist_dreck():
		return "HINT_FEGEN"
	if t is Mess:
		return "HINT_CLEAN"
	return ""

## Anvisiertes Objekt: dünner Umriss statt des gelben Bodenrings (Test 13.09.:
## der Ring nervte). assets/shader/umriss.tres als Overlay auf alle Meshes des Ziels.
const UMRISS := preload("res://assets/shader/umriss.tres")
var _umriss_ziel: Node3D

func _update_highlight() -> void:
	if _highlight_ring:
		_highlight_ring.visible = false
	if _current_target == _umriss_ziel:
		return
	# Das alte Ziel kann inzwischen weg sein (Gast gegangen, Krug aufgehoben)
	if is_instance_valid(_umriss_ziel):
		_umriss_setzen(_umriss_ziel, false)
	_umriss_ziel = _current_target
	_umriss_setzen(_umriss_ziel, true)

## Ohne Typangabe: ein freigegebenes Objekt darf hier ankommen, ohne Skriptfehler.
func _umriss_setzen(ziel, an: bool) -> void:
	if ziel == null or not is_instance_valid(ziel):
		return
	for mi in ziel.find_children("*", "MeshInstance3D", true, false):
		(mi as MeshInstance3D).material_overlay = UMRISS if an else null

func _handle_interaction(delta: float) -> void:
	# Etwas in der Hand und E bewirkt beim Ziel nichts (oder kein Ziel): ablegen.
	# Im vollen Zelt ist fast immer irgendetwas im Blick — nur bei „nichts im Blick"
	# abzulegen, klappte im Test praktisch nie.
	var traegt := carry_state != 0 or not extra_kruege.is_empty()
	if traegt and Input.is_action_just_pressed("interact") \
			and (_current_target == null or _hint_for(_current_target) == ""):
		_ablegen()
		return
	if Input.is_action_just_pressed("interact"):
		# Jemanden auf dem Arm? Dann wirft dieses E ihn weg, egal wohin man schaut.
		if traegt_raufbold or traegt_spieler:
			if traegt_spieler:
				_world.net_spieler_packen.rpc_id(1, 0)
			else:
				_world.net_rauswerfen.rpc_id(1, 0)
			_sfx("pop")
			return
		# Mitspieler packen: einer steht direkt vor einem und nichts im Blick
		if _current_target == null and _world.has_method("net_spieler_packen"):
			var wer := mitspieler_vor_mir()
			if wer != 0:
				_world.net_spieler_packen.rpc_id(1, wer)
				_sfx("pop")
				return
	if _current_target == null:
		return
	if Input.is_action_just_pressed("interact"):
		if _current_target.has_method("ist_abgelegt"):
			# Abgelegten Krug/Teller aufheben — nur mit freien Händen
			if carry_state == 0:
				_world.net_aufheben.rpc_id(1, _current_target.ablage_id)
				_sfx("pop")
			return
		if _current_target.has_method("ist_budenbesitzer"):
			# Schießbude: beim Budenbesitzer bezahlen (Server), dann startet das Spiel
			var bude = _current_target.bude
			if bude and not bude.laeuft() and carry_state == 0:
				_minispiel_bude = bude
				_world.net_schiessen_bezahlen.rpc_id(1, _world.get_path_to(bude))
			return
		if _current_target.has_method("ist_raufbold"):
			# Schlägerei: erst packen, mit dem nächsten E werfen
			if _current_target.ist_raufbold():
				_world.net_rauswerfen.rpc_id(1, _current_target.gast_id)
				_sfx("pop")
			return
		if _current_target.has_method("ist_eroeffnung"):
			_world.net_zelt_eroeffnen.rpc_id(1)
			_sfx("cheer")
			return
		if _current_target.has_method("ist_saboteur"):
			if _current_target.ist_saboteur():
				_world.net_saboteur_fangen.rpc_id(1)
				_sfx("cheer")
			return
		if _current_target.has_method("ist_huber"):
			_current_target.ansprechen()
			return
		if _current_target.has_method("ist_wiesnchef"):
			_current_target.ansprechen()
			return
		if _current_target is Customer and carry_state == 1 and carry_type == WASSER and carry_fill >= 0.999:
			if (_current_target as Customer).rausch_stufe >= 1:
				_world.net_wasser_geben.rpc_id(1, (_current_target as Customer).cust_id)
				carry_fill = 0.0
				carry_type = 0
				_sfx("glug")
			return
		if _current_target is Customer and (_current_target as Customer).rausch_stufe == 3 \
				and carry_state == 0 and extra_kruege.is_empty():
			_world.net_heimbringen.rpc_id(1, (_current_target as Customer).cust_id)
			_sfx("pop")
			return
		if _current_target is Customer and (_has_ready() or not extra_kruege.is_empty()):
			var g := _current_target as Customer
			if _has_ready() and g.can_serve(_carry_kind(), carry_type):
				_world.net_serve_guest.rpc_id(1, g.cust_id, _carry_kind(), carry_type)
				carry_state = 0
				carry_fill = 0.0
				carry_type = 0
				_naechster_krug_in_hand()
				_sfx("ding")
			elif g.order_state == 1 and g.order_kind == 1 and extra_kruege.has(g.order_type):
				# Passender Krug aus den zusätzlichen — der in der Hand bleibt
				_world.net_serve_guest.rpc_id(1, g.cust_id, 1, g.order_type)
				extra_kruege.erase(g.order_type)
				_sfx("ding")
		elif _current_target is BeerTable:
			# Molada masayı tut/bırak (yerleştir)
			if _world.has_method("in_intermission") and _world.in_intermission():
				_world.net_move_table.rpc_id(1, (_current_target as BeerTable).idx)
				_sfx("pop")
		elif _current_target is Einrichtung:
			# Molada Lampe/Deko aufnehmen oder abstellen
			if _world.has_method("in_intermission") and _world.in_intermission():
				_world.net_move_einrichtung.rpc_id(1, (_current_target as Einrichtung).deko_id)
				_sfx("pop")
		elif _current_target is Ausgabe and _has_ready() and carry_state in [1, 2] \
				and not (carry_state == 1 and carry_type == WASSER) and hinter_der_theke(_current_target):
			# Von hinten (Fassseite): vollen Krug oder fertige Portion für die
			# Kellner abstellen. Essen ging vorher gar nicht — es landete als
			# Bier auf der Ausgabe und war nirgends zu sehen.
			_world.net_put_ausgabe.rpc_id(1, carry_type, carry_state)
			_sfx("pop")
		elif _current_target is Ausgabe and (carry_state == 0 or kann_weiteren_krug()):
			# Fertigen Krug/Teller von der Ausgabe nehmen (Server entscheidet was)
			if (_current_target as Ausgabe).hat_fertiges():
				if carry_state != 0:
					_krug_weglegen()
				_world.net_take_ausgabe.rpc_id(1)
				_sfx("pop")
		elif _current_target is MugDispenser and (carry_state == 0 or kann_weiteren_krug()):
			if carry_state != 0:
				_krug_weglegen()   # vollen Krug zu den anderen, neuen leeren nehmen
			carry_state = 1
			carry_fill = 0.0
			carry_type = 0
			_sfx("pop")
		elif _current_target is Computer:
			# Bilgisayar arayüzünü aç (rol seçimi)
			if _world.has_method("open_computer_ui"):
				_world.open_computer_ui()
		elif _current_target is Package and carry_state == 0:
			# Warenpaket aufnehmen
			var pk := _current_target as Package
			carry_state = 3
			carry_pkg_kind = pk.kind
			carry_pkg_amount = pk.amount
			carry_fill = 1.0
			_world.net_pickup_package.rpc_id(1, pk.pkg_id)
			_sfx("pop")
		elif _current_target is Lager:
			# Außerhalb der Schicht mit leeren Händen: Regal aufnehmen/abstellen
			if carry_state == 0 and _world.has_method("in_intermission") and _world.in_intermission():
				_world.net_move_lager.rpc_id(1, _world._lagerregale().find(_current_target))
				_sfx("pop")
			# Getragenes Paket abladen
			elif carry_state == 3 and carry_pkg_kind == 3:
				pass   # Müll gehört vor die Tür, nicht ins Lager
			elif carry_state == 3:
				_world.net_store_package.rpc_id(1, carry_pkg_kind, carry_pkg_amount)
				carry_state = 0
				carry_pkg_kind = 0
				carry_pkg_amount = 0
				carry_fill = 0.0
				_sfx("ding")
		elif _current_target is Muellplatz and carry_state == 3 and carry_pkg_kind == 3:
			_world.net_muell_abgeben.rpc_id(1)
			carry_state = 0
			carry_pkg_kind = 0
			carry_pkg_amount = 0
			carry_fill = 0.0
			_sfx("ding")
		elif _current_target is ZeltVermietung:
			# Mietdialog: Preis sehen, Zeltnamen eingeben, bestätigen
			if _world.has_method("open_rent_ui"):
				_world.open_rent_ui()
			_sfx("pop")
		elif _current_target is OfficeDesk:
			# Wiesenbüro: Zelt/Lizenzen/Personal (nur wenn Zelt geschlossen)
			if _world.has_method("in_intermission") and _world.in_intermission():
				if _world.has_method("open_booking_ui"):
					_world.open_booking_ui()
			else:
				_sfx("pop")
		elif _current_target is BookingKiosk:
			# Zelt buchen / Tisch stellen / upgrade (sadece molada)
			if _world.has_method("in_intermission") and _world.in_intermission():
				if _world.has_method("open_booking_ui"):
					_world.open_booking_ui()
		elif _current_target is Gaerfass:
			# Sud mit Hefe ins Fass — danach gärt es fünf Minuten
			if _world.has_method("net_gaerfass_fuellen"):
				_world.net_gaerfass_fuellen.rpc_id(1, _world.gaerfass_index(_current_target))
				_sfx("pop")
		elif _current_target is Caravan:
			# Uyu → sonraki gün (sadece molada)
			if _world.has_method("in_intermission") and _world.in_intermission():
				_world.net_sleep.rpc_id(1)
				if _sfx_node:
					_sfx_node.play_oder("tuer", "pop")
	# Brauen: Halten ruehrt im Bottich bzw. kocht im Kessel (Server rechnet)
	if Input.is_action_pressed("interact") and _current_target is Braustation:
		if _world.has_method("net_brauen"):
			_world.net_brauen.rpc_id(1, int((_current_target as Braustation).schritt))
			_sfx_loop("glug" if int((_current_target as Braustation).schritt) == 1 else "sizzle")
	if Input.is_action_pressed("interact") and _current_target is KegStation:
		if carry_state == 1 and carry_fill < 1.0:
			if carry_fill <= 0.0:
				_sfx("zapfen")   # Zapfhahn auf — nur mit Datei
			carry_type = (_current_target as KegStation).beer_type
			carry_fill = minf(carry_fill + FILL_RATE * delta, 1.0)
			_sfx_loop("glug")
	# Yemek hazırlama (mutfak) — eller boşsa başlar, basılı tutunca pişer
	if Input.is_action_pressed("interact") and _current_target is FoodStation:
		var ft := (_current_target as FoodStation).food_type
		if carry_state == 0:
			carry_state = 2
			carry_type = ft
			carry_fill = 0.0
		if carry_state == 2 and carry_type == ft and carry_fill < 1.0:
			carry_fill = minf(carry_fill + FILL_RATE * delta, 1.0)
			_sfx_loop("sizzle")
	# Kir temizle (E basılı tut)
	if Input.is_action_pressed("interact") and _current_target is Mess:
		if _world.has_method("net_clean"):
			_world.net_clean.rpc_id(1, (_current_target as Mess).mess_id)
			if not (_current_target as Mess).ist_plane():
				_fegt_bis = Time.get_ticks_msec() / 1000.0 + 0.2
			_sfx_loop("scrub")

func _has_full_mug() -> bool:
	return carry_state == 1 and carry_fill >= 0.999

## Noch Platz für einen weiteren vollen Krug? (Hand voll, weniger als MAX_KRUEGE)
func kann_weiteren_krug() -> bool:
	return _has_full_mug() and extra_kruege.size() < MAX_KRUEGE - 1

## Vollen Krug aus der Hand zu den zusätzlichen legen — die Hand ist dann frei.
func _krug_weglegen() -> void:
	if not _has_full_mug():
		return
	extra_kruege.append(carry_type)
	carry_state = 0
	carry_fill = 0.0
	carry_type = 0

## Steht der Spieler auf der Fassseite der Ausgabe? Die Theke läuft quer (x),
## die Gäste stehen davor (größeres z), Fässer und Regal dahinter.
func hinter_der_theke(ausgabe: Node3D) -> bool:
	return global_position.z < ausgabe.global_position.z - 0.2

## Gegenstand aus der Hand vor sich ablegen (E ins Leere). Pakete werden wieder
## Pakete, Krüge und Teller liegen sichtbar am Boden (GameManager.net_ablegen).
func _ablegen() -> void:
	var ort := global_position - global_transform.basis.z * 0.9
	if carry_state == 3:
		_world.net_paket_ablegen.rpc_id(1, carry_pkg_kind, carry_pkg_amount, ort)
		carry_pkg_kind = 0
		carry_pkg_amount = 0
	elif carry_state == 1 or carry_state == 2:
		_world.net_ablegen.rpc_id(1, carry_state, carry_type, carry_fill, ort)
	elif not extra_kruege.is_empty():
		_world.net_ablegen.rpc_id(1, 1, extra_kruege.pop_back(), 1.0, ort)
		_sfx("pop")
		return
	carry_state = 0
	carry_fill = 0.0
	carry_type = 0
	_naechster_krug_in_hand()
	_sfx("pop")

# ------------------------------------------------------------ Trinken und Rausch
## Bier in der Hand trinken (G halten). Wer zu viel trinkt, schwankt: Kopf wiegt,
## die Laufrichtung zieht zur Seite. Baut sich langsam wieder ab.
const TRINK_TEMPO := 0.7        # Krugfüllung pro Sekunde
const PROMILLE_JE_KRUG := 0.45
const PROMILLE_ABBAU := 0.012   # pro Sekunde
const PROMILLE_MAX := 3.0
var promille := 0.0
var _rausch_t := 0.0
var _rausch_stufe := 0
## Summe des selbst getrunkenen Biers in Maß, seit der letzten gemeldeten Maß
var _getrunken := 0.0

func _trinken(delta: float) -> void:
	var trinkt := _kotz_t <= 0.0 and not _tippt() and InputMap.has_action("trinken") and Input.is_action_pressed("trinken") \
		and carry_state == 1 and carry_fill > 0.0 and carry_type > 0
	if trinkt:
		var schluck := minf(carry_fill, TRINK_TEMPO * delta)
		carry_fill -= schluck
		# Selbst getrunkenes Bier geht auch vom Lager ab — vorher kostete der
		# Zapfhahn für einen selbst nichts, nur Verkaufen zählte. Gezählt wird
		# in Maß: eine volle Maß ausgetrunken = eine weniger im Lager.
		if carry_type != WASSER:
			_getrunken += schluck
			while _getrunken >= 1.0:
				_getrunken -= 1.0
				if _world and _world.has_method("net_selbst_getrunken"):
					_world.net_selbst_getrunken.rpc_id(1)
		promille = maxf(0.0, promille - schluck * PROMILLE_JE_KRUG) if carry_type == WASSER \
			else minf(PROMILLE_MAX, promille + schluck * PROMILLE_JE_KRUG)
		_sfx_loop("glug")
		if carry_fill <= 0.001:
			carry_fill = 0.0
			carry_type = 0   # leerer Krug bleibt in der Hand
	else:
		promille = maxf(0.0, promille - PROMILLE_ABBAU * delta)
	_rausch_t += delta
	var stufe := 2 if promille >= 1.6 else (1 if promille >= 0.7 else 0)
	if stufe > _rausch_stufe:
		var hud := _world.get_node_or_null("HUD")
		if hud and hud.has_method("melde"):
			hud.melde("MSG_RAUSCH_STARK" if stufe == 2 else "MSG_RAUSCH", [], 0)
	_rausch_stufe = stufe
	# Kopf wiegt mit dem Rausch
	if _kotz_t <= 0.0:
		_head.rotation.z = sin(_rausch_t * 1.3) * 0.05 * promille
	if promille >= KOTZ_GRENZE and _kotz_t <= 0.0:
		_kotzen_starten()

# ------------------------------------------------------------------ Übergeben
## Wer es übertreibt, übergibt sich: kurz gebückt würgen, dabei landet ein Fleck
## auf dem Boden, danach ist der Rausch fast raus. Den Fleck legt der Server an
## (GameManager.net_spieler_kotzt) — sonst hätte ihn nur der eigene Rechner.
## Mitspieler sehen das Würgen, weil emote = 2 in _push_state mitläuft.
const KOTZ_GRENZE := 2.2        # ab so viel Promille geht es los
const KOTZ_DAUER := 3.0
const KOTZ_FLECK_NACH := 0.9    # so lange wird erst gewürgt
const KOTZ_REST := 0.8          # so viel Promille bleiben danach
## Ein Stoß dauert so lange, danach der nächste
const KOTZ_TAKT := 0.95
## So weit beugt sich der Kopf in der eigenen Sicht nach vorn (Ruhe → voller Stoß)
const KOTZ_NEIGUNG := -0.7
const KOTZ_NEIGUNG_STOSS := -0.25
var _kotz_t := 0.0
var _kotz_fleck := false
## Läuft, solange gewürgt wird — auch bei Mitspielern (die kennen nur emote = 2)
var _kotz_anim_t := 0.0
## Läuft, solange ein Emote aus dem Rad gezeigt wird (auch bei Mitspielern)
var _emote_anim_t := 0.0
## Ruhelage des Kopfes, damit die eigene Sicht danach wieder sitzt
var _kopf_ruhe := Vector3.ZERO
var _kotz_stoesse := 0
## Läuft der Schwall gerade?
var _strahl_an := false

## Takt des Würgens: schnell vorschnellen, langsam zurück. 0 = Luft holen,
## 1 = voller Stoß. Figur und eigene Sicht laufen damit im Gleichschritt.
static func kotz_heftig(t: float) -> float:
	var p := fposmod(t, KOTZ_TAKT) / KOTZ_TAKT
	if p < 0.18:
		return p / 0.18
	var r := (p - 0.18) / 0.82
	return (1.0 - r) * (1.0 - r)

## Läuft gerade das Übergeben? (Wettschleppen und Co. fragen danach)
func kotzt() -> bool:
	return _kotz_t > 0.0

func _kotzen_starten() -> void:
	_kotz_t = KOTZ_DAUER
	_kotz_fleck = false
	_kotz_stoesse = 0
	emote = 2
	if _kopf_ruhe == Vector3.ZERO:
		_kopf_ruhe = _head.position
	_sfx("splash")   # AUDIO.md: splash ist der Klang für Kotze
	var hud := _world.get_node_or_null("HUD")
	if hud and hud.has_method("melde"):
		hud.melde("MSG_KOTZ", [], 1)

func _kotzen(delta: float) -> void:
	_kotz_t -= delta
	# Erst würgen, dann liegt es auf dem Boden — wie bei den Gästen
	if not _kotz_fleck and _kotz_t <= KOTZ_DAUER - KOTZ_FLECK_NACH:
		_kotz_fleck = true
		promille = KOTZ_REST
		if _world and _world.has_method("net_spieler_kotzt"):
			_world.net_spieler_kotzt.rpc_id(1)
	# Eigene Sicht: Kopf kippt mit jedem Stoß nach vorn und unten, der Körper geht
	# dabei in die Knie — dieselbe Kurve, die auch die Figur bewegt.
	var vergangen := KOTZ_DAUER - _kotz_t
	var h := kotz_heftig(vergangen)
	var w := clampf(delta * 6.0, 0.0, 1.0)
	_head.rotation.x = lerpf(_head.rotation.x, KOTZ_NEIGUNG + KOTZ_NEIGUNG_STOSS * h, w)
	_head.rotation.z = lerpf(_head.rotation.z, sin(vergangen * 3.0) * 0.02, w)
	_head.position = _head.position.lerp(_kopf_ruhe + Vector3(0, -0.12 - 0.06 * h, -0.03 * h), w)
	# Bei jedem neuen Stoß ein Würgen zu hören
	var stoesse := int(vergangen / KOTZ_TAKT) + 1
	if stoesse > _kotz_stoesse:
		_kotz_stoesse = stoesse
		_sfx("splash")
	if _kotz_t <= 0.0:
		_kotz_t = 0.0
		emote = 0
		_head.rotation.x = _pitch
		_head.rotation.z = 0.0
		_head.position = _kopf_ruhe

## Server hat den Krug aus der Hand auf die Ausgabe gestellt.
func krug_abgestellt() -> void:
	# Gilt auch für fertige Portionen — die kommen genauso auf die Ausgabe
	if not _has_ready() or carry_state not in [1, 2]:
		return
	carry_state = 0
	carry_fill = 0.0
	carry_type = 0
	_naechster_krug_in_hand()

## Nach dem Bedienen: nächsten vollen Krug in die Hand nehmen.
func _naechster_krug_in_hand() -> void:
	if carry_state != 0 or extra_kruege.is_empty():
		return
	carry_state = 1
	carry_fill = 1.0
	carry_type = extra_kruege.pop_front()

func _carry_kind() -> int:
	# 1 = içecek (bardak), 2 = yemek
	return carry_state

func _has_ready() -> bool:
	return carry_state != 0 and carry_fill >= 0.999

func _update_carry_visual() -> void:
	var has_mug := carry_state == 1
	var has_food := carry_state == 2
	# Zusätzliche volle Krüge neben dem in der Hand
	for i in _extra_nodes.size():
		var n := _extra_nodes[i]
		n.visible = i < extra_kruege.size()
		if n.visible:
			n.farbe = BEER_COLORS.get(extra_kruege[i], BEER_COLORS[0])
	# Glaskrug mit Füllstand: beim Zapfen steigt das Bier
	_carry_glass.visible = has_mug
	if has_mug:
		_carry_glass.fuellung = carry_fill
		_carry_glass.farbe = BEER_COLORS.get(carry_type, BEER_COLORS[0])
	if _carry_sack:
		_carry_sack.visible = carry_state == 3 and carry_pkg_kind == 3
	if carry_state == 3 and carry_pkg_kind == 3:
		_carry_teller.visible = false
		_carry_food.visible = false
		return
	# Paket wird als große Kiste in der Hand gezeigt
	if carry_state == 3:
		_carry_teller.visible = false
		_carry_food.visible = true
		_carry_food.scale = Vector3(2.2, 2.2, 2.2)
		var pm := _carry_food.material_override as StandardMaterial3D
		if pm:
			pm.albedo_color = Color(0.75, 0.55, 0.35) if carry_pkg_kind == 1 else Color(0.6, 0.45, 0.3)
		return
	_carry_food.visible = false
	_carry_teller.visible = has_food
	if has_food:
		# Beim Kochen wächst die Portion (sichtbarer Fortschritt)
		var s := lerpf(0.5, 1.0, clampf(carry_fill, 0.0, 1.0))
		_carry_teller.scale = Vector3(s, s, s)
		_carry_teller.sorte = clampi(carry_type, 1, 3)

# ---------------------------------------------------------------- Einleitung
## In der Einleitung (scripts/ui/kino.gd) sieht man sich selbst von außen —
## sonst ist die eigene Figur ausgeblendet (Ich-Perspektive).
func kino_zeigen(an: bool) -> void:
	if _model:
		_model.visible = an or not _is_local

## Passend zum Dialog gestikulieren: eine Steh-Extraanimation, sonst kurz jubeln.
func geste(jubel := false) -> void:
	var figur := _model as Figur
	if figur == null or figur.anim == null:
		return
	if jubel:
		if not figur.tanzen(1.0):
			figur.stehen()
	elif not figur.extra():
		if not figur.tanzen(0.8):
			figur.stehen()
	_cur_anim = "geste"
	_geste_bis = Time.get_ticks_msec() / 1000.0 + 2.6

## Besen: sichtbar, solange man putzt; kehrt vor den Füßen hin und her
func _besen_zeigen() -> void:
	if _besen == null:
		return
	var t := Time.get_ticks_msec() / 1000.0
	var an := _is_local and t < _fegt_bis
	_besen.visible = an
	if an:
		var s := sin(t * 9.0)
		_besen.position = Vector3(0.3 + s * 0.18, 0.02, -1.0)
		_besen.rotation.y = s * 0.35

# ------------------------------------------------------------ Umgefahren
## Vom Lieferwagen erwischt (scripts/lieferwagen.gd, nur beim eigenen Spieler):
## fliegt im Bogen, die Kamera kippt, kurz keine Steuerung.
var _geschleudert_bis := 0.0
## Laufgeschwindigkeit von außen gedrosselt (Wettschleppen)
var tempo_faktor := 1.0

func wird_geschleudert() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _geschleudert_bis

func geschleudert(tempo: Vector3) -> void:
	if not _is_local or wird_geschleudert():
		return
	velocity = tempo
	_geschleudert_bis = Time.get_ticks_msec() / 1000.0 + 1.4
	_sfx("pop")

## Während des Flugs: nur Schwerkraft und Bremsen am Boden, Kamera schwankt
func _geschleudert() -> bool:
	if not wird_geschleudert():
		if _head and absf(_head.rotation.z) > 0.001:
			_head.rotation.z = lerpf(_head.rotation.z, 0.0, 0.2)
		return false
	var dt := get_physics_process_delta_time()
	velocity.y -= 20.0 * dt
	if is_on_floor() and velocity.y <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * dt)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * dt)
	var rest := _geschleudert_bis - Time.get_ticks_msec() / 1000.0
	_head.rotation.z = sin(rest * 9.0) * 0.35 * clampf(rest, 0.0, 1.0)
	move_and_slide()
	return true

## Vom Server an einen einzelnen Spieler: hierhin stellen (nach dem Schlafen
## vor den Wohnwagen, GameManager._spieler_zum_wohnwagen). Nur der Server darf
## das — die eigene Figur gehört sonst allein diesem Rechner.
## "call_local", weil der Server sich selbst mitschickt: im Solo und beim Host
## ist der eigene Spieler Peer 1, und Godot verwirft ein rpc_id an sich selbst
## ohne dieses Merkmal ("RPC 'versetzen' on yourself is not allowed"). Der Host
## blieb deshalb nach dem Schlafen stehen, wo er eingeschlafen ist, statt vor dem
## Wohnwagen aufzuwachen (gefunden im Bot-Lauf tools/sim_saison, 25.09.2026).
@rpc("any_peer", "reliable", "call_local")
func versetzen(pos: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() not in [0, 1]:
		return
	global_position = pos
	rotation.y = yaw
	velocity = Vector3.ZERO
	_net_pos = pos
	_net_yaw = yaw

# ------------------------------------------------------------------ Emote-Rad
## Q halten öffnet das Rad (scenes/ui/emote_rad.tscn), loslassen spielt das
## gewählte Emote. Die Nummer läuft über emote in _push_state mit — Mitspieler
## sehen dasselbe.
const EMOTE_TANZEN := 1
const EMOTE_KOTZEN := 2
const EMOTE_WINKEN := 3
const EMOTE_JUBEL := 4
const EMOTE_POSEN := 5
const EMOTE_SITZEN := 6
## So lange läuft ein Emote, wenn man nicht vorher weiterläuft
const EMOTE_DAUER := 6.0

func _emote_rad() -> Node:
	var hud := _world.get_node_or_null("HUD") if _world else null
	return hud.get_node_or_null("EmoteRad") if hud else null

func _rad_oeffnen() -> void:
	var rad := _emote_rad()
	if rad == null:
		return
	if not rad.gewaehlt.is_connected(_emote_starten):
		rad.gewaehlt.connect(_emote_starten)
	rad.oeffnen()

## Vom Rad: Emote läuft los.
func _emote_starten(welches: int) -> void:
	if welches == EMOTE_KOTZEN:
		_kotzen_starten()
		return
	emote_wahl = welches
	_emote_until = Time.get_ticks_msec() / 1000.0 + EMOTE_DAUER
	if welches == EMOTE_JUBEL:
		_sfx("cheer")
		_sfx("prost")   # Krüge klirren — nur mit Datei

## Läuft gerade ein Emote aus dem Rad?
func emote_laeuft() -> bool:
	return emote_wahl > 0 and Time.get_ticks_msec() / 1000.0 < _emote_until

# ------------------------------------------------------- Kamera beim Emote
## Während eines Emotes rückt die Kamera nach hinten und die eigene Figur wird
## sichtbar — sonst sieht man von der eigenen Vorstellung nichts. Danach geht
## sie weich zurück in die Ich-Perspektive.
const KAMERA_ABSTAND := 2.8
const KAMERA_HOCH := 0.65
## Etwas über die Schulter statt genau dahinter — so verdeckt die eigene Figur
## nicht die halbe Sicht
const KAMERA_SEITE := 0.6
var _kam_ruhe := Vector3.INF

func _kamera_aussen(an: bool, delta: float) -> void:
	if _kam_ruhe == Vector3.INF:
		_kam_ruhe = _cam.position
	var ziel := _kam_ruhe
	if an:
		# Nicht in die Wand: nach hinten tasten und davor bleiben
		var weg := KAMERA_ABSTAND
		var raum := get_world_3d().direct_space_state
		if raum:
			var von := _head.global_position
			var abf := PhysicsRayQueryParameters3D.create(von,
				von + _head.global_transform.basis.z * KAMERA_ABSTAND + Vector3(0, KAMERA_HOCH, 0))
			abf.exclude = [get_rid()]
			var t := raum.intersect_ray(abf)
			if not t.is_empty():
				weg = maxf(0.5, von.distance_to(t.position) - 0.35)
		ziel = _kam_ruhe + Vector3(KAMERA_SEITE, KAMERA_HOCH, weg)
	_cam.position = _cam.position.lerp(ziel, clampf(delta * 8.0, 0.0, 1.0))
	# Figur einblenden, solange die Kamera draußen ist
	var draussen := an or _cam.position.distance_to(_kam_ruhe) > 0.25
	if _is_local:
		_model.visible = draussen

## Trägt dieser Spieler gerade einen Raufbold? Setzt der GameManager
## (_net_gepackt / _net_losgerissen / _net_geworfen). Damit zeigt der Hinweis
## „werfen" statt „packen", und E wirft auch ohne Ziel im Blick.
var traegt_raufbold := false

func raufbold_auf_dem_arm(ja: bool) -> void:
	traegt_raufbold = ja

# --------------------------------------------- Von einem Mitspieler getragen
## Ein anderer Spieler hat einen auf dem Arm: der Server schiebt die Figur jedes
## Bild an ihren Platz, die eigene Steuerung ist so lange aus. Bleiben die
## Päckchen aus (Verbindung weg), läuft man nach einer halben Sekunde weiter.
var _getragen_bis := 0.0
## Trägt dieser Spieler gerade einen Mitspieler?
var traegt_spieler := false

func wird_getragen() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _getragen_bis

# call_local wie bei versetzen: der Server schickt das auch an sich selbst,
# wenn der Host derjenige ist, der getragen wird.
@rpc("any_peer", "unreliable_ordered", "call_local")
func getragen_stellen(pos: Vector3, yaw: float) -> void:
	if multiplayer.get_remote_sender_id() not in [0, 1]:
		return
	_getragen_bis = Time.get_ticks_msec() / 1000.0 + 0.5
	global_position = pos
	rotation.y = yaw
	velocity = Vector3.ZERO
	_net_pos = pos
	_net_yaw = yaw

@rpc("any_peer", "reliable", "call_local")
func getragen_geworfen(tempo: Vector3) -> void:
	if multiplayer.get_remote_sender_id() not in [0, 1]:
		return
	_getragen_bis = 0.0
	geschleudert(tempo)

func spieler_auf_dem_arm(ja: bool) -> void:
	traegt_spieler = ja

## Mitspieler in Reichweite vor einem — für das Packen in der Schlägerei.
func mitspieler_vor_mir() -> int:
	var vorn := -global_transform.basis.z
	vorn.y = 0.0
	for p in get_tree().get_nodes_in_group("player"):
		if p == self or not is_instance_valid(p):
			continue
		var zu: Vector3 = (p as Node3D).global_position - global_position
		zu.y = 0.0
		if zu.length() > 2.0 or zu.length() < 0.01:
			continue
		if vorn.normalized().dot(zu.normalized()) > 0.55:
			return (p as Node).name.to_int()
	return 0
