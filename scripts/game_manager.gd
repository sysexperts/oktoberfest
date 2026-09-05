extends Node3D
## GameManager (ağ-farkında). Faz makinesi: MOLA <-> VARDİYA.
## Mola: role kayıt (bilgisayar), müşteri yok. Vardiya: müşteri/servis.
## Rol için insan yoksa NPC ("Tasarom Firma Çalışanı") doldurur -> az gelir.
## Dünyayı KURMAZ; main.tscn'deki düğümleri okur.

enum Phase { INTERMISSION = 0, SHIFT = 1 }

const INTERMISSION_TIME := 45.0
const SHIFT_TIME := 180.0
const SPAWN_START := 6.0
const SPAWN_MIN := 2.5
const SYNC_INTERVAL := 0.15
const MISS_PENALTY := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")

# Roller
const ROLE_NONE := 0
const ROLE_KITCHEN := 1
const ROLE_CLEAN := 2
const ROLE_WAITER := 3
const ROLE_NAMES := {0: "—", 1: "Mutfak", 2: "Temizlik", 3: "Garson"}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🧹", 3: "🍺"}
const TASAROM := "Tasarom Firma Çalışanı"

var _tables: Array[CustomerTable] = []
var _spawn_points: Array[Vector3] = []
var _hud: HUD
var _players_container: Node3D
var _players_nodes := {}
var _spawn_index_by_peer := {}
var _next_spawn := 0

var _phase: int = Phase.INTERMISSION
var _phase_time := INTERMISSION_TIME
var _roles := {}            # peer_id -> role
var _npc_roles := {}        # vardiyada insan olmayan roller (set gibi kullanılır)
var _spawn_timer := 3.0
var _sync_timer := 0.0
var _served := 0
var _missed := 0
var _last_earn := 0

func _ready() -> void:
	Game.reset()
	_hud = $HUD
	_players_container = $Players
	for c in $Tables.get_children():
		if c is CustomerTable:
			_tables.append(c)
	_tables.sort_custom(func(a, b): return a.table_index < b.table_index)
	for c in $SpawnPoints.get_children():
		if c is Node3D:
			_spawn_points.append((c as Node3D).position)
	if _spawn_points.is_empty():
		_spawn_points.append(Vector3(0, 0.1, 0))

	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)
	_hud.set_time(_phase_time)
	_hud.set_phase(_phase_name())

	if multiplayer.is_server():
		multiplayer.peer_disconnected.connect(_on_peer_left)
		if Net.dedicated:
			_next_spawn = 0
		else:
			_spawn_index_by_peer[1] = 0
			_next_spawn = 1
			_add_player(1, 0)
		_broadcast_meta()
	else:
		_client_ready.rpc_id(1)

func _phase_name() -> String:
	return "VARDİYA" if _phase == Phase.SHIFT else "MOLA"

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
	_broadcast_meta()  # yeni gelene faz/rol bilgisi

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
	_roles.erase(peer_id)
	_remove_player.rpc(peer_id)
	_broadcast_meta()

# ================================================= rol seçimi (bilgisayar)
@rpc("any_peer", "reliable")
func net_set_role(role: int) -> void:
	if not multiplayer.is_server():
		return
	if _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	_roles[s] = clampi(role, 0, 3)
	_broadcast_meta()

## Yerel oyuncu bilgisayara bastığında UI açar.
func open_computer_ui() -> void:
	_hud.open_computer()

# ================================================= host servis
func host_try_serve(index: int, beer_type: int) -> bool:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return false
	if index < 0 or index >= _tables.size():
		return false
	if _tables[index].host_serve(beer_type):
		_served += 1
		var waiter_npc := _npc_roles.has(ROLE_WAITER)
		var reward := CustomerTable.REWARD
		var tip := 0 if waiter_npc else randi_range(0, 5)
		if waiter_npc:
			reward = int(reward * 0.5)   # NPC garson -> az gelir
		_last_earn += reward + tip
		Game.add_score(reward)
		Game.add_money(reward + tip)
		return true
	return false

# ================================================= döngü
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	# Dedicated + kimse yoksa molada bekle
	if Net.dedicated and _players_nodes.is_empty():
		return

	_phase_time -= delta
	if _phase == Phase.SHIFT:
		_shift_process(delta)
		if _phase_time <= 0.0:
			_end_shift()
	else:
		if _phase_time <= 0.0:
			_start_shift()

	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = SYNC_INTERVAL
		_broadcast_sync()

func _shift_process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_try_spawn_customer()
		var progress := 1.0 - (_phase_time / SHIFT_TIME)
		_spawn_timer = lerpf(SPAWN_START, SPAWN_MIN, progress)
	for t in _tables:
		if t.host_tick(delta) == 1:
			_missed += 1
			Game.add_score(-MISS_PENALTY)

func _start_shift() -> void:
	_phase = Phase.SHIFT
	_phase_time = SHIFT_TIME
	_served = 0
	_missed = 0
	_last_earn = 0
	_spawn_timer = 3.0
	# İnsan olmayan rolleri NPC (Tasarom) doldurur
	_npc_roles = {}
	var covered := {}
	for r in _roles.values():
		if r != ROLE_NONE:
			covered[r] = true
	for role in [ROLE_KITCHEN, ROLE_CLEAN, ROLE_WAITER]:
		if not covered.has(role):
			_npc_roles[role] = true
	_broadcast_meta()

func _end_shift() -> void:
	_phase = Phase.INTERMISSION
	_phase_time = INTERMISSION_TIME
	for t in _tables:
		t.host_reset()
	_broadcast_meta()

func _try_spawn_customer() -> void:
	var free: Array[CustomerTable] = []
	for t in _tables:
		if t.is_free():
			free.append(t)
	if free.is_empty():
		return
	free.pick_random().host_seat()

# ================================================= senkron
func _broadcast_sync() -> void:
	var st := PackedInt32Array()
	var ra := PackedFloat32Array()
	var rq := PackedInt32Array()
	for t in _tables:
		st.append(t.state)
		ra.append(t.ratio())
		rq.append(t.required_type)
	_net_sync.rpc(Game.money, Game.score, _phase_time, st, ra, rq)

@rpc("authority", "unreliable")
func _net_sync(money: int, score: int, time_left: float, st: PackedInt32Array, ra: PackedFloat32Array, rq: PackedInt32Array) -> void:
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(time_left)
	for i in range(_tables.size()):
		if i < st.size():
			_tables[i].apply_sync(st[i], ra[i], rq[i])

func _roster_string() -> String:
	var lines := []
	for role in [ROLE_KITCHEN, ROLE_CLEAN, ROLE_WAITER]:
		var who := []
		for pid in _roles.keys():
			if int(_roles[pid]) == role:
				who.append("P%s" % str(pid).substr(0, 3))
		var val: String
		if who.is_empty():
			val = TASAROM if _phase == Phase.SHIFT else "—"
		else:
			val = ", ".join(who)
		lines.append("%s %s: %s" % [ROLE_ICONS[role], ROLE_NAMES[role], val])
	return "\n".join(lines)

func _broadcast_meta() -> void:
	net_meta.rpc(_phase, _roster_string())

@rpc("authority", "reliable", "call_local")
func net_meta(phase: int, roster: String) -> void:
	_phase = phase
	_hud.set_phase(_phase_name())
	_hud.set_roster(roster)
