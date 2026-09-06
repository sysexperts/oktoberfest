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
const MESS_SCENE := preload("res://scenes/mess.tscn")
const CUSTOMER_SCENE := preload("res://scenes/customer.tscn")

# Müşteri NPC
const CUST_SPEED := 3.0
const ENTRANCE := Vector3(0, 0.1, 10.0)   # çadır girişi (ön)
const EXIT := Vector3(0, 0.1, 10.0)

# Temizlik / hijyen
const MESS_CHANCE := 0.4        # içen müşteri ayrılınca kir bırakma olasılığı
const CLEAN_PER_CALL := 0.05    # E basılı her karede temizlik ilerlemesi
const HYGIENE_DRAIN := 1.5      # her kir başına saniyede hijyen kaybı
const HYGIENE_REGEN := 1.0      # kir yokken saniyede toparlanma
const NPC_CLEAN_RATE := 0.06    # Tasarom temizlikçi saniyede (yavaş)

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

var _messes_container: Node3D
var _messes := {}        # id -> Mess node
var _mess_clean := {}    # id -> temizlik ilerlemesi 0..1 (host)
var _mess_next := 0
var _hygiene := 100.0

var _customers_container: Node3D
var _customers := {}     # id -> Customer node
var _cust_sim := {}      # id -> {pos, tgt, mode, table, yaw}  (host)
var _cust_next := 0
var _table_cust := {}    # table_index -> cust_id

func _ready() -> void:
	Game.reset()
	_hud = $HUD
	_players_container = $Players
	_messes_container = $Messes
	_customers_container = $Customers
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
	# Mevcut kirleri yeni gelene gönder
	for mid in _messes.keys():
		var mp: Vector3 = (_messes[mid] as Node3D).position
		_add_mess.rpc_id(sender, mid, mp)
	# Mevcut müşterileri yeni gelene gönder
	for cid in _cust_sim.keys():
		_add_customer.rpc_id(sender, cid, _cust_sim[cid].pos)
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

func _active_table_count() -> int:
	var n := 0
	for t in _tables:
		if t.active:
			n += 1
	return n

func _table_cost() -> int:
	return 40 + _active_table_count() * 25

## Molada para ile yeni masa aç.
@rpc("any_peer", "reliable")
func net_buy_table() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var cost := _table_cost()
	if Game.money < cost:
		return
	for t in _tables:
		if not t.active:
			t.set_active(true)
			Game.add_money(-cost)
			_broadcast_meta()
			return

func _mgmt_string() -> String:
	var total := _tables.size()
	var act := _active_table_count()
	if act >= total:
		return "Masalar: %d/%d (hepsi açık)" % [act, total]
	return "Masalar: %d/%d · Yeni masa: %d€" % [act, total, _table_cost()]

# ================================================= host servis
func host_try_serve(index: int, kind: int, type: int) -> bool:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return false
	if index < 0 or index >= _tables.size():
		return false
	if _tables[index].host_serve(kind, type):
		_served += 1
		var waiter_npc := _npc_roles.has(ROLE_WAITER)
		var hyg_factor := 0.4 + 0.6 * (_hygiene / 100.0)  # düşük hijyen -> az gelir
		var reward := int(CustomerTable.REWARD * hyg_factor)
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
		var code := t.host_tick(delta)
		if code == 1:
			_missed += 1
			Game.add_score(-MISS_PENALTY)
		elif code == 2 and randf() < MESS_CHANCE:
			_spawn_mess_near(t.global_pos())
	_leave_customers_of_free_tables()
	_update_customers(delta)
	_update_hygiene(delta)

func _update_hygiene(delta: float) -> void:
	var n := _messes.size()
	if n > 0:
		_hygiene = maxf(0.0, _hygiene - HYGIENE_DRAIN * n * delta)
		if _npc_roles.has(ROLE_CLEAN):
			_npc_clean(delta)
	else:
		_hygiene = minf(100.0, _hygiene + HYGIENE_REGEN * delta)

func _npc_clean(delta: float) -> void:
	for mid in _messes.keys():
		_mess_clean[mid] = float(_mess_clean.get(mid, 0.0)) + NPC_CLEAN_RATE * delta
		if _mess_clean[mid] >= 1.0:
			_remove_mess.rpc(mid)
		return  # sadece bir kir/kare (yavaş)

func _spawn_mess_near(pos: Vector3) -> void:
	var off := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-0.5, 1.5))
	_spawn_mess(pos + off)

func _spawn_mess(pos: Vector3) -> void:
	var id := _mess_next
	_mess_next += 1
	_mess_clean[id] = 0.0
	_add_mess.rpc(id, Vector3(pos.x, 0.02, pos.z))

@rpc("authority", "reliable", "call_local")
func _add_mess(id: int, pos: Vector3) -> void:
	if _messes.has(id):
		return
	var m := MESS_SCENE.instantiate()
	m.mess_id = id
	m.position = pos
	_messes_container.add_child(m)
	_messes[id] = m

@rpc("authority", "reliable", "call_local")
func _remove_mess(id: int) -> void:
	if _messes.has(id):
		var m: Node = _messes[id]
		if is_instance_valid(m):
			m.queue_free()
		_messes.erase(id)
	_mess_clean.erase(id)

func _clear_messes() -> void:
	for mid in _messes.keys().duplicate():
		_remove_mess.rpc(mid)

## Oyuncu kir üstünde E basılı tutunca çağrılır (host otoriter).
@rpc("any_peer", "reliable")
func net_clean(id: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	if not _messes.has(id):
		return
	_mess_clean[id] = float(_mess_clean.get(id, 0.0)) + CLEAN_PER_CALL
	if _mess_clean[id] >= 1.0:
		_remove_mess.rpc(id)

func _start_shift() -> void:
	_phase = Phase.SHIFT
	_phase_time = SHIFT_TIME
	_served = 0
	_missed = 0
	_last_earn = 0
	_spawn_timer = 3.0
	_hygiene = 100.0
	_clear_messes()
	_clear_customers()
	_net_banner.rpc("🍺 VARDİYA BAŞLADI!")
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
	_clear_messes()
	_clear_customers()
	_net_banner.rpc("Vardiya bitti! Kazanç: %d€ · Servis: %d · Kaçırılan: %d" % [_last_earn, _served, _missed])
	_broadcast_meta()

func _try_spawn_customer() -> void:
	var free: Array[CustomerTable] = []
	for t in _tables:
		if t.is_free() and not _table_cust.has(t.table_index):
			free.append(t)
	if free.is_empty():
		return
	var t: CustomerTable = free.pick_random()
	t.host_seat()
	_spawn_customer(t)

# ---- Müşteri NPC (host) ----
func _spawn_customer(t: CustomerTable) -> void:
	var id := _cust_next
	_cust_next += 1
	var seat := t.global_position + Vector3(0, 0.1, 0.9)
	_cust_sim[id] = {"pos": ENTRANCE, "tgt": seat, "mode": 0, "table": t.table_index, "yaw": 0.0}
	_table_cust[t.table_index] = id
	_add_customer.rpc(id, ENTRANCE)

func _update_customers(delta: float) -> void:
	for id in _cust_sim.keys().duplicate():
		var s: Dictionary = _cust_sim[id]
		var pos: Vector3 = s.pos
		var to: Vector3 = s.tgt - pos
		to.y = 0
		var d := to.length()
		if d > 0.15:
			pos += to.normalized() * minf(CUST_SPEED * delta, d)
			s.yaw = atan2(to.x, to.z)
		else:
			if s.mode == 0:
				s.mode = 1
				# Otururken masaya dön
				var ti: int = s.table
				if ti >= 0 and ti < _tables.size():
					var dir: Vector3 = _tables[ti].global_position - pos
					dir.y = 0
					if dir.length() > 0.01:
						s.yaw = atan2(dir.x, dir.z)
			elif s.mode == 2:
				_despawn_customer(id)
				continue
		s.pos = pos
		_cust_sim[id] = s
		var node = _customers.get(id)
		if node:
			node.set_net(pos, s.yaw)

func _leave_customers_of_free_tables() -> void:
	for t in _tables:
		if t.is_free() and _table_cust.has(t.table_index):
			var cid: int = _table_cust[t.table_index]
			_table_cust.erase(t.table_index)
			if _cust_sim.has(cid):
				_cust_sim[cid].mode = 2
				_cust_sim[cid].tgt = EXIT

func _despawn_customer(id: int) -> void:
	_remove_customer.rpc(id)
	_cust_sim.erase(id)

func _clear_customers() -> void:
	for id in _customers.keys().duplicate():
		_remove_customer.rpc(id)
	_cust_sim.clear()
	_table_cust.clear()

@rpc("authority", "reliable", "call_local")
func _add_customer(id: int, pos: Vector3) -> void:
	if _customers.has(id):
		return
	var c := CUSTOMER_SCENE.instantiate()
	c.cust_id = id
	c.position = pos
	_customers_container.add_child(c)
	_customers[id] = c

@rpc("authority", "reliable", "call_local")
func _remove_customer(id: int) -> void:
	if _customers.has(id):
		var c: Node = _customers[id]
		if is_instance_valid(c):
			c.queue_free()
		_customers.erase(id)

# ================================================= senkron
func _broadcast_sync() -> void:
	var st := PackedInt32Array()
	var ra := PackedFloat32Array()
	var rq := PackedInt32Array()
	var rk := PackedInt32Array()
	var ta := PackedInt32Array()
	for t in _tables:
		st.append(t.state)
		ra.append(t.ratio())
		rq.append(t.required_type)
		rk.append(t.order_kind)
		ta.append(1 if t.active else 0)
	_net_sync.rpc(Game.money, Game.score, _phase_time, st, ra, rq, rk, ta)
	# Çevre: hijyen + kir ilerlemesi
	var ids := PackedInt32Array()
	var pr := PackedFloat32Array()
	for mid in _messes.keys():
		ids.append(mid)
		pr.append(float(_mess_clean.get(mid, 0.0)))
	_net_env.rpc(_hygiene, ids, pr)
	# Müşteri konumları
	var cids := PackedInt32Array()
	var cx := PackedFloat32Array()
	var cz := PackedFloat32Array()
	var cyaw := PackedFloat32Array()
	for id in _cust_sim.keys():
		var s: Dictionary = _cust_sim[id]
		cids.append(id)
		cx.append(s.pos.x)
		cz.append(s.pos.z)
		cyaw.append(s.yaw)
	_net_cust.rpc(cids, cx, cz, cyaw)

@rpc("authority", "unreliable")
func _net_cust(cids: PackedInt32Array, cx: PackedFloat32Array, cz: PackedFloat32Array, cyaw: PackedFloat32Array) -> void:
	for i in range(cids.size()):
		var c = _customers.get(cids[i])
		if c:
			c.set_net(Vector3(cx[i], 0.1, cz[i]), cyaw[i])

@rpc("authority", "unreliable")
func _net_sync(money: int, score: int, time_left: float, st: PackedInt32Array, ra: PackedFloat32Array, rq: PackedInt32Array, rk: PackedInt32Array, ta: PackedInt32Array) -> void:
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(time_left)
	for i in range(_tables.size()):
		if i < st.size():
			_tables[i].apply_sync(st[i], ra[i], rq[i], rk[i], ta[i] == 1)

@rpc("authority", "unreliable")
func _net_env(hygiene: float, ids: PackedInt32Array, pr: PackedFloat32Array) -> void:
	_hygiene = hygiene
	_hud.set_hygiene(hygiene)
	for i in range(ids.size()):
		var m = _messes.get(ids[i])
		if m:
			m.apply_progress(pr[i])

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
	net_meta.rpc(_phase, _roster_string(), _mgmt_string())

@rpc("authority", "reliable", "call_local")
func _net_banner(text: String) -> void:
	_hud.show_banner(text)

@rpc("authority", "reliable", "call_local")
func net_meta(phase: int, roster: String, mgmt: String) -> void:
	_phase = phase
	_hud.set_phase(_phase_name())
	_hud.set_roster(roster)
	_hud.set_mgmt(mgmt)
