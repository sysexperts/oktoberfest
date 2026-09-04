extends Node3D
## GameManager — dünyayı prosedürel kurar, vardiyayı yönetir:
## müşteri spawn, sipariş sonuçları, süre, vardiya sonu özeti, yeniden başlatma.

const SHIFT_TIME := 120.0
const SPAWN_START := 6.0   # ilk spawn aralığı
const SPAWN_MIN := 2.5     # zamanla düşen minimum aralık

var _tables: Array[CustomerTable] = []
var _hud: HUD
var _time_left := SHIFT_TIME
var _spawn_timer := 3.0
var _served := 0
var _missed := 0
var _shift_over := false

func _ready() -> void:
	Game.reset()
	_build_environment()
	_build_arena()
	_hud = HUD.new()
	add_child(_hud)
	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)

# ---------------------------------------------------------------- ortam
func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

# ---------------------------------------------------------------- arena
func _build_arena() -> void:
	# Zemin
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 24)
	floor_mesh.mesh = plane
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.35, 0.28, 0.2)
	floor_mesh.material_override = fmat
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new()
	var floor_shape := WorldBoundaryShape3D.new()
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)

	# Çadır duvarları (blockout — oyuncuyu içeride tutar)
	_build_wall(Vector3(0, 1.5, -12), Vector3(24, 3, 0.5))
	_build_wall(Vector3(0, 1.5, 12), Vector3(24, 3, 0.5))
	_build_wall(Vector3(-12, 1.5, 0), Vector3(0.5, 3, 24))
	_build_wall(Vector3(12, 1.5, 0), Vector3(0.5, 3, 24))

	# İstasyonlar
	var dispenser := MugDispenser.new()
	dispenser.position = Vector3(-6, 0, -8)
	add_child(dispenser)

	var keg := KegStation.new()
	keg.position = Vector3(-2, 0, -8)
	add_child(keg)

	var keg2 := KegStation.new()
	keg2.position = Vector3(2, 0, -8)
	add_child(keg2)

	# Masalar
	var positions := [
		Vector3(-6, 0, 4), Vector3(-2, 0, 6), Vector3(2, 0, 6),
		Vector3(6, 0, 4), Vector3(-6, 0, 0), Vector3(6, 0, 0),
	]
	for p in positions:
		var t := CustomerTable.new()
		t.position = p
		add_child(t)
		t.order_served.connect(_on_order_served)
		t.order_missed.connect(_on_order_missed)
		_tables.append(t)

	# Oyuncu
	var player := Player.new()
	player.position = Vector3(0, 0.1, 0)
	add_child(player)

func _build_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.5, 0.35)
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

# ---------------------------------------------------------------- döngü
func _process(delta: float) -> void:
	if _shift_over:
		if _hud.restart_requested():
			_shift_over = false
			get_tree().reload_current_scene()
		return

	_time_left -= delta
	_hud.set_time(_time_left)
	if _time_left <= 0.0:
		_end_shift()
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_try_spawn_customer()
		# Zaman geçtikçe daha sık müşteri
		var progress := 1.0 - (_time_left / SHIFT_TIME)
		_spawn_timer = lerpf(SPAWN_START, SPAWN_MIN, progress)

func _try_spawn_customer() -> void:
	var free: Array[CustomerTable] = []
	for t in _tables:
		if t.is_free():
			free.append(t)
	if free.is_empty():
		return
	free.pick_random().seat_customer()

func _on_order_served(reward: int) -> void:
	_served += 1
	Game.add_score(reward)
	Game.add_money(reward)

func _on_order_missed() -> void:
	_missed += 1
	Game.add_score(-5)

func _end_shift() -> void:
	_shift_over = true
	_hud.set_time(0.0)
	_hud.show_summary(_served, _missed, Game.money, Game.score)
