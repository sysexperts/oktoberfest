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
## Teamleiter-Boni in der eigenen Abteilung (Putzen: GameManager.BONUS_PUTZEN)
const BONUS_ZAPFEN := 1.4
const BONUS_KOCHEN := 1.6
const BONUS_LAGER_TEMPO := 1.2

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
var emote := 0           # 0 yok, 1 Prost/dans (senkron)
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
var _fegt_bis := 0.0
## Abteilung, die dieser Spieler leitet ("" = keine) — aus der Lobby (GameManager._spieler_info)
var abteilung := ""
const ABT_SYMBOL := {"kueche": "🍳", "service": "🍺", "sauberkeit": "🧹", "lager": "📦"}

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
				# Aus dem Warteraum (Einladungscode): Name, Figur, Abteilung stehen schon fest
				var w := KoopDaten.lobby_wahl
				_world.net_lobby_setzen.rpc_id(1, str(w.get("name", "")), costume, str(w.get("abt", "")), int(w.get("figur", 0)), str(w.get("id", "")))
			elif _world.has_method("open_lobby_ui"):
				# Direkt beigetreten (IP, offizieller Server): Lobby-Fenster im Spiel
				_world.call_deferred("open_lobby_ui")

## Name, Farbe, Abteilung und Figur aus der Lobby (vom Server an alle).
func set_info(spielername: String, farbe: int, abt: String, figur: int = 0) -> void:
	abteilung = abt
	costume = clampi(farbe, 0, COSTUME_COLORS.size() - 1)
	_apply_costume()
	_figur_setzen(figur)
	if _is_local:
		return
	var symbol: String = ABT_SYMBOL.get(abt, "")
	_namensschild.text = (symbol + " " if symbol != "" else "") + spielername
	_namensschild.visible = spielername != ""

## Bonus in der eigenen Abteilung — sonst normales Tempo.
func _bonus(abt: String, faktor: float) -> float:
	return faktor if abteilung == abt else 1.0

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
			_emote_until = Time.get_ticks_msec() / 1000.0 + 3.0
			_sfx("cheer")
			_sfx("prost")   # Krüge klirren — nur mit Datei
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

func _physics_process(delta: float) -> void:
	if _is_local:
		_sfx_cd -= delta
		_handle_movement(delta)
		_update_target()
		_update_hint()
		if not _tippt():
			_handle_interaction(delta)
		_trinken(delta)
		emote = 1 if Time.get_ticks_msec() / 1000.0 < _emote_until else 0
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
	var w := clampf(delta * 10.0, 0.0, 1.0)
	_model.rotation.x = lerpf(_model.rotation.x, -0.35 if in_luft else 0.0, w)
	# Sprung: in der Luft gestreckt, bei der Landung kurz gestaucht
	var ziel_skala := Vector3(0.94, 1.1, 0.94) if in_luft else Vector3.ONE
	if _war_in_luft and not in_luft:
		_model.scale = Vector3(1.1, 0.85, 1.1)
	_war_in_luft = in_luft
	_model.scale = _model.scale.lerp(ziel_skala, w)
	_emote_label.visible = emote == 1
	if emote == 1:
		if _cur_anim != "tanzen":
			figur.tanzen()
			_cur_anim = "tanzen"
		return
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
	var input_dir := Vector2.ZERO if _tippt() else Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis.x * input_dir.x) + (transform.basis.z * input_dir.y)
	dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	# Rausch: die Laufrichtung zieht zur Seite
	if promille > 0.05 and dir != Vector3.ZERO:
		dir = dir.rotated(Vector3.UP, sin(_rausch_t * 0.8) * 0.22 * promille)
	# Springen (Leertaste) — nur vom Boden aus
	if not _tippt() and InputMap.has_action("springen") and Input.is_action_just_pressed("springen") and is_on_floor():
		velocity.y = SPRUNG_TEMPO
		_sfx("pop")
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	speed *= 1.0 - TRAG_BREMSE * float(extra_kruege.size())   # mehrere Krüge bremsen
	if carry_state == 3:
		speed *= _bonus("lager", BONUS_LAGER_TEMPO)   # Lager-Teamleiter trägt Pakete flotter
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
	for node in get_tree().get_nodes_in_group("interactable"):
		var n3 := node as Node3D
		if n3 == null or not n3.is_visible_in_tree():
			continue
		if _world.has_method("im_zelt") and _world.im_zelt(n3.global_position) != ich_drin:
			continue
		# Emporen: nichts durch den Emporenboden hindurch (oben ↔ unten)
		if ich_drin and (global_position.y > 1.8) != (n3.global_position.y > 3.3 and absf(n3.global_position.x) > 7.7):
			continue
		# Objekte dürfen einen eigenen Ansprechpunkt melden (z. B. Wohnwagen-Tür)
		var ipos: Vector3 = n3.global_position
		if n3.has_method("interact_point"):
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

## Hinweis am Fadenkreuz — nur neu setzen, wenn er sich ändert.
var _hint_key := "-"

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
	if t.has_method("ist_eroeffnung"):
		return "HINT_ZELT_EROEFFNEN"
	if t.has_method("ist_huber"):
		return "HINT_HUBER"
	if t.has_method("ist_wiesnchef"):
		return "HINT_WIESNCHEF" if t.ansprechbar() else ""
	if t.has_method("ist_raufbold"):
		return "HINT_RAUSWERFEN" if t.ist_raufbold() else ""
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
		if g.order_state != 1 or not (_has_ready() or not extra_kruege.is_empty()):
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
			# Massenschlägerei: Raufbold packen und rauswerfen
			if _current_target.ist_raufbold():
				_world.net_rauswerfen.rpc_id(1, _current_target.gast_id)
				_sfx("pop")
			return
		if _current_target.has_method("ist_eroeffnung"):
			_world.net_zelt_eroeffnen.rpc_id(1)
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
		elif _current_target is Ausgabe and _has_full_mug() and carry_type != WASSER and hinter_der_theke(_current_target):
			# Von hinten (Fassseite): vollen Krug für die Kellner abstellen
			_world.net_put_ausgabe.rpc_id(1, carry_type)
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
		elif _current_target is Caravan:
			# Uyu → sonraki gün (sadece molada)
			if _world.has_method("in_intermission") and _world.in_intermission():
				_world.net_sleep.rpc_id(1)
				if _sfx_node:
					_sfx_node.play_oder("tuer", "pop")
	if Input.is_action_pressed("interact") and _current_target is KegStation:
		if carry_state == 1 and carry_fill < 1.0:
			if carry_fill <= 0.0:
				_sfx("zapfen")   # Zapfhahn auf — nur mit Datei
			carry_type = (_current_target as KegStation).beer_type
			carry_fill = minf(carry_fill + FILL_RATE * _bonus("service", BONUS_ZAPFEN) * delta, 1.0)
			_sfx_loop("glug")
	# Yemek hazırlama (mutfak) — eller boşsa başlar, basılı tutunca pişer
	if Input.is_action_pressed("interact") and _current_target is FoodStation:
		var ft := (_current_target as FoodStation).food_type
		if carry_state == 0:
			carry_state = 2
			carry_type = ft
			carry_fill = 0.0
		if carry_state == 2 and carry_type == ft and carry_fill < 1.0:
			carry_fill = minf(carry_fill + FILL_RATE * _bonus("kueche", BONUS_KOCHEN) * delta, 1.0)
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

func _trinken(delta: float) -> void:
	var trinkt := not _tippt() and InputMap.has_action("trinken") and Input.is_action_pressed("trinken") \
		and carry_state == 1 and carry_fill > 0.0 and carry_type > 0
	if trinkt:
		var schluck := minf(carry_fill, TRINK_TEMPO * delta)
		carry_fill -= schluck
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
	_head.rotation.z = sin(_rausch_t * 1.3) * 0.05 * promille

## Server hat den Krug aus der Hand auf die Ausgabe gestellt.
func krug_abgestellt() -> void:
	if not _has_full_mug():
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
		figur.tanzen(1.0)
	elif not figur.extra():
		figur.tanzen(0.8)
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
