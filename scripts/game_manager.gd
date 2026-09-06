extends Node3D
## GameManager. Faz: MOLA <-> VARDİYA. Misafirler popülerliğe göre gelir,
## bira masalarındaki koltuklara oturur, TÜM vardiya boyunca kalır ve
## tekrar tekrar sipariş verir; otururken kutlar. Rol için insan yoksa NPC (Tasarom).

enum Phase { INTERMISSION = 0, SHIFT = 1 }

const INTERMISSION_TIME := 40.0
const SHIFT_TIME := 200.0
const SYNC_INTERVAL := 0.12
const MISS_PENALTY := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CUSTOMER_SCENE := preload("res://scenes/customer.tscn")
const MESS_SCENE := preload("res://scenes/mess.tscn")

# Roller
const ROLE_NONE := 0
const ROLE_KITCHEN := 1
const ROLE_CLEAN := 2
const ROLE_WAITER := 3
const ROLE_NAMES := {0: "—", 1: "Mutfak", 2: "Temizlik", 3: "Garson"}
const ROLE_ICONS := {1: "👨‍🍳", 2: "🧹", 3: "🍺"}
const TASAROM := "Tasarom Firma Çalışanı"

# Misafir / sipariş / popülerlik
const ENTRANCE := Vector3(0, 0.1, 12.0)
const CUST_SPEED := 3.0
const GUEST_SPAWN_INTERVAL := 2.0
const ORDER_PATIENCE := 38.0        # sabır (servis için süre) — artırıldı
const ORDER_COOLDOWN_MIN := 22.0    # siparişler arası bekleme — uzatıldı
const ORDER_COOLDOWN_MAX := 45.0
const SERVED_SHOW := 3.0
const POP_START := 20.0             # az misafirle başla
const POP_SERVE := 1.5
const POP_MISS := 3.0
const MESS_CHANCE_PER_SEC := 0.02   # oturan sarhoş misafir kir yapma olasılığı/sn

# Temizlik
const CLEAN_PER_CALL := 0.05
const HYGIENE_DRAIN := 1.2
const HYGIENE_REGEN := 1.0
const NPC_CLEAN_RATE := 0.06
const START_MONEY := 10000   # TEST (yayında 0)

# Zelt / makro-döngü (Wasenplatz mantığı)
const TENT_STAGE_NAMES := {0: "Zelt yok", 1: "Küçük Zelt", 2: "Orta Zelt", 3: "Büyük Zelt"}
const TENT_TABLE_LIMIT := {0: 0, 1: 4, 2: 6, 3: 6}   # sahnedeki masa sayısıyla sınırlı (6)
const TENT_BOOK_COST := 500
const TENT_UPGRADE_COST := {2: 3000, 3: 10000}
const TABLE_COST := 200
const DAILY_RENT := 150
const WIESN_DAYS := 16

var _hud: HUD
var _sfx_node: Node
var _players_container: Node3D
var _customers_container: Node3D
var _messes_container: Node3D
var _players_nodes := {}
var _spawn_index_by_peer := {}
var _next_spawn := 0

var _phase: int = Phase.INTERMISSION
var _phase_time := INTERMISSION_TIME
var _roles := {}
var _npc_roles := {}
var _sync_timer := 0.0
var _served := 0
var _missed := 0
var _last_earn := 0
var _shift_num := 0
var _popularity := POP_START

# Zelt / makro-döngü durumu
var _tent_stage := 0     # 0 = kiralanmadı, 1..3 zelt büyüklüğü
var _active_count := 0   # aktif (görünür/oturulabilir) masa sayısı
var _day := 1            # Wiesn günü

# Koltuklar: her biri {pos:Vector3, yaw:float, guest:int}
var _seats: Array = []
var _all_tables: Array = []   # sahnedeki tüm bira masaları (kararlı sıra)
var _beertables: Array = []   # sadece aktif masalar (servis/oturma)
var _held := {}   # peer_id -> beertable idx (molada taşıma)
# Misafir sim: id -> {seat:int, mode:int(0 gir,1 otur,2 çık), pos, tgt, yaw,
#                     ostate, okind, otype, patience, cooldown, served_t}
var _guests := {}         # id -> Customer node
var _guest_sim := {}
var _guest_next := 0
var _guest_spawn_timer := 1.0

var _hygiene := 100.0
var _messes := {}
var _mess_clean := {}
var _mess_next := 0

func _ready() -> void:
	Game.reset()
	_hud = $HUD
	_sfx_node = $Sfx
	_players_container = $Players
	_customers_container = $Customers
	_messes_container = $Messes

	# Bira masalarını topla (kararlı sıra). Başta zelt kiralanmadı → 0 aktif.
	_all_tables = get_tree().get_nodes_in_group("beertable")
	_all_tables.sort_custom(func(a, b): return a.name < b.name)
	_apply_tent()

	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)
	_hud.set_time(_phase_time)
	_hud.set_phase(_phase_name())
	_hud.set_day(_day, WIESN_DAYS)

	if multiplayer.is_server():
		Game.add_money(START_MONEY)
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

func in_intermission() -> bool:
	return _phase == Phase.INTERMISSION

func _tent_ready() -> bool:
	return _tent_stage > 0 and _active_count > 0

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
	for mid in _messes.keys():
		_add_mess.rpc_id(sender, mid, (_messes[mid] as Node3D).position)
	for gid in _guest_sim.keys():
		_add_guest.rpc_id(sender, gid, _guest_sim[gid].pos)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _add_player(peer_id: int, spawn_index: int) -> void:
	if _players_nodes.has(peer_id):
		return
	var p := PLAYER_SCENE.instantiate()
	p.name = str(peer_id)
	p.set_multiplayer_authority(peer_id)
	var pts := $SpawnPoints.get_children()
	if pts.size() > 0:
		p.position = (pts[spawn_index % pts.size()] as Node3D).position
	else:
		p.position = Vector3(0, 0.1, 0)
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

# ================================================= rol
@rpc("any_peer", "reliable")
func net_set_role(role: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	_roles[s] = clampi(role, 0, 3)
	_broadcast_meta()

func open_computer_ui() -> void:
	_hud.open_computer()

func open_booking_ui() -> void:
	_hud.open_booking()

func _rebuild_seats() -> void:
	_seats.clear()
	for bt in _beertables:
		var origin: Vector3 = (bt as Node3D).global_position
		for sp in bt.seat_points():
			var d: Vector3 = origin - sp
			d.y = 0
			var yaw := atan2(-d.x, -d.z) if d.length() > 0.01 else 0.0
			_seats.append({"pos": sp, "yaw": yaw, "guest": -1})

## Zelt kiralamaya göre masaları aktif/pasif yap + koltukları kur.
func _apply_tent() -> void:
	for i in _all_tables.size():
		var bt := _all_tables[i] as Node3D
		var on: bool = i < _active_count
		bt.idx = i
		bt.visible = on
		if on:
			if not bt.is_in_group("beertable"):
				bt.add_to_group("beertable")
			if not bt.is_in_group("interactable"):
				bt.add_to_group("interactable")
		else:
			if bt.is_in_group("beertable"):
				bt.remove_from_group("beertable")
			if bt.is_in_group("interactable"):
				bt.remove_from_group("interactable")
	_beertables = []
	for i in _active_count:
		_beertables.append(_all_tables[i])
	_rebuild_seats()

## Kiosk: Zelt buchen (Stufe 1).
@rpc("any_peer", "reliable")
func net_book_tent() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION or _tent_stage != 0:
		return
	if Game.money < TENT_BOOK_COST:
		_net_banner.rpc("💶 Yetersiz para! (Zelt: %d€)" % TENT_BOOK_COST)
		return
	Game.add_money(-TENT_BOOK_COST)
	_tent_stage = 1
	_active_count = 0
	_apply_tent()
	_net_banner.rpc("🎪 %s kiralandı! Şimdi masa yerleştir." % TENT_STAGE_NAMES[1])
	_broadcast_meta()

## Kiosk: Tisch kaufen/platzieren (limit je Zeltstufe).
@rpc("any_peer", "reliable")
func net_buy_table() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _tent_stage == 0:
		_net_banner.rpc("Önce Zelt buchen! (Kiosk)")
		return
	var limit: int = TENT_TABLE_LIMIT[_tent_stage]
	if _active_count >= limit:
		_net_banner.rpc("🪑 Tisch-Limit dolu (%d). Zelt upgrade et." % limit)
		return
	if Game.money < TABLE_COST:
		_net_banner.rpc("💶 Yetersiz para! (Tisch: %d€)" % TABLE_COST)
		return
	Game.add_money(-TABLE_COST)
	_active_count += 1
	_apply_tent()
	_net_banner.rpc("🪑 Masa +1 (%d/%d)" % [_active_count, limit])
	_broadcast_meta()

## Kiosk: Zelt upgraden (mehr Tische / Kapazität).
@rpc("any_peer", "reliable")
func net_upgrade_tent() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var nxt := _tent_stage + 1
	if not TENT_UPGRADE_COST.has(nxt):
		_net_banner.rpc("🎪 En büyük Zelt zaten!")
		return
	var cost: int = TENT_UPGRADE_COST[nxt]
	if Game.money < cost:
		_net_banner.rpc("💶 Yetersiz para! (Upgrade: %d€)" % cost)
		return
	Game.add_money(-cost)
	_tent_stage = nxt
	_apply_tent()
	_net_banner.rpc("🎪 %s! Tisch-Limit: %d" % [TENT_STAGE_NAMES[nxt], TENT_TABLE_LIMIT[nxt]])
	_broadcast_meta()

## Wohnwagen: schlafen → nächster Tag (Miete abziehen).
@rpc("any_peer", "reliable")
func net_sleep() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _tent_stage == 0:
		_net_banner.rpc("Önce Zelt buchen, sonra uyu 😴")
		return
	_day += 1
	Game.add_money(-DAILY_RENT)
	_phase_time = INTERMISSION_TIME
	if _day > WIESN_DAYS:
		_net_banner.rpc("🎉 Wiesn bitti! %d gün tamamlandı 🍺" % WIESN_DAYS)
		_day = 1
	else:
		_net_banner.rpc("😴 Wiesn-Tag %d/%d · Kira -%d€" % [_day, WIESN_DAYS, DAILY_RENT])
	_broadcast_meta()

## Molada bira masasını tut/bırak (yerleştir).
@rpc("any_peer", "reliable")
func net_move_table(index: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _held.has(s):
		_held.erase(s)
	elif index >= 0 and index < _beertables.size() and not _held.values().has(index):
		_held[s] = index

func _update_held_tables() -> void:
	for peer in _held.keys():
		var idx: int = _held[peer]
		var pl = _players_nodes.get(peer)
		if pl == null or idx < 0 or idx >= _beertables.size():
			continue
		var fwd: Vector3 = -pl.global_transform.basis.z
		var p: Vector3 = pl.global_position + fwd * 2.5
		_beertables[idx].position = Vector3(p.x, 0.0, p.z)

# ================================================= servis (misafire)
@rpc("any_peer", "reliable")
func net_serve_guest(id: int, kind: int, type: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	if not _guest_sim.has(id):
		return
	var g: Dictionary = _guest_sim[id]
	if g.ostate != 1 or g.okind != kind or g.otype != type:
		return
	g.ostate = 2
	g.served_t = SERVED_SHOW
	_guest_sim[id] = g
	_served += 1
	_popularity = minf(100.0, _popularity + POP_SERVE)
	var waiter_npc := _npc_roles.has(ROLE_WAITER)
	var hyg := 0.4 + 0.6 * (_hygiene / 100.0)
	var reward := int(CustomerReward() * hyg)
	var tip := 0 if waiter_npc else randi_range(0, 5)
	if waiter_npc:
		reward = int(reward * 0.5)
	_last_earn += reward + tip
	Game.add_score(reward)
	Game.add_money(reward + tip)

func CustomerReward() -> int:
	return 10

# ================================================= döngü
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if Net.dedicated and _players_nodes.is_empty():
		return
	_phase_time -= delta
	if _phase == Phase.SHIFT:
		_shift_process(delta)
		if _phase_time <= 0.0:
			_end_shift()
	else:
		if _phase_time <= 0.0:
			if _tent_ready():
				_start_shift()
			else:
				_phase_time = INTERMISSION_TIME
	_update_held_tables()
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = SYNC_INTERVAL
		_broadcast_sync()

func _shift_process(delta: float) -> void:
	# Popülerliğe göre misafir çağır
	_guest_spawn_timer -= delta
	if _guest_spawn_timer <= 0.0:
		_guest_spawn_timer = GUEST_SPAWN_INTERVAL
		var target := int(round(_popularity / 100.0 * float(_seats.size())))
		if _guest_sim.size() < target:
			_spawn_guest()
	_update_guests(delta)
	_update_hygiene(delta)

func _start_shift() -> void:
	_phase = Phase.SHIFT
	_phase_time = SHIFT_TIME
	_served = 0
	_missed = 0
	_last_earn = 0
	_guest_spawn_timer = 1.0
	_hygiene = 100.0
	_held.clear()
	_rebuild_seats()   # taşınmış masalara göre koltukları güncelle
	_clear_messes()
	_shift_num += 1
	_npc_roles = {}
	var covered := {}
	for r in _roles.values():
		if r != ROLE_NONE:
			covered[r] = true
	for role in [ROLE_KITCHEN, ROLE_CLEAN, ROLE_WAITER]:
		if not covered.has(role):
			_npc_roles[role] = true
	_net_banner.rpc("🍺 VARDİYA %d BAŞLADI!" % _shift_num)
	_broadcast_meta()

func _end_shift(closed_early := false) -> void:
	_phase = Phase.INTERMISSION
	_phase_time = INTERMISSION_TIME
	# Tüm misafirleri çıkışa yolla
	for gid in _guest_sim.keys():
		_guest_sim[gid].mode = 2
		_guest_sim[gid].tgt = ENTRANCE
		_guest_sim[gid].ostate = 0
	_clear_messes()
	if closed_early:
		_net_banner.rpc("🚫 Çok şikayet! Çadır kapandı 😅 · Kazanç: %d€" % _last_earn)
	else:
		_net_banner.rpc("Vardiya bitti! Kazanç: %d€ · Servis: %d · Kaçırılan: %d" % [_last_earn, _served, _missed])
	_broadcast_meta()

# ---- Misafirler ----
func _free_seat() -> int:
	var free := []
	for i in _seats.size():
		if _seats[i].guest == -1:
			free.append(i)
	if free.is_empty():
		return -1
	return free.pick_random()

func _spawn_guest() -> void:
	var si := _free_seat()
	if si < 0:
		return
	var id := _guest_next
	_guest_next += 1
	_seats[si].guest = id
	_guest_sim[id] = {
		"seat": si, "mode": 0, "pos": ENTRANCE, "tgt": _seats[si].pos, "yaw": 0.0,
		"ostate": 0, "okind": 1, "otype": 1, "patience": ORDER_PATIENCE,
		"cooldown": randf_range(8.0, 20.0), "served_t": 0.0
	}
	_add_guest.rpc(id, ENTRANCE)

func _update_guests(delta: float) -> void:
	for id in _guest_sim.keys().duplicate():
		var g: Dictionary = _guest_sim[id]
		var pos: Vector3 = g.pos
		var to: Vector3 = g.tgt - pos
		to.y = 0
		var d := to.length()
		if d > 0.15:
			pos += to.normalized() * minf(CUST_SPEED * delta, d)
			g.yaw = atan2(-to.x, -to.z)
		else:
			if g.mode == 0:
				g.mode = 1
				g.yaw = _seats[g.seat].yaw
			elif g.mode == 2:
				_despawn_guest(id)
				continue
		# Oturan misafir: sipariş döngüsü
		if g.mode == 1:
			_guest_order(g, id, delta)
		g.pos = pos
		_guest_sim[id] = g
		var node = _guests.get(id)
		if node:
			node.set_net(pos, g.yaw)
			node.set_order(g.ostate, g.okind, g.otype, clampf(g.patience / ORDER_PATIENCE, 0.0, 1.0))

func _guest_order(g: Dictionary, id: int, delta: float) -> void:
	if g.ostate == 0:
		g.cooldown -= delta
		if g.cooldown <= 0.0:
			g.ostate = 1
			if randf() < 0.6:
				g.okind = 1
				g.otype = randi_range(1, 3)
			else:
				g.okind = 2
				g.otype = randi_range(1, 2)
			g.patience = ORDER_PATIENCE
	elif g.ostate == 1:
		g.patience -= delta
		if g.patience <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
			_missed += 1
			Game.add_score(-MISS_PENALTY)
			_popularity = maxf(5.0, _popularity - POP_MISS)
			if _missed >= 20:
				_end_shift(true)
	elif g.ostate == 2:
		g.served_t -= delta
		if g.served_t <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
	# Sarhoş: ara sıra kir
	if randf() < MESS_CHANCE_PER_SEC * delta:
		_spawn_mess_near(_seats[g.seat].pos)

func _despawn_guest(id: int) -> void:
	if _guest_sim.has(id):
		var si: int = _guest_sim[id].seat
		if si >= 0 and si < _seats.size():
			_seats[si].guest = -1
		_guest_sim.erase(id)
	_remove_guest.rpc(id)

@rpc("authority", "reliable", "call_local")
func _add_guest(id: int, pos: Vector3) -> void:
	if _guests.has(id):
		return
	var c := CUSTOMER_SCENE.instantiate()
	c.cust_id = id
	c.position = pos
	_customers_container.add_child(c)
	_guests[id] = c

@rpc("authority", "reliable", "call_local")
func _remove_guest(id: int) -> void:
	if _guests.has(id):
		var c: Node = _guests[id]
		if is_instance_valid(c):
			c.queue_free()
		_guests.erase(id)

# ---- Temizlik / hijyen ----
func _update_hygiene(delta: float) -> void:
	var n := _messes.size()
	if n > 0:
		_hygiene = maxf(0.0, _hygiene - HYGIENE_DRAIN * n * delta)
		if _npc_roles.has(ROLE_CLEAN):
			for mid in _messes.keys():
				_mess_clean[mid] = float(_mess_clean.get(mid, 0.0)) + NPC_CLEAN_RATE * delta
				if _mess_clean[mid] >= 1.0:
					_remove_mess.rpc(mid)
				break
	else:
		_hygiene = minf(100.0, _hygiene + HYGIENE_REGEN * delta)

func _spawn_mess_near(p: Vector3) -> void:
	var off := Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
	var id := _mess_next
	_mess_next += 1
	_mess_clean[id] = 0.0
	_add_mess.rpc(id, Vector3(p.x + off.x, 0.02, p.z + off.z))

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

@rpc("any_peer", "reliable")
func net_clean(id: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	if not _messes.has(id):
		return
	_mess_clean[id] = float(_mess_clean.get(id, 0.0)) + CLEAN_PER_CALL
	if _mess_clean[id] >= 1.0:
		_remove_mess.rpc(id)

# ================================================= senkron
func _broadcast_sync() -> void:
	# Misafirler
	var cids := PackedInt32Array()
	var cx := PackedFloat32Array()
	var cz := PackedFloat32Array()
	var cyaw := PackedFloat32Array()
	var cstate := PackedInt32Array()
	var ckind := PackedInt32Array()
	var ctype := PackedInt32Array()
	var cratio := PackedFloat32Array()
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		cids.append(id)
		cx.append(g.pos.x)
		cz.append(g.pos.z)
		cyaw.append(g.yaw)
		cstate.append(g.ostate)
		ckind.append(g.okind)
		ctype.append(g.otype)
		cratio.append(clampf(g.patience / ORDER_PATIENCE, 0.0, 1.0))
	_net_guests.rpc(cids, cx, cz, cyaw, cstate, ckind, ctype, cratio)
	# Çevre
	var ids := PackedInt32Array()
	var pr := PackedFloat32Array()
	for mid in _messes.keys():
		ids.append(mid)
		pr.append(float(_mess_clean.get(mid, 0.0)))
	_net_env.rpc(Game.money, Game.score, _phase_time, _hygiene, _popularity, ids, pr)
	# Bira masası konumları (taşıma senkronu)
	var bx := PackedFloat32Array()
	var bz := PackedFloat32Array()
	for bt in _beertables:
		bx.append((bt as Node3D).position.x)
		bz.append((bt as Node3D).position.z)
	_net_tables.rpc(bx, bz)

@rpc("authority", "unreliable")
func _net_tables(bx: PackedFloat32Array, bz: PackedFloat32Array) -> void:
	for i in range(_beertables.size()):
		if i < bx.size():
			(_beertables[i] as Node3D).position = Vector3(bx[i], 0.0, bz[i])

@rpc("authority", "unreliable")
func _net_guests(cids: PackedInt32Array, cx: PackedFloat32Array, cz: PackedFloat32Array, cyaw: PackedFloat32Array, cstate: PackedInt32Array, ckind: PackedInt32Array, ctype: PackedInt32Array, cratio: PackedFloat32Array) -> void:
	for i in range(cids.size()):
		var c = _guests.get(cids[i])
		if c:
			c.set_net(Vector3(cx[i], 0.1, cz[i]), cyaw[i])
			c.set_order(cstate[i], ckind[i], ctype[i], cratio[i])

@rpc("authority", "unreliable")
func _net_env(money: int, score: int, time_left: float, hygiene: float, pop: float, ids: PackedInt32Array, pr: PackedFloat32Array) -> void:
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(time_left)
	_hud.set_hygiene(hygiene)
	_hud.set_popularity(pop)
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

func _mgmt_string() -> String:
	var limit: int = TENT_TABLE_LIMIT[_tent_stage]
	return "%s · Masa: %d/%d · Koltuk: %d · Popülerlik: %d%%\nKira/gün: %d€ · Wiesn-Tag: %d/%d" % [
		TENT_STAGE_NAMES[_tent_stage], _active_count, limit, _seats.size(),
		int(round(_popularity)), DAILY_RENT, _day, WIESN_DAYS]

func _broadcast_meta() -> void:
	net_meta.rpc(_phase, _roster_string(), _mgmt_string(), _day, _tent_stage, _active_count)

@rpc("authority", "reliable", "call_local")
func net_meta(phase: int, roster: String, mgmt: String, day: int, tent_stage: int, active_count: int) -> void:
	_phase = phase
	_day = day
	_tent_stage = tent_stage
	# Clientlerde masaların görünürlüğünü senkronla
	if not multiplayer.is_server() and _active_count != active_count:
		_active_count = active_count
		_apply_tent()
	_active_count = active_count
	_hud.set_phase(_phase_name())
	_hud.set_roster(roster)
	_hud.set_mgmt(mgmt)
	_hud.set_day(day, WIESN_DAYS)
	if _sfx_node:
		if phase == Phase.SHIFT:
			_sfx_node.play_music()
		else:
			_sfx_node.stop_music()

@rpc("authority", "reliable", "call_local")
func _net_banner(text: String) -> void:
	_hud.show_banner(text)
