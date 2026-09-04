extends Node3D
## GameManager (ağ-farkında). Dünyayı KURMAZ — main.tscn'deki düğümleri okur.
## Host: vardiya/müşteri/skor otoriter yürütür ve istemcilere senkronlar.
## Düzenlenebilir her şey (masa/istasyon/ışık/spawn/çadır) sahnede düğüm olarak durur.

const SHIFT_TIME := 800.0
const SPAWN_START := 6.0
const SPAWN_MIN := 2.5
const SYNC_INTERVAL := 0.15
const MISS_PENALTY := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _tables: Array[CustomerTable] = []
var _spawn_points: Array[Vector3] = []
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
	_hud = $HUD
	_players_container = $Players

	# Masaları sahneden topla (table_index'e göre sırala)
	for c in $Tables.get_children():
		if c is CustomerTable:
			_tables.append(c)
	_tables.sort_custom(func(a, b): return a.table_index < b.table_index)

	# Spawn noktalarını sahneden oku
	for c in $SpawnPoints.get_children():
		if c is Node3D:
			_spawn_points.append((c as Node3D).position)
	if _spawn_points.is_empty():
		_spawn_points.append(Vector3(0, 0.1, 0))

	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)
	_hud.set_time(_time_left)

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_left)
		if Net.dedicated:
			_next_spawn = 0
		else:
			_spawn_index_by_peer[1] = 0
			_next_spawn = 1
			_add_player(1, 0)
	else:
		_client_ready.rpc_id(1)

# ================================================= oyuncular
@rpc("any_peer", "reliable")
func _client_ready() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	for pid in _spawn_index_by_peer.keys():
		_add_player.rpc_id(sender, pid, _spawn_index_by_peer[pid])
	var sidx := _next_spawn
	_next_spawn += 1
	_spawn_index_by_peer[sender] = sidx
	_add_player.rpc(sender, sidx)

@rpc("authority", "reliable", "call_local")
func _add_player(peer_id: int, spawn_index: int) -> void:
	if _players_nodes.has(peer_id):
		return
	var p := PLAYER_SCENE.instantiate()
	p.name = str(peer_id)
	p.set_multiplayer_authority(peer_id)
	p.position = _spawn_points[spawn_index % _spawn_points.size()]
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
func host_try_serve(index: int, beer_type: int) -> bool:
	if not multiplayer.is_server():
		return false
	if index < 0 or index >= _tables.size():
		return false
	if _tables[index].host_serve(beer_type):
		_served += 1
		var tip := randi_range(0, 5)
		Game.add_score(CustomerTable.REWARD)
		Game.add_money(CustomerTable.REWARD + tip)
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
	var rq := PackedInt32Array()
	for t in _tables:
		st.append(t.state)
		ra.append(t.ratio())
		rq.append(t.required_type)
	_net_sync.rpc(Game.money, Game.score, _time_left, st, ra, rq)

@rpc("authority", "unreliable")
func _net_sync(money: int, score: int, time_left: float, st: PackedInt32Array, ra: PackedFloat32Array, rq: PackedInt32Array) -> void:
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(time_left)
	for i in range(_tables.size()):
		if i < st.size():
			_tables[i].apply_sync(st[i], ra[i], rq[i])

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
