extends Node3D
## GameManager (ağ-farkında). Dünyayı tüm peer'larda prosedürel kurar.
## Host: vardiya/müşteri/skor otoriter yürütür ve istemcilere senkronlar.
## Oyuncular spawner-benzeri el sıkışma ile eklenir; hareket Player içinde senkronlanır.

const SHIFT_TIME := 120.0
const SPAWN_START := 6.0
const SPAWN_MIN := 2.5
const SYNC_INTERVAL := 0.15
const MISS_PENALTY := 5

const SPAWN_POINTS := [
	Vector3(-1.5, 0.1, 0), Vector3(1.5, 0.1, 0),
	Vector3(-1.5, 0.1, 2), Vector3(1.5, 0.1, 2),
]

var _tables: Array[CustomerTable] = []
var _hud: HUD
var _players_container: Node3D
var _players_nodes := {}          # peer_id -> Player
var _spawn_index_by_peer := {}    # peer_id -> spawn index
var _next_spawn := 0

var _time_left := SHIFT_TIME
var _spawn_timer := 3.0
var _sync_timer := 0.0
var _served := 0
var _missed := 0
var _shift_over := false

func _ready() -> void:
	Game.reset()
	_build_environment()
	_build_arena()

	_players_container = Node3D.new()
	_players_container.name = "Players"
	add_child(_players_container)

	_hud = HUD.new()
	add_child(_hud)
	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)
	_hud.set_time(_time_left)

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_left)
		if Net.dedicated:
			# Dedicated server: kendisi oyuncu değil, sadece simülasyonu yürütür
			_next_spawn = 0
		else:
			_spawn_index_by_peer[1] = 0
			_next_spawn = 1
			_add_player(1, 0)
	else:
		_client_ready.rpc_id(1)

# ================================================= dünya
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

const TENT_X0 := -9.5
const TENT_X1 := 9.5
const TENT_Z0 := -11.5
const TENT_Z1 := 9.5

func _build_arena() -> void:
	# Zemin çarpışması (görünmez, her yerde)
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	var floor_col := CollisionShape3D.new()
	floor_col.shape = WorldBoundaryShape3D.new()
	floor_body.add_child(floor_col)

	# Görsel çadır + çevre çarpışması yalnız istemcilerde (dedicated server hafif kalsın)
	if not Net.dedicated:
		_build_tent()
		_collision_box(Vector3(0, 2, TENT_Z0 - 0.3), Vector3(22, 4, 0.6))
		_collision_box(Vector3(0, 2, TENT_Z1 + 0.3), Vector3(22, 4, 0.6))
		_collision_box(Vector3(TENT_X0 - 0.3, 2, -1), Vector3(0.6, 4, 24))
		_collision_box(Vector3(TENT_X1 + 0.3, 2, -1), Vector3(0.6, 4, 24))

	var dispenser := MugDispenser.new()
	dispenser.position = Vector3(-6, 0, -8)
	add_child(dispenser)
	var keg := KegStation.new()
	keg.position = Vector3(-2, 0, -8)
	add_child(keg)
	var keg2 := KegStation.new()
	keg2.position = Vector3(2, 0, -8)
	add_child(keg2)

	var positions := [
		Vector3(-6, 0, 4), Vector3(-2, 0, 6), Vector3(2, 0, 6),
		Vector3(6, 0, 4), Vector3(-6, 0, 0), Vector3(6, 0, 0),
	]
	var idx := 0
	for p in positions:
		var t := CustomerTable.new()
		t.position = p
		t.table_index = idx
		add_child(t)
		_tables.append(t)
		idx += 1

## Görünmez çarpışma kutusu (oyuncular çadırdan çıkamasın)
func _collision_box(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)
	var col := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	col.shape = box_shape
	body.add_child(col)

## Oktoberfest çadırını modüler modellerle döşer (kapalı oda: overlap ile boşluksuz).
func _build_tent() -> void:
	const S := 1.8            # biraz daha büyük
	const WALL_OVL := 0.82    # duvar bindirme (boşluksuz)
	const ROOF_OVL := 0.86    # çatı bindirme (boşluksuz)
	var floor_ps := load("res://assets/models/floor.glb")
	var wall_ps := load("res://assets/models/wall.glb")
	var roof_ps := load("res://assets/models/roof.glb")

	# Zemin karoları
	var fs := 1.903 * S * 0.98
	var y_floor := -0.096 * S
	var x := TENT_X0
	while x <= TENT_X1 + 0.01:
		var z := TENT_Z0
		while z <= TENT_Z1 + 0.01:
			_spawn_model(floor_ps, Vector3(x, y_floor, z), S, 0.0)
			z += fs
		x += fs

	# Duvarlar (kenarlar boyunca, bitişik/overlap) + fener ışıkları
	var ws := 1.489 * S * WALL_OVL
	var y_wall := 0.951 * S
	var lamp_y := y_wall + 0.55 * S
	var inw := 0.5
	var li := 0
	x = TENT_X0
	while x <= TENT_X1 + 0.01:
		_spawn_model(wall_ps, Vector3(x, y_wall, TENT_Z0), S, 0.0)
		_spawn_model(wall_ps, Vector3(x, y_wall, TENT_Z1), S, 180.0)
		if li % 2 == 0:
			_add_lantern_light(Vector3(x, lamp_y, TENT_Z0 + inw))
			_add_lantern_light(Vector3(x, lamp_y, TENT_Z1 - inw))
		li += 1
		x += ws
	var z2 := TENT_Z0
	while z2 <= TENT_Z1 + 0.01:
		_spawn_model(wall_ps, Vector3(TENT_X0, y_wall, z2), S, 90.0)
		_spawn_model(wall_ps, Vector3(TENT_X1, y_wall, z2), S, -90.0)
		if li % 2 == 0:
			_add_lantern_light(Vector3(TENT_X0 + inw, lamp_y, z2))
			_add_lantern_light(Vector3(TENT_X1 - inw, lamp_y, z2))
		li += 1
		z2 += ws

	# Çatı (overlap + kenarlarda saçak taşması → boşluksuz, kapalı)
	var rsx := 1.445 * S * ROOF_OVL
	var rsz := 1.917 * S * ROOF_OVL
	var y_roof := 1.9 * S + 0.30 * S
	x = TENT_X0 - 1.0
	while x <= TENT_X1 + 1.0:
		var z3 := TENT_Z0 - 1.0
		while z3 <= TENT_Z1 + 1.0:
			_spawn_model(roof_ps, Vector3(x, y_roof, z3), S, 0.0)
			z3 += rsz
		x += rsx

## Sıcak fener ışığı (gölgesiz, performans için)
func _add_lantern_light(pos: Vector3) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = Color(1.0, 0.80, 0.48)
	l.light_energy = 2.2
	l.omni_range = 6.5
	l.omni_attenuation = 1.5
	l.shadow_enabled = false
	add_child(l)

func _spawn_model(ps: PackedScene, pos: Vector3, s: float, rot_y: float) -> void:
	var m: Node3D = ps.instantiate()
	m.position = pos
	m.scale = Vector3(s, s, s)
	m.rotation_degrees.y = rot_y
	add_child(m)

# ================================================= oyuncular
@rpc("any_peer", "reliable")
func _client_ready() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	# Mevcut oyuncuları yeni gelene gönder
	for pid in _spawn_index_by_peer.keys():
		_add_player.rpc_id(sender, pid, _spawn_index_by_peer[pid])
	# Yeni geleni herkese ekle
	var sidx := _next_spawn
	_next_spawn += 1
	_spawn_index_by_peer[sender] = sidx
	_add_player.rpc(sender, sidx)

@rpc("authority", "reliable", "call_local")
func _add_player(peer_id: int, spawn_index: int) -> void:
	if _players_nodes.has(peer_id):
		return
	var p := Player.new()
	p.name = str(peer_id)
	p.set_multiplayer_authority(peer_id)
	p.position = SPAWN_POINTS[spawn_index % SPAWN_POINTS.size()]
	_players_container.add_child(p)
	_players_nodes[peer_id] = p

@rpc("authority", "reliable", "call_local")
func _remove_player(peer_id: int) -> void:
	if _players_nodes.has(peer_id):
		var p: Node = _players_nodes[peer_id]
		if is_instance_valid(p):
			p.queue_free()
		_players_nodes.erase(peer_id)

func _on_peer_left(peer_id: int) -> void:
	if not multiplayer.is_server():
		return
	_spawn_index_by_peer.erase(peer_id)
	_remove_player.rpc(peer_id)

# ================================================= host servis
func host_try_serve(index: int) -> bool:
	if not multiplayer.is_server():
		return false
	if index < 0 or index >= _tables.size():
		return false
	if _tables[index].host_serve():
		_served += 1
		Game.add_score(CustomerTable.REWARD)
		Game.add_money(CustomerTable.REWARD)
		return true
	return false

# ================================================= döngü
func _process(delta: float) -> void:
	if _shift_over:
		if multiplayer.is_server() and _hud.restart_requested():
			_net_reload.rpc()
		return
	if not multiplayer.is_server():
		return

	# Dedicated server: kimse yokken vardiyayı başlatma/çalıştırma
	if Net.dedicated and _players_nodes.is_empty():
		return

	_time_left -= delta
	_hud.set_time(_time_left)
	if _time_left <= 0.0:
		_end_shift()
		return

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_try_spawn_customer()
		var progress := 1.0 - (_time_left / SHIFT_TIME)
		_spawn_timer = lerpf(SPAWN_START, SPAWN_MIN, progress)

	for t in _tables:
		if t.host_tick(delta) == 1:
			_missed += 1
			Game.add_score(-MISS_PENALTY)

	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = SYNC_INTERVAL
		_broadcast_sync()

func _try_spawn_customer() -> void:
	var free: Array[CustomerTable] = []
	for t in _tables:
		if t.is_free():
			free.append(t)
	if free.is_empty():
		return
	free.pick_random().host_seat()

func _broadcast_sync() -> void:
	var st := PackedInt32Array()
	var ra := PackedFloat32Array()
	for t in _tables:
		st.append(t.state)
		ra.append(t.ratio())
	_net_sync.rpc(Game.money, Game.score, _time_left, st, ra)

@rpc("authority", "unreliable")
func _net_sync(money: int, score: int, time_left: float, st: PackedInt32Array, ra: PackedFloat32Array) -> void:
	# Sadece istemcilerde çalışır (host'ta call_local yok)
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(time_left)
	for i in range(_tables.size()):
		if i < st.size():
			_tables[i].apply_sync(st[i], ra[i])

func _end_shift() -> void:
	_shift_over = true
	_net_end_shift.rpc(_served, _missed, Game.money, Game.score)

@rpc("authority", "reliable", "call_local")
func _net_end_shift(served: int, missed: int, money: int, score: int) -> void:
	_shift_over = true
	_hud.set_time(0.0)
	_hud.show_summary(served, missed, money, score)

@rpc("authority", "reliable", "call_local")
func _net_reload() -> void:
	get_tree().reload_current_scene()
