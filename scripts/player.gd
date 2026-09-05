class_name Player
extends CharacterBody3D
## Ağ-farkında oyuncu (FPS). Görsel yapı player.tscn'de gerçek düğümlerdir.
## Yerel oyuncu (authority) girdi işler + durum yayınlar; uzaklar senkron görünür.

const SPEED := 4.0
const SPRINT_SPEED := 7.0
const ACCEL := 12.0
const INTERACT_RANGE := 2.2
const FACING_DOT := 0.35
const MOUSE_SENS := 0.0025
const PITCH_LIMIT := deg_to_rad(85.0)
const EYE_HEIGHT := 1.35
const FILL_RATE := 0.6

# 1 Helles, 2 Weizen, 3 Radler
const BEER_COLORS := {0: Color(0.95, 0.65, 0.05), 1: Color(0.95, 0.75, 0.2), 2: Color(0.85, 0.5, 0.15), 3: Color(0.85, 0.85, 0.45)}

# Ağ ile senkronlanan durum
var carry_state := 0     # 0 = boş el, 1 = bardak
var carry_fill := 0.0    # 0..1
var carry_type := 0      # 0 boş, 1 Helles, 2 Weizen, 3 Radler
var emote := 0           # 0 yok, 1 Prost/dans (senkron)
var _emote_until := 0.0

var _is_local := false
var _world: Node
var _current_target: Node3D = null
var _highlight_ring: MeshInstance3D
var _pitch := 0.0
var _anim: AnimationPlayer
var _cur_anim := ""
var _last_anim_pos: Vector3
var _net_pos: Vector3
var _net_yaw: float

@onready var _model: Node3D = $Model
@onready var _head: Node3D = $Head
@onready var _cam: Camera3D = $Head/Camera3D
@onready var _hold_point: Node3D = $Head/HoldPoint
@onready var _carry_glass: MeshInstance3D = $Head/HoldPoint/CarryGlass
@onready var _carry_beer: MeshInstance3D = $Head/HoldPoint/CarryGlass/CarryBeer
@onready var _emote_label: Label3D = $Emote
@onready var _ring: MeshInstance3D = $Ring

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
	if not _is_local:
		_hold_point.position = Vector3(0.3, 1.15, -0.45) # uzakta bardak elde görünür

	# Animasyon (GLB'de Idle/Walk/Run)
	var aps := _model.find_children("*", "AnimationPlayer", true, false)
	if aps.size() > 0:
		_anim = aps[0]
		for n in ["Idle", "Walk", "Run", "Dance"]:
			if _anim.has_animation(n):
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
		if _anim.has_animation("Idle"):
			_anim.play("Idle")
			_cur_anim = "Idle"
	_last_anim_pos = global_position

	# Oyuncuyu kimliğe göre renklendir (kim kim belli olsun)
	var hue := fmod(absf(float(auth)) * 0.61803399, 1.0)
	var col := Color.from_hsv(hue, 0.75, 1.0)
	var rm := _ring.material_override as StandardMaterial3D
	if rm:
		rm.albedo_color = col
		rm.emission = col

	if _is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_make_highlight_ring()

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

func _unhandled_input(event: InputEvent) -> void:
	if not _is_local:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		rotate_y(-mm.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - mm.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
		_head.rotation.x = _pitch
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Q: Prost/dans emote (InputMap yerine doğrudan tuş — autoload'a bağlı değil)
	if event is InputEventKey and event.pressed and not event.echo and (event as InputEventKey).physical_keycode == KEY_Q:
		_emote_until = Time.get_ticks_msec() / 1000.0 + 3.0
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _is_local:
		_handle_movement(delta)
		_update_target()
		_handle_interaction(delta)
		emote = 1 if Time.get_ticks_msec() / 1000.0 < _emote_until else 0
		_push_state.rpc(global_position, rotation.y, carry_state, carry_fill, carry_type, emote)
	else:
		var t := clampf(delta * 12.0, 0.0, 1.0)
		global_position = global_position.lerp(_net_pos, t)
		rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	_update_carry_visual()
	_update_animation(delta)

func _update_animation(delta: float) -> void:
	if _anim == null:
		return
	_emote_label.visible = emote == 1
	if emote == 1:
		if _cur_anim != "Dance" and _anim.has_animation("Dance"):
			_anim.play("Dance")
			_cur_anim = "Dance"
		return
	var spd: float
	if _is_local:
		spd = Vector2(velocity.x, velocity.z).length()
	else:
		spd = (global_position - _last_anim_pos).length() / maxf(delta, 0.0001)
	_last_anim_pos = global_position
	var want := "Idle"
	if spd > 5.5:
		want = "Run"
	elif spd > 0.4:
		want = "Walk"
	if want != _cur_anim and _anim.has_animation(want):
		_anim.play(want)
		_cur_anim = want

@rpc("authority", "unreliable_ordered")
func _push_state(pos: Vector3, yaw: float, cstate: int, cfill: float, ctype: int, em: int) -> void:
	_net_pos = pos
	_net_yaw = yaw
	carry_state = cstate
	carry_fill = cfill
	carry_type = ctype
	emote = em

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis.x * input_dir.x) + (transform.basis.z * input_dir.y)
	dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3.ZERO
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED
	if dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta * speed)
		velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta * speed)
	else:
		velocity.x = move_toward(velocity.x, 0, ACCEL * delta * speed)
		velocity.z = move_toward(velocity.z, 0, ACCEL * delta * speed)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

func _update_target() -> void:
	var best: Node3D = null
	var best_score := -1.0
	var forward := -global_transform.basis.z
	var origin := global_position + Vector3(0, EYE_HEIGHT * 0.5, 0)
	for node in get_tree().get_nodes_in_group("interactable"):
		var n3 := node as Node3D
		if n3 == null:
			continue
		var to: Vector3 = n3.global_position - origin
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

func _update_highlight() -> void:
	if _highlight_ring == null or not _highlight_ring.is_inside_tree():
		return
	if _current_target != null:
		_highlight_ring.visible = true
		_highlight_ring.global_position = _current_target.global_position + Vector3(0, 0.05, 0)
	else:
		_highlight_ring.visible = false

func _handle_interaction(delta: float) -> void:
	if _current_target == null:
		if Input.is_action_just_pressed("interact") and carry_state != 0:
			carry_state = 0
			carry_fill = 0.0
			carry_type = 0
		return
	if Input.is_action_just_pressed("interact"):
		if _current_target is CustomerTable and _has_full_mug():
			_serve((_current_target as CustomerTable).table_index, carry_type)
		elif _current_target is MugDispenser and carry_state == 0:
			carry_state = 1
			carry_fill = 0.0
			carry_type = 0
		elif _current_target is Computer:
			# Molada rol seç (host'ta doğrulanır)
			if _world.has_method("net_cycle_role"):
				_world.net_cycle_role.rpc_id(1)
	if Input.is_action_pressed("interact") and _current_target is KegStation:
		if carry_state == 1 and carry_fill < 1.0:
			carry_type = (_current_target as KegStation).beer_type
			carry_fill = minf(carry_fill + FILL_RATE * delta, 1.0)

func _has_full_mug() -> bool:
	return carry_state == 1 and carry_fill >= 0.999

func _serve(index: int, bt: int) -> void:
	if multiplayer.is_server():
		_apply_serve(index, bt)
	else:
		_serve_request.rpc_id(1, index, bt)

@rpc("any_peer", "reliable")
func _serve_request(index: int, bt: int) -> void:
	if multiplayer.is_server():
		_apply_serve(index, bt)

func _apply_serve(index: int, bt: int) -> void:
	if _world.has_method("host_try_serve") and _world.host_try_serve(index, bt):
		if is_multiplayer_authority():
			carry_state = 0
			carry_fill = 0.0
			carry_type = 0
		else:
			_clear_carry.rpc_id(get_multiplayer_authority())

@rpc("any_peer", "reliable")
func _clear_carry() -> void:
	carry_state = 0
	carry_fill = 0.0
	carry_type = 0

func _update_carry_visual() -> void:
	var has_mug := carry_state == 1
	_carry_glass.visible = has_mug
	_carry_beer.visible = has_mug and carry_fill > 0.01
	if has_mug:
		_carry_beer.scale.y = maxf(carry_fill, 0.001)
		_carry_beer.position.y = -0.08 + (0.16 * carry_fill) * 0.5
		var m := _carry_beer.material_override as StandardMaterial3D
		if m:
			m.albedo_color = BEER_COLORS.get(carry_type, BEER_COLORS[0])
