class_name Player
extends CharacterBody3D
## Ağ-farkında oyuncu (FPS). Yerel oyuncu (authority) girdi işler ve durumunu yayınlar;
## uzak oyuncular senkron konum + bean modeli + eldeki bardakla görünür.
## Elde taşıma ayrı ağ nesnesi DEĞİL: carry_state/carry_fill senkronlanır, görsel yerelde çizilir.

const SPEED := 4.0
const SPRINT_SPEED := 7.0
const ACCEL := 12.0
const INTERACT_RANGE := 2.2
const FACING_DOT := 0.35
const MOUSE_SENS := 0.0025
const PITCH_LIMIT := deg_to_rad(85.0)
const EYE_HEIGHT := 1.55
const FILL_RATE := 0.6 # saniyede doluluk
const CHAR_SCENE: PackedScene = preload("res://assets/character/character/bavarian_bean.glb")
const MODEL_HEIGHT := 1.7
const MODEL_YAW := 180.0

# Ağ ile senkronlanan durum
var carry_state := 0     # 0 = boş el, 1 = bardak
var carry_fill := 0.0    # 0..1

var _is_local := false
var _model: Node3D
var _head: Node3D
var _cam: Camera3D
var _hold_point: Node3D
var _world: Node
var _current_target: Node3D = null
var _highlight_ring: MeshInstance3D
var _pitch := 0.0
var _carry_glass: MeshInstance3D
var _carry_beer: MeshInstance3D
var _net_pos: Vector3
var _net_yaw: float

func _ready() -> void:
	add_to_group("player")
	_world = get_tree().current_scene
	# Authority'yi düğüm adından türet (ad = peer_id). Zamanlamadan bağımsız, garantili.
	var auth := name.to_int()
	set_multiplayer_authority(auth)
	_is_local = (auth == multiplayer.get_unique_id())
	_net_pos = global_position
	_net_yaw = rotation.y
	_build_body()
	if _is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)

	# Karakter modeli — sadece UZAK oyuncularda görünür (kendi FPS görüşünü kapatmasın)
	_model = CHAR_SCENE.instantiate()
	add_child(_model)
	_model.rotation_degrees.y = MODEL_YAW
	_fit_model(_model, MODEL_HEIGHT)
	# Erken-zamanlama (global_transform henüz oturmamışsa) hatalarına karşı bir kare sonra tekrar ölç
	call_deferred("_fit_model", _model, MODEL_HEIGHT)
	_model.visible = not _is_local

	# Baş + kamera (kamera yalnız yerelde aktif)
	_head = Node3D.new()
	_head.position = Vector3(0, EYE_HEIGHT, 0)
	add_child(_head)
	_cam = Camera3D.new()
	_cam.current = _is_local
	_head.add_child(_cam)

	# Tutma noktası + bardak görseli (herkeste; senkron duruma göre çizilir)
	_hold_point = Node3D.new()
	_hold_point.position = Vector3(0.35, -0.28, -0.6) if _is_local else Vector3(0.3, 1.15, -0.45)
	_head.add_child(_hold_point)
	_build_carry_visual()

	# Vurgu halkası yalnız yerel oyuncuya lazım
	if _is_local:
		_highlight_ring = MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = 0.35
		ring.outer_radius = 0.5
		_highlight_ring.mesh = ring
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = Color(1, 0.9, 0.2)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(1, 0.8, 0.1)
		_highlight_ring.material_override = ring_mat
		_highlight_ring.visible = false
		_world.add_child.call_deferred(_highlight_ring)

func _build_carry_visual() -> void:
	_carry_glass = MeshInstance3D.new()
	var glass := CylinderMesh.new()
	glass.top_radius = 0.06
	glass.bottom_radius = 0.05
	glass.height = 0.18
	_carry_glass.mesh = glass
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.85, 0.9, 0.95, 0.35)
	gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_carry_glass.material_override = gmat
	_hold_point.add_child(_carry_glass)

	_carry_beer = MeshInstance3D.new()
	var beer := CylinderMesh.new()
	beer.top_radius = 0.055
	beer.bottom_radius = 0.048
	beer.height = 0.16
	_carry_beer.mesh = beer
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.95, 0.65, 0.05)
	_carry_beer.material_override = bmat
	_carry_glass.add_child(_carry_beer)

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
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if _is_local:
		_handle_movement(delta)
		_update_target()
		_handle_interaction(delta)
		_push_state.rpc(global_position, rotation.y, carry_state, carry_fill)
	else:
		var t := clampf(delta * 12.0, 0.0, 1.0)
		global_position = global_position.lerp(_net_pos, t)
		rotation.y = lerp_angle(rotation.y, _net_yaw, t)
	_update_carry_visual()

@rpc("authority", "unreliable_ordered")
func _push_state(pos: Vector3, yaw: float, cstate: int, cfill: float) -> void:
	_net_pos = pos
	_net_yaw = yaw
	carry_state = cstate
	carry_fill = cfill

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
		# Boşa E: elindeki bardağı boşalt/at
		if Input.is_action_just_pressed("interact") and carry_state != 0:
			carry_state = 0
			carry_fill = 0.0
		return
	if Input.is_action_just_pressed("interact"):
		if _current_target is CustomerTable and _has_full_mug():
			_serve((_current_target as CustomerTable).table_index)
		elif _current_target is MugDispenser and carry_state == 0:
			carry_state = 1
			carry_fill = 0.0
	if Input.is_action_pressed("interact") and _current_target is KegStation:
		if carry_state == 1 and carry_fill < 1.0:
			carry_fill = minf(carry_fill + FILL_RATE * delta, 1.0)

func _has_full_mug() -> bool:
	return carry_state == 1 and carry_fill >= 0.999

func _serve(index: int) -> void:
	if multiplayer.is_server():
		_apply_serve(index)
	else:
		_serve_request.rpc_id(1, index)

@rpc("any_peer", "reliable")
func _serve_request(index: int) -> void:
	if multiplayer.is_server():
		_apply_serve(index)

# Yalnız host'ta çalışır
func _apply_serve(index: int) -> void:
	if _world.has_method("host_try_serve") and _world.host_try_serve(index):
		if is_multiplayer_authority():
			carry_state = 0
			carry_fill = 0.0
		else:
			_clear_carry.rpc_id(get_multiplayer_authority())

@rpc("any_peer", "reliable")
func _clear_carry() -> void:
	carry_state = 0
	carry_fill = 0.0

func _update_carry_visual() -> void:
	var has_mug := carry_state == 1
	_carry_glass.visible = has_mug
	_carry_beer.visible = has_mug and carry_fill > 0.01
	if has_mug:
		_carry_beer.scale.y = maxf(carry_fill, 0.001)
		_carry_beer.position.y = -0.08 + (0.16 * carry_fill) * 0.5

## Modeli gerçek görünen boyutuna göre ölçekler (dünya-uzayı AABB, çarpımsal).
## Ölçek modelin kökünde/iç düğümünde gömülü olsa da doğru çalışır.
func _fit_model(root: Node3D, target_height: float) -> void:
	var a := _world_aabb(root)
	if a.size.y > 0.0001:
		root.scale *= (target_height / a.size.y)
	# Ayakları oyuncunun taban hizasına çek
	var a2 := _world_aabb(root)
	root.global_position.y += (global_position.y - a2.position.y)

## Tüm görsel alt-düğümlerin DÜNYA uzayındaki birleşik AABB'si (mevcut ölçek dahil).
func _world_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var has := false
	for child in root.find_children("*", "VisualInstance3D", true, false):
		var vi := child as VisualInstance3D
		var a := vi.global_transform * vi.get_aabb()
		if not has:
			result = a
			has = true
		else:
			result = result.merge(a)
	return result
