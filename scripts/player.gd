class_name Player
extends CharacterBody3D
## Oyuncu: yürüme/koşma + önündeki etkileşilebilir nesneyi tespit edip
## E ile etkileşim (al/bırak/servis) ve E'yi basılı tutunca doldurma.

const SPEED := 4.0
const SPRINT_SPEED := 7.0
const ACCEL := 12.0
const INTERACT_RANGE := 1.8
const FACING_DOT := 0.35 # ne kadar "öne bakıyor" sayılacağı

var held: Carryable = null

var _hold_point: Node3D
var _world: Node3D
var _current_target: Node3D = null
var _highlight_ring: MeshInstance3D
var _cam: Camera3D
const CAM_OFFSET := Vector3(0, 6, 7)

func _ready() -> void:
	add_to_group("player")
	_world = get_tree().current_scene
	_build_body()

func _build_body() -> void:
	# Çarpışma
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	shape.shape = capsule
	shape.position.y = 0.8
	add_child(shape)

	# Gövde görseli
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.35
	body_mesh.height = 1.6
	body.mesh = body_mesh
	body.position.y = 0.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.85)
	body.material_override = mat
	add_child(body)

	# Yön göstergesi (burun)
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.15, 0.15, 0.3)
	nose.mesh = nose_mesh
	nose.position = Vector3(0, 1.0, -0.4)
	add_child(nose)

	# Tutma noktası (önde, elde)
	_hold_point = Node3D.new()
	_hold_point.position = Vector3(0, 1.0, -0.6)
	add_child(_hold_point)

	# Kamera (omuz üstü, sabit açı — oyuncu dönse bile dönmez)
	_cam = Camera3D.new()
	_cam.top_level = true # ebeveyn (oyuncu) dönüşünü yok say
	_cam.rotation_degrees = Vector3(-40, 0, 0)
	add_child(_cam)
	_cam.global_position = global_position + CAM_OFFSET

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

func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	_update_target()
	_handle_interaction(delta)
	# Kamera oyuncuyu sabit ofsetle takip etsin
	if _cam:
		_cam.global_position = _cam.global_position.lerp(global_position + CAM_OFFSET, 8.0 * delta)

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input_dir.x, 0, input_dir.y)
	var speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else SPEED

	if dir.length() > 0.01:
		velocity.x = move_toward(velocity.x, dir.x * speed, ACCEL * delta * speed)
		velocity.z = move_toward(velocity.z, dir.z * speed, ACCEL * delta * speed)
		# Hareket yönüne dön
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, 12.0 * delta)
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
	var forward := -global_transform.basis.z
	for node in get_tree().get_nodes_in_group("interactable"):
		if node == held:
			continue
		var n3 := node as Node3D
		if n3 == null:
			continue
		var to: Vector3 = n3.global_position - global_position
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

## Servis/tüketim sonrası elindeki nesneyi yok et.
func consume_held() -> void:
	if held == null:
		return
	held.queue_free()
	held = null
