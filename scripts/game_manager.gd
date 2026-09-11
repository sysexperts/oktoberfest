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

# Roller
const ROLE_NONE := 0
const ROLE_KITCHEN := 1
const ROLE_CLEAN := 2
const ROLE_WAITER := 3

# Misafir / sipariş / popülerlik
const ENTRANCE := Vector3(0, 0.1, 12.0)
## Gäste kommen durchs Kirmes-Haupttor und laufen über den Weg ins Zelt.
const HAUPTTOR := Vector3(6.8, 0.1, 25.5)
const WEG_REIN := [Vector3(6.8, 0.1, 19.0), Vector3(0.0, 0.1, 19.0), Vector3(0.0, 0.1, 12.0)]
const WEG_RAUS := [Vector3(0.0, 0.1, 19.0), Vector3(6.8, 0.1, 19.0), Vector3(6.8, 0.1, 25.5)]
## So viele Sekunden nach dem Aufwachen machen sich die ersten Gäste auf den Weg
## (plus der Fußweg vom Tor) — der Tag beginnt ruhig.
const ERSTE_GAESTE_MIN := 45.0
const ERSTE_GAESTE_MAX := 75.0
const CUST_SPEED := 3.0
const GUEST_SPAWN_INTERVAL := 2.0
## Anteil der Plätze, der auch bei geringer Beliebtheit belegt wird
const GRUNDANDRANG := 0.4
## Ab dieser Uhrzeit kommt der volle Andrang
const VOLL_AB_STUNDE := 13.0
## Einrichtung (Lampen, Deko): Katalog, Obergrenze, Tragabstand, Anziehung
const Katalog := preload("res://scripts/einrichtung_katalog.gd")
const DEKO_MAX := 16
const DEKO_ABSTAND := 1.8
const DEKO_ANDRANG := 0.02        # je Gegenstand 2 % mehr Gäste …
const DEKO_ANDRANG_MAX := 0.2     # … höchstens 20 %
## Abgestellt wird nur innerhalb der Zeltwände
const ZELT_MIN := Vector3(-11.3, 0, -8.0)
const ZELT_MAX := Vector3(11.3, 0, 10.6)
const ORDER_PATIENCE := 38.0        # sabır (servis için süre) — artırıldı
const ORDER_COOLDOWN_MIN := 18.0    # Pause zwischen zwei Bestellungen eines Gasts
const ORDER_COOLDOWN_MAX := 35.0    # (vorher 22–45 s; 15–30 war allein nicht zu schaffen)
const SERVED_SHOW := 3.0
const NIGHT_FRACTION := 0.25        # son %25 = "gece" (PlateUp tarzı endspurt)
const PATIENCE_NIGHT_MULT := 1.8    # gece sabır daha hızlı azalır
const POP_START := 20.0             # az misafirle başla
const POP_SERVE := 1.5
const POP_MISS := 2.0
## Trinkgeld, wenn der Spieler selbst bedient (vorher 0–5 €)
const TRINKGELD_MIN := 2
const TRINKGELD_MAX := 8
const MESS_CHANCE_PER_SEC := 0.02   # Wahrscheinlichkeit pro Sekunde
const DRINKS_BEFORE_PUKE := 4       # so viele Getränke, bevor jemandem schlecht wird

# Temizlik
const CLEAN_PER_CALL := 0.05
const CLEAN_TIP_MIN := 6      # Trinkgeld fürs Saubermachen
const CLEAN_TIP_MAX := 12
const HYGIENE_DRAIN := 0.4   # je Fleck pro Sekunde (1.2 hielt die Sauberkeit dauerhaft bei 0)
## Anteil der Einnahmen, der auch im dreckigsten Zelt bleibt (vorher 40 %)
const HYGIENE_MIN_ANTEIL := 0.7
const HYGIENE_REGEN := 1.0
const NPC_CLEAN_RATE := 0.06
const START_MONEY := 1200   # Startbudget: Zelt 500 + 2 Tische 400 + 1 Paket Bier 60

# Zelt / makro-döngü (Wasenplatz mantığı)
const TENT_TABLE_LIMIT := {0: 0, 1: 4, 2: 8, 3: 12}   # sahnede 12 masa var
const TENT_BOOK_COST := 500
const TENT_UPGRADE_COST := {2: 2000, 3: 6000}   # vorher 3000/10000: im Bot nie erreicht
const TABLE_COST := 200
## Zeltmiete pro Tag am ersten Tag — steigt danach mit Wirtschaft.miete.
const TENT_RENT := {0: 0, 1: 120, 2: 220, 3: 450}   # vorher 300/700: großes Zelt machte Verlust
# Upgrades (kiosk)
const MARKETING_COST := 400   # her seviye +15 popülerlik enjeksiyonu
const MARKETING_BOOST := 15.0
const DEKO_COST := 600        # her seviye +%15 gelir
const DEKO_BONUS := 0.15
# E2.4 Lizenzen — başta sadece Helles satılır, gerisi Wiesenbüro'dan alınır
const LIC_COST := {"weizen": 800, "radler": 800, "brezn": 1200, "sosis": 1200}

# ---- E3: Personal ----
const STAFF_SCENE := preload("res://scenes/staff.tscn")
const ROLE_KOCH := 1
const ROLE_KELLNER := 2
const ROLE_REINIGUNG := 3
const ROLE_ZAPFER := 4
const STAFF_HIRE_COST := {1: 600, 2: 500, 3: 400, 4: 450}
const STAFF_WAGE_BASE := {1: 120, 2: 100, 3: 80, 4: 90}   # Lohn/Schicht auf Level 1
const STAFF_UPGRADE_BASE := 400                     # × aktuelles Level
const STAFF_MAX_LEVEL := 5
## Wie viele Krüge ein Kellner auf einmal trägt — höhere Level sparen Laufwege.
## Stufe 1 trug nur 1 Krug — mit 4 Tischen blieben 20–35 Bestellungen am Tag liegen (Spielbot).
const WAITER_CAPACITY := {1: 2, 2: 3, 3: 5, 4: 8, 5: 12}
const STAFF_BASE_SPEED := 4.5   # vorher 3.0 — im großen Zelt blieben bis 100 Bestellungen liegen
const TABLE_AVOID_RADIUS := 2.2   # Mitarbeiter halten Abstand zu Tischen
const BAR_POINT := Vector3(-2.0, 0.1, -8.0)    # Kellner holt hier ab (vor der Ausgabe)
const KITCHEN_POINT := Vector3(6.5, 0.1, -10.4) # Koch steht hinter der Theke bei den Kochstellen
const ZAPFER_POINT := Vector3(-2.0, 0.1, -10.4) # Zapfer steht hinter der Theke an der Ausgabe
## Zapfer und Koch stellen Fertiges auf die Ausgabe (scenes/ausgabe.tscn).
const ZAPF_ZEIT := 2.2        # Sekunden pro Krug auf Stufe 1
const KOCH_ZEIT := 4.5        # Sekunden pro Portion auf Stufe 1
const AUSGABE_MAX_KRUEGE := 6 # + 2 je Stufe des Zapfers, höchstens 12 Plätze
const AUSGABE_MAX_ESSEN := 3  # + 1 je Stufe des Kochs, höchstens 6 Plätze
const DRINK_PREP := 1.5                        # Kellner zapft selbst, wenn kein Krug auf der Ausgabe steht
const FOOD_PREP := 3.0                         # Sekunden pro Speise (mit Koch)

# ---- E4: Ware & Lieferung ----
const PACKAGE_SCENE := preload("res://scenes/package.tscn")
const VAN_SCENE := preload("res://scenes/delivery_van.tscn")
const WARE_BIER := 1
const WARE_ESSEN := 2
const PACK_UNITS := 10                    # Einheiten pro Paket
const PACK_COST := {1: 40, 2: 50}         # Preis pro Paket (10 Einheiten)
const DELIVERY_DELAY := 30.0              # Lieferzeit nach Bestellung (Sekunden, vorher 60)
const VAN_START := Vector3(-42.0, 0.0, 19.0)
const VAN_DROP := Vector3(2.0, 0.0, 19.0)
const VAN_END := Vector3(42.0, 0.0, 19.0)
const VAN_SPEED := 9.0
const DROP_POINT := Vector3(0.0, 0.0, 15.5)   # wo die Pakete landen

# ---- E5: Bühne & Künstler ----
const ARTIST_SCENE := preload("res://scenes/artist.tscn")
const ARTIST_COST := {1: 500, 2: 2000, 3: 6000}
const ARTIST_COUNT := {1: 1, 2: 3, 3: 5}      # wie viele auf der Bühne stehen
const ARTIST_POP := {1: 5.0, 2: 12.0, 3: 25.0}  # Beliebtheitsschub beim Buchen
const ARTIST_DRAW := {1: 0.15, 2: 0.35, 3: 0.6} # zusätzliche Auslastung während der Schicht

# ---- E6: Klo, Urin, Beschwerden ----
const TOILET_COST := 1000   # vorher 1800 — fast so teuer wie der Zeltausbau
const BLADDER_MIN := 70.0        # Sekunden bis ein Gast muss
const BLADDER_MAX := 150.0
const PEE_CORNER := Vector3(-10.5, 0.1, 8.0)   # Ecke, in die ohne Klo gepinkelt wird
const TOILET_POINT := Vector3(10.5, 0.1, 8.0)  # Klo-Ecke (wenn gekauft)
const PEE_DURATION := 4.0
const COMPLAIN_INTERVAL := 6.0   # wie oft geprüft wird
const COMPLAIN_RADIUS := 5.0     # Umkreis eines Urinflecks
## Jeder Gast beschwert sich höchstens einmal — früher alle 6 s erneut, das
## trieb die Beliebtheit binnen Tagen auf 5 % (Spielbot, 30 Tage).
const COMPLAIN_POP := 1.0        # Beliebtheitsverlust pro Beschwerde
const LEAVE_CHANCE := 0.15       # Wahrscheinlichkeit, dass ein Gast deshalb geht
## Untergrenze der Beliebtheit — darunter kommt kaum noch jemand, das Spiel wäre verloren
const POP_MIN := 10.0
## Nächtliche Erholung: 25 % des Abstands zu 40 % Beliebtheit
const POP_ERHOLUNG_ZIEL := 40.0
const POP_ERHOLUNG := 0.25
## Höchstens so viel Beliebtheit kosten verpasste Bestellungen pro Tag —
## im großen Zelt waren es sonst 100 × 2 Punkte
const POP_MISS_TAG_MAX := 20.0
## Gute Stimmung: ab 17 Uhr (oder mit Künstler auf der Bühne) steigen Gäste auf
## die Tische und tanzen — je Tisch 2 oder 3, jeweils eine Weile.
const TANZ_AB_STUNDE := 17.0
const TANZ_BELIEBTHEIT := 55.0
const TANZ_SAUBERKEIT := 50.0
const TANZ_PRUEF_INTERVALL := 4.0
const TANZ_DAUER_MIN := 15.0
const TANZ_DAUER_MAX := 30.0
const TANZ_PLAETZE := [-0.6, 0.6, 0.0]   # Versatz entlang der Tischlänge

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
var _bierpreis := 1.0   # Faktor auf den Tagespreis je Maß (Zelt-Computer)
var _pop_verlust_heute := 0.0   # Beliebtheit, die verpasste Bestellungen heute schon gekostet haben
## Fertiges auf der Ausgabe: "art_typ" -> Anzahl (art 1 Getränk, 2 Essen).
## Verbraucht wird der Lagerbestand erst beim Servieren — deshalb nie mehr
## vorbereiten, als im Lager ist.
var _ausgabe := {}
var _tanz_timer := 0.0
var _ohne_ware_s := 0.0   # Sekunden heute, in denen Gäste warteten, das Lager aber leer war
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
var _last_report := {}   # Zahlen der letzten Tagesbilanz (siehe _end_shift)
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
# Meilensteine (Plan 3.2): Lebenszeit-Zähler und erreichte IDs, beides im Spielstand
const Meilensteine := preload("res://scripts/meilensteine.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
var _stats := {"served": 0, "earned": 0, "days": 0, "cleaned": 0}
var _meilensteine: Array = []
# Rettungskredit (Plan 3.5): offene Schuld bei der Brauerei, heute getilgt
var _kredit_rest := 0
var _kredit_heute := 0

# Koltuklar: her biri {pos:Vector3, yaw:float, guest:int}
var _seats: Array = []
var _all_tables: Array = []   # sahnedeki tüm bira masaları (kararlı sıra)
var _beertables: Array = []   # sadece aktif masalar (servis/oturma)
var _held := {}   # peer_id -> beertable idx (molada taşıma)
var _held_deko := {}          # peer_id -> Einrichtungs-ID, die er gerade trägt
var _einrichtung := {}        # id -> {art, x, z, rot} (Server, wird gespeichert)
var _einrichtung_nodes := {}  # id -> Einrichtung-Knoten (alle Rechner)
var _einrichtung_next := 1
var _einrichtung_container: Node3D
var _haelt_deko := {}         # vom Server: Peer-ID (Text) -> ID, für Hinweise beim Spieler
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
	_einrichtung_container = get_node_or_null("Einrichtung")
	if _einrichtung_container == null:
		_einrichtung_container = Node3D.new()
		_einrichtung_container.name = "Einrichtung"
		add_child(_einrichtung_container)
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
	_hud.set_phase(_phase == Phase.SHIFT)
	_hud.set_day(_day)
	_sichere_wohnwagen()

	if multiplayer.is_server():
		if Net.neues_spiel:
			_loesche_speicherstand()
			Game.add_money(START_MONEY)
		elif not _load_game():
			Game.add_money(START_MONEY)
		Net.neues_spiel = false
		# Erreichte Meilensteine nachtragen — falls Steam beim Erreichen nicht lief
		for ms_id: String in _meilensteine:
			SteamDienst.errungenschaft(ms_id)
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
		_client_ready.rpc_id(1, Net.version_text())
		# Antwortet der Server nicht (etwa ein älterer Stand, der die Nachricht
		# nicht versteht), nicht ewig in einer leeren Welt stehen
		get_tree().create_timer(SPAWN_WARTEZEIT).timeout.connect(_pruefe_eigenen_spieler)

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
	# ab Mittag voll, morgens schon gut die Hälfte
	return clampf(0.55 + 0.45 * ((h - GUEST_START_HOUR) / (VOLL_AB_STUNDE - GUEST_START_HOUR)), 0.0, 1.0)

# ================================================= kayıt (E3)
## Sunucuda ilerlemeyi diske yaz (para, gün, zelt, upgrade, masa konumları).
## "Neues Spiel" im Menue: alten Stand entfernen, damit "Weiterspielen" ihn
## nicht mehr anbietet, auch wenn vor dem ersten Speichern beendet wird.
func _loesche_speicherstand() -> void:
	var pfad := Net.speicherstand_pfad()
	if FileAccess.file_exists(pfad):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(pfad))

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
		"quest_version": QUEST_VERSION,
		"ever_artist": _ever_artist,
		"stats": _stats,
		"meilensteine": _meilensteine,
		# Formatversion: ältere Spielversionen laden keinen neueren Stand (Net.SAVE_FORMAT)
		"kredit": _kredit_rest,
		"bierpreis": _bierpreis,
		"einrichtung": _einrichtung.values(),
		"format": Net.SAVE_FORMAT,
		"saved_at": int(Time.get_unix_time_from_system()),
	}
	# Gespeichert wird bei jeder Zustandsänderung (_broadcast_meta) — also auch
	# beim Schlafen, wenn der neue Tag beginnt.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Net.SAVE_DIR))
	var f := FileAccess.open(Net.speicherstand_pfad(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

## Kayıt varsa yükle. Başarılıysa true.
func _load_game() -> bool:
	var pfad := Net.speicherstand_pfad()
	if not FileAccess.file_exists(pfad):
		return false
	var f := FileAccess.open(pfad, FileAccess.READ)
	if f == null:
		return false
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = parsed
	if int(d.get("format", 0)) > Net.SAVE_FORMAT:
		push_warning("Spielstand %s stammt aus einer neueren Version — nicht geladen." % pfad)
		return false
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
	# Alte Stände: Schritte ab 3 sind durch die zwei neuen Liefer-Schritte eins weiter
	if int(d.get("quest_version", 1)) < QUEST_VERSION and _quest_step >= 3:
		_quest_step += 1
	_ever_artist = bool(d.get("ever_artist", false))
	var gespeicherte_stats: Variant = d.get("stats", {})
	if gespeicherte_stats is Dictionary:
		for k in Meilensteine.ZAEHLER:
			_stats[k] = int((gespeicherte_stats as Dictionary).get(k, 0))
	var erreicht: Variant = d.get("meilensteine", [])
	if erreicht is Array:
		_meilensteine = (erreicht as Array).map(func(x: Variant) -> String: return str(x))
	_kredit_rest = maxi(0, int(d.get("kredit", 0)))
	_bierpreis = clampf(float(d.get("bierpreis", 1.0)), Wirtschaft.BIERPREIS_MIN, Wirtschaft.BIERPREIS_MAX)
	var einr: Variant = d.get("einrichtung", [])
	if einr is Array:
		for e: Variant in einr:
			if e is Dictionary and Katalog.ARTEN.has(str((e as Dictionary).get("art", ""))):
				var ed: Dictionary = e
				var did := _einrichtung_next
				_einrichtung_next += 1
				_einrichtung[did] = {"art": str(ed.art), "x": float(ed.get("x", 0.0)),
					"z": float(ed.get("z", 0.0)), "rot": float(ed.get("rot", 0.0))}
				_add_einrichtung(did, str(ed.art), float(_einrichtung[did].x), float(_einrichtung[did].z), float(_einrichtung[did].rot))
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
## Geduld je Bestellung — sinkt mit dem Spieltag (Wirtschaft.geduld).
func _geduld() -> float:
	return Wirtschaft.geduld(ORDER_PATIENCE, _day)

func _daily_rent() -> int:
	return Wirtschaft.miete(int(TENT_RENT.get(_tent_stage, 0)), _day)

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
## Sekunden, die ein Client nach dem Verbinden auf seinen Spieler wartet.
const SPAWN_WARTEZEIT := 15.0

func _pruefe_eigenen_spieler() -> void:
	if not multiplayer.is_server() and not _players_nodes.has(multiplayer.get_unique_id()):
		Net.trennen_mit_meldung("NET_NO_ANSWER")

## Server lehnt den Beitritt ab (z. B. andere Version) — beim Client.
@rpc("authority", "reliable")
func _net_abgelehnt(schluessel: String, werte: Array) -> void:
	Net.trennen_mit_meldung(schluessel, werte)

@rpc("any_peer", "reliable")
func _client_ready(version: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	# Unterschiedliche Stände verstehen ihre Nachrichten nicht — sauber ablehnen,
	# statt den Spieler in einer halb synchronen Welt stehen zu lassen.
	if version != Net.version_text():
		_net_abgelehnt.rpc_id(sender, "NET_VERSION_MISMATCH", [Net.version_text(), version])
		# Für jede Netzart (ENet oder Steam) — beide können einzelne Peers trennen
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var peer := multiplayer.multiplayer_peer
			if peer and not peer is OfflineMultiplayerPeer:
				peer.disconnect_peer(sender))
		return
	for pid in _spawn_index_by_peer.keys():
		_add_player.rpc_id(sender, pid, _spawn_index_by_peer[pid])
	var sidx := _next_spawn
	_next_spawn += 1
	_spawn_index_by_peer[sender] = sidx
	_add_player.rpc(sender, sidx)
	_melde("NET_PLAYER_JOINED", [], 2)
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
	for did in _einrichtung.keys():
		var e: Dictionary = _einrichtung[did]
		_add_einrichtung.rpc_id(sender, did, str(e.art), float(e.x), float(e.z), float(e.rot))
	_net_ausgabe.rpc_id(sender, _ausgabe)
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
	# Nur melden, wer wirklich im Spiel war — abgelehnte Beitritte nicht
	if _spawn_index_by_peer.has(peer_id):
		_melde("NET_PLAYER_LEFT")
	_spawn_index_by_peer.erase(peer_id)
	if _held_deko.has(peer_id):
		_deko_abstellen(peer_id)
	_remove_player.rpc(peer_id)
	_broadcast_meta()

# ================================================= Bierpreis
## Zelt-Computer: Bierpreis in 10-%-Schritten ändern — auch während der Schicht.
## Billig lockt mehr Gäste (Wirtschaft.preis_andrang), bringt aber weniger je Maß.
@rpc("any_peer", "reliable", "call_local")
func net_set_bierpreis(schritte: int) -> void:
	if not multiplayer.is_server():
		return
	var neu := snappedf(_bierpreis + 0.1 * float(clampi(schritte, -5, 5)), 0.1)
	_bierpreis = clampf(neu, Wirtschaft.BIERPREIS_MIN, Wirtschaft.BIERPREIS_MAX)
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

## „Zu vermieten"-Schild am Zelteingang: nur solange das Zelt noch frei ist.
func _vermietung_aktualisieren() -> void:
	for schild in get_tree().get_nodes_in_group("zelt_vermietung"):
		schild.frei_setzen(_tent_stage == 0)

## Zelt kiralamaya göre masaları aktif/pasif yap + koltukları kur.
func _apply_tent() -> void:
	_vermietung_aktualisieren()
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
@rpc("any_peer", "reliable", "call_local")
func net_book_tent() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION or _tent_stage != 0:
		return
	if not _afford(TENT_BOOK_COST):
		_fehler("MSG_NO_MONEY", ["OFFER_TENT_RENT", _eur(TENT_BOOK_COST)])
		return
	Game.add_money(-TENT_BOOK_COST)
	_tent_stage = 1
	_active_count = 0
	_apply_tent()
	_melde("MSG_TENT_RENTED", ["TENT_STAGE_1"], 2)
	_broadcast_meta()

## Kiosk: Tisch kaufen/platzieren (limit je Zeltstufe).
@rpc("any_peer", "reliable", "call_local")
func net_buy_table() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _tent_stage == 0:
		_fehler("MSG_NEED_TENT")
		return
	var limit: int = TENT_TABLE_LIMIT[_tent_stage]
	if _active_count >= limit:
		_fehler("MSG_TABLE_LIMIT", [limit])
		return
	if _active_count >= 2 and _kredit_sperrt():
		return
	# Die ersten zwei Tische sind Pflicht — dafür gilt die Warenreserve nicht
	if _active_count >= 2 and not _reserve_ok(TABLE_COST):
		return
	if not _afford(TABLE_COST):
		_fehler("MSG_NO_MONEY", ["OFFER_TABLE", _eur(TABLE_COST)])
		return
	Game.add_money(-TABLE_COST)
	_active_count += 1
	_apply_tent()
	_melde("MSG_TABLE_PLACED", [_active_count, limit], 2)
	_broadcast_meta()

## Kiosk: Werbung — anında popülerlik enjeksiyonu (her seviye daha pahalı).
@rpc("any_peer", "reliable", "call_local")
func net_buy_marketing() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _kredit_sperrt():
		return
	var cost := MARKETING_COST * (_upg_marketing + 1)
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", ["OFFER_MARKETING", _eur(cost)])
		return
	Game.add_money(-cost)
	_upg_marketing += 1
	_popularity = minf(100.0, _popularity + MARKETING_BOOST)
	_melde("MSG_MARKETING", [_upg_marketing, int(MARKETING_BOOST)], 2)
	_broadcast_meta()

## Kiosk: Deko — kalıcı gelir çarpanı.
@rpc("any_peer", "reliable", "call_local")
func net_buy_deko() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _kredit_sperrt():
		return
	var cost := DEKO_COST * (_upg_deko + 1)
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", ["OFFER_DEKO", _eur(cost)])
		return
	Game.add_money(-cost)
	_upg_deko += 1
	_melde("MSG_DEKO", [_upg_deko, int(DEKO_BONUS * _upg_deko * 100)], 2)
	_broadcast_meta()

# ================================================= E6: Klo & Beschwerden
## Wiesenbüro: Toilette einbauen — danach pinkelt niemand mehr in die Ecke.
@rpc("any_peer", "reliable", "call_local")
func net_buy_toilet() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _kredit_sperrt():
		return
	if _has_toilet:
		_fehler("MSG_TOILET_HAVE")
		return
	if _tent_stage == 0:
		_fehler("MSG_NEED_TENT")
		return
	if not _reserve_ok(TOILET_COST):
		return
	if not _afford(TOILET_COST):
		_fehler("MSG_NO_MONEY", ["OFFER_TOILET", _eur(TOILET_COST)])
		return
	Game.add_money(-TOILET_COST)
	_has_toilet = true
	_melde("MSG_TOILET_DONE", [], 2)
	_broadcast_meta()

## Blase der sitzenden Gäste. Ohne Klo → Urinfleck in der Ecke.
func _update_bladder(g: Dictionary, id: int, delta: float) -> void:
	if int(g.mode) == 3:
		# Erst ankommen — Pfütze und Pinkelzeit beginnen am Ziel, nicht beim Losgehen
		var bis_ziel: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
		bis_ziel.y = 0.0
		if bis_ziel.length() > 0.3:
			return
		if not _has_toilet and not bool(g.get("pfuetze", false)):
			g.pfuetze = true
			_spawn_mess_at((g.tgt as Vector3) + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4)), 1)
			_urin_count += 1
		g.pee_t = float(g.pee_t) - delta
		if float(g.pee_t) <= 0.0:
			g.mode = 1
			g.tgt = _seats[int(g.seat)].pos
			g.bladder = randf_range(BLADDER_MIN, BLADDER_MAX)
		return
	g.bladder = float(g.bladder) - delta
	if float(g.bladder) > 0.0:
		return
	# Muss mal — ohne Klo in die Ecke (leicht gestreut, damit nicht alle auf einen Fleck)
	g.mode = 3
	g.pee_t = PEE_DURATION
	g.ostate = 0
	g.pfuetze = false
	g.tgt = TOILET_POINT if _has_toilet else PEE_CORNER + Vector3(randf_range(-1.2, 1.2), 0.0, randf_range(-1.2, 1.2))

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
		if not near or bool(g.get("beschwert", false)):
			continue
		g.beschwert = true
		_complaints += 1
		_popularity = maxf(POP_MIN, _popularity - COMPLAIN_POP)
		if randf() < LEAVE_CHANCE:
			g.mode = 2
			g.tgt = ENTRANCE
			g.ostate = 0
			g.wuetend = true   # zeigt 😠 beim Gehen — der Spieler sieht warum
			_guest_sim[gid] = g
			_left_guests += 1
		else:
			_guest_sim[gid] = g


# ================================================= Tutorial & Schutzregeln
## Preis eines Bierpakets — so viel muss übrig bleiben, solange kein Bier da ist.
const GOODS_RESERVE := 40
## Dispo: bis hierhin darf das Konto ins Minus. Rückzahlung kostet 5% Zinsen.
const OVERDRAFT_LIMIT := 1000
const OVERDRAFT_INTEREST := 0.05

## Popup beim anfragenden Spieler (nicht bei allen).
func _popup_to_sender(key: String, args: Array = []) -> void:
	var s := multiplayer.get_remote_sender_id()
	if s <= 1:
		net_popup(key, args)
	else:
		net_popup.rpc_id(s, key, args)

@rpc("authority", "reliable", "call_local")
func net_popup(key: String, args: Array) -> void:
	if _hud:
		_hud.show_popup(Texte.meldung(key, args))

const Texte := preload("res://scripts/ui/texte.gd")

## Kein Bier im Lager und keine Lieferung unterwegs?
func _needs_goods() -> bool:
	return int(_stock.get(WARE_BIER, 0)) <= 0 and _pending.is_empty()

## Verhindert, dass man sein letztes Geld ausgibt, ohne Ware zu haben.
func _reserve_ok(cost: int) -> bool:
	if not _needs_goods():
		return true
	if Game.money - cost >= GOODS_RESERVE:
		return true
	_popup_to_sender("POPUP_RESERVE", [_eur(GOODS_RESERVE)])
	return false

# ---- Tutorial ----
## Anzahl der Schritte. Texte liegen in locale/texte.csv (QUEST_<n>_TITLE/_TEXT),
## übersetzt wird beim Spieler — gesendet wird nur die Schrittnummer.
const QUEST_COUNT := 12
## Seit Version 2 gibt es die Schritte „auf den Lieferwagen warten" und „Pakete
## ins Regal räumen" — ältere Spielstände ab Schritt 3 rücken eins weiter.
const QUEST_VERSION := 2

func _quest_done(step: int) -> bool:
	match step:
		0: return _tent_stage > 0
		1: return _active_count >= 2
		2: return int(_stock.get(WARE_BIER, 0)) > 0 or not _pending.is_empty()
		# Lieferwagen ist da: Pakete liegen vor dem Zelt (oder schon eingeräumt)
		3: return not _packages.is_empty() or int(_stock.get(WARE_BIER, 0)) > 0
		# alle Pakete eingeräumt
		4: return int(_stock.get(WARE_BIER, 0)) > 0 and _packages.is_empty()
		5: return _shift_num >= 1
		6: return _served >= 1 or _quest_served_once
		7: return _shift_num >= 1 and _phase == Phase.INTERMISSION
		8: return _has_staff(ROLE_KELLNER)
		9: return _lic.values().has(true)
		10: return _has_toilet
		11: return _ever_artist
	return false

func _has_staff(role: int) -> bool:
	for s in _staff_sim.values():
		if int(s.role) == role:
			return true
	return false

## Schritte weiterschalten, solange sie erfüllt sind. true = etwas hat sich geändert.
func _check_quest() -> bool:
	var before := _quest_step
	while _quest_step < QUEST_COUNT and _quest_done(_quest_step):
		_quest_step += 1
	return _quest_step != before

## Neu erreichte Meilensteine eintragen, Belohnung auszahlen, allen melden.
## true = mindestens einer neu. Belohnung zählt nicht als Umsatz.
func _pruefe_meilensteine() -> bool:
	var zustand := _buero_state()
	var neu := false
	for m: Dictionary in Meilensteine.LISTE:
		if _meilensteine.has(m.id):
			continue
		if Meilensteine.wert_von(m.wert, _stats, zustand) < int(m.ziel):
			continue
		_meilensteine.append(m.id)
		Game.add_money(int(m.belohnung))
		_melde("MSG_MILESTONE", ["MS_%s_TITLE" % m.id, _eur(int(m.belohnung))], 2)
		_net_errungenschaft.rpc(m.id)
		neu = true
	return neu

## Steam-Errungenschaft bei allen, die gerade mitspielen (Plan 5.4).
@rpc("authority", "reliable", "call_local")
func _net_errungenschaft(id: String) -> void:
	SteamDienst.errungenschaft(id)

func tutorial_active() -> bool:
	return _quest_step < QUEST_COUNT

## Pausemenü: Tutorial überspringen (gilt für alle, der Host hält den Stand).
@rpc("any_peer", "reliable", "call_local")
func net_skip_tutorial() -> void:
	if not multiplayer.is_server():
		return
	_quest_step = QUEST_COUNT
	_broadcast_meta()

# ================================================= E5: Künstler
## Wiesenbüro: Künstler für die nächste Schicht buchen.
@rpc("any_peer", "reliable", "call_local")
func net_book_artist(tier: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not ARTIST_COST.has(tier):
		return
	if _kredit_sperrt():
		return
	if _artist_tier > 0:
		_fehler("MSG_ACT_BOOKED_ALREADY", ["ACT_%d" % _artist_tier])
		return
	var cost: int = ARTIST_COST[tier]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", ["ACT_%d" % tier, _eur(cost)])
		return
	Game.add_money(-cost)
	_artist_tier = tier
	_ever_artist = true
	_popularity = minf(100.0, _popularity + float(ARTIST_POP[tier]))
	_melde("MSG_ACT_BOOKED", ["ACT_%d" % tier, int(ARTIST_POP[tier])], 2)
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


# ================================================= E4: Ware & Lieferung
## Wiesenbüro: Ware bestellen. Kommt nach ~1 Minute per Lieferwagen.
@rpc("any_peer", "reliable", "call_local")
func net_order_goods(kind: int, packs: int) -> void:
	if not multiplayer.is_server():
		return
	if _tent_stage == 0:
		_popup_to_sender("POPUP_NO_TENT", [_eur(TENT_BOOK_COST)])
		return
	if not PACK_COST.has(kind) or packs <= 0:
		return
	var cost: int = Wirtschaft.paketpreis(int(PACK_COST[kind]), _day) * packs
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", [WARE_KEYS[kind], _eur(cost)])
		return
	Game.add_money(-cost)
	_goods_cost += cost
	_pending.append({"kind": kind, "packs": packs, "t": DELIVERY_DELAY})
	_melde("MSG_GOODS_ORDERED", [packs, WARE_KEYS[kind], _eur(cost)], 2)
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
	_melde("MSG_GOODS_DELIVERED", [n])

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
@rpc("any_peer", "reliable", "call_local")
func net_pickup_package(id: int) -> void:
	if not multiplayer.is_server():
		return
	if not _packages.has(id):
		return
	_remove_package.rpc(id)

## Spieler lädt getragenes Paket im Lager ab.
@rpc("any_peer", "reliable", "call_local")
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


# ================================================= E3: Personal
## Wiesenbüro: Mitarbeiter einstellen (1 Koch, 2 Kellner, 3 Reinigung).
@rpc("any_peer", "reliable", "call_local")
func net_hire_staff(role: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not STAFF_HIRE_COST.has(role):
		return
	if _kredit_sperrt():
		return
	var cost: int = STAFF_HIRE_COST[role]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", [STAFF_KEYS[role], _eur(cost)])
		return
	Game.add_money(-cost)
	var id := _staff_next
	_staff_next += 1
	var start: Vector3 = _staff_start(role)
	_staff_sim[id] = {
		"role": role, "level": 1, "pos": start, "tgt": start, "yaw": 0.0,
		"state": 0, "timer": 0.0, "orders": [], "idx": 0
	}
	_add_staff.rpc(id, start, role, 1)
	_melde("MSG_STAFF_HIRED", [STAFF_KEYS[role], _eur(STAFF_WAGE_BASE[role])], 2)
	_broadcast_meta()

## Wiesenbüro: schwächsten Mitarbeiter dieser Rolle aufstufen.
@rpc("any_peer", "reliable", "call_local")
func net_upgrade_staff(role: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _kredit_sperrt():
		return
	var target := -1
	var low := 999
	for sid in _staff_sim.keys():
		var s: Dictionary = _staff_sim[sid]
		if int(s.role) == role and int(s.level) < low and int(s.level) < STAFF_MAX_LEVEL:
			low = int(s.level)
			target = sid
	if target < 0:
		_fehler("MSG_STAFF_NONE", [STAFF_KEYS.get(role, "")])
		return
	var cost: int = STAFF_UPGRADE_BASE * low
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", ["BTN_UPGRADE_PLAIN", _eur(cost)])
		return
	Game.add_money(-cost)
	var s2: Dictionary = _staff_sim[target]
	s2.level = low + 1
	_staff_sim[target] = s2
	_set_staff_info.rpc(target, role, int(s2.level))
	if role == ROLE_KELLNER:
		_melde("MSG_WAITER_UP", [int(s2.level), int(WAITER_CAPACITY.get(int(s2.level), 1))], 2)
	else:
		_melde("MSG_STAFF_UP", [STAFF_KEYS[role], int(s2.level)], 2)
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
	var start: Vector3 = _staff_start(role)
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

## Wo ein neuer Mitarbeiter anfängt.
func _staff_start(role: int) -> Vector3:
	match role:
		ROLE_KOCH:
			return KITCHEN_POINT
		ROLE_ZAPFER:
			return ZAPFER_POINT
	return BAR_POINT

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
		return FOOD_PREP * 2.0   # ohne Koch doppelt so lange (vorher dreifach)
	return FOOD_PREP / (1.0 + 0.15 * float(lv))


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
			ROLE_ZAPFER:
				_update_zapfer(s, delta)
			ROLE_KOCH:
				_update_koch(s, delta)
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
				# Getränke einzeln zapfen, Essen kommt als eine Portion-Runde aus der
				# Küche — früher zählte jedes Essen voll, ein Kellner mit 5 Essen wartete
				# 45 s und alle Bestellungen verfielen (Spielbot, Zelt 3).
				var t := 0.0
				var mit_essen := false
				for gid in s.orders:
					if _guest_sim.has(gid):
						var art := int(_guest_sim[gid].okind)
						# Fertiges von der Ausgabe (Zapfer, Koch) kostet keine Zeit
						if _ausgabe_nehmen(art, int(_guest_sim[gid].otype)):
							continue
						if art == 2:
							mit_essen = true
						else:
							t += DRINK_PREP   # ohne Zapfer zapft der Kellner selbst
				if mit_essen:
					t += _food_prep_time()
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

## Zapfer: steht hinter der Theke und zapft vor — volle Krüge landen auf der
## Ausgabe, Spieler und Kellner nehmen sie nur noch mit.
func _update_zapfer(s: Dictionary, delta: float) -> void:
	s.tgt = ZAPFER_POINT
	if not _staff_move(s, delta):
		return
	s.timer = float(s.timer) - delta
	if float(s.timer) > 0.0:
		return
	var lv := int(s.level)
	s.timer = ZAPF_ZEIT / (1.0 + 0.25 * float(lv - 1))
	var platz := mini(12, AUSGABE_MAX_KRUEGE + 2 * (lv - 1))
	if _ausgabe_gesamt(1) >= mini(platz, int(_stock[WARE_BIER])):
		return
	_ausgabe_hinzufuegen(1, _naechste_sorte(1, _drinks_avail()))

## Koch: kocht Brezn und Würstl vor und stellt sie auf die Ausgabe.
func _update_koch(s: Dictionary, delta: float) -> void:
	s.tgt = KITCHEN_POINT
	if not _staff_move(s, delta):
		return
	var sorten := _foods_avail()
	if sorten.is_empty():
		return
	s.timer = float(s.timer) - delta
	if float(s.timer) > 0.0:
		return
	var lv := int(s.level)
	s.timer = KOCH_ZEIT / (1.0 + 0.2 * float(lv - 1))
	var platz := mini(6, AUSGABE_MAX_ESSEN + (lv - 1))
	if _ausgabe_gesamt(2) >= mini(platz, int(_stock[WARE_ESSEN])):
		return
	_ausgabe_hinzufuegen(2, _naechste_sorte(2, sorten))

## Welche Sorte als Nächstes: was offen bestellt ist und noch nicht bereitsteht.
func _naechste_sorte(art: int, sorten: Array) -> int:
	var beste: int = sorten[0]
	var bester_wert := -INF
	for typ: int in sorten:
		var offen := 0
		for g: Dictionary in _guest_sim.values():
			if int(g.ostate) == 1 and int(g.okind) == art and int(g.otype) == typ:
				offen += 1
		var wert := float(offen) - float(_ausgabe.get("%d_%d" % [art, typ], 0)) + randf() * 0.1
		if wert > bester_wert:
			bester_wert = wert
			beste = typ
	return beste

func _ausgabe_gesamt(art: int) -> int:
	var n := 0
	for schluessel: String in _ausgabe:
		if schluessel.begins_with("%d_" % art):
			n += int(_ausgabe[schluessel])
	return n

func _ausgabe_hinzufuegen(art: int, typ: int) -> void:
	var schluessel := "%d_%d" % [art, typ]
	_ausgabe[schluessel] = int(_ausgabe.get(schluessel, 0)) + 1
	_ausgabe_senden()

## Nimmt ein fertiges Stück von der Ausgabe. false, wenn keins da ist.
func _ausgabe_nehmen(art: int, typ: int) -> bool:
	var schluessel := "%d_%d" % [art, typ]
	var n := int(_ausgabe.get(schluessel, 0))
	if n <= 0:
		return false
	if n == 1:
		_ausgabe.erase(schluessel)
	else:
		_ausgabe[schluessel] = n - 1
	_ausgabe_senden()
	return true

func _ausgabe_senden() -> void:
	_net_ausgabe.rpc(_ausgabe)

@rpc("authority", "reliable", "call_local")
func _net_ausgabe(inhalt: Dictionary) -> void:
	if not multiplayer.is_server():
		_ausgabe = inhalt.duplicate()
	for n in get_tree().get_nodes_in_group("ausgabe"):
		n.set_inhalt(inhalt.duplicate())

## Spieler nimmt an der Ausgabe das, was die wartenden Gäste am meisten brauchen.
@rpc("any_peer", "reliable", "call_local")
func net_take_ausgabe() -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var beste := ""
	var bester_wert := -1
	for schluessel: String in _ausgabe:
		var t := schluessel.split("_")
		var offen := 0
		for g: Dictionary in _guest_sim.values():
			if int(g.ostate) == 1 and int(g.okind) == int(t[0]) and int(g.otype) == int(t[1]):
				offen += 1
		var wert := offen * 100 + int(_ausgabe[schluessel])
		if wert > bester_wert:
			bester_wert = wert
			beste = schluessel
	if beste == "":
		return
	var teile := beste.split("_")
	if _ausgabe_nehmen(int(teile[0]), int(teile[1])):
		_net_ausgabe_genommen.rpc_id(s, int(teile[0]), int(teile[1]))

## Beim nehmenden Spieler: fertigen Krug bzw. Teller in die Hand.
@rpc("authority", "reliable", "call_local")
func _net_ausgabe_genommen(art: int, typ: int) -> void:
	var p = _players_nodes.get(multiplayer.get_unique_id())
	if p and int(p.carry_state) == 0:
		p.carry_state = art
		p.carry_type = typ
		p.carry_fill = 1.0

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
			_stats.cleaned += 1
			_net_betrag.rpc(mn.global_position, tip, true)
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
	_stats.served += 1
	g.drinks = int(g.get("drinks", 0)) + 1
	_quest_served_once = true
	_popularity = minf(100.0, _popularity + POP_SERVE)
	var hyg := HYGIENE_MIN_ANTEIL + (1.0 - HYGIENE_MIN_ANTEIL) * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind)) * hyg * (1.0 + DEKO_BONUS * _upg_deko))
	_last_earn += reward
	Game.add_score(reward)
	_add_income(reward)
	_net_betrag.rpc(g.pos, reward, false)

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
@rpc("any_peer", "reliable", "call_local")
func net_buy_license(key: String) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not LIC_COST.has(key):
		return
	if _kredit_sperrt():
		return
	if _lic.get(key, false):
		_fehler("MSG_LIC_HAVE", [LIC_KEYS[key]])
		return
	var cost: int = LIC_COST[key]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", [LIC_KEYS[key], _eur(cost)])
		return
	Game.add_money(-cost)
	_lic[key] = true
	_melde("MSG_LIC_DONE", [LIC_KEYS[key]], 2)
	_broadcast_meta()


## Kiosk: Zelt upgraden (mehr Tische / Kapazität).
@rpc("any_peer", "reliable", "call_local")
func net_upgrade_tent() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _kredit_sperrt():
		return
	var nxt := _tent_stage + 1
	if not TENT_UPGRADE_COST.has(nxt):
		_fehler("MSG_TENT_MAX")
		return
	var cost: int = TENT_UPGRADE_COST[nxt]
	if not _reserve_ok(cost):
		return
	if not _afford(cost):
		_fehler("MSG_NO_MONEY", ["OFFER_TENT_UPGRADE", _eur(cost)])
		return
	Game.add_money(-cost)
	_tent_stage = nxt
	_apply_tent()
	_melde("MSG_TENT_UP", ["TENT_STAGE_%d" % nxt, int(TENT_TABLE_LIMIT[nxt])], 2)
	_broadcast_meta()

## Ohne einen Wohnwagen mit is_mine kann niemand schlafen und der Tag endet nie.
## Das ist beim Bearbeiten der Map schon zweimal passiert, deshalb hier ein Netz:
## fehlt der eigene Wohnwagen, wird der erstbeste dazu erklärt.
func _sichere_wohnwagen() -> void:
	var alle: Array = []
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Caravan:
			return   # es gibt schon einen eigenen
	for n in find_children("*", "Node3D", true, false):
		if n is Caravan:
			alle.append(n)
	if alle.is_empty():
		push_warning("Kein Wohnwagen in der Map — schlafen ist nicht möglich.")
		return
	var w := alle[0] as Caravan
	w.is_mine = true
	w.add_to_group("interactable")
	var label := w.get_node_or_null("Label") as Label3D
	if label:
		label.visible = true
	push_warning("Kein Wohnwagen mit is_mine gefunden — '%s' übernimmt das." % w.name)

## Wohnwagen: schlafen → nächster Tag (Miete abziehen).
@rpc("any_peer", "reliable", "call_local")
func net_sleep() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _tent_stage == 0:
		_fehler("MSG_SLEEP_NEED_TENT")
		return
	if _active_count <= 0:
		_fehler("MSG_SLEEP_NEED_TABLE")
		return
	# Uyu → ertesi sabah 07:00, zelt açılır. Misafirler 08:00'de gelmeye başlar.
	net_sleep_fade.rpc()
	_start_shift()
	_melde("MSG_DAY_START", [_day])

## Kiosk: Tisch verkaufen (yarı fiyat iade).
@rpc("any_peer", "reliable", "call_local")
func net_sell_table() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _active_count <= 0:
		_fehler("MSG_TABLE_NONE")
		return
	_active_count -= 1
	_add_income(int(TABLE_COST / 2))
	_apply_tent()
	_melde("MSG_TABLE_SOLD", [_eur(int(TABLE_COST / 2)), _active_count])
	_broadcast_meta()

## Molada bira masasını tut/bırak (yerleştir).
@rpc("any_peer", "reliable", "call_local")
func net_move_table(index: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _held.has(s):
		_held.erase(s)
	elif index >= 0 and index < _beertables.size() and not _held.values().has(index) and not _held_deko.has(s):
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
	# Getragene Einrichtung schwebt vor dem Spieler mit
	for peer in _held_deko.keys():
		var did: int = _held_deko[peer]
		var pl = _players_nodes.get(peer)
		var n: Node3D = _einrichtung_nodes.get(did)
		if pl == null or n == null:
			continue
		var fwd: Vector3 = -pl.global_transform.basis.z
		var p: Vector3 = pl.global_position + fwd * DEKO_ABSTAND
		n.position = Vector3(p.x, 0.0, p.z)
		_einrichtung[did].x = p.x
		_einrichtung[did].z = p.z

# ================================================= Einrichtung (Lampen, Deko)
## Wiesenbüro: Gegenstand kaufen. Er erscheint am Zelteingang (drinnen) — das
## Büro steht weit weg, dort vor dem Käufer wäre er fehl am Platz.
@rpc("any_peer", "reliable", "call_local")
func net_buy_einrichtung(art: String) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if not Katalog.ARTEN.has(art):
		return
	if _tent_stage == 0:
		_fehler("MSG_NEED_TENT")
		return
	if _einrichtung.size() >= DEKO_MAX:
		_fehler("MSG_DECO_LIMIT", [DEKO_MAX])
		return
	var preis := int(Katalog.ARTEN[art].preis)
	if _kredit_sperrt() or not _reserve_ok(preis):
		return
	if not _afford(preis):
		_fehler("MSG_NO_MONEY", [Katalog.name_key(art), _eur(preis)])
		return
	Game.add_money(-preis)
	var did := _einrichtung_next
	_einrichtung_next += 1
	var x := -4.0 + float(_einrichtung.size() % 5) * 2.0
	_einrichtung[did] = {"art": art, "x": x, "z": 8.5, "rot": 0.0}
	_add_einrichtung.rpc(did, art, x, 8.5, 0.0)
	_melde("MSG_DECO_BOUGHT", [Katalog.name_key(art)], 2)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _add_einrichtung(did: int, art: String, x: float, z: float, rot: float) -> void:
	if _einrichtung_nodes.has(did) or not Katalog.ARTEN.has(art):
		return
	var n: Node3D = (Katalog.ARTEN[art].szene as PackedScene).instantiate()
	n.name = "Deko%d" % did
	n.deko_id = did
	n.art = art
	n.position = Vector3(x, 0.0, z)
	n.rotation.y = rot
	_einrichtung_container.add_child(n)
	_einrichtung_nodes[did] = n

## Molada: Gegenstand aufnehmen oder hinstellen (wie Tische).
@rpc("any_peer", "reliable", "call_local")
func net_move_einrichtung(did: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _held_deko.has(s):
		_deko_abstellen(s)
	elif _einrichtung.has(did) and not _held_deko.values().has(did) and not _held.has(s):
		_held_deko[s] = did
	_broadcast_meta()

## Getragenen Gegenstand um 45° drehen.
@rpc("any_peer", "reliable", "call_local")
func net_rotate_einrichtung() -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if not _held_deko.has(s):
		return
	var did: int = _held_deko[s]
	_einrichtung[did].rot = wrapf(float(_einrichtung[did].rot) + PI / 4.0, -PI, PI)
	(_einrichtung_nodes[did] as Node3D).rotation.y = float(_einrichtung[did].rot)

## Getragenen Gegenstand verkaufen — die Hälfte des Kaufpreises kommt zurück.
@rpc("any_peer", "reliable", "call_local")
func net_sell_einrichtung() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if not _held_deko.has(s):
		return
	var did: int = _held_deko[s]
	_held_deko.erase(s)
	if not _einrichtung.has(did):
		return
	var art := str(_einrichtung[did].art)
	var erloes := int(Katalog.ARTEN[art].preis) / 2
	_einrichtung.erase(did)
	_remove_einrichtung.rpc(did)
	Game.add_money(erloes)
	_melde("MSG_DECO_SOLD", [Katalog.name_key(art), _eur(erloes)], 2)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _remove_einrichtung(did: int) -> void:
	var n: Node = _einrichtung_nodes.get(did)
	_einrichtung_nodes.erase(did)
	if n:
		n.queue_free()

func _deko_abstellen(s: int) -> void:
	var did: int = _held_deko[s]
	_held_deko.erase(s)
	if not _einrichtung.has(did):
		return
	var e: Dictionary = _einrichtung[did]
	e.x = clampf(float(e.x), ZELT_MIN.x, ZELT_MAX.x)
	e.z = clampf(float(e.z), ZELT_MIN.z, ZELT_MAX.z)
	_set_einrichtung.rpc(did, float(e.x), float(e.z), float(e.rot))

@rpc("authority", "reliable", "call_local")
func _set_einrichtung(did: int, x: float, z: float, rot: float) -> void:
	var n: Node3D = _einrichtung_nodes.get(did)
	if n:
		n.position = Vector3(x, 0.0, z)
		n.rotation.y = rot

@rpc("authority", "unreliable")
func _net_einrichtung_pos(ids: PackedInt32Array, xs: PackedFloat32Array, zs: PackedFloat32Array, rots: PackedFloat32Array) -> void:
	for i in ids.size():
		var n: Node3D = _einrichtung_nodes.get(ids[i])
		if n:
			n.position = Vector3(xs[i], 0.0, zs[i])
			n.rotation.y = rots[i]

## Für den Spieler-Hinweis: trägt dieser Spieler gerade einen Gegenstand?
func haelt_einrichtung(peer_id: int) -> bool:
	return _haelt_deko.has(str(peer_id))

# ================================================= servis (misafire)
@rpc("any_peer", "reliable", "call_local")
func net_serve_guest(id: int, kind: int, type: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT:
		return
	if not _guest_sim.has(id):
		return
	var g: Dictionary = _guest_sim[id]
	if g.ostate != 1 or g.okind != kind or g.otype != type:
		return
	if not _has_stock(int(g.okind)):
		_melde("MSG_STOCK_EMPTY", [WARE_KEYS[WARE_ESSEN if int(g.okind) == 2 else WARE_BIER]], 1)
		return
	_consume_stock(int(g.okind))
	g.ostate = 2
	g.served_t = SERVED_SHOW
	_guest_sim[id] = g
	_served += 1
	_stats.served += 1
	g.drinks = int(g.get("drinks", 0)) + 1
	_quest_served_once = true
	_popularity = minf(100.0, _popularity + POP_SERVE)
	var waiter_npc := _npc_roles.has(ROLE_WAITER)
	var hyg := HYGIENE_MIN_ANTEIL + (1.0 - HYGIENE_MIN_ANTEIL) * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind)) * hyg * (1.0 + DEKO_BONUS * _upg_deko))
	var tip := 0 if waiter_npc else randi_range(TRINKGELD_MIN, TRINKGELD_MAX)
	if waiter_npc:
		reward = int(reward * 0.5)
	_last_earn += reward + tip
	Game.add_score(reward)
	_add_income(reward + tip)
	_net_betrag.rpc(g.pos, reward + tip, false)

## Verkaufspreis je Bestellung. Einkauf: Bier 4€, Zutaten 5€ pro Einheit —
## damit bleibt genug Marge, um Miete und Löhne zu tragen.
func _reward_for(okind: int) -> int:
	if okind == 2:
		return Wirtschaft.verkaufspreis(Wirtschaft.ESSEN_BASIS, _day)
	# Bier: Tagespreis × selbst gewählter Bierpreis
	return roundi(float(Wirtschaft.verkaufspreis(Wirtschaft.BIER_BASIS, _day)) * _bierpreis)

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
		var geaendert := _check_quest()
		if _pruefe_meilensteine():
			geaendert = true
		if geaendert:
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
		# Grundandrang 50 % der Plätze, Beliebtheit füllt den Rest — mit reiner
		# Beliebtheit (Start 20 %) kamen bei 2 Tischen am ersten Abend nur 2 Gäste.
		var andrang := GRUNDANDRANG + (1.0 - GRUNDANDRANG) * _popularity / 100.0
		# Bierpreis und Einrichtung ziehen mit
		andrang *= Wirtschaft.preis_andrang(_bierpreis)
		andrang *= 1.0 + minf(DEKO_ANDRANG_MAX, DEKO_ANDRANG * float(_einrichtung.size()))
		var target := mini(_seats.size(), int(round(andrang * float(_seats.size()) * _time_factor() * draw)))
		if _guest_sim.size() < target:
			_spawn_guest()
	# Akşam: 19:00'dan sonra karanlık + sabırsızlık
	if not _night and _clock_hour() >= NIGHT_HOUR:
		_night = true
		_apply_night_visual(true)   # host görseli
		_melde("MSG_EVENING")
	_update_guests(delta)
	_update_tanz(delta)
	if int(_stock[WARE_BIER]) <= 0 and not _guest_sim.is_empty():
		_ohne_ware_s += delta
	_update_staff(delta)
	_update_complaints(delta)
	_update_hygiene(delta)

## Sichtbare Laune über dem Kopf: 0 normal, 1 verpasste Bestellung (😤), 2 geht genervt (😠).
func _laune(g: Dictionary) -> int:
	if bool(g.get("wuetend", false)):
		return 2
	if float(g.get("verpasst_t", 0.0)) > 0.0:
		return 1
	return 0

## Ist die Stimmung gut genug zum Tanzen auf den Tischen?
func stimmung_gut() -> bool:
	var abend := _clock_hour() >= TANZ_AB_STUNDE or _artist_tier > 0
	return abend and _popularity >= TANZ_BELIEBTHEIT and _hygiene >= TANZ_SAUBERKEIT

## Gute Stimmung: satte, zufriedene Gäste steigen auf ihren Tisch und tanzen.
## Je Tisch fest 2 oder 3, damit nicht das ganze Zelt auf den Tischen steht.
func _update_tanz(delta: float) -> void:
	_tanz_timer -= delta
	if _tanz_timer > 0.0:
		return
	_tanz_timer = TANZ_PRUEF_INTERVALL
	if not stimmung_gut():
		return
	var je_tisch := {}
	for g: Dictionary in _guest_sim.values():
		if int(g.mode) == 5 and int(g.seat) < _seats.size():
			var t := int(_seats[int(g.seat)].table)
			je_tisch[t] = int(je_tisch.get(t, 0)) + 1
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		if int(g.mode) != 1 or int(g.ostate) != 0 or int(g.get("drinks", 0)) < 1:
			continue
		var seat: Dictionary = _seats[int(g.seat)]
		var ti := int(seat.table)
		var belegt := int(je_tisch.get(ti, 0))
		if belegt >= tanz_max(ti) or randf() > 0.35 or ti >= _beertables.size():
			continue
		var bt := _beertables[ti] as Node3D
		var ziel: Vector3 = bt.global_position + bt.global_transform.basis.x * float(TANZ_PLAETZE[belegt % TANZ_PLAETZE.size()])
		g.mode = 5
		g.tanz_t = randf_range(TANZ_DAUER_MIN, TANZ_DAUER_MAX)
		g.tgt = Vector3(ziel.x, 0.1, ziel.z)
		_guest_sim[id] = g
		je_tisch[ti] = belegt + 1

## Wie viele Gäste auf diesem Tisch tanzen dürfen: 2 oder 3, fest je Tisch.
func tanz_max(tisch: int) -> int:
	return 2 + (tisch % 2)

func _start_shift() -> void:
	_phase = Phase.SHIFT
	_phase_time = SHIFT_TIME
	_served = 0
	_missed = 0
	_pop_verlust_heute = 0.0
	_ohne_ware_s = 0.0
	_ausgabe.clear()
	_ausgabe_senden()
	_last_earn = 0
	_guest_spawn_timer = randf_range(ERSTE_GAESTE_MIN, ERSTE_GAESTE_MAX)
	_hygiene = 100.0
	_night = false
	_apply_night_visual(false)
	_did_shift = true
	for s in _held_deko.keys():
		_deko_abstellen(s)
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
	# Nur einmal pro Tag: mehrere verpasste Bestellungen im selben Moment riefen
	# das doppelt auf — Tag +2, Miete und Löhne doppelt (Spielbot, 30 Tage).
	if _phase != Phase.SHIFT:
		return
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
	_ausgabe.clear()          # Übriges von der Ausgabe wird weggeräumt
	_ausgabe_senden()
	_artist_tier = 0

	# Erken kapatma → popülerlik cezası (ne kadar erken, o kadar çok)
	var pop_penalty := 0.0
	if reason == 2:
		pop_penalty = hours_left * POP_EARLY_CLOSE_PER_HOUR
		_popularity = maxf(POP_MIN, _popularity - pop_penalty)

	# Endlos: nach der Schonfrist bröckelt die Beliebtheit jede Nacht etwas
	_popularity = maxf(POP_MIN, _popularity - Wirtschaft.beliebtheit_verlust(_day))
	# Über Nacht erholt sich eine schlechte Beliebtheit ein Stück — sonst bleibt
	# ein überlastetes Zelt für immer bei der Untergrenze (Spielbot, 30 Tage).
	if _popularity < POP_ERHOLUNG_ZIEL:
		_popularity += (POP_ERHOLUNG_ZIEL - _popularity) * POP_ERHOLUNG

	# Günlük bilanço: kira + personel maaşları
	var rent := _daily_rent()
	var wages := _total_wages()
	_wages_last = wages
	Game.add_money(-rent - wages)
	var goods := _goods_cost      # schon beim Bestellen bezahlt, hier nur ausgewiesen
	var net_profit := _last_earn - rent - wages - goods - _interest_paid - _kredit_heute
	net_report.rpc({
		"reason": reason, "closed_at": int(closed_at), "pop_penalty": pop_penalty, "day": _day,
		"earn": _last_earn, "tips": _clean_tips, "rent": rent, "wages": wages, "goods": goods,
		"interest": _interest_paid, "net": net_profit, "served": _served, "missed": _missed,
		"urin": _urin_count, "complaints": _complaints, "left": _left_guests,
		"loan": _kredit_heute,
		# für die Tipps in der Bilanz (Texte.tipps)
		"toilet": _has_toilet, "kellner": _has_staff(ROLE_KELLNER), "zapfer": _has_staff(ROLE_ZAPFER),
		"reinigung": _has_staff(ROLE_REINIGUNG), "ohne_ware": roundi(_ohne_ware_s), "pop": roundi(_popularity),
	})
	match reason:
		1:
			_melde("REPORT_END_COMPLAINTS", [], 1)
		2:
			_melde("REPORT_END_EARLY", [int(closed_at), roundi(pop_penalty)], 1)
	_melde("MSG_DAY_END", [_eur(net_profit)], 2 if net_profit >= 0 else 1)
	_clean_tips = 0
	_interest_paid = 0
	_kredit_heute = 0
	_goods_cost = 0
	_urin_count = 0
	_complaints = 0
	_left_guests = 0
	_day += 1   # endlos: Tag 17, 18, 19 … — kein Rücksprung mehr
	_stats.days += 1
	_pruefe_pleite()   # nach Miete und Löhnen — erst dann steht fest, ob es reicht
	_broadcast_meta()

## Bilgisayardan zelti erken kapat (popülerlik cezası).
@rpc("any_peer", "reliable", "call_local")
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
	# Vom Haupttor über den Weg zum Zelteingang, dann zum Platz
	var weg: Array = WEG_REIN.duplicate()
	weg.append(_seats[si].pos)
	var start: Vector3 = HAUPTTOR + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(0.0, 1.5))
	_guest_sim[id] = {
		"seat": si, "mode": 0, "pos": start, "tgt": weg.pop_front(), "weg": weg, "yaw": 0.0,
		"ostate": 0, "okind": 1, "otype": 1, "patience": _geduld(),
		"cooldown": randf_range(8.0, 20.0), "served_t": 0.0,
		"bladder": randf_range(BLADDER_MIN, BLADDER_MAX), "pee_t": 0.0,
		"drinks": 0, "puke_t": 0.0, "puked": false
	}
	_add_guest.rpc(id, start)

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
				var weg: Array = g.get("weg", [])
				if not weg.is_empty():
					g.tgt = weg.pop_front()   # nächster Wegpunkt Richtung Platz
					g.weg = weg
				else:
					g.mode = 1
					g.yaw = _seats[g.seat].yaw
			elif g.mode == 2:
				# Beim Gehen erst zum Zelteingang (das setzen die Aufrufer), dann über
				# den Weg zurück zum Haupttor — erst dort verschwinden
				if not bool(g.get("raus_gesetzt", false)):
					g.raus_gesetzt = true
					g.raus = WEG_RAUS.duplicate()
				var raus: Array = g.get("raus", [])
				if raus.is_empty():
					_despawn_guest(id)
					continue
				g.tgt = raus.pop_front()
				g.raus = raus
		# Oturan misafir: sipariş döngüsü
		if g.mode == 1:
			_guest_order(g, id, delta)
		if float(g.get("verpasst_t", 0.0)) > 0.0:
			g.verpasst_t = float(g.verpasst_t) - delta
		# Tanzt auf dem Tisch — danach zurück auf den Platz
		if g.mode == 5:
			g.tanz_t = float(g.get("tanz_t", 0.0)) - delta
			if float(g.tanz_t) <= 0.0:
				g.mode = 0
				g.weg = []
				g.tgt = _seats[int(g.seat)].pos
				g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
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
			node.set_order(g.ostate, g.okind, g.otype, clampf(g.patience / _geduld(), 0.0, 1.0))
			# Host/Solo bekommen _net_guests nicht (kein call_local) — direkt setzen
			node.set_tanz(int(g.mode) == 5)
			node.set_laune(_laune(g))

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
			g.patience = _geduld()
	elif g.ostate == 1:
		g.patience -= delta * (PATIENCE_NIGHT_MULT if _night else 1.0)
		if g.patience <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
			_missed += 1
			Game.add_score(-MISS_PENALTY)
			g.verpasst_t = 3.0   # kurz 😤 über dem Kopf
			var abzug := minf(POP_MISS, maxf(0.0, POP_MISS_TAG_MAX - _pop_verlust_heute))
			_pop_verlust_heute += abzug
			_popularity = maxf(POP_MIN, _popularity - abzug)
			# Zu viele verpasste: Zelt schließt früh. Grenze wächst mit den Plätzen,
			# sonst endet mit 4 Tischen fast jeder Tag vorzeitig.
			if _missed >= maxi(20, _seats.size() * 2):
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
		g.puked = false
		g.kotzt = false
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

@rpc("any_peer", "reliable", "call_local")
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
		_stats.cleaned += 1
		_net_betrag.rpc((_messes[id] as Node3D).global_position, tip, true)
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
	var ctanz := PackedByteArray()
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		cids.append(id)
		cx.append(g.pos.x)
		cz.append(g.pos.z)
		cyaw.append(g.yaw)
		cstate.append(g.ostate)
		ckind.append(g.okind)
		ctype.append(g.otype)
		cratio.append(clampf(g.patience / _geduld(), 0.0, 1.0))
		ctanz.append((1 if int(g.mode) == 5 else 0) | (_laune(g) << 1))
	_net_guests.rpc(cids, cx, cz, cyaw, cstate, ckind, ctype, cratio, ctanz)
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
	# Getragene Einrichtung (nur solange jemand trägt)
	if not _held_deko.is_empty():
		var dids := PackedInt32Array()
		var dx := PackedFloat32Array()
		var dz := PackedFloat32Array()
		var drot := PackedFloat32Array()
		for did in _held_deko.values():
			if _einrichtung.has(did):
				dids.append(did)
				dx.append(float(_einrichtung[did].x))
				dz.append(float(_einrichtung[did].z))
				drot.append(float(_einrichtung[did].rot))
		_net_einrichtung_pos.rpc(dids, dx, dz, drot)

@rpc("authority", "unreliable")
func _net_tables(bx: PackedFloat32Array, bz: PackedFloat32Array) -> void:
	for i in range(_beertables.size()):
		if i < bx.size():
			(_beertables[i] as Node3D).position = Vector3(bx[i], 0.0, bz[i])

@rpc("authority", "unreliable")
func _net_guests(cids: PackedInt32Array, cx: PackedFloat32Array, cz: PackedFloat32Array, cyaw: PackedFloat32Array, cstate: PackedInt32Array, ckind: PackedInt32Array, ctype: PackedInt32Array, cratio: PackedFloat32Array, ctanz: PackedByteArray) -> void:
	for i in range(cids.size()):
		var c = _guests.get(cids[i])
		if c:
			c.set_net(Vector3(cx[i], 0.1, cz[i]), cyaw[i])
			c.set_order(cstate[i], ckind[i], ctype[i], cratio[i])
			var bits: int = ctanz[i] if i < ctanz.size() else 0
			c.set_tanz(bits & 1 == 1)
			c.set_laune(bits >> 1)

## call_local: Uhrzeit, Beliebtheit und Sauberkeit braucht auch das HUD des
## Hosts bzw. im Solo-Spiel — ohne kam dort nie etwas an („Zelt geschlossen",
## Beliebtheit stand still).
@rpc("authority", "unreliable", "call_local")
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

## Alles, was Wiesenbüro, Zelt-Computer und HUD anzeigen — als Zahlen, nicht
## als Text: übersetzt wird beim Spieler (scripts/ui/texte.gd, wiesenbuero.gd).
func _buero_state() -> Dictionary:
	var staff := []
	for s in _staff_sim.values():
		staff.append([int(s.role), int(s.level)])
	var haelt := {}
	for pid in _held_deko.keys():
		haelt[str(pid)] = int(_held_deko[pid])
	return {
		"stage": _tent_stage, "tables": _active_count, "limit": int(TENT_TABLE_LIMIT[_tent_stage]),
		"seats": _seats.size(), "rent": _daily_rent(), "mkt": _upg_marketing, "deko": _upg_deko,
		"toilet": _has_toilet, "lic": _lic.duplicate(), "staff": staff, "artist": _artist_tier,
		"pending": _pending.size(), "bier": int(_stock[WARE_BIER]), "essen": int(_stock[WARE_ESSEN]),
		"haelt": haelt, "bierpreis": _bierpreis, "einrichtung": _einrichtung.size(),
		"shift": _phase == Phase.SHIFT,
		"stats": _stats.duplicate(), "ms": _meilensteine.duplicate(), "day": _day,
		"kredit": _kredit_rest,
	}

func _broadcast_meta() -> void:
	_check_quest()
	net_meta.rpc(_phase, _day, _tent_stage, _active_count, _quest_step, _buero_state())
	_save_game()   # E3: her durum değişiminde ilerlemeyi kaydet

@rpc("authority", "reliable", "call_local")
func net_meta(phase: int, day: int, tent_stage: int, active_count: int, quest_step: int, buero: Dictionary) -> void:
	_phase = phase
	_day = day
	_tent_stage = tent_stage
	_vermietung_aktualisieren()
	_quest_step = quest_step   # auch bei Clients — der Zielmarker braucht ihn
	_haelt_deko = buero.get("haelt", {})
	# Clientlerde masaların görünürlüğünü senkronla
	if not multiplayer.is_server() and _active_count != active_count:
		_active_count = active_count
		_apply_tent()
	_active_count = active_count
	_hud.set_phase(phase == Phase.SHIFT)
	_hud.set_buero(buero)
	# Statusanzeige in der Steam-Freundesliste (tut außerhalb des Steam-Builds nichts)
	var status := "#Status_Offen" if phase == Phase.SHIFT else ("#Status_Solo" if Net.solo else "#Status_Koop")
	SteamDienst.status_setzen(status, day)
	_hud.set_day(day)
	_hud.set_quest(quest_step, QUEST_COUNT)
	if _sfx_node:
		if phase == Phase.SHIFT:
			_sfx_node.play_music()
		else:
			_sfx_node.stop_music()

## Meldung bei allen Spielern. key: Übersetzungsschlüssel, args: Werte dafür —
## Texte darin sind selbst Schlüssel, _eur(n) wird zum Betrag (texte.gd meldung).
## art: 0 Info, 1 Problem, 2 Erfolg.
@rpc("authority", "reliable", "call_local")
func _net_banner(key: String, args: Array, art: int) -> void:
	if _hud:
		_hud.melde(key, args, art)

func _melde(key: String, args: Array = [], art := 0) -> void:
	_net_banner.rpc(key, args, art)

## Problem nur beim Spieler, der die Aktion ausgelöst hat — die anderen
## brauchen nicht zu lesen, dass jemandem das Geld fehlt.
func _fehler(key: String, args: Array = []) -> void:
	var s := multiplayer.get_remote_sender_id()
	if s <= 1:
		_net_banner(key, args, 1)
	else:
		_net_banner.rpc_id(s, key, args, 1)

static func _eur(betrag: int) -> Dictionary:
	return {"euro": betrag}

## Namen als Übersetzungsschlüssel für Meldungen
const WARE_KEYS := {1: "GOODS_BEER", 2: "GOODS_FOOD"}
const STAFF_KEYS := {1: "STAFF_COOK", 2: "STAFF_WAITER", 3: "STAFF_CLEANER", 4: "STAFF_TAPSTER"}
const LIC_KEYS := {"weizen": "LIC_WEIZEN", "radler": "LIC_RADLER", "brezn": "LIC_BREZN", "sosis": "LIC_SOSIS"}
const BETRAG_SZENE := preload("res://scenes/ui/betrag.tscn")

## Schwebender Betrag über Gast oder Pfütze, bei allen Spielern — mit Kasse
## (Verkauf) oder Münzen (Trinkgeld), sobald die Tondateien da sind.
@rpc("authority", "unreliable", "call_local")
func _net_betrag(pos: Vector3, betrag: int, trinkgeld: bool) -> void:
	if betrag <= 0 or DisplayServer.get_name() == "headless":
		return
	var b := BETRAG_SZENE.instantiate()
	add_child(b)
	b.global_position = pos + Vector3(0, 2.0, 0)
	b.starte(betrag)
	if _sfx_node:
		_sfx_node.play("muenzen" if trinkgeld else "kasse", -8.0)

## Kotz-Ablauf: Gast läuft vom Tisch weg, übergibt sich dort, geht zurück.
## Reihenfolge: hinlaufen → ankommen → würgen → erst dann der Fleck → zurück.
func _update_puke(g: Dictionary, id: int, delta: float) -> void:
	if not bool(g.get("kotzt", false)):
		var d: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
		d.y = 0
		if d.length() > 0.2:
			return   # noch unterwegs
		g.kotzt = true
		g.puke_t = 3.5
		_net_guest_vomit.rpc(id)
	g.puke_t = float(g.puke_t) - delta
	# nach kurzem Würgen landet es auf dem Boden
	if not bool(g.get("puked", false)) and float(g.puke_t) <= 2.6:
		g.puked = true
		g.drinks = 0
		_spawn_mess_at(g.pos as Vector3, 0)
	if float(g.puke_t) <= 0.0:
		g.mode = 1
		g.kotzt = false
		g.tgt = _seats[int(g.seat)].pos

## Kurze Schwarzblende beim Schlafen (bei allen Spielern).
@rpc("authority", "reliable", "call_local")
func net_sleep_fade() -> void:
	if _hud and _hud.has_method("play_sleep_fade"):
		_hud.play_sleep_fade()

## Letzte Tagesbilanz — im Wiesenbüro jederzeit nachlesbar.
@rpc("authority", "reliable", "call_local")
func net_report(bilanz: Dictionary) -> void:
	_last_report = bilanz
	if _hud:
		_hud.set_report(bilanz)

## Pleite (Plan 3.5): Steht das Konto nach dem Tagesabschluss unter dem
## Dispolimit, springt die Brauerei ein. Konto zurück auf 0, Schuld = Fehlbetrag
## plus Aufschlag. Bis sie getilgt ist, geht ein Teil jeder Einnahme an die
## Brauerei und Ausbauten sind gesperrt (_kredit_sperrt). Ein zweites Mal pleite
## erhöht die Schuld — kein Game Over.
func _pruefe_pleite() -> void:
	if Game.money >= -OVERDRAFT_LIMIT:
		return
	var fehlbetrag := -Game.money
	Game.add_money(fehlbetrag)
	_kredit_rest += roundi(float(fehlbetrag) * (1.0 + Wirtschaft.KREDIT_AUFSCHLAG))
	net_popup.rpc("POPUP_LOAN", [_eur(-fehlbetrag), _eur(_kredit_rest), roundi(Wirtschaft.KREDIT_ANTEIL * 100.0)])
	_broadcast_meta()

## Ausbauten sind gesperrt, solange der Rettungskredit läuft. true = gesperrt.
func _kredit_sperrt() -> bool:
	if _kredit_rest <= 0:
		return false
	_fehler("MSG_LOAN_LOCKED")
	return true

## Reicht das Geld — inklusive Dispo bis -1000€?
func _afford(cost: int) -> bool:
	return Game.money - cost >= -OVERDRAFT_LIMIT

## Einnahmen. Steht das Konto im Minus, gehen 5% Zinsen vom Betrag ab,
## der die Schulden tilgt.
func _add_income(amount: int) -> void:
	if amount <= 0:
		Game.add_money(amount)
		return
	_stats.earned += amount
	# Rettungskredit: ein Teil jeder Einnahme geht an die Brauerei
	if _kredit_rest > 0:
		var tilgung := mini(ceili(float(amount) * Wirtschaft.KREDIT_ANTEIL), _kredit_rest)
		_kredit_rest -= tilgung
		_kredit_heute += tilgung
		amount -= tilgung
		if _kredit_rest == 0:
			_melde("MSG_LOAN_PAID", [], 2)
			_broadcast_meta()
	if Game.money < 0:
		var debt: int = -Game.money
		var repay: int = mini(amount, debt)
		var interest: int = int(ceil(float(repay) * OVERDRAFT_INTEREST))
		_interest_paid += interest
		Game.add_money(amount - interest)
	else:
		Game.add_money(amount)
