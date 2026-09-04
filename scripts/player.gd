class_name Player
extends CharacterBody3D
## Oyuncu (BİRİNCİ ŞAHIS / FPS): fare ile bakış, WASD bakış yönüne göre hareket.
## Önündeki etkileşilebilir nesneyi tespit + E ile al/bırak/servis, fıçıda E basılı tut.

const SPEED := 4.0
const SPRINT_SPEED := 7.0
const ACCEL := 12.0
const INTERACT_RANGE := 2.2
const FACING_DOT := 0.35 # ne kadar "öne bakıyor" sayılacağı
const MOUSE_SENS := 0.0025
const PITCH_LIMIT := deg_to_rad(85.0)
const EYE_HEIGHT := 1.55
const CHAR_SCENE: PackedScene = preload("res://assets/character/character/bavarian_bean.glb")
const MODEL_HEIGHT := 1.7   # modeli bu boya ölçekle
const MODEL_YAW := 180.0    # model yanlış yöne bakıyorsa bunu değiştir (derece)

var held: Carryable = null

var _model: Node3D
var _hold_point: Node3D
var _head: Node3D
var _cam: Camera3D
var _world: Node3D
var _current_target: Node3D = null
var _highlight_ring: MeshInstance3D
var _pitch := 0.0

func _ready() -> void:
	add_to_group("player")
	_world = get_tree().current_scene
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	# Çarpışma
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)

	# Karakter modeli (bavarian_bean). Ayaklar y=0'da, ~MODEL_HEIGHT boyunda.
	_model = CHAR_SCENE.instantiate()
	add_child(_model)
	_model.rotation_degrees.y = MODEL_YAW
	_fit_model(_model, MODEL_HEIGHT)

	# Baş (yaw oyuncuda, pitch başta) + kamera
	_head = Node3D.new()
	_head.position = Vector3(0, EYE_HEIGHT, 0)
	add_child(_head)

	_cam = Camera3D.new()
	_head.add_child(_cam)

	# Tutma noktası — kameranın görüş alanında (sağ-alt-önde), başa bağlı
	_hold_point = Node3D.new()
	_hold_point.position = Vector3(0.35, -0.28, -0.6)
	_head.add_child(_hold_point)

	# Hedef vurgulama halkası
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

func _unhandled_input(event: InputEvent) -> void:
	# Fare ile bakış (yalnızca fare kilitliyken)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		rotate_y(-mm.relative.x * MOUSE_SENS)
		_pitch = clampf(_pitch - mm.relative.y * MOUSE_SENS, -PITCH_LIMIT, PITCH_LIMIT)
		_head.rotation.x = _pitch
	# Esc: fareyi serbest bırak
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Sol tık: fareyi tekrar kilitle
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_target()
	_handle_interaction(delta)

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Bakış yönüne göre: sağ = +basis.x, geri = +basis.z (ileri = -basis.z)
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

	# Basit yerçekimi (zemine yapışık kalsın)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()

func _update_target() -> void:
	var best: Node3D = null
	var best_score := -1.0
	var forward := -global_transform.basis.z # yatay bakış yönü (yaw)
	var origin := global_position + Vector3(0, EYE_HEIGHT * 0.5, 0)
	for node in get_tree().get_nodes_in_group("interactable"):
		if node == held:
			continue
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
	if not _highlight_ring.is_inside_tree():
		return
	if _current_target and _current_target.has_method("interact"):
		_highlight_ring.visible = true
		_highlight_ring.global_position = _current_target.global_position + Vector3(0, 0.05, 0)
	else:
		_highlight_ring.visible = false

func _handle_interaction(delta: float) -> void:
	if _current_target == null:
		# Hedef yok: elinde bir şey varsa E ile yere bırak.
		if Input.is_action_just_pressed("interact") and held != null:
			drop()
		return
	if Input.is_action_just_pressed("interact") and _current_target.has_method("interact"):
		_current_target.interact(self)
	if Input.is_action_pressed("interact") and _current_target.has_method("hold_interact"):
		_current_target.hold_interact(self, delta)

func pick_up(c: Carryable) -> void:
	if held != null:
		return
	held = c
	c.on_carried(_hold_point)

func drop() -> void:
	if held == null:
		return
	var drop_pos := global_position + (-global_transform.basis.z * 0.8) + Vector3(0, 0.5, 0)
	held.on_dropped(_world, drop_pos)
	held = null

## Modeli hedef boya ölçekler ve ayaklarını y=0'a hizalar (bilinmeyen import ölçeğine dayanıklı).
func _fit_model(root: Node3D, target_height: float) -> void:
	var aabb := _combined_aabb(root)
	if aabb.size.y <= 0.0001:
		return
	var s := target_height / aabb.size.y
	root.scale = Vector3(s, s, s)
	root.position.y = -aabb.position.y * s

func _combined_aabb(root: Node3D) -> AABB:
	var result := AABB()
	var has := false
	var inv := root.global_transform.affine_inverse()
	for child in root.find_children("*", "VisualInstance3D", true, false):
		var vi := child as VisualInstance3D
		var local := inv * vi.global_transform
		var a := local * vi.get_aabb()
		if not has:
			result = a
			has = true
		else:
			result = result.merge(a)
	return result

## Servis/tüketim sonrası elindeki nesneyi yok et.
func consume_held() -> void:
	if held == null:
		return
	held.queue_free()
	held = null
