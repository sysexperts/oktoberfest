extends Node3D
## GameManager. Faz: MOLA <-> VARDİYA. Misafirler popülerliğe göre gelir,
## bira masalarındaki koltuklara oturur, TÜM vardiya boyunca kalır ve
## tekrar tekrar sipariş verir; otururken kutlar. Rol için insan yoksa NPC (Tasarom).

enum Phase { INTERMISSION = 0, SHIFT = 1 }

const INTERMISSION_TIME := 40.0
const SHIFT_TIME := 300.0          # 07:00–22:00 arası gerçek süre (sn)
# Gün saati (oyun içi saat)
const DAY_START_HOUR := 7.0        # uyanma / zelt açılış
const GUEST_START_HOUR := 8.0      # misafirler bu saatten sonra gelir
const DAY_END_HOUR := 22.0         # en geç kapanış
const NIGHT_HOUR := 19.0           # bu saatten sonra akşam: karanlık + sabırsız
const DUSK_START := 16.5           # Dämmerung beginnt
const DUSK_END := 21.0             # ab hier ist es ganz dunkel
## Zum Testen der Nachtbeleuchtung auf true stellen — dann ist es immer Nacht.
const ALWAYS_NIGHT := false
const POP_EARLY_CLOSE_PER_HOUR := 1.5   # erken kapatma cezası (saat başına)
const SYNC_INTERVAL := 0.12
const MISS_PENALTY := 5
const PLAYER_SCENE := preload("res://scenes/player.tscn")
const CUSTOMER_SCENE := preload("res://scenes/customer.tscn")
const MESS_SCENE := preload("res://scenes/mess.tscn")
const SAVE_PATH := "user://oktoberfest_save.json"

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
const NIGHT_FRACTION := 0.25        # son %25 = "gece" (PlateUp tarzı endspurt)
const PATIENCE_NIGHT_MULT := 1.8    # gece sabır daha hızlı azalır
const POP_START := 20.0             # az misafirle başla
const POP_SERVE := 1.5
const POP_MISS := 3.0
const MESS_CHANCE_PER_SEC := 0.02   # Wahrscheinlichkeit pro Sekunde
const DRINKS_BEFORE_PUKE := 4       # so viele Getränke, bevor jemandem schlecht wird

# Temizlik
const CLEAN_PER_CALL := 0.05
const CLEAN_TIP_MIN := 6      # Trinkgeld fürs Saubermachen
const CLEAN_TIP_MAX := 12
const HYGIENE_DRAIN := 1.2
const HYGIENE_REGEN := 1.0
const NPC_CLEAN_RATE := 0.06
const START_MONEY := 1200   # Startbudget: Zelt 500 + 2 Tische 400 + 1 Paket Bier 60

# Zelt / makro-döngü (Wasenplatz mantığı)
const TENT_STAGE_NAMES := {0: "Zelt yok", 1: "Küçük Zelt", 2: "Orta Zelt", 3: "Büyük Zelt"}
const TENT_TABLE_LIMIT := {0: 0, 1: 4, 2: 8, 3: 12}   # sahnede 12 masa var
const TENT_BOOK_COST := 500
const TENT_UPGRADE_COST := {2: 3000, 3: 10000}
const TABLE_COST := 200
## Zeltmiete pro Tag — fest je Zeltgröße, steigt nicht mit den Tagen.
const TENT_RENT := {0: 0, 1: 120, 2: 300, 3: 700}
const DAILY_RENT := 120       # (nicht mehr verwendet, bleibt für Kompatibilität)
const RENT_PER_DAY := 30      # Aufschlag pro Tag (Wirtschaftsdruck)
const WIESN_DAYS := 16
# Upgrades (kiosk)
const MARKETING_COST := 400   # her seviye +15 popülerlik enjeksiyonu
const MARKETING_BOOST := 15.0
const DEKO_COST := 600        # her seviye +%15 gelir
const DEKO_BONUS := 0.15
# E2.4 Lizenzen — başta sadece Helles satılır, gerisi Wiesenbüro'dan alınır
const LIC_COST := {"weizen": 800, "radler": 800, "brezn": 1200, "sosis": 1200}
const LIC_NAMES := {"weizen": "🍺 Weizen", "radler": "🍋 Radler", "brezn": "🥨 Brezn", "sosis": "🌭 Sosis"}

# ---- E3: Personal ----
const STAFF_SCENE := preload("res://scenes/staff.tscn")
const ROLE_KOCH := 1
const ROLE_KELLNER := 2
const ROLE_REINIGUNG := 3
const STAFF_NAMES := {1: "👨‍🍳 Koch", 2: "🍺 Kellner", 3: "🧹 Reinigung"}
const STAFF_HIRE_COST := {1: 600, 2: 500, 3: 400}
const STAFF_WAGE_BASE := {1: 120, 2: 100, 3: 80}   # Lohn/Schicht auf Level 1
const STAFF_UPGRADE_BASE := 400                     # × aktuelles Level
const STAFF_MAX_LEVEL := 5
## Wie viele Krüge ein Kellner auf einmal trägt — höhere Level sparen Laufwege.
const WAITER_CAPACITY := {1: 1, 2: 2, 3: 4, 4: 8, 5: 12}
const STAFF_BASE_SPEED := 3.0
const TABLE_AVOID_RADIUS := 2.2   # Mitarbeiter halten Abstand zu Tischen
const BAR_POINT := Vector3(0, 0.1, -7.0)      # Kellner holt hier ab
const KITCHEN_POINT := Vector3(7.0, 0.1, -7.0) # Koch steht hier
const DRINK_PREP := 1.2                        # Sekunden pro Getränk
const FOOD_PREP := 3.0                         # Sekunden pro Speise (mit Koch)

# ---- E4: Ware & Lieferung ----
const PACKAGE_SCENE := preload("res://scenes/package.tscn")
const VAN_SCENE := preload("res://scenes/delivery_van.tscn")
const WARE_BIER := 1
const WARE_ESSEN := 2
const WARE_NAMES := {1: "🍺 Bier", 2: "🥨 Zutaten"}
const PACK_UNITS := 10                    # Einheiten pro Paket
const PACK_COST := {1: 40, 2: 50}         # Preis pro Paket (10 Einheiten)
const DELIVERY_DELAY := 60.0              # Lieferzeit nach Bestellung (Sekunden)
const VAN_START := Vector3(-42.0, 0.0, 19.0)
const VAN_DROP := Vector3(2.0, 0.0, 19.0)
const VAN_END := Vector3(42.0, 0.0, 19.0)
const VAN_SPEED := 9.0
const DROP_POINT := Vector3(0.0, 0.0, 15.5)   # wo die Pakete landen

# ---- E5: Bühne & Künstler ----
const ARTIST_SCENE := preload("res://scenes/artist.tscn")
const ARTIST_NAMES := {1: "🎸 Straßenmusiker", 2: "🎺 Blaskapelle", 3: "⭐ Star-Act"}
const ARTIST_COST := {1: 500, 2: 2000, 3: 6000}
const ARTIST_COUNT := {1: 1, 2: 3, 3: 5}      # wie viele auf der Bühne stehen
const ARTIST_POP := {1: 5.0, 2: 12.0, 3: 25.0}  # Beliebtheitsschub beim Buchen
const ARTIST_DRAW := {1: 0.15, 2: 0.35, 3: 0.6} # zusätzliche Auslastung während der Schicht

# ---- E6: Klo, Urin, Beschwerden ----
const TOILET_COST := 1800
const BLADDER_MIN := 70.0        # Sekunden bis ein Gast muss
const BLADDER_MAX := 150.0
const PEE_CORNER := Vector3(-10.5, 0.1, 8.0)   # Ecke, in die ohne Klo gepinkelt wird
const TOILET_POINT := Vector3(10.5, 0.1, 8.0)  # Klo-Ecke (wenn gekauft)
const PEE_DURATION := 4.0
const COMPLAIN_INTERVAL := 6.0   # wie oft geprüft wird
const COMPLAIN_RADIUS := 5.0     # Umkreis eines Urinflecks
const COMPLAIN_POP := 2.5        # Beliebtheitsverlust pro Beschwerde
const LEAVE_CHANCE := 0.25       # Wahrscheinlichkeit, dass ein Gast deshalb geht

var _hud: HUD
var _sfx_node: Node
var _players_container: Node3D
var _customers_container: Node3D
var _messes_container: Node3D
var _staff_container: Node3D
var _packages_container: Node3D
var _crowd: Node3D
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
var _night := false
var _did_shift := false   # bu gün en az bir vardiya yapıldı mı (bilanço için)
var _popularity := POP_START

# Zelt / makro-döngü durumu
var _tent_stage := 0     # 0 = kiralanmadı, 1..3 zelt büyüklüğü
var _active_count := 0   # aktif (görünür/oturulabilir) masa sayısı
var _day := 1            # Wiesn günü
var _upg_marketing := 0  # Werbung seviyesi (popülerlik enjeksiyonu)
var _upg_deko := 0       # Deko seviyesi (gelir çarpanı)
# E2.4: satın alınan lisanslar (Helles lisanssız hep satılır)
var _lic := {"weizen": false, "radler": false, "brezn": false, "sosis": false}
# E3: Personal. sim: id -> {role, level, pos, tgt, yaw, state, timer, orders:Array, idx}
var _staff := {}        # id -> Staff node
var _staff_sim := {}
var _staff_next := 0
var _assigned := {}     # guest_id -> staff_id (doppelte Bedienung vermeiden)
var _wages_last := 0
var _clean_tips := 0
var _interest_paid := 0
var _last_report := ""
# E4: Bestand + Lieferungen
var _stock := {1: 0, 2: 0}      # WARE_BIER / WARE_ESSEN
var _goods_cost := 0            # Wareneinsatz des Tages (für die Bilanz)
var _pending := []              # [{kind, packs, t}] — offene Lieferungen
var _packages := {}             # id -> Package node
var _pkg_next := 0
var _van_node: Node3D = null
var _van_state := 0             # 0 aus, 1 anfahrt, 2 abladen, 3 abfahrt
var _van_pos := Vector3.ZERO
var _van_timer := 0.0
var _van_cargo := []            # [{kind, packs}] die abgeladen werden
# E5: gebuchter Künstler (gilt für die nächste Schicht, danach verbraucht)
var _artist_tier := 0
var _artist_nodes := []
# E6: Klo / Urin / Beschwerden
var _has_toilet := false
var _mess_kind := {}          # mess_id -> 0 Erbrochenes, 1 Urin
var _complain_timer := 0.0
var _urin_count := 0          # Tageszähler für den Report
var _complaints := 0
var _left_guests := 0
# Tutorial-Fortschritt
var _quest_step := 0
var _quest_served_once := false
var _ever_artist := false
var _quest_timer := 0.0

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

var _sun: DirectionalLight3D
var _world_env: WorldEnvironment
var _day_sun_energy := 1.0
var _day_ambient := 0.35
var _day_bg := 1.0
var _day_fog := 0.0008
var _day_fog_color := Color(0.78, 0.70, 0.62)
var _night_visual := false
var _night_t := -1.0

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
	_staff_container = get_node_or_null("StaffNodes")
	if _staff_container == null:
		_staff_container = Node3D.new()
		_staff_container.name = "StaffNodes"
		add_child(_staff_container)
	_crowd = get_node_or_null("Crowd")
	_packages_container = get_node_or_null("Packages")
	if _packages_container == null:
		_packages_container = Node3D.new()
		_packages_container.name = "Packages"
		add_child(_packages_container)
	_sun = $Sun
	_world_env = $WorldEnvironment
	_day_sun_energy = _sun.light_energy
	if _world_env.environment:
		_day_ambient = _world_env.environment.ambient_light_energy
		_day_bg = _world_env.environment.background_energy_multiplier
		_day_fog = _world_env.environment.fog_density
		_day_fog_color = _world_env.environment.fog_light_color
	_apply_night_visual(false)

	# Bira masalarını topla (kararlı sıra). Başta zelt kiralanmadı → 0 aktif.
	_all_tables = get_tree().get_nodes_in_group("beertable")
	_all_tables.sort_custom(func(a, b): return _tbl_num(a.name) < _tbl_num(b.name))
	_apply_tent()

	Game.money_changed.connect(_hud.set_money)
	Game.score_changed.connect(_hud.set_score)
	_hud.set_money(Game.money)
	_hud.set_score(Game.score)
	_hud.set_time(_clock_hour())
	_hud.set_phase(_phase_name())
	_hud.set_day(_day, WIESN_DAYS)

	if multiplayer.is_server():
		if not _load_game():
			Game.add_money(START_MONEY)
		multiplayer.peer_disconnected.connect(_on_peer_left)
		if Net.dedicated:
			_next_spawn = 0
		else:
			_spawn_index_by_peer[1] = 0
			_next_spawn = 1
			_add_player(1, 0)
		_broadcast_meta()
		_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))
	else:
		_client_ready.rpc_id(1)

func _phase_name() -> String:
	return "ZELT AÇIK" if _phase == Phase.SHIFT else "KAPALI (uyu → yeni gün)"

func in_intermission() -> bool:
	return _phase == Phase.INTERMISSION

func _tent_ready() -> bool:
	return _tent_stage > 0 and _active_count > 0

## Vardiyadaki oyun içi saat (7.0 = 07:00). Kapalıyken -1.
func _clock_hour() -> float:
	if _phase != Phase.SHIFT:
		return -1.0
	var elapsed: float = SHIFT_TIME - _phase_time
	return DAY_START_HOUR + (elapsed / SHIFT_TIME) * (DAY_END_HOUR - DAY_START_HOUR)

## Saate göre kalabalık çarpanı: sabah az, akşam çok.
func _time_factor() -> float:
	var h: float = _clock_hour()
	if h < GUEST_START_HOUR:
		return 0.0
	return clampf(0.25 + 0.75 * ((h - GUEST_START_HOUR) / (DAY_END_HOUR - GUEST_START_HOUR)), 0.0, 1.0)

# ================================================= kayıt (E3)
## Sunucuda ilerlemeyi diske yaz (para, gün, zelt, upgrade, masa konumları).
func _save_game() -> void:
	if not multiplayer.is_server():
		return
	var tables := []
	for bt in _all_tables:
		var p: Vector3 = (bt as Node3D).position
		tables.append({"x": p.x, "z": p.z})
	var data := {
		"money": Game.money,
		"score": Game.score,
		"day": _day,
		"tent_stage": _tent_stage,
		"active_count": _active_count,
		"upg_marketing": _upg_marketing,
		"upg_deko": _upg_deko,
		"popularity": _popularity,
		"shift_num": _shift_num,
		"tables": tables,
		"lic": _lic,
		"staff": _staff_save_list(),
		"stock_bier": int(_stock[WARE_BIER]),
		"stock_essen": int(_stock[WARE_ESSEN]),
		"toilet": _has_toilet,
		"quest": _quest_step,
		"ever_artist": _ever_artist,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

## Kayıt varsa yükle. Başarılıysa true.
func _load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	Game.add_money(int(d.get("money", 0)) - Game.money)
	Game.add_score(int(d.get("score", 0)) - Game.score)
	_day = maxi(1, int(d.get("day", 1)))
	_tent_stage = clampi(int(d.get("tent_stage", 0)), 0, 3)
	_active_count = int(d.get("active_count", 0))
	_upg_marketing = int(d.get("upg_marketing", 0))
	_upg_deko = int(d.get("upg_deko", 0))
	_popularity = clampf(float(d.get("popularity", POP_START)), 5.0, 100.0)
	_shift_num = int(d.get("shift_num", 0))
	var lic: Variant = d.get("lic", {})
	if lic is Dictionary:
		for k in LIC_COST.keys():
			_lic[k] = bool((lic as Dictionary).get(k, false))
	_has_toilet = bool(d.get("toilet", false))
	_quest_step = int(d.get("quest", 0))
	_ever_artist = bool(d.get("ever_artist", false))
	_stock[WARE_BIER] = int(d.get("stock_bier", 0))
	_stock[WARE_ESSEN] = int(d.get("stock_essen", 0))
	var st: Variant = d.get("staff", [])
	if st is Array:
		for e in (st as Array):
			if e is Dictionary:
				_restore_staff(int((e as Dictionary).get("role", 2)), int((e as Dictionary).get("level", 1)))
	var tp: Variant = d.get("tables", [])
	if tp is Array:
		var arr: Array = tp
		for i in range(mini(arr.size(), _all_tables.size())):
			var e: Variant = arr[i]
			if e is Dictionary:
				var ed: Dictionary = e
				(_all_tables[i] as Node3D).position = Vector3(float(ed.get("x", 0.0)), 0.0, float(ed.get("z", 0.0)))
	_active_count = clampi(_active_count, 0, _all_tables.size())
	_apply_tent()
	return true

## Bühnenlicht nur bei offenem Zelt.
func _apply_stage(on: bool) -> void:
	for s in get_tree().get_nodes_in_group("stage"):
		if s.has_method("set_active"):
			s.set_active(on)

## E7: Besucherdichte draußen aus der Uhrzeit ableiten (geschlossen = leer).
func _apply_crowd(clock: float) -> void:
	if _crowd == null:
		return
	var f := 0.0
	if clock >= 0.0:
		f = clampf((clock - DAY_START_HOUR) / (DAY_END_HOUR - DAY_START_HOUR), 0.15, 1.0)
	_crowd.set_density(f)

## Gece görsel: güneş + ortam ışığını kıs (akşam hissi).
func _apply_night_visual(night: bool) -> void:
	# Alt-Aufruf: leitet auf die stufenlose Variante um
	_apply_daylight(_clock_hour() if night else -1.0)

## 0.0 = heller Tag, 1.0 = tiefe Nacht. Dazwischen wird weich überblendet.
func _daylight_factor(clock: float) -> float:
	if ALWAYS_NIGHT:
		return 1.0
	if clock < 0.0:
		return 0.0
	if clock <= DUSK_START:
		return 0.0
	if clock >= DUSK_END:
		return 1.0
	return smoothstep(0.0, 1.0, (clock - DUSK_START) / (DUSK_END - DUSK_START))

## Dämmerung stufenlos: Sonne, Himmel und Umgebungslicht wandern langsam runter.
func _apply_daylight(clock: float) -> void:
	var t := _daylight_factor(clock)
	if absf(t - _night_t) < 0.01:
		return
	_night_t = t
	if _sun:
		# Nachts bleibt ein weiches, leicht blaues Mondlicht — dunkel genug, dass
		# die bunten Kirmeslichter wirken, hell genug, dass man alles erkennt.
		_sun.light_energy = lerpf(_day_sun_energy, _day_sun_energy * 0.14, t)
		_sun.light_color = Color(1, 1, 1).lerp(Color(0.62, 0.68, 0.92), t)
		_sun.shadow_enabled = t < 0.5
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		env.ambient_light_energy = lerpf(_day_ambient, _day_ambient * 0.30, t)
		env.background_energy_multiplier = lerpf(_day_bg, _day_bg * 0.22, t)
		# Nebel bleibt ein dünner Dunst — er soll das Licht der Buden einfangen,
		# nicht die Sicht nehmen. Nachts etwas dichter und dunkler, damit die
		# bunten Lichter Schwaden werfen.
		env.fog_density = lerpf(_day_fog, _day_fog * 4.0, t)
		env.fog_light_color = _day_fog_color.lerp(Color(0.26, 0.23, 0.30), t)
func _daily_rent() -> int:
	return int(TENT_RENT.get(_tent_stage, 0))

## E2.4: satılabilir içecek tipleri — lisansa bağlı (1 Helles hep açık).
func _drinks_avail() -> Array:
	var a := [1]
	if _lic.get("weizen", false):
		a.append(2)
	if _lic.get("radler", false):
		a.append(3)
	return a

## E2.4: satılabilir yemek tipleri — lisans yoksa hiç yemek satılmaz.
func _foods_avail() -> Array:
	var a := []
	if _lic.get("brezn", false):
		a.append(1)
	if _lic.get("sosis", false):
		a.append(2)
	return a

## Node adındaki sayıyı çıkar (BeerTable10 -> 10) — doğal sıralama için.
func _tbl_num(n: String) -> int:
	var digits := ""
	for i in n.length():
		var ch := n[i]
		if ch >= "0" and ch <= "9":
			digits += ch
	return int(digits) if digits != "" else 0

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
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		_add_staff.rpc_id(sender, sid, st.pos, int(st.role), int(st.level))
	for pid in _packages.keys():
		var pk = _packages[pid]
		_add_package.rpc_id(sender, pid, (pk as Node3D).position, int(pk.kind), int(pk.amount))
	_push_stock.rpc_id(sender, int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))
	net_report.rpc_id(sender, _last_report)
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
	for ti in _beertables.size():
		var bt = _beertables[ti]
		var origin: Vector3 = (bt as Node3D).global_position
		for sp in bt.seat_points():
			var d: Vector3 = origin - sp
			d.y = 0
			var yaw := atan2(-d.x, -d.z) if d.length() > 0.01 else 0.0
			var away: Vector3 = (sp - origin)
			away.y = 0
			away = away.normalized() if away.length() > 0.01 else Vector3.FORWARD
			_seats.append({"pos": sp, "yaw": yaw, "guest": -1, "table": ti, "away": away})

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
	if not _afford(TENT_BOOK_COST):
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
	# Die ersten zwei Tische sind Pflicht — dafür gilt die Warenreserve nicht
	if _active_count >= 2 and not _reserve_ok(TABLE_COST):
		return
	if not _afford(TABLE_COST):
		_net_banner.rpc("💶 Yetersiz para! (Tisch: %d€)" % TABLE_COST)
		return
	Game.add_money(-TABLE_COST)
	_active_count += 1
	_apply_tent()
	_net_banner.rpc("🪑 Masa +1 (%d/%d)" % [_active_count, limit])
	_broadcast_meta()

## Kiosk: Werbung — anında popülerlik enjeksiyonu (her seviye daha pahalı).
@rpc("any_peer", "reliable")
func net_buy_marketing() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var cost := MARKETING_COST * (_upg_marketing + 1)
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (Werbung: %d€)" % cost)
		return
	Game.add_money(-cost)
	_upg_marketing += 1
	_popularity = minf(100.0, _popularity + MARKETING_BOOST)
	_net_banner.rpc("📣 Werbung Lv%d! Popülerlik +%d%%" % [_upg_marketing, int(MARKETING_BOOST)])
	_broadcast_meta()

## Kiosk: Deko — kalıcı gelir çarpanı.
@rpc("any_peer", "reliable")
func net_buy_deko() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var cost := DEKO_COST * (_upg_deko + 1)
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (Deko: %d€)" % cost)
		return
	Game.add_money(-cost)
	_upg_deko += 1
	_net_banner.rpc("🎨 Deko Lv%d! Gelir +%d%%" % [_upg_deko, int(DEKO_BONUS * _upg_deko * 100)])
	_broadcast_meta()

# ================================================= E6: Klo & Beschwerden
## Wiesenbüro: Toilette einbauen — danach pinkelt niemand mehr in die Ecke.
@rpc("any_peer", "reliable")
func net_buy_toilet() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _has_toilet:
		_net_banner.rpc("🚻 Toilette ist schon eingebaut")
		return
	if _tent_stage == 0:
		_net_banner.rpc("Erst ein Zelt mieten!")
		return
	if not _reserve_ok(TOILET_COST):
		return
	if not _afford(TOILET_COST):
		_net_banner.rpc("💶 Yetersiz para! (Toilette: %d€)" % TOILET_COST)
		return
	Game.add_money(-TOILET_COST)
	_has_toilet = true
	_net_banner.rpc("🚻 Toilette eingebaut! Schluss mit Pinkeln in der Ecke.")
	_broadcast_meta()

## Blase der sitzenden Gäste. Ohne Klo → Urinfleck in der Ecke.
func _update_bladder(g: Dictionary, id: int, delta: float) -> void:
	if int(g.mode) == 3:
		# unterwegs / gerade dabei
		g.pee_t = float(g.pee_t) - delta
		if float(g.pee_t) <= 0.0:
			g.mode = 1
			g.tgt = _seats[int(g.seat)].pos
			g.bladder = randf_range(BLADDER_MIN, BLADDER_MAX)
		return
	g.bladder = float(g.bladder) - delta
	if float(g.bladder) > 0.0:
		return
	# Muss mal
	if _has_toilet:
		# geht kurz aufs Klo, kein Dreck
		g.mode = 3
		g.pee_t = PEE_DURATION
		g.tgt = TOILET_POINT
		g.ostate = 0
	else:
		g.mode = 3
		g.pee_t = PEE_DURATION
		g.tgt = PEE_CORNER
		g.ostate = 0
		_spawn_mess_at(PEE_CORNER + Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2)), 1)
		_urin_count += 1

## Beschwerden: Gäste in der Nähe von Urin meckern, manche gehen.
func _update_complaints(delta: float) -> void:
	_complain_timer -= delta
	if _complain_timer > 0.0:
		return
	_complain_timer = COMPLAIN_INTERVAL
	var urin_pos := []
	for mid in _messes.keys():
		if int(_mess_kind.get(mid, 0)) == 1:
			var m := _messes[mid] as Node3D
			if m:
				urin_pos.append(m.global_position)
	if urin_pos.is_empty():
		return
	for gid in _guest_sim.keys().duplicate():
		var g: Dictionary = _guest_sim[gid]
		if int(g.mode) != 1:
			continue
		var near := false
		for p in urin_pos:
			if (g.pos as Vector3).distance_to(p) <= COMPLAIN_RADIUS:
				near = true
				break
		if not near:
			continue
		_complaints += 1
		_popularity = maxf(5.0, _popularity - COMPLAIN_POP)
		if randf() < LEAVE_CHANCE:
			g.mode = 2
			g.tgt = ENTRANCE
			g.ostate = 0
			_guest_sim[gid] = g
			_left_guests += 1
		else:
			_guest_sim[gid] = g

func _toilet_string() -> String:
	return "🚻 Toilette: ja" if _has_toilet else "🚻 Toilette: FEHLT (Gäste pinkeln in die Ecke)"

# ================================================= Tutorial & Schutzregeln
## Preis eines Bierpakets — so viel muss übrig bleiben, solange kein Bier da ist.
const GOODS_RESERVE := 40
## Dispo: bis hierhin darf das Konto ins Minus. Rückzahlung kostet 5% Zinsen.
const OVERDRAFT_LIMIT := 1000
const OVERDRAFT_INTEREST := 0.05

## Popup beim anfragenden Spieler (nicht bei allen).
func _popup_to_sender(msg: String) -> void:
	var s := multiplayer.get_remote_sender_id()
	if s <= 1:
		net_popup(msg)
	else:
		net_popup.rpc_id(s, msg)

@rpc("authority", "reliable", "call_local")
func net_popup(text: String) -> void:
	if _hud and _hud.has_method("show_popup"):
		_hud.show_popup(text)

## Kein Bier im Lager und keine Lieferung unterwegs?
func _needs_goods() -> bool:
	return int(_stock.get(WARE_BIER, 0)) <= 0 and _pending.is_empty()

## Verhindert, dass man sein letztes Geld ausgibt, ohne Ware zu haben.
func _reserve_ok(cost: int) -> bool:
	if not _needs_goods():
		return true
	if Game.money - cost >= GOODS_RESERVE:
		return true
	_popup_to_sender("📦 Erst Ware einkaufen!\n\nDu hast kein Bier im Lager und keine Lieferung unterwegs.\nBehalte mindestens %d€ für ein Paket Bier —\nsonst kannst du nichts verkaufen.\n\nWiesenbüro → Reiter Ware" % GOODS_RESERVE)
	return false

# ---- Tutorial ----
const QUEST_TEXTS := [
	"🎪 Miete dein Festzelt\nWiesenbüro (Nordosten) → Zelt → Zelt mieten (500€)",
	"🪑 Stelle 2 Tische auf\nWiesenbüro → Zelt → Tisch stellen (200€)",
	"🍺 Bestelle Bier\nWiesenbüro → Ware → 🍺 Bier ×1 (60€)",
	"🚚 Der Lieferwagen kommt (~1 Min) und hupt.\nPakete mit E aufnehmen → ins Lager tragen",
	"😴 Schlafe im Wohnwagen\n(Südseite, schmale Gasse) → Tag startet um 07:00",
	"🍻 Bediene einen Gast\nKrug nehmen → am Fass zapfen (E halten) → Gast (E)",
	"🌙 Halte bis 22:00 durch\nDanach kommt die Tagesbilanz",
	"👷 Stelle einen Kellner ein\nWiesenbüro → Personal (500€) — er bedient für dich",
	"📜 Kaufe eine Lizenz\nWiesenbüro → Lizenzen — mehr Auswahl, mehr Umsatz",
	"🚻 Baue eine Toilette ein (1800€)\nSonst pinkeln die Gäste in die Ecke",
	"🎤 Buche einen Künstler\nWiesenbüro → Künstler — bringt mehr Gäste",
]

func _quest_done(step: int) -> bool:
	match step:
		0: return _tent_stage > 0
		1: return _active_count >= 2
		2: return int(_stock.get(WARE_BIER, 0)) > 0 or not _pending.is_empty()
		3: return int(_stock.get(WARE_BIER, 0)) > 0
		4: return _shift_num >= 1
		5: return _served >= 1 or _quest_served_once
		6: return _shift_num >= 1 and _phase == Phase.INTERMISSION
		7: return _has_staff(ROLE_KELLNER)
		8: return _lic.values().has(true)
		9: return _has_toilet
		10: return _ever_artist
	return false

func _has_staff(role: int) -> bool:
	for s in _staff_sim.values():
		if int(s.role) == role:
			return true
	return false

## Schritte weiterschalten, solange sie erfüllt sind. true = etwas hat sich geändert.
func _check_quest() -> bool:
	var before := _quest_step
	while _quest_step < QUEST_TEXTS.size() and _quest_done(_quest_step):
		_quest_step += 1
	return _quest_step != before

func _quest_text() -> String:
	if _quest_step >= QUEST_TEXTS.size():
		return ""
	return "📋 Aufgabe %d/%d\n%s" % [_quest_step + 1, QUEST_TEXTS.size(), QUEST_TEXTS[_quest_step]]

# ================================================= E5: Künstler
## Wiesenbüro: Künstler für die nächste Schicht buchen.
@rpc("any_peer", "reliable")
func net_book_artist(tier: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not ARTIST_COST.has(tier):
		return
	if _artist_tier > 0:
		_net_banner.rpc("🎤 %s ist schon gebucht" % ARTIST_NAMES[_artist_tier])
		return
	var cost: int = ARTIST_COST[tier]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (%s: %d€)" % [ARTIST_NAMES[tier], cost])
		return
	Game.add_money(-cost)
	_artist_tier = tier
	_ever_artist = true
	_popularity = minf(100.0, _popularity + float(ARTIST_POP[tier]))
	_net_banner.rpc("🎤 %s gebucht! Popularität +%d%%\nSpielt in der nächsten Schicht." % [
		ARTIST_NAMES[tier], int(ARTIST_POP[tier])])
	_broadcast_meta()

## Künstler auf die Bühne stellen (Schichtbeginn).
func _spawn_artists() -> void:
	if _artist_tier <= 0:
		return
	var stages := get_tree().get_nodes_in_group("stage")
	if stages.is_empty():
		return
	var pts: Array = stages[0].artist_points()
	if pts.is_empty():
		return
	# Künstler zur Publikumsseite drehen (Bühnen-Vorderseite = lokales +Z)
	var fwd: Vector3 = (stages[0] as Node3D).global_transform.basis.z
	var yaw := atan2(-fwd.x, -fwd.z)
	var n: int = mini(int(ARTIST_COUNT[_artist_tier]), pts.size())
	for i in n:
		_add_artist.rpc(i, pts[i], _artist_tier, yaw)

func _clear_artists() -> void:
	_remove_artists.rpc()

@rpc("authority", "reliable", "call_local")
func _add_artist(idx: int, pos: Vector3, tier: int, yaw: float) -> void:
	var a := ARTIST_SCENE.instantiate()
	a.name = "Artist%d" % idx
	a.position = pos
	a.rotation.y = yaw
	_staff_container.add_child(a)
	a.set_tier(tier)
	_artist_nodes.append(a)

@rpc("authority", "reliable", "call_local")
func _remove_artists() -> void:
	for a in _artist_nodes:
		if is_instance_valid(a):
			a.queue_free()
	_artist_nodes.clear()

func _artist_string() -> String:
	if _artist_tier <= 0:
		return "Bühne: kein Künstler gebucht"
	return "Bühne: %s (+%d%% Andrang)" % [ARTIST_NAMES[_artist_tier], int(ARTIST_DRAW[_artist_tier] * 100.0)]

# ================================================= E4: Ware & Lieferung
## Wiesenbüro: Ware bestellen. Kommt nach ~1 Minute per Lieferwagen.
@rpc("any_peer", "reliable")
func net_order_goods(kind: int, packs: int) -> void:
	if not multiplayer.is_server():
		return
	if _tent_stage == 0:
		_popup_to_sender("🎪 Du hast noch kein Zelt!\n\nOhne Festzelt kannst du keine Ware lagern.\nMiete zuerst ein Zelt:\nWiesenbüro → Reiter Zelt → Zelt mieten (500€)")
		return
	if not PACK_COST.has(kind) or packs <= 0:
		return
	var cost: int = PACK_COST[kind] * packs
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (%d× %s: %d€)" % [packs, WARE_NAMES[kind], cost])
		return
	Game.add_money(-cost)
	_goods_cost += cost
	_pending.append({"kind": kind, "packs": packs, "t": DELIVERY_DELAY})
	_net_banner.rpc("🚚 %d× %s bestellt (%d€)\nLieferung in ~1 Minute" % [packs, WARE_NAMES[kind], cost])
	_broadcast_meta()

func _update_delivery(delta: float) -> void:
	# Offene Bestellungen herunterzählen
	for i in range(_pending.size() - 1, -1, -1):
		var o: Dictionary = _pending[i]
		o.t = float(o.t) - delta
		_pending[i] = o
		if float(o.t) <= 0.0 and _van_state == 0:
			_van_cargo = [{"kind": int(o.kind), "packs": int(o.packs)}]
			_pending.remove_at(i)
			# gleiche fällige Bestellungen mitnehmen
			for j in range(_pending.size() - 1, -1, -1):
				if float(_pending[j].t) <= 0.0:
					_van_cargo.append({"kind": int(_pending[j].kind), "packs": int(_pending[j].packs)})
					_pending.remove_at(j)
			_van_pos = VAN_START
			_van_state = 1
			_van_show.rpc(true, VAN_START)
			break
	if _van_state == 0:
		return
	match _van_state:
		1:
			var to: Vector3 = VAN_DROP - _van_pos
			var d := to.length()
			if d <= 0.4:
				_van_state = 2
				_van_timer = 1.2
				_drop_cargo()
				_van_honk.rpc()
			else:
				_van_pos += to.normalized() * minf(VAN_SPEED * delta, d)
		2:
			_van_timer -= delta
			if _van_timer <= 0.0:
				_van_state = 3
		3:
			var to2: Vector3 = VAN_END - _van_pos
			var d2 := to2.length()
			if d2 <= 0.5:
				_van_state = 0
				_van_show.rpc(false, VAN_END)
			else:
				_van_pos += to2.normalized() * minf(VAN_SPEED * delta, d2)
	if _van_state != 0:
		_van_move.rpc(_van_pos)

func _drop_cargo() -> void:
	var n := 0
	for c in _van_cargo:
		for p in int(c.packs):
			var id := _pkg_next
			_pkg_next += 1
			var off := Vector3(randf_range(-2.5, 2.5), 0.0, randf_range(-1.5, 1.5))
			_add_package.rpc(id, DROP_POINT + off, int(c.kind), PACK_UNITS)
			n += 1
	_van_cargo = []
	_net_banner.rpc("📦 %d Paket(e) geliefert! Bring sie ins Lager." % n)

@rpc("authority", "reliable", "call_local")
func _van_show(on: bool, pos: Vector3) -> void:
	if on:
		if _van_node == null:
			_van_node = VAN_SCENE.instantiate()
			add_child(_van_node)
		_van_node.position = pos
		_van_node.rotation.y = PI * 0.5   # Wagen zeigt nach +Z, fährt aber nach +X
	else:
		if _van_node and is_instance_valid(_van_node):
			_van_node.queue_free()
		_van_node = null

@rpc("authority", "unreliable")
func _van_move(pos: Vector3) -> void:
	if _van_node and is_instance_valid(_van_node):
		_van_node.position = pos
		_van_node.rotation.y = PI * 0.5   # Wagen zeigt nach +Z, fährt aber nach +X

@rpc("authority", "reliable", "call_local")
func _van_honk() -> void:
	if _sfx_node:
		_sfx_node.play("honk", 0.0)

@rpc("authority", "reliable", "call_local")
func _add_package(id: int, pos: Vector3, kind: int, amount: int) -> void:
	if _packages.has(id):
		return
	var p := PACKAGE_SCENE.instantiate()
	p.pkg_id = id
	p.position = pos
	_packages_container.add_child(p)
	p.set_info(kind, amount)
	_packages[id] = p

@rpc("authority", "reliable", "call_local")
func _remove_package(id: int) -> void:
	if _packages.has(id):
		var p: Node = _packages[id]
		if is_instance_valid(p):
			p.queue_free()
		_packages.erase(id)

## Spieler hebt ein Paket auf.
@rpc("any_peer", "reliable")
func net_pickup_package(id: int) -> void:
	if not multiplayer.is_server():
		return
	if not _packages.has(id):
		return
	_remove_package.rpc(id)

## Spieler lädt getragenes Paket im Lager ab.
@rpc("any_peer", "reliable")
func net_store_package(kind: int, amount: int) -> void:
	if not multiplayer.is_server():
		return
	if not _stock.has(kind):
		return
	_stock[kind] = int(_stock[kind]) + amount
	_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _push_stock(bier: int, essen: int) -> void:
	_stock[WARE_BIER] = bier
	_stock[WARE_ESSEN] = essen
	# Bestand ist EIN gemeinsames Lager; die Regale zeigen ihn aufgeteilt an
	var shelves := get_tree().get_nodes_in_group("lager")
	shelves.sort_custom(func(a, b): return String(a.name) < String(b.name))
	for i in shelves.size():
		var l = shelves[i]
		if l.has_method("set_stock"):
			l.set_stock(bier, essen, i)
	if _hud:
		_hud.set_stock(bier, essen)

## Reicht der Bestand für diese Bestellung? (kind: 1 Getränk, 2 Essen)
func _has_stock(okind: int) -> bool:
	var w: int = WARE_ESSEN if okind == 2 else WARE_BIER
	return int(_stock.get(w, 0)) > 0

func _consume_stock(okind: int) -> void:
	var w: int = WARE_ESSEN if okind == 2 else WARE_BIER
	_stock[w] = maxi(0, int(_stock.get(w, 0)) - 1)
	_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))

func _stock_string() -> String:
	var pend := ""
	if not _pending.is_empty():
		var soon := 999.0
		for o in _pending:
			soon = minf(soon, float(o.t))
		pend = " · 🚚 unterwegs (%ds)" % int(ceil(soon))
	return "Lager: 🍺 %d · 🥨 %d%s" % [int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]), pend]

# ================================================= E3: Personal
## Wiesenbüro: Mitarbeiter einstellen (1 Koch, 2 Kellner, 3 Reinigung).
@rpc("any_peer", "reliable")
func net_hire_staff(role: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not STAFF_HIRE_COST.has(role):
		return
	var cost: int = STAFF_HIRE_COST[role]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (%s: %d€)" % [STAFF_NAMES[role], cost])
		return
	Game.add_money(-cost)
	var id := _staff_next
	_staff_next += 1
	var start: Vector3 = KITCHEN_POINT if role == ROLE_KOCH else BAR_POINT
	_staff_sim[id] = {
		"role": role, "level": 1, "pos": start, "tgt": start, "yaw": 0.0,
		"state": 0, "timer": 0.0, "orders": [], "idx": 0
	}
	_add_staff.rpc(id, start, role, 1)
	_net_banner.rpc("🤝 %s Lv1 eingestellt! Lohn: %d€/Schicht" % [STAFF_NAMES[role], STAFF_WAGE_BASE[role]])
	_broadcast_meta()

## Wiesenbüro: schwächsten Mitarbeiter dieser Rolle aufstufen.
@rpc("any_peer", "reliable")
func net_upgrade_staff(role: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var target := -1
	var low := 999
	for sid in _staff_sim.keys():
		var s: Dictionary = _staff_sim[sid]
		if int(s.role) == role and int(s.level) < low and int(s.level) < STAFF_MAX_LEVEL:
			low = int(s.level)
			target = sid
	if target < 0:
		_net_banner.rpc("Kein %s zum Aufstufen (oder schon Lv%d)" % [STAFF_NAMES.get(role, "?"), STAFF_MAX_LEVEL])
		return
	var cost: int = STAFF_UPGRADE_BASE * low
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (Aufstufen: %d€)" % cost)
		return
	Game.add_money(-cost)
	var s2: Dictionary = _staff_sim[target]
	s2.level = low + 1
	_staff_sim[target] = s2
	_set_staff_info.rpc(target, role, int(s2.level))
	var extra := ""
	if role == ROLE_KELLNER:
		extra = " — trägt jetzt %d Krüge" % int(WAITER_CAPACITY.get(int(s2.level), 1))
	_net_banner.rpc("⬆️ %s → Lv%d%s" % [STAFF_NAMES[role], int(s2.level), extra])
	_broadcast_meta()

func _staff_save_list() -> Array:
	var out := []
	for s in _staff_sim.values():
		out.append({"role": int(s.role), "level": int(s.level)})
	return out

## Beim Laden: Mitarbeiter ohne Kosten wiederherstellen.
func _restore_staff(role: int, level: int) -> void:
	if not STAFF_HIRE_COST.has(role):
		return
	var id := _staff_next
	_staff_next += 1
	var start: Vector3 = KITCHEN_POINT if role == ROLE_KOCH else BAR_POINT
	_staff_sim[id] = {
		"role": role, "level": clampi(level, 1, STAFF_MAX_LEVEL), "pos": start, "tgt": start,
		"yaw": 0.0, "state": 0, "timer": 0.0, "orders": [], "idx": 0
	}
	_add_staff.rpc(id, start, role, clampi(level, 1, STAFF_MAX_LEVEL))

func _staff_wage(role: int, level: int) -> int:
	return int(round(float(STAFF_WAGE_BASE[role]) * (1.0 + 0.3 * (float(level) - 1.0))))

func _total_wages() -> int:
	var w := 0
	for s in _staff_sim.values():
		w += _staff_wage(int(s.role), int(s.level))
	return w

func _cook_level() -> int:
	var lv := 0
	for s in _staff_sim.values():
		if int(s.role) == ROLE_KOCH:
			lv = maxi(lv, int(s.level))
	return lv

## Ohne Koch dauert Essen 3× so lange.
func _food_prep_time() -> float:
	var lv := _cook_level()
	if lv <= 0:
		return FOOD_PREP * 3.0
	return FOOD_PREP / (1.0 + 0.15 * float(lv))

func _staff_string() -> String:
	if _staff_sim.is_empty():
		return "Personal: — (Wiesenbüro → Personal)"
	var counts := {}
	for s in _staff_sim.values():
		var r := int(s.role)
		if not counts.has(r):
			counts[r] = []
		(counts[r] as Array).append(int(s.level))
	var parts := []
	for r in [ROLE_KOCH, ROLE_KELLNER, ROLE_REINIGUNG]:
		if counts.has(r):
			var lv: Array = counts[r]
			lv.sort()
			parts.append("%s ×%d (Lv %s)" % [STAFF_NAMES[r], lv.size(), ",".join(lv.map(func(x): return str(x)))])
	return "Personal: " + " · ".join(parts) + " — Lohn %d€/Schicht" % _total_wages()

## Bewegung Richtung tgt. true = angekommen.
func _staff_move(s: Dictionary, delta: float) -> bool:
	var to: Vector3 = s.tgt - s.pos
	to.y = 0
	var d := to.length()
	if d <= 0.35:
		return true
	var dir := to.normalized()
	# Tische umlaufen — aber nur solange das Ziel weit weg ist, sonst käme
	# der Kellner nie an einem Sitzplatz an (der liegt direkt am Tisch).
	if d > 2.6:
		dir = _avoid_tables(s.pos, dir)
	# Blickrichtung weich nachziehen und IMMER vorwärts laufen,
	# sonst schlurfen die Mitarbeiter seitlich oder rückwärts.
	var want := atan2(-dir.x, -dir.z)
	s.yaw = lerp_angle(float(s.yaw), want, clampf(delta * 7.0, 0.0, 1.0))
	var fwd := Vector3(-sin(float(s.yaw)), 0.0, -cos(float(s.yaw)))
	var sp: float = STAFF_BASE_SPEED * (0.7 + 0.06 * float(s.level))
	if fwd.dot(dir) > 0.2:
		s.pos += fwd * minf(sp * delta, d)
	return false
func _avoid_tables(pos: Vector3, dir: Vector3) -> Vector3:
	var out := dir
	for bt in _beertables:
		var c: Vector3 = (bt as Node3D).global_position
		var away: Vector3 = pos - c
		away.y = 0
		var dist := away.length()
		if dist < TABLE_AVOID_RADIUS and dist > 0.01:
			out += away.normalized() * (1.0 - dist / TABLE_AVOID_RADIUS) * 1.8
	out.y = 0
	return out.normalized() if out.length() > 0.01 else dir
func _update_staff(delta: float) -> void:
	for sid in _staff_sim.keys():
		var s: Dictionary = _staff_sim[sid]
		match int(s.role):
			ROLE_KELLNER:
				_update_waiter(s, sid, delta)
			ROLE_REINIGUNG:
				_update_cleaner(s, delta)
			_:
				s.tgt = KITCHEN_POINT
				_staff_move(s, delta)
		_staff_sim[sid] = s
		var node = _staff.get(sid)
		if node:
			node.set_net(s.pos, s.yaw)

## Kellner: Bestellungen sammeln (Level = Anzahl Krüge) → Theke → ausliefern.
func _update_waiter(s: Dictionary, sid: int, delta: float) -> void:
	match int(s.state):
		0:
			var picked := []
			var cap: int = int(WAITER_CAPACITY.get(int(s.level), 1))
			for gid in _guest_sim.keys():
				if picked.size() >= cap:
					break
				var g: Dictionary = _guest_sim[gid]
				# Ohne Bestand nicht annehmen — sonst läuft der Kellner umsonst
				if int(g.ostate) == 1 and not _assigned.has(gid) and _has_stock(int(g.okind)):
					picked.append(gid)
					_assigned[gid] = sid
			if picked.is_empty():
				s.tgt = BAR_POINT
				_staff_move(s, delta)
				return
			s.orders = picked
			s.tgt = BAR_POINT
			s.state = 1
		1:
			if _staff_move(s, delta):
				var t := 0.0
				for gid in s.orders:
					if _guest_sim.has(gid):
						if int(_guest_sim[gid].okind) == 2:
							t += _food_prep_time()
						else:
							t += DRINK_PREP
				s.timer = t
				s.state = 2
		2:
			s.timer -= delta
			if s.timer <= 0.0:
				s.idx = 0
				s.state = 3
		3:
			var orders: Array = s.orders
			while int(s.idx) < orders.size() and not _guest_sim.has(orders[int(s.idx)]):
				_assigned.erase(orders[int(s.idx)])
				s.idx = int(s.idx) + 1
			if int(s.idx) >= orders.size():
				s.orders = []
				s.state = 0
				return
			var gid2: int = orders[int(s.idx)]
			var g2: Dictionary = _guest_sim[gid2]
			var seat := int(g2.seat)
			if seat < 0 or seat >= _seats.size():
				_assigned.erase(gid2)
				s.idx = int(s.idx) + 1
				return
			s.tgt = _seats[seat].pos
			if _staff_move(s, delta):
				_serve_by_staff(gid2)
				_assigned.erase(gid2)
				s.idx = int(s.idx) + 1

## Reinigung: läuft zum nächsten Dreck und putzt ihn weg.
func _update_cleaner(s: Dictionary, delta: float) -> void:
	if _messes.is_empty():
		s.tgt = BAR_POINT + Vector3(-4.0, 0, 3.0)
		_staff_move(s, delta)
		return
	var best := -1
	var bestd := 1.0e9
	for mid in _messes.keys():
		var m := _messes[mid] as Node3D
		if m == null:
			continue
		var d: float = (m.global_position - s.pos).length()
		if d < bestd:
			bestd = d
			best = mid
	if best < 0:
		return
	var mn := _messes[best] as Node3D
	s.tgt = mn.global_position
	if _staff_move(s, delta):
		var rate: float = 0.2 + 0.06 * float(s.level)
		_mess_clean[best] = float(_mess_clean.get(best, 0.0)) + rate * delta
		if float(_mess_clean[best]) >= 1.0:
			# Trinkgeld gibt es auch, wenn die Reinigungskraft putzt
			var tip := randi_range(CLEAN_TIP_MIN, CLEAN_TIP_MAX)
			_add_income(tip)
			_last_earn += tip
			_clean_tips += tip
			_remove_mess.rpc(best)

## Mitarbeiter serviert: volle Bezahlung, aber kein Trinkgeld (das bekommt nur der Chef).
func _serve_by_staff(gid: int) -> void:
	if not _guest_sim.has(gid):
		return
	var g: Dictionary = _guest_sim[gid]
	if int(g.ostate) != 1:
		return
	if not _has_stock(int(g.okind)):
		return
	_consume_stock(int(g.okind))
	g.ostate = 2
	g.served_t = SERVED_SHOW
	_guest_sim[gid] = g
	_served += 1
	g.drinks = int(g.get("drinks", 0)) + 1
	_quest_served_once = true
	_popularity = minf(100.0, _popularity + POP_SERVE)
	var hyg := 0.4 + 0.6 * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind)) * hyg * (1.0 + DEKO_BONUS * _upg_deko))
	_last_earn += reward
	Game.add_score(reward)
	_add_income(reward)

@rpc("authority", "reliable", "call_local")
func _add_staff(id: int, pos: Vector3, role: int, level: int) -> void:
	if _staff.has(id):
		return
	var n := STAFF_SCENE.instantiate()
	n.staff_id = id
	n.position = pos
	_staff_container.add_child(n)
	n.set_info(role, level)
	_staff[id] = n

@rpc("authority", "reliable", "call_local")
func _set_staff_info(id: int, role: int, level: int) -> void:
	var n = _staff.get(id)
	if n:
		n.set_info(role, level)

@rpc("authority", "unreliable")
func _net_staff(ids: PackedInt32Array, sx: PackedFloat32Array, sz: PackedFloat32Array, syaw: PackedFloat32Array, scarry: PackedInt32Array) -> void:
	for i in range(ids.size()):
		var n = _staff.get(ids[i])
		if n:
			n.set_net(Vector3(sx[i], 0.1, sz[i]), syaw[i])
			if i < scarry.size() and n.has_method("set_carrying"):
				n.set_carrying(scarry[i])

## Wiesenbüro: Lizenz kaufen (weizen/radler/brezn/sosis).
@rpc("any_peer", "reliable")
func net_buy_license(key: String) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not LIC_COST.has(key):
		return
	if _lic.get(key, false):
		_net_banner.rpc("✅ %s lisansı zaten var" % LIC_NAMES[key])
		return
	var cost: int = LIC_COST[key]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_net_banner.rpc("💶 Yetersiz para! (%s: %d€)" % [LIC_NAMES[key], cost])
		return
	Game.add_money(-cost)
	_lic[key] = true
	_net_banner.rpc("📜 %s lisansı alındı! Artık satabilirsin." % LIC_NAMES[key])
	_broadcast_meta()

func _lic_string() -> String:
	var have := []
	for k in LIC_COST.keys():
		if _lic.get(k, false):
			have.append(LIC_NAMES[k])
	if have.is_empty():
		return "Lizenz: nur 🍺 Helles"
	return "Lizenz: 🍺 Helles, " + ", ".join(have)

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
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
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
	if _active_count <= 0:
		_net_banner.rpc("🪑 Önce en az bir masa yerleştir!")
		return
	# Uyu → ertesi sabah 07:00, zelt açılır. Misafirler 08:00'de gelmeye başlar.
	net_sleep_fade.rpc()
	_start_shift()
	_net_banner.rpc("😴 Wiesn-Tag %d/%d · 07:00 — Zelt açık!\n🕗 08:00'de misafirler gelmeye başlar · 22:00 Feierabend\n%s" % [
		_day, WIESN_DAYS, _lic_string()])

## Kiosk: Tisch verkaufen (yarı fiyat iade).
@rpc("any_peer", "reliable")
func net_sell_table() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _active_count <= 0:
		_net_banner.rpc("🪑 Satılacak masa yok")
		return
	_active_count -= 1
	_add_income(int(TABLE_COST / 2))
	_apply_tent()
	_net_banner.rpc("🪑 Masa satıldı (+%d€) · %d masa kaldı" % [int(TABLE_COST / 2), _active_count])
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
	if not _has_stock(int(g.okind)):
		_net_banner.rpc("📦 Lager leer! %s nachbestellen (Wiesenbüro → Ware)" % WARE_NAMES[WARE_ESSEN if int(g.okind) == 2 else WARE_BIER])
		return
	_consume_stock(int(g.okind))
	g.ostate = 2
	g.served_t = SERVED_SHOW
	_guest_sim[id] = g
	_served += 1
	g.drinks = int(g.get("drinks", 0)) + 1
	_quest_served_once = true
	_popularity = minf(100.0, _popularity + POP_SERVE)
	var waiter_npc := _npc_roles.has(ROLE_WAITER)
	var hyg := 0.4 + 0.6 * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind)) * hyg * (1.0 + DEKO_BONUS * _upg_deko))
	var tip := 0 if waiter_npc else randi_range(0, 5)
	if waiter_npc:
		reward = int(reward * 0.5)
	_last_earn += reward + tip
	Game.add_score(reward)
	_add_income(reward + tip)

## Verkaufspreis je Bestellung. Einkauf: Bier 4€, Zutaten 5€ pro Einheit —
## damit bleibt genug Marge, um Miete und Löhne zu tragen.
func _reward_for(okind: int) -> int:
	return 14 if okind == 2 else 15

func CustomerReward() -> int:
	return 15
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if Net.dedicated and _players_nodes.is_empty():
		return
	if _phase == Phase.SHIFT:
		_phase_time -= delta
		_shift_process(delta)
		if _phase_time <= 0.0:
			_end_shift(0)   # 22:00 — normal kapanış
	elif not _guest_sim.is_empty():
		# Nach Feierabend laufen die restlichen Gäste noch hinaus
		_update_guests(delta)
	_update_delivery(delta)   # Lieferungen laufen in beiden Phasen
	_apply_crowd(_clock_hour())   # Host: Besuchermenge draußen
	_apply_stage(_clock_hour() >= 0.0)
	_apply_daylight(_clock_hour())
	# Tutorial: Fortschritt regelmäßig prüfen (Bedingungen ändern sich im Spiel)
	_quest_timer -= delta
	if _quest_timer <= 0.0:
		_quest_timer = 1.0
		if _check_quest():
			_broadcast_meta()
	_update_held_tables()
	_sync_timer -= delta
	if _sync_timer <= 0.0:
		_sync_timer = SYNC_INTERVAL
		_broadcast_sync()

func _shift_process(delta: float) -> void:
	# Popülerliğe + saate göre misafir çağır (sabah az, akşam çok; 08:00'den önce yok)
	_guest_spawn_timer -= delta
	if _guest_spawn_timer <= 0.0:
		_guest_spawn_timer = GUEST_SPAWN_INTERVAL
		var draw := 1.0
		if _artist_tier > 0:
			draw += float(ARTIST_DRAW[_artist_tier])
		var target := int(round(_popularity / 100.0 * float(_seats.size()) * _time_factor() * draw))
		if _guest_sim.size() < target:
			_spawn_guest()
	# Akşam: 19:00'dan sonra karanlık + sabırsızlık
	if not _night and _clock_hour() >= NIGHT_HOUR:
		_night = true
		_apply_night_visual(true)   # host görseli
		_net_banner.rpc("🌙 Akşam oldu (19:00)! Zelt doluyor, misafirler sabırsız 🍻")
	_update_guests(delta)
	_update_staff(delta)
	_update_complaints(delta)
	_update_hygiene(delta)

func _start_shift() -> void:
	_phase = Phase.SHIFT
	_phase_time = SHIFT_TIME
	_served = 0
	_missed = 0
	_last_earn = 0
	_guest_spawn_timer = 1.0
	_hygiene = 100.0
	_night = false
	_apply_night_visual(false)
	_did_shift = true
	_held.clear()
	_rebuild_seats()   # taşınmış masalara göre koltukları güncelle
	_clear_messes()
	_shift_num += 1
	_npc_roles = {}          # E3: Aushilfs-NPCs entfallen — echtes Personal übernimmt
	_assigned.clear()
	_spawn_artists()          # E5: gebuchter Künstler betritt die Bühne
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		st.state = 0
		st.orders = []
		st.idx = 0
		st.timer = 0.0
		_staff_sim[sid] = st
	_broadcast_meta()   # banner'ı net_sleep gönderir (gün başlangıcı mesajı)

## Günü bitir. reason: 0 = 22:00 normal, 1 = çok şikayet, 2 = oyuncu erken kapattı.
func _end_shift(reason := 0) -> void:
	var closed_at: float = _clock_hour()          # faz değişmeden önce oku
	var hours_left: float = maxf(0.0, DAY_END_HOUR - closed_at)
	_phase = Phase.INTERMISSION
	_phase_time = 0.0
	_night = false
	_apply_night_visual(false)
	# Tüm misafirleri çıkışa yolla
	for gid in _guest_sim.keys():
		_guest_sim[gid].mode = 2
		_guest_sim[gid].tgt = ENTRANCE
		_guest_sim[gid].ostate = 0
	_clear_messes()
	_clear_artists()          # E5: Auftritt vorbei
	_artist_tier = 0

	# Erken kapatma → popülerlik cezası (ne kadar erken, o kadar çok)
	var pop_penalty := 0.0
	if reason == 2:
		pop_penalty = hours_left * POP_EARLY_CLOSE_PER_HOUR
		_popularity = maxf(5.0, _popularity - pop_penalty)

	# Günlük bilanço: kira + personel maaşları
	var rent := _daily_rent()
	var wages := _total_wages()
	_wages_last = wages
	Game.add_money(-rent - wages)
	var goods := _goods_cost      # schon beim Bestellen bezahlt, hier nur ausgewiesen
	var net_profit := _last_earn - rent - wages - goods - _interest_paid
	var head := ""
	match reason:
		1: head = "🚫 Çok şikayet! Zelt erken kapandı 😅"
		2: head = "🚪 Zelti %02d:00'da kapattın · Popülerlik -%.0f%%" % [int(closed_at), pop_penalty]
		_: head = "🌙 22:00 — Feierabend!"
	var report := "%s\n\n📊 TAG %d\nUmsatz  %d€   (davon Trinkgeld fürs Putzen %d€)\nMiete  -%d€\nLöhne  -%d€\nWare   -%d€\nZinsen -%d€\n───────────────\nNetto  %s%d€\n\nServiert %d · Verpasst %d\n🚻 Urin %d · Beschwerden %d · Gäste weg %d" % [
		head, _day, _last_earn, _clean_tips, rent, wages, goods, _interest_paid,
		"+" if net_profit >= 0 else "", net_profit,
		_served, _missed, _urin_count, _complaints, _left_guests]
	net_report.rpc(report)
	_net_banner.rpc("%s\n📊 Tag %d · Umsatz %d€ · Miete -%d€ · Löhne -%d€ · Ware -%d€ · Netto %s%d€\n😴 Wohnwagen: schlafen → neuer Tag  ·  Bilanz: Wiesenbüro → 📊" % [
		head, _day, _last_earn, rent, wages, goods, "+" if net_profit >= 0 else "", net_profit])
	_clean_tips = 0
	_interest_paid = 0
	_goods_cost = 0
	_urin_count = 0
	_complaints = 0
	_left_guests = 0
	_day += 1
	if _day > WIESN_DAYS:
		_day = 1
	_broadcast_meta()

## Bilgisayardan zelti erken kapat (popülerlik cezası).
@rpc("any_peer", "reliable")
func net_close_tent() -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	_end_shift(2)

# ---- Misafirler ----
func _free_seat() -> int:
	# Gäste auf die Tische verteilen: der am wenigsten besetzte Tisch zuerst.
	# Rein zufällig blieb bei wenig Andrang sonst ein Tisch den ganzen Tag leer.
	var occupied := {}
	for s in _seats:
		var t := int(s.get("table", 0))
		if not occupied.has(t):
			occupied[t] = 0
		if int(s.guest) != -1:
			occupied[t] = int(occupied[t]) + 1
	var best := -1
	var free := []
	for i in _seats.size():
		if int(_seats[i].guest) != -1:
			continue
		var t := int(_seats[i].get("table", 0))
		var o := int(occupied.get(t, 0))
		if best < 0 or o < best:
			best = o
			free = [i]
		elif o == best:
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
		"cooldown": randf_range(8.0, 20.0), "served_t": 0.0,
		"bladder": randf_range(BLADDER_MIN, BLADDER_MAX), "pee_t": 0.0,
		"drinks": 0, "puke_t": 0.0, "puked": false
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
		# E6: Blase (sitzend oder auf dem Weg zur Ecke/Toilette)
		if g.mode == 4:
			_update_puke(g, id, delta)
		if g.mode == 1 or g.mode == 3:
			_update_bladder(g, id, delta)
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
			var foods: Array = _foods_avail()
			# Yemek lisansı yoksa sadece içecek istenir
			if foods.is_empty() or randf() < 0.6:
				g.okind = 1
				g.otype = _drinks_avail().pick_random()
			else:
				g.okind = 2
				g.otype = foods.pick_random()
			g.patience = ORDER_PATIENCE
	elif g.ostate == 1:
		g.patience -= delta * (PATIENCE_NIGHT_MULT if _night else 1.0)
		if g.patience <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
			_missed += 1
			Game.add_score(-MISS_PENALTY)
			_popularity = maxf(5.0, _popularity - POP_MISS)
			if _missed >= 20:
				_end_shift(1)
	elif g.ostate == 2:
		g.served_t -= delta
		if g.served_t <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
	# Sarhoş: ara sıra kus + kir bırak (C3)
	# Betrunken: erst nach ein paar Bier, dann steht der Gast auf und geht
	# ein paar Schritte vom Tisch weg, bevor er sich übergibt.
	if int(g.get("drinks", 0)) >= DRINKS_BEFORE_PUKE and randf() < MESS_CHANCE_PER_SEC * delta:
		var seat: Dictionary = _seats[int(g.seat)]
		g.mode = 4
		g.ostate = 0
		g.puke_t = 7.0
		g.puked = false
		g.tgt = (seat.pos as Vector3) + (seat.get("away", Vector3.FORWARD) as Vector3) * 3.2

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

## C3: misafir kusma animasyonunu tetikle (nadir olay, reliable).
@rpc("authority", "reliable", "call_local")
func _net_guest_vomit(id: int) -> void:
	var c = _guests.get(id)
	if c and c.has_method("play_vomit"):
		c.play_vomit()

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
	_spawn_mess_at(Vector3(p.x + off.x, 0.02, p.z + off.z), 0)

## kind: 0 = Erbrochenes, 1 = Urin
func _spawn_mess_at(p: Vector3, kind: int) -> void:
	var id := _mess_next
	_mess_next += 1
	_mess_clean[id] = 0.0
	_mess_kind[id] = kind
	_add_mess.rpc(id, Vector3(p.x, 0.02, p.z), kind)

@rpc("authority", "reliable", "call_local")
func _add_mess(id: int, pos: Vector3, kind: int = 0) -> void:
	if _messes.has(id):
		return
	var m := MESS_SCENE.instantiate()
	m.mess_id = id
	m.position = pos
	_messes_container.add_child(m)
	m.set_kind(kind)
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
		# Trinkgeld fürs Saubermachen — nur wenn ein Spieler selbst putzt
		var tip := randi_range(CLEAN_TIP_MIN, CLEAN_TIP_MAX)
		_add_income(tip)
		_last_earn += tip
		_clean_tips += tip
		_remove_mess.rpc(id)
		_net_banner.rpc("🧽 Sauber! Trinkgeld +%d€" % tip)

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
	# Personal
	var sids := PackedInt32Array()
	var sx := PackedFloat32Array()
	var sz := PackedFloat32Array()
	var syaw := PackedFloat32Array()
	var scarry := PackedInt32Array()
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		sids.append(sid)
		sx.append(st.pos.x)
		sz.append(st.pos.z)
		syaw.append(st.yaw)
		# Krüge in der Hand: nur beim Ausliefern
		var carr := 0
		if int(st.role) == ROLE_KELLNER and int(st.state) == 3:
			carr = maxi(0, (st.orders as Array).size() - int(st.idx))
		scarry.append(carr)
	if sids.size() > 0:
		_net_staff.rpc(sids, sx, sz, syaw, scarry)
	# Çevre
	var ids := PackedInt32Array()
	var pr := PackedFloat32Array()
	for mid in _messes.keys():
		ids.append(mid)
		pr.append(float(_mess_clean.get(mid, 0.0)))
	_net_env.rpc(Game.money, Game.score, _clock_hour(), _hygiene, _popularity, ids, pr, _night)
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
func _net_env(money: int, score: int, clock: float, hygiene: float, pop: float, ids: PackedInt32Array, pr: PackedFloat32Array, night: bool) -> void:
	_hud.set_money(money)
	_hud.set_score(score)
	_hud.set_time(clock, night)
	_hud.set_hygiene(hygiene)
	_hud.set_popularity(pop)
	_apply_daylight(clock)
	_apply_crowd(clock)
	_apply_stage(clock >= 0.0)
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
	return "%s · Masa: %d/%d · Koltuk: %d · Popülerlik: %d%%\nKira/gün: %d€ · Wiesn-Tag: %d/%d · 📣Werbung Lv%d · 🎨Deko Lv%d\n%s" % [
		TENT_STAGE_NAMES[_tent_stage], _active_count, limit, _seats.size(),
		int(round(_popularity)), _daily_rent(), _day, WIESN_DAYS, _upg_marketing, _upg_deko,
		_lic_string() + "\n" + _stock_string() + "\n" + _artist_string() + " · " + _toilet_string()]

func _broadcast_meta() -> void:
	_check_quest()
	net_meta.rpc(_phase, _staff_string(), _mgmt_string(), _day, _tent_stage, _active_count, _quest_text())
	_save_game()   # E3: her durum değişiminde ilerlemeyi kaydet

@rpc("authority", "reliable", "call_local")
func net_meta(phase: int, roster: String, mgmt: String, day: int, tent_stage: int, active_count: int, quest: String) -> void:
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
	_hud.set_quest(quest)
	if _sfx_node:
		if phase == Phase.SHIFT:
			_sfx_node.play_music()
		else:
			_sfx_node.stop_music()

@rpc("authority", "reliable", "call_local")
func _net_banner(text: String) -> void:
	_hud.show_banner(text)

## Kotz-Ablauf: Gast läuft vom Tisch weg, übergibt sich dort, geht zurück.
func _update_puke(g: Dictionary, id: int, delta: float) -> void:
	g.puke_t = float(g.puke_t) - delta
	var d: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
	d.y = 0
	if not bool(g.get("puked", false)) and d.length() < 0.7:
		g.puked = true
		g.drinks = 0
		_net_guest_vomit.rpc(id)
		_spawn_mess_at(g.pos as Vector3, 0)
	if float(g.puke_t) <= 0.0:
		g.mode = 1
		g.tgt = _seats[int(g.seat)].pos

## Kurze Schwarzblende beim Schlafen (bei allen Spielern).
@rpc("authority", "reliable", "call_local")
func net_sleep_fade() -> void:
	if _hud and _hud.has_method("play_sleep_fade"):
		_hud.play_sleep_fade()

## Letzte Tagesbilanz — im Wiesenbüro jederzeit nachlesbar.
@rpc("authority", "reliable", "call_local")
func net_report(text: String) -> void:
	_last_report = text
	if _hud and _hud.has_method("set_report"):
		_hud.set_report(text)

## Reicht das Geld — inklusive Dispo bis -1000€?
func _afford(cost: int) -> bool:
	return Game.money - cost >= -OVERDRAFT_LIMIT

## Einnahmen. Steht das Konto im Minus, gehen 5% Zinsen vom Betrag ab,
## der die Schulden tilgt.
func _add_income(amount: int) -> void:
	if amount <= 0:
		Game.add_money(amount)
		return
	if Game.money < 0:
		var debt: int = -Game.money
		var repay: int = mini(amount, debt)
		var interest: int = int(ceil(float(repay) * OVERDRAFT_INTEREST))
		_interest_paid += interest
		Game.add_money(amount - interest)
	else:
		Game.add_money(amount)
