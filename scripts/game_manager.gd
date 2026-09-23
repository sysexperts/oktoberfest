extends Node3D
const Kino := preload("res://scripts/ui/kino.gd")
const KoopDaten := preload("res://scripts/koop_daten.gd")
## GameManager. Faz: MOLA <-> VARDİYA. Misafirler popülerliğe göre gelir,
## bira masalarındaki koltuklara oturur, TÜM vardiya boyunca kalır ve
## tekrar tekrar sipariş verir; otururken kutlar. Rol için insan yoksa NPC (Tasarom).

enum Phase { INTERMISSION = 0, SHIFT = 1 }

const INTERMISSION_TIME := 40.0
const SHIFT_TIME := 300.0          # 08:00–22:00 arası gerçek süre (sn)
# Gün saati (oyun içi saat)
const DAY_START_HOUR := 8.0        # uyanma — die Uhr steht hier, bis das Zelt öffnet
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
const DEKO_MAX := 30
const DEKO_ABSTAND := 1.8
const DEKO_ANDRANG := 0.02        # je Gegenstand 2 % mehr Gäste …
const DEKO_ANDRANG_MAX := 0.2     # … höchstens 20 %
## Abgestellt wird nur innerhalb der Zeltwände
const ZELT_MIN := Vector3(-11.6, 0, -13.6)
const ZELT_MAX := Vector3(11.6, 0, 10.6)
## Innenseiten der Zeltwände — hier hängt Wanddeko (scripts/einrichtung_katalog.gd "wand")
const WAND_X := 11.75
const WAND_HINTEN := -13.75
const WAND_VORN := 10.75
## Beim Tragen rastet Wanddeko erst ein, wenn eine Wand so nah ist
const WAND_FANG := 3.5

## Emporen links und rechts (scenes/tent.tscn Galerie, gebaut von tools/bake_zelt.gd).
## Gäste und Personal laufen ohne Navigation: liegt ihr Ziel auf einer anderen Ebene,
## führt _route sie über die Treppe (vor der Treppe → Fuß → Kopf → Austritt).
const EMPORE_Y := 3.6
const EMPORE_KANTE := 7.8        # ab |x| liegt oben die Empore
const EMPORE_LAUF_MAX := 10.4    # |x| für Laufziele oben — dahinter liegt das Treppenloch
## Je Empore (Index 0 West, 1 Ost): vor der Treppe, Treppenfuß, Treppenkopf, Austritt
const TREPPE := [
	[Vector3(-10.3, 0.1, -0.5), Vector3(-11.35, 0.1, 0.2), Vector3(-11.35, 3.7, 6.4), Vector3(-9.2, 3.7, 7.2)],
	[Vector3(10.3, 0.1, -10.8), Vector3(11.35, 0.1, -9.8), Vector3(11.35, 3.7, -3.7), Vector3(9.2, 3.7, -2.9)],
]
## Treppen am Boden (Mitte x/z, halbe Breite x/z) — dort keine Regale abstellen
const TREPPEN_BODEN := [[Vector2(-11.35, 3.25), Vector2(1.05, 3.7)], [Vector2(11.35, -6.75), Vector2(1.05, 3.7)]]
## Tischmitte oben: fest bei |x| = EMPORE_TISCH_X, längs gedreht; erlaubte z-Bereiche
## je Empore (nicht über dem Treppenloch und dem Austritt)
const EMPORE_TISCH_X := 10.3
const EMPORE_TISCH_Z := [
	[Vector2(-12.4, 1.1), Vector2(8.7, 9.4)],
	[Vector2(-12.4, -8.9), Vector2(-1.3, 9.4)],
]

## 0 = Boden, 1 = Empore West, 2 = Empore Ost
static func ebene_von(p: Vector3) -> int:
	if p.y < 1.8:
		return 0
	return 1 if p.x < 0.0 else 2

## Bodenhöhe einer Ebene
static func ebene_boden(ebene: int) -> float:
	return EMPORE_Y if ebene > 0 else 0.0

## Wegpunkte zum Ziel — über die Treppe(n), wenn das Ziel auf einer anderen Ebene liegt.
static func _route(von: Vector3, ziel: Vector3) -> Array:
	var a := ebene_von(von)
	var b := ebene_von(ziel)
	var r := []
	if a != b:
		if a > 0:
			var runter: Array = TREPPE[a - 1]
			r.append_array([runter[3], runter[2], runter[1], runter[0]])
		if b > 0:
			var hoch: Array = TREPPE[b - 1]
			r.append_array([hoch[0], hoch[1], hoch[2], hoch[3]])
	r.append(ziel)
	return r

## Nächster Wegpunkt für Gast/Mitarbeiter (Dictionary mit pos und tgt). Die Route
## wird neu berechnet, sobald sich das Ziel ändert; erreichte Zwischenpunkte fallen weg.
static func _wegpunkt(e: Dictionary, erreicht: float) -> Vector3:
	var ziel: Vector3 = e.tgt
	if not e.has("r_ziel") or (e.r_ziel as Vector3).distance_squared_to(ziel) > 0.0001:
		e.r_ziel = ziel
		e.route = _route(e.pos, ziel)
	var r: Array = e.route
	var pos: Vector3 = e.pos
	while r.size() > 1 and Vector2(pos.x - r[0].x, pos.z - r[0].z).length() <= erreicht:
		r.pop_front()
	return r[0]

## Ist nur noch das eigentliche Ziel übrig (keine Treppe mehr dazwischen)?
static func _nur_noch_ziel(e: Dictionary) -> bool:
	return (e.get("route", []) as Array).size() <= 1

## Punkt auf die Lauffläche seiner Ebene klemmen (Boden: vor der Theke; Empore:
## zwischen Brüstung und Treppenloch).
static func _auf_ebene(p: Vector3, ebene: int) -> Vector3:
	if ebene == 0:
		return Vector3(clampf(p.x, ZELT_MIN.x, ZELT_MAX.x), 0.1, clampf(p.z, -7.5, ZELT_MAX.z))
	var s := -1.0 if ebene == 1 else 1.0
	return Vector3(s * clampf(absf(p.x), EMPORE_KANTE + 0.5, EMPORE_LAUF_MAX), EMPORE_Y + 0.1,
		clampf(p.z, ZELT_MIN.z + 0.4, ZELT_MAX.z - 0.2))

## Regal/Gegenstand nicht auf einer Treppe: zur Zeltmitte hin daneben rücken.
static func _neben_treppe(p: Vector3) -> Vector3:
	for t: Array in TREPPEN_BODEN:
		var c: Vector2 = t[0]
		var h: Vector2 = t[1]
		if absf(p.x - c.x) < h.x and absf(p.z - c.y) < h.y:
			p.x = c.x - signf(c.x) * h.x
	return p
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
## Müll am Tisch: je Gast und Sekunde. Bei 20 Gästen sind das etwa vier Stück
## in der Minute — genug, dass immer etwas zu fegen ist, ohne das Zelt zuzumüllen.
const GAST_MUELL_JE_SEK := 0.0035
## Beim Gehen lässt ein Gast so oft noch etwas liegen
const GAST_MUELL_BEIM_GEHEN := 0.55

## Rausch der Gäste (0–100): Stufen ab 40 beschwipst, 70 betrunken, 90 Bierleiche.
const RAUSCH_STUFEN := [40.0, 70.0, 90.0]
const RAUSCH_JE_SORTE := {1: 18.0, 2: 20.0, 3: 10.0, 4: 26.0}
const RAUSCH_ESSEN := 12.0
const RAUSCH_ABBAU := 2.0 / 60.0          # je Sekunde am Platz
const RAUSCH_WASSER := 35.0
const RAUSCH_NACH_KOTZEN := 25.0
const BESCHWIPST_TRINKGELD := 0.15        # +15 % Trinkgeld ab Stufe 1
const BETRUNKEN_GEDULD := 0.8             # ab Stufe 2
const UMWERF_CHANCE := 0.2                # ab Stufe 2 geht jeder 5. Krug zu Bruch
const BIERLEICHE_KOTZEN := 60.0           # Sekunden, bis eine Bierleiche kotzt
const BIERLEICHE_POP := 2.0
const WASSER_POP := 1.0
const HEIMBRINGEN_TRINKGELD := 5
const WASSER_SORTE := 5                   # Krug mit Wasser (Fass am Rückwandregal)

## 0 gut gelaunt, 1 beschwipst, 2 betrunken, 3 Bierleiche
static func rausch_stufe(g: Dictionary) -> int:
	var r := float(g.get("rausch", 0.0))
	var s := 0
	for grenze: float in RAUSCH_STUFEN:
		if r >= grenze:
			s += 1
	return s
const DRINKS_BEFORE_PUKE := 4       # so viele Getränke, bevor jemandem schlecht wird

# Temizlik
const CLEAN_PER_CALL := 0.05
## Anteil von CLEAN_PER_CALL beim Dreck im verlassenen Zelt (Tutorial)
const DRECK_TEMPO := 0.1
## Paketsorte für Müllsäcke (Package.kind)
const MUELL := 3
const CLEAN_TIP_MIN := 6      # Trinkgeld fürs Saubermachen
const CLEAN_TIP_MAX := 12
const HYGIENE_DRAIN := 0.4   # je Fleck pro Sekunde (1.2 hielt die Sauberkeit dauerhaft bei 0)
## Anteil der Einnahmen, der auch im dreckigsten Zelt bleibt (vorher 40 %)
const HYGIENE_MIN_ANTEIL := 0.7
const HYGIENE_REGEN := 1.0
const NPC_CLEAN_RATE := 0.06
const START_MONEY := 1200   # Startbudget: Zelt 500 + 2 Tische 400 + 1 Paket Bier 60
## Schwierigkeit (Spaß-Plan 6.1): 0 Gemütlich, 1 Normal, 2 Wiesn-Wahnsinn
const STARTGELD := [1600, 1200, 900]
const GEDULD_FAKTOR := [1.35, 1.0, 0.8]
const ANDRANG_FAKTOR := [0.9, 1.0, 1.2]
const MIETE_FAKTOR := [0.75, 1.0, 1.3]
## Koop (Spaß-Plan 5.1): je weiterer Spieler so viel mehr Andrang
const KOOP_ANDRANG_JE_SPIELER := 0.2   # vorher 0.5 — zu viert war das nur noch Schleppen
## Abstimmung „Nächster Tag?": so lange läuft sie (Sekunden)
const ABSTIMMUNG_ZEIT := 30.0
## Klo: so lange wartet ein Gast vor besetztem Klo, dann geht er irgendwo ins Zelt
const KLO_WARTEN := 8.0
const SPIELERNAME_MAX := 16

# Zelt / makro-döngü (Wasenplatz mantığı)
const TENT_TABLE_LIMIT := {0: 0, 1: 4, 2: 8, 3: 16, 4: 24}   # main.tscn hat 24 Tische
## Tischanordnung in main.tscn. Ältere Spielstände (12er-Raster) bekommen die neue
## Anordnung, sonst stünden neue Tische auf alten.
const TISCH_LAYOUT := 3
const TENT_BOOK_COST := 500
const TENT_UPGRADE_COST := {2: 2000, 3: 6000, 4: 15000}   # vorher 3000/10000: im Bot nie erreicht
const TABLE_COST := 200
## Zeltmiete pro Tag am ersten Tag — steigt danach mit Wirtschaft.miete.
const TENT_RENT := {0: 0, 1: 120, 2: 220, 3: 450, 4: 650}   # vorher 300/700: großes Zelt machte Verlust
# Upgrades (kiosk)
const MARKETING_COST := 400   # her seviye +15 popülerlik enjeksiyonu
const MARKETING_BOOST := 15.0
const DEKO_COST := 600        # her seviye +%15 gelir
const DEKO_BONUS := 0.15
# E2.4 Lizenzen — başta sadece Helles satılır, gerisi Wiesenbüro'dan alınır
## Test 13.09.: etwas teurer — dafür bringt jede Lizenz mehr Spielraum beim Bierpreis
const LIC_COST := {"weizen": 1000, "radler": 1000, "brezn": 1500, "sosis": 1500, "festbier": 5000, "hendl": 6000}
## Bierpreis-Spielraum: ohne Lizenz 80–130 %, jede Lizenz erweitert ihn
const PREISRAUM_BASIS := Vector2(0.8, 1.3)
const PREISRAUM_JE_LIZENZ := Vector2(-0.05, 0.12)

## Wie weit sich der Bierpreis (Faktor) heute verstellen lässt.
func bierpreis_grenzen() -> Vector2:
	var n := 0
	for k: String in _lic:
		if _lic[k]:
			n += 1
	var unten := maxf(Wirtschaft.BIERPREIS_MIN, PREISRAUM_BASIS.x + PREISRAUM_JE_LIZENZ.x * n)
	var oben := minf(Wirtschaft.BIERPREIS_MAX, PREISRAUM_BASIS.y + PREISRAUM_JE_LIZENZ.y * n)
	return Vector2(snappedf(unten, 0.1), snappedf(oben, 0.1))

## Essenspreis (Faktor) — Test 13.09.: Lizenzen sollen an den Preisen schrauben
## lassen, nicht nur beim Bier. Spielraum wächst mit den Essenslizenzen.
const ESSEN_LIZENZEN := ["brezn", "sosis", "hendl"]
var _essenpreis := 1.0

func essenpreis_grenzen() -> Vector2:
	var n := 0
	for k: String in ESSEN_LIZENZEN:
		if _lic.get(k, false):
			n += 1
	var unten := maxf(Wirtschaft.BIERPREIS_MIN, PREISRAUM_BASIS.x + PREISRAUM_JE_LIZENZ.x * 1.5 * n)
	var oben := minf(Wirtschaft.BIERPREIS_MAX, PREISRAUM_BASIS.y + PREISRAUM_JE_LIZENZ.y * 1.5 * n)
	return Vector2(snappedf(unten, 0.1), snappedf(oben, 0.1))

## Zelt-Computer: Essenspreis in 10-%-Schritten (teurer bringt mehr je Portion,
## Gäste bestellen aber etwas seltener Essen).
@rpc("any_peer", "reliable", "call_local")
func net_set_essenpreis(schritte: int) -> void:
	if not multiplayer.is_server():
		return
	var raum := essenpreis_grenzen()
	_essenpreis = clampf(snappedf(_essenpreis + 0.1 * float(clampi(schritte, -5, 5)), 0.1), raum.x, raum.y)
	_broadcast_meta()
## Spätlizenzen (Spaß-Plan 4.3): erst ab Zeltstufe 3 oder der 2. Wiesn, dafür teurer im Verkauf
const LIC_SPAET := ["festbier", "hendl"]
const BIER_FESTBIER := 4
const ESSEN_HENDL := 3
const PREIS_FAKTOR_SORTE := {"1_4": 1.35, "2_3": 1.6}

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
## Eigenschaften beim Einstellen (Spaß-Plan 4.4): Tempo- und Lohnfaktor.
## charmeur: +Beliebtheit je Schicht · schluckspecht: trinkt nachts Bier vom Lager.
const EIGENSCHAFTEN := {
	"schnell": {"tempo": 1.3, "lohn": 1.25},
	"gemuetlich": {"tempo": 0.8, "lohn": 0.75},
	"charmeur": {"tempo": 1.0, "lohn": 1.15},
	"schluckspecht": {"tempo": 1.0, "lohn": 0.7},
	"normal": {"tempo": 1.0, "lohn": 1.0},
}
const CHARMEUR_POP := 2.0
const SCHLUCKSPECHT_BIER := 4
const STAFF_BASE_SPEED := 4.5   # vorher 3.0 — im großen Zelt blieben bis 100 Bestellungen liegen
## So weit hinter der Bank stehen Stehgäste
const STEHABSTAND := 0.55
const Figuren := preload("res://scripts/figuren.gd")
const TABLE_AVOID_RADIUS := 1.6   # Mitarbeiter halten Abstand zu Tischen (größer = bleiben in engen Gängen hängen)
const BAR_POINT := Vector3(-2.0, 0.1, -8.0)    # Kellner holt hier ab (vor der Ausgabe)
const KITCHEN_POINT := Vector3(5.0, 0.1, -12.2) # Koch steht vor der Kochtheke an der Rückwand
const ZAPFER_POINT := Vector3(-4.2, 0.1, -12.6) # Zapfer steht hinten an den Fässern am Rückwandregal
const KOCH_ABLAGE := Vector3(-0.8, 0.1, -10.4)  # hier stellt der Koch die Portion auf die Ausgabe
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
## Lieferwagen: kommt mittig die Allee vom Kirmestor herunter (nur ~4 m zwischen
## den Buden, Mitte x = -0.5), hält vor dem Eingangsbogen, wirft die Ware vor
## sich ab (DROP_POINT), setzt rückwärts bis zur freien Fläche bei z ≈ 58 zurück,
## wendet dort und fährt vorwärts wieder hoch. Wegpunkt = [Ort, rückwärts?].
const VAN_REIN := [[Vector3(-0.5, 0.0, 88.0), false], [Vector3(-0.5, 0.0, 30.0), false], [Vector3(-0.5, 0.0, 24.5), false]]
const VAN_RAUS := [[Vector3(-0.5, 0.0, 52.0), true], [Vector3(-3.5, 0.0, 58.5), true],
	[Vector3(-0.5, 0.0, 64.0), false], [Vector3(-0.5, 0.0, 88.0), false]]
## Langsamer auf den letzten Metern vor dem Halt und beim Wenden
const VAN_LANGSAM := 3.5
const VAN_SPEED := 9.0
const DROP_POINT := Vector3(-0.5, 0.0, 21.4)   # wo die Pakete landen (vor dem Wagen, am Bogen)

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
const PEE_CORNER := Vector3(11.2, 0.1, 7.6)    # Ecke, in die ohne Klo gepinkelt wird (dort kommt später das Klo hin)
const TOILET_POINT := Vector3(8.4, 0.1, 9.9)   # vor dem Klo-Container (main.tscn KloContainer)
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
## Tanzplätze auf dem Tisch, im Tischmaß (x = Länge 2,4 m, y = Tiefe 1,6 m).
## Vorher lagen sie bei -0,6 / +0,6 / 0,0 alle auf der Mittellinie — der dritte
## stand damit genau zwischen den beiden anderen, und weil der Platz nur aus der
## Anzahl der Tänzer abgeleitet wurde, bekamen nach einem Wechsel auch zwei
## denselben. Jetzt stehen sich zwei gegenüber, der dritte tanzt daneben.
const TANZ_PLAETZE := [Vector2(-0.55, 0.4), Vector2(-0.55, -0.4), Vector2(0.8, 0.0)]
## Wer wem zugewandt tanzt (Platz -> Gegenüber, -1 = niemand)
const TANZ_PARTNER := [1, 0, -1]
## Tagesereignisse (Spaß-Plan 3.1): ab Tag 3 wird morgens eins angekündigt.
const EREIGNISSE := ["bus", "kontrolle", "happy", "fass", "prosit", "promi", "regen"]
const REGEN_VOLL_CHANCE := 0.6   # so oft flüchten bei Regen viele ins Zelt
const EREIGNIS_AB_TAG := 3
const EREIGNIS_CHANCE := 0.7
const HAPPY_VON := 18.0
const HAPPY_BIS := 19.0
const KONTROLLE_UM := 15.0
const KONTROLLE_GRENZE := 60.0
const KONTROLLE_STRAFE := 300
const KONTROLLE_BONUS := 10.0
const PROSIT_ALLE := 40.0          # Sekunden (~2 Spielstunden)
## Kombo: schnell hintereinander bedienen gibt mehr Trinkgeld (Spaß-Plan 2.1)
const KOMBO_FENSTER_MS := 8000
const KOMBO_BONUS := 2
const KOMBO_MAX := 10
## Finale am letzten Wiesn-Tag: voller Andrang, Star-Act spielt gratis
const FINALE_ANDRANG := 1.3
## Nächste Wiesn wird anspruchsvoller (Spaß-Plan 4.2) — je Wiesn nach der ersten:
const SAISON_MIETE := 0.2       # +20 % Miete
const SAISON_GEDULD := 0.06     # −6 % Geduld (nie unter 70 %)
const SAISON_ANDRANG := 0.1     # +10 % Gäste
## Gästetypen (Spaß-Plan 3.2): "" normal, stamm, tourist, tracht, vip — Gewichte
const GAST_TYPEN := {"": 55, "stamm": 15, "tourist": 15, "tracht": 10, "vip": 5}
const TYP_GEDULD := {"stamm": 1.5, "tourist": 0.7, "vip": 0.8}
const TYP_TRINKGELD := {"stamm": 5, "tourist": 3, "vip": 15}
const TYP_POP := {"stamm": 1.5, "vip": 2.5}   # Beliebtheit beim Bedienen und Verpassen
const VIP_AB_BELIEBTHEIT := 40.0

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
var _ereignis := ""          # heutiges Tagesereignis ("" = keins)
var _ereignis_erledigt := false
var _prosit_timer := 0.0
var _fass_kaputt := 0        # Sorte, die heute fehlt (Ereignis "fass")
var _kombo := {}             # Peer -> {n, t}: Kombo beim Bedienen
## Zahlen der laufenden Wiesn (für die Bewertung am Finale), wird gespeichert
var _saison := {"umsatz": 0, "netto": 0, "bedient": 0, "verpasst": 0, "pop_summe": 0, "tage": 0}
var _saison_nr := 1
var _schwierigkeit := 1
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
## Vom Spieler beim Mieten vergeben ("" = Standardname)
var _zelt_name := ""
## Gast auf dem Klo (-1 = frei) — eine Person gleichzeitig
var _klo_gast := -1
## Laufende Abstimmung: {starter, ja: {peer: true}, nein: {peer: true}, rest: Sekunden}
var _abstimmung := {}
## Spieler aus der Lobby: {peer: {name, farbe, figur}}
var _spieler_info := {}
const ZELTNAME_MAX := 24
var _active_count := 0   # aktif (görünür/oturulabilir) masa sayısı
var _day := 1            # Wiesn günü
var _upg_marketing := 0  # Werbung seviyesi (popülerlik enjeksiyonu)
var _upg_deko := 0       # Deko seviyesi (gelir çarpanı)
# E2.4: satın alınan lisanslar (Helles lisanssız hep satılır)
var _lic := {"weizen": false, "radler": false, "brezn": false, "sosis": false, "festbier": false, "hendl": false}
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
var _van_weg: Array = []        # restliche Wegpunkte
var _van_yaw := PI
var _van_cargo := []            # [{kind, packs}] die abgeladen werden
# E5: gebuchter Künstler (gilt für die nächste Schicht, danach verbraucht)
var _artist_tier := 0
var _artist_nodes := []
# E6: Klo / Urin / Beschwerden
var _has_toilet := false
var _mess_kind := {}          # mess_id -> 0 Erbrochenes, 1 Urin
var _complain_timer := 0.0
var _urin_count := 0          # Tageszähler für den Report
## Tageszähler: gekochte Portionen (Koch und Spieler) und rausgeworfene Gäste —
## beides steht abends im Wiesn-Kurier
var _essen_gekocht := 0
var _rausgeworfen := 0
var _complaints := 0
var _left_guests := 0
# Tutorial-Fortschritt
var _quest_step := 0
## Einleitung gelaufen und dem Wiesnchef zum Zelt gefolgt (Schritt 0)
var _folge_geschafft := false
var _quest_served_once := false
var _ever_artist := false
var _quest_timer := 0.0
# Meilensteine (Plan 3.2): Lebenszeit-Zähler und erreichte IDs, beides im Spielstand
const Meilensteine := preload("res://scripts/meilensteine.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
var _stats := {"served": 0, "earned": 0, "days": 0, "cleaned": 0, "saisons": 0, "beste_wertung": 0,
	"tanzen": 0, "gekotzt": 0, "kombo_max": 0, "tage_sauber": 0, "ereignisse": 0}
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
var _haelt_tisch := {}        # vom Server: Peer-ID (Text) -> Tischindex, für Drehen und Hinweise
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
## Tageswerte für den Lichterfest-Abend (Leuchten, Belichtung, Sättigung)
var _day_glow := 0.7
var _day_bloom := 0.05
var _day_exposure := 1.0
var _day_saettigung := 1.0
var _night_visual := false
var _night_t := -1.0
## Helligkeit der Deckenlichter bei voller Nacht
const DECKENLICHT_ENERGIE := 0.4   # Test 13.09.: nachts zu grell (vorher 0.55)
var _regen_t := -1.0
## Nach 22 Uhr bis zum Schlafen: Zelt geschlossen, aber Nacht
var _nachts_geschlossen := false
var _nachtruhe := false
var _regen_voll := false   # Regen: flüchten heute viele ins Zelt?

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
		_day_glow = _world_env.environment.glow_intensity
		_day_bloom = _world_env.environment.glow_bloom
		_day_exposure = _world_env.environment.tonemap_exposure
		_day_saettigung = _world_env.environment.adjustment_saturation
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
			_schwierigkeit = clampi(Net.schwierigkeit, 0, 2)
			Game.add_money(int(STARTGELD[_schwierigkeit]))
		elif not _load_game():
			Game.add_money(int(STARTGELD[_schwierigkeit]))
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
		# Onkel Sepps Brief läuft nicht mehr als Einleitung am Kirmestor: die hing
		# am Hochfahren des Hosts und wurde auf einem eigenen Server (Koop über
		# den Vermittler) übersprungen, wo es keine Oberfläche gibt — dort sah ihn
		# niemand. Jetzt liest ihn der Wiesnchef im ersten Gespräch vor
		# (scripts/npc_wiesnchef.gd).
	else:
		_anmelden_beim_server()

func in_intermission() -> bool:
	return _phase == Phase.INTERMISSION

func _tent_ready() -> bool:
	return _tent_stage > 0 and _active_count > 0

## Beliebtheit: Durch gutes Bedienen allein geht es nur bis POP_NATUR_MAX. Den Rest
## bis 100 % holt man mit gebuchten Künstlern (je Stufe mehr), Werbung und Deko —
## sonst hätten Künstler keinen Sinn (Test 13.09.: nach kurzer Zeit 100 %).
const POP_NATUR_MAX := 65.0
const POP_KUENSTLER_GRENZE := {1: 10.0, 2: 20.0, 3: 35.0}
const POP_DEKO_GRENZE := 2.0      # je Einrichtungsgegenstand …
const POP_DEKO_GRENZE_MAX := 10.0 # … höchstens so viel

## Gemütlichkeit: aufgestellte Einrichtung macht die Gäste geduldiger.
## Vorher zog Deko nur die Beliebtheitsgrenze um höchstens 10 Punkte hoch —
## im Spiel war das kaum zu merken, Deko also fast sinnlos. Jetzt zählt der
## Wert des Aufgestellten (Katalogpreis): teure Stücke bringen mehr als viele
## billige. Gerechnet je 100 €, gedeckelt — sonst wäre Warten irgendwann egal.
const GEMUET_JE_100 := 0.01
const GEMUET_MAX := 0.25

## Wert der aufgestellten Einrichtung in Euro
func deko_wert() -> int:
	var w := 0
	for e: Dictionary in _einrichtung.values():
		w += Katalog.preis(str(e.get("art", "")))
	return w

## Geduldzuschlag aus der Gemütlichkeit (0.0 … GEMUET_MAX)
func gemuetlichkeit() -> float:
	return minf(GEMUET_MAX, float(deko_wert()) / 100.0 * GEMUET_JE_100)

func _pop_grenze() -> float:
	var g := POP_NATUR_MAX + float(POP_KUENSTLER_GRENZE.get(_artist_tier, 0.0))
	g += minf(POP_DEKO_GRENZE_MAX, POP_DEKO_GRENZE * float(_einrichtung.size()))
	# Festliche Tagesereignisse (Promi, Prosit, Freibierfass, Happy Hour, Finale)
	# ziehen die Grenze ebenfalls hoch — Regen, Kontrolle und Bus nicht
	if _ereignis in POP_EREIGNIS_GRENZE:
		g += float(POP_EREIGNIS_GRENZE[_ereignis])
	return minf(100.0, g)

const POP_EREIGNIS_GRENZE := {"promi": 15.0, "prosit": 10.0, "fass": 10.0, "happy": 5.0, "finale": 20.0, "anstich": 5.0, "italiener": 5.0}

## Beliebtheit durch Bedienen erhöhen — höchstens bis zur heutigen Grenze.
func _pop_erhoehen(betrag: float) -> void:
	var grenze := _pop_grenze()
	if _popularity < grenze:
		_popularity = minf(grenze, _popularity + betrag)

# ================================================= Ablegen und Aufheben (Test 13.09.)
## E ins Leere mit etwas in der Hand: ablegen statt löschen. Krüge und Teller liegen
## sichtbar am Boden (scenes/abgelegt.tscn), Pakete werden wieder zu Paketen.
const ABGELEGT_SCENE := preload("res://scenes/abgelegt.tscn")
const ABLAGE_MAX := 40
const ABLAGE_REICHWEITE := 3.0
var _abgelegt := {}          # id -> {pos, art, typ, fill}
var _abgelegt_nodes := {}
var _abgelegt_next := 0

## Ablageort nahe beim Spieler (Server prüft, damit niemand quer durchs Zelt legt).
func _ablageort(s: int, pos: Vector3) -> Vector3:
	var pl = _players_nodes.get(s)
	if pl and (pl as Node3D).global_position.distance_to(pos) > ABLAGE_REICHWEITE:
		pos = (pl as Node3D).global_position
	# Auf der Empore bleibt es oben liegen
	return Vector3(pos.x, ebene_boden(ebene_von(pos)), pos.z)

@rpc("any_peer", "reliable", "call_local")
func net_ablegen(art: int, typ: int, fill: float, pos: Vector3) -> void:
	if not multiplayer.is_server() or (art != 1 and art != 2):
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _abgelegt.size() >= ABLAGE_MAX:
		var aeltester: int = _abgelegt.keys().min()
		_abgelegt.erase(aeltester)
		_remove_abgelegt.rpc(aeltester)
	var id := _abgelegt_next
	_abgelegt_next += 1
	var ort := _ablageort(s, pos)
	_abgelegt[id] = {"pos": ort, "art": art, "typ": clampi(typ, 0, WASSER_SORTE), "fill": clampf(fill, 0.0, 1.0)}
	_add_abgelegt.rpc(id, ort, art, clampi(typ, 0, WASSER_SORTE), clampf(fill, 0.0, 1.0))

@rpc("authority", "reliable", "call_local")
func _add_abgelegt(id: int, pos: Vector3, art: int, typ: int, fill: float) -> void:
	if _abgelegt_nodes.has(id):
		return
	var n := ABGELEGT_SCENE.instantiate()
	n.name = "Abgelegt%d" % id
	n.ablage_id = id
	n.position = pos
	add_child(n)
	n.setzen(art, typ, fill)
	_abgelegt_nodes[id] = n

@rpc("authority", "reliable", "call_local")
func _remove_abgelegt(id: int) -> void:
	var n = _abgelegt_nodes.get(id)
	if n and is_instance_valid(n):
		n.queue_free()
	_abgelegt_nodes.erase(id)

@rpc("any_peer", "reliable", "call_local")
func net_aufheben(id: int) -> void:
	if not multiplayer.is_server() or not _abgelegt.has(id):
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var d: Dictionary = _abgelegt[id]
	_abgelegt.erase(id)
	_remove_abgelegt.rpc(id)
	if s == multiplayer.get_unique_id():
		_net_aufgehoben(int(d.art), int(d.typ), float(d.fill))
	else:
		_net_aufgehoben.rpc_id(s, int(d.art), int(d.typ), float(d.fill))

## Beim aufhebenden Spieler: in die Hand (Hand ist leer — sonst gleich wieder hinlegen).
@rpc("authority", "reliable", "call_local")
func _net_aufgehoben(art: int, typ: int, fill: float) -> void:
	var p = _players_nodes.get(multiplayer.get_unique_id())
	if p == null:
		return
	if int(p.carry_state) != 0:
		net_ablegen.rpc_id(1, art, typ, fill, (p as Node3D).global_position)
		return
	p.carry_state = art
	p.carry_type = typ
	p.carry_fill = fill

## Getragenes Warenpaket ablegen — es wird wieder ein Paket am Boden.
@rpc("any_peer", "reliable", "call_local")
func net_paket_ablegen(kind: int, amount: int, pos: Vector3) -> void:
	if not multiplayer.is_server() or (not _stock.has(kind) and kind != MUELL) or amount <= 0:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var id := _pkg_next
	_pkg_next += 1
	_add_package.rpc(id, _ablageort(s, pos), kind, clampi(amount, 1, PACK_UNITS * 5))

# ================================================= Zelt eröffnen (Test 13.09.)
## Nach dem Aufstehen ist die Kirmes offen, das Festzelt noch zu. Ein Spieler sticht
## am Eingang das Fass an (scenes/zelt_eroeffnung.tscn), erst dann kommen Gäste.
## Macht es niemand, öffnet das Zelt um AUTO_OEFFNEN_STUNDE von selbst.
## Solange das Zelt zu ist, steht die Uhr — vorbereiten geht also ohne
## Zeitdruck. Macht es niemand auf, öffnet es nach dieser Wartezeit von selbst.
## 60 s entsprechen den früheren drei Spielstunden von 7 bis 10 Uhr, als die Uhr
## beim Warten noch weiterlief.
const AUTO_OEFFNEN_WARTEN := 60.0
var _zelt_offen := true
var _zelt_wartet := 0.0   # Sekunden seit dem Aufstehen, in denen das Zelt zu ist

func _eroeffnung_anzeigen() -> void:
	var bereit := _phase == Phase.SHIFT and not _zelt_offen and _tent_stage > 0
	for n in get_tree().get_nodes_in_group("zelt_eroeffnung"):
		if n.has_method("bereit_setzen"):
			n.bereit_setzen(bereit)

@rpc("any_peer", "reliable", "call_local")
func net_zelt_eroeffnen() -> void:
	if not multiplayer.is_server() or _phase != Phase.SHIFT or _zelt_offen:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	_zelt_eroeffnen(_spieler_bezeichnung(s), false)

func _zelt_eroeffnen(wer: String, von_selbst: bool) -> void:
	_zelt_offen = true
	# Erste Gäste bald nach der Eröffnung, nicht erst eine Minute später
	_guest_spawn_timer = randf_range(ERSTE_GAESTE_MIN * 0.4, ERSTE_GAESTE_MAX * 0.4)
	if von_selbst:
		_melde("MSG_ZELT_AUTO")
	else:
		_melde("MSG_ZELT_OFFEN", [wer], 2)
	_eroeffnung_anzeigen()
	_broadcast_meta()

## Vardiyadaki oyun içi saat (8.0 = 08:00). Kapalıyken -1.
## Zelt noch nicht eröffnet: die Uhr steht auf DAY_START_HOUR.
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
		tables.append({"x": p.x, "y": p.y, "z": p.z, "r": (bt as Node3D).rotation.y})
	var data := {
		"tisch_layout": TISCH_LAYOUT,
		"massen_gehabt": _massen_gehabt,
		"lager_gekauft": _lager_gekauft,
		"lager_lagen": _lager_lagen(),
		"essenpreis": _essenpreis,
		"money": Game.money,
		"score": Game.score,
		"day": _day,
		"tent_stage": _tent_stage,
		"zelt_name": _zelt_name,
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
		"folge": _folge_geschafft,
		"quest_version": QUEST_VERSION,
		"ever_artist": _ever_artist,
		"stats": _stats,
		"meilensteine": _meilensteine,
		# Formatversion: ältere Spielversionen laden keinen neueren Stand (Net.SAVE_FORMAT)
		"kredit": _kredit_rest,
		"bank": _bank_bezahlt,
		"huber_wette": _huber_wette,
		"sabotage_tag": _letzte_sabotage,
		"duell_saison": _duell_saison,
		"plan": _plan,
		"plan_saison": _plan_saison,
		"stamm": _stamm,
		"tagesziel": _tagesziel,
		"bierpreis": _bierpreis,
		"einrichtung": _einrichtung.values(),
		"saison": _saison,
		"saison_nr": _saison_nr,
		"schwierigkeit": _schwierigkeit,
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
	_tent_stage = clampi(int(d.get("tent_stage", 0)), 0, 4)
	_zelt_name = zeltname_pruefen(str(d.get("zelt_name", "")))
	_active_count = int(d.get("active_count", 0))
	_upg_marketing = int(d.get("upg_marketing", 0))
	_upg_deko = int(d.get("upg_deko", 0))
	_popularity = clampf(float(d.get("popularity", POP_START)), 5.0, 100.0)
	_shift_num = int(d.get("shift_num", 0))
	var lic: Variant = d.get("lic", {})
	if lic is Dictionary:
		for k in LIC_COST.keys():
			_lic[k] = bool((lic as Dictionary).get(k, false))
	var raum := bierpreis_grenzen()
	_bierpreis = clampf(_bierpreis, raum.x, raum.y)
	var essen_raum := essenpreis_grenzen()
	_essenpreis = clampf(float(d.get("essenpreis", 1.0)), essen_raum.x, essen_raum.y)
	_has_toilet = bool(d.get("toilet", false))
	_quest_step = int(d.get("quest", 0))
	_folge_geschafft = bool(d.get("folge", false))
	_dreck_nachlegen = true   # Flecken werden nicht gespeichert — im Putzschritt neu auslegen
	# Alte Stände: Schritte ab 3 sind durch die zwei neuen Liefer-Schritte eins weiter
	var quest_alt := int(d.get("quest_version", 1))
	if quest_alt < 2 and _quest_step >= 3:
		_quest_step += 1
	# Version 3: Schritt 0 (dem Wiesnchef folgen) kam vorn dazu — der ist in alten
	# Spielständen längst gelaufen, also rücken alle Schritte eins weiter.
	if quest_alt < 4 and quest_alt >= 3 and _quest_step >= 2:
		_quest_step += 1
	if quest_alt < 3:
		if _quest_step >= 1:
			_quest_step += 1   # Putzschritt (Version 4)
		_quest_step += 1
		_folge_geschafft = true
	_ever_artist = bool(d.get("ever_artist", false))
	var gespeicherte_stats: Variant = d.get("stats", {})
	if gespeicherte_stats is Dictionary:
		for k in Meilensteine.ZAEHLER:
			_stats[k] = int((gespeicherte_stats as Dictionary).get(k, 0))
	var erreicht: Variant = d.get("meilensteine", [])
	if erreicht is Array:
		_meilensteine = (erreicht as Array).map(func(x: Variant) -> String: return str(x))
	_kredit_rest = maxi(0, int(d.get("kredit", 0)))
	# Sepps Schulden: ältere Spielstände (vor Version 175) haben keine — dort gilt alles als bezahlt
	_bank_bezahlt = clampi(int(d.get("bank", Wirtschaft.BANK_RATEN.size())), 0, Wirtschaft.BANK_RATEN.size())
	var wette_gespeichert: Variant = d.get("huber_wette", {})
	_huber_wette = wette_gespeichert if wette_gespeichert is Dictionary else {}
	_letzte_sabotage = int(d.get("sabotage_tag", 0))
	_duell_saison = int(d.get("duell_saison", 0))
	var plan_gespeichert: Variant = d.get("plan", [])
	_plan = plan_gespeichert if plan_gespeichert is Array else []
	_plan_saison = int(d.get("plan_saison", 0))
	var stamm_gespeichert: Variant = d.get("stamm", {})
	_stamm = stamm_gespeichert if stamm_gespeichert is Dictionary else {}
	var ziel_gespeichert: Variant = d.get("tagesziel", {})
	_tagesziel = ziel_gespeichert if ziel_gespeichert is Dictionary else {}
	_bierpreis = float(d.get("bierpreis", 1.0))   # Spielraum wird nach dem Laden der Lizenzen geprüft
	_saison_nr = maxi(1, int(d.get("saison_nr", 1 + (_day - 1) / Wirtschaft.SAISON_TAGE)))
	_schwierigkeit = clampi(int(d.get("schwierigkeit", 1)), 0, 2)
	var gespeicherte_saison: Variant = d.get("saison", {})
	if gespeicherte_saison is Dictionary:
		for k in _saison.keys():
			_saison[k] = int((gespeicherte_saison as Dictionary).get(k, 0))
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
				_restore_staff(int((e as Dictionary).get("role", 2)), int((e as Dictionary).get("level", 1)),
					str((e as Dictionary).get("eig", "normal")), e as Dictionary)
	_massen_gehabt = bool(d.get("massen_gehabt", false))
	var tp: Variant = d.get("tables", [])
	if tp is Array and int(d.get("tisch_layout", 1)) == TISCH_LAYOUT:
		var arr: Array = tp
		for i in range(mini(arr.size(), _all_tables.size())):
			var e: Variant = arr[i]
			if e is Dictionary:
				var ed: Dictionary = e
				var ty := EMPORE_Y if float(ed.get("y", 0.0)) > 1.8 else 0.0
				(_all_tables[i] as Node3D).position = Vector3(float(ed.get("x", 0.0)), ty, float(ed.get("z", 0.0)))
				(_all_tables[i] as Node3D).rotation.y = float(ed.get("r", 0.0))
	_active_count = clampi(_active_count, 0, _all_tables.size())
	# Gekaufte Lagerregale wieder aufstellen, dann die Lage aller Regale
	_lager_gekauft = clampi(int(d.get("lager_gekauft", 0)), 0, LAGERREGAL_PLAETZE.size())
	for nr in range(1, _lager_gekauft + 1):
		var platz: Vector3 = LAGERREGAL_PLAETZE[nr - 1]
		_add_lagerregal(nr, platz.x, platz.y, platz.z)
	var lagen: Variant = d.get("lager_lagen", [])
	if lagen is Array:
		_net_lager(lagen)
	# Spielstände von vor den Emporen: Regale nicht auf den Treppen stehen lassen
	for r in _lagerregale():
		(r as Node3D).position = _neben_treppe((r as Node3D).position)
	_apply_tent()
	# … und Tische nicht auf Treppen oder Stützen
	for i in _beertables.size():
		_tisch_freistellen(i)
	_rebuild_seats()
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
	if _ereignis == "regen":
		f *= 0.25   # bei Regen ist draußen kaum jemand
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
		# Zelt zu: nach Feierabend bleibt es Nacht, erst mit dem Schlafen wird es Tag
		return 1.0 if _nachts_geschlossen else 0.0
	if clock <= DUSK_START:
		return 0.0
	if clock >= DUSK_END:
		return 1.0
	return smoothstep(0.0, 1.0, (clock - DUSK_START) / (DUSK_END - DUSK_START))

const ALTSTADT_MAT := preload("res://assets/altstadt/altstadt.tres")

## Dämmerung stufenlos: Sonne, Himmel und Umgebungslicht wandern langsam runter.
func _apply_daylight(clock: float) -> void:
	var t := _daylight_factor(clock)
	# Feierabend: Fahrgeschäfte stehen still, das Standpersonal geht heim (Gruppe „nachtruhe")
	var ruhe := clock < 0.0 and _nachts_geschlossen
	if ruhe != _nachtruhe:
		_nachtruhe = ruhe
		get_tree().call_group("nachtruhe", "nachtruhe", ruhe)
	var r := 1.0 if _ereignis == "regen" else 0.0
	if absf(t - _night_t) < 0.01 and absf(r - _regen_t) < 0.01:
		return
	_night_t = t
	_regen_t = r
	if _sun:
		# Nachts bleibt ein weiches, leicht blaues Mondlicht — dunkel genug, dass
		# die bunten Kirmeslichter wirken, hell genug, dass man alles erkennt.
		# Schatten bleiben an: früher gingen sie bei halber Dämmerung aus und die
		# Sonne schien schlagartig durchs Zeltdach — das Zelt wurde plötzlich hell.
		# Look „Stil“ (tools/look_test.tscn, Variante C): warme, kräftige Sonne am Tag
		_sun.light_energy = lerpf(_day_sun_energy, _day_sun_energy * 0.096, t) * (1.0 - 0.45 * r)
		_sun.light_color = Color(1.0, 0.9, 0.76).lerp(Color(0.86, 0.8, 0.68), t)
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		env.ambient_light_energy = lerpf(_day_ambient, _day_ambient * 0.6, t) * (1.0 - 0.3 * r)
		env.background_energy_multiplier = lerpf(_day_bg, _day_bg * 0.22, t)
		# Nebel bleibt ein dünner Dunst — er soll das Licht der Buden einfangen,
		# nicht die Sicht nehmen. Nachts und bei Regen dichter.
		# (vorher ×4 nachts — mit dem Lichterfest-Look wirkte das Zelt dann milchig)
		env.fog_density = lerpf(_day_fog, _day_fog * 1.8, t) * (1.0 + 3.0 * r)
		env.fog_light_color = _day_fog_color.lerp(Color(0.26, 0.23, 0.30), t)
		# Lichterfest-Abend (Stilvorschau tools/render_licht.tscn): Lichterketten
		# leuchten warm, etwas höher belichtet, kräftigere Farben. Lichtnebel nur
		# auf Grafikstufe Hoch — der ist teuer (Glow/Farbkorrektur schaltet grafikstufe.gd).
		# Test 13.09.: nachts taten die Lichter in den Augen weh — Glühen und
		# Belichtung deutlich zurückgenommen
		env.glow_intensity = lerpf(_day_glow, 0.9, t)
		env.glow_bloom = lerpf(_day_bloom, 0.08, t)
		env.tonemap_exposure = lerpf(_day_exposure, 1.36, t)
		env.adjustment_saturation = lerpf(_day_saettigung, _day_saettigung * 1.1, t)
		env.volumetric_fog_enabled = Einstellungen.grafik >= 2 and t > 0.02
		env.volumetric_fog_density = 0.006 * t
		env.volumetric_fog_albedo = Color(1.0, 0.82, 0.62)
	# Warme Deckenlichter über den Tischen (main.tscn Deckenlichter) — nur abends,
	# ohne Schatten; sonst ist das Zelt nachts zu dunkel
	for d in get_tree().get_nodes_in_group("deckenlicht"):
		(d as Light3D).light_energy = DECKENLICHT_ENERGIE * t
		(d as Light3D).visible = t > 0.01
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		if env.sky and env.sky.sky_material is ShaderMaterial:
			var himmel := env.sky.sky_material as ShaderMaterial
			himmel.set_shader_parameter("nacht", t)
			himmel.set_shader_parameter("regen", r)
	# Altstadt-Kulisse: nachts leuchten die Fenster
	ALTSTADT_MAT.set_shader_parameter("nacht", t)
## Geduld je Bestellung — sinkt mit dem Spieltag (Wirtschaft.geduld).
func _geduld() -> float:
	var g := Wirtschaft.geduld(ORDER_PATIENCE, _day) * float(GEDULD_FAKTOR[_schwierigkeit]) \
		* maxf(0.7, 1.0 - SAISON_GEDULD * float(_saison_nr - 1))
	if _ereignis == "familie":
		g *= 1.2   # Familien warten geduldiger
	g *= 1.0 + gemuetlichkeit()   # gemütliches Zelt: man wartet lieber
	return g * 0.85 if _ereignis == "bus" else g

func _daily_rent() -> int:
	return roundi(float(Wirtschaft.miete(int(TENT_RENT.get(_tent_stage, 0)), _day)) * float(MIETE_FAKTOR[_schwierigkeit])
		* (1.0 + SAISON_MIETE * float(_saison_nr - 1)))

## E2.4: satılabilir içecek tipleri — lisansa bağlı (1 Helles hep açık).
func _drinks_avail() -> Array:
	var a := [1]
	if _lic.get("weizen", false):
		a.append(2)
	if _lic.get("radler", false):
		a.append(3)
	if _lic.get("festbier", false):
		a.append(BIER_FESTBIER)
	if _fass_kaputt > 0 and a.size() > 1:
		a.erase(_fass_kaputt)
	return a

## E2.4: satılabilir yemek tipleri — lisans yoksa hiç yemek satılmaz.
func _foods_avail() -> Array:
	var a := []
	if _lic.get("brezn", false):
		a.append(1)
	if _lic.get("sosis", false):
		a.append(2)
	if _lic.get("hendl", false):
		a.append(ESSEN_HENDL)
	return a

## Spätlizenzen kaufbar? (Zeltstufe 3 oder ab der 2. Wiesn)
func spaetlizenz_frei() -> bool:
	return _tent_stage >= 3 or _saison_nr >= 2

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
## Vom Vermittler gestartete Spiele: so lange ohne Spieler, dann speichern und beenden.
## Der Warteraum mit dem Code bleibt — „Los" startet das Spiel am Spielstand neu.
const LEER_ENDE := 300.0
var _leer_seit := 0.0

func _leer_pruefen(delta: float) -> void:
	if Net.spiel_code == "":
		return
	_leer_seit += delta
	if _leer_seit >= LEER_ENDE:
		print("[DEDICATED] Spiel %s: niemand mehr da — speichern und beenden" % Net.spiel_code)
		_save_game()
		get_tree().quit()

## Code-Spiele melden dem Vermittler alle paar Sekunden, wer drin ist. Wer weg ist,
## gibt dort Platz und Abteilung frei (tools/server/vermittler.py a_spielstand).
const VERMITTLER_MELDUNG_URL := "http://127.0.0.1:8700/spielstand"
const VERMITTLER_MELDEN_ALLE := 10.0
var _vermittler_t := 0.0
## Warteraum-ID je Spieler — nur auf dem Server, nicht an Clients verteilen
var _lobby_ids := {}

func _vermittler_melden(delta: float) -> void:
	if Net.spiel_code == "":
		return
	_vermittler_t -= delta
	if _vermittler_t > 0.0:
		return
	_vermittler_t = VERMITTLER_MELDEN_ALLE
	var http := get_node_or_null("VermittlerMeldung") as HTTPRequest
	if http == null or http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var ids: Array[String] = []
	for peer in _lobby_ids.keys():
		if _players_nodes.has(peer):
			ids.append(str(_lobby_ids[peer]))
	http.request(VERMITTLER_MELDUNG_URL, PackedStringArray(["Content-Type: application/json"]),
		HTTPClient.METHOD_POST, JSON.stringify({"code": Net.spiel_code, "ids": ids}))

func _pruefe_eigenen_spieler() -> void:
	if not multiplayer.is_server() and not _players_nodes.has(multiplayer.get_unique_id()):
		Net.trennen_mit_meldung("NET_NO_ANSWER")

## Beim Server anmelden — und es wiederholen, solange kein eigener Spieler kommt.
##
## Ein eigener Server (Koop über den Vermittler) öffnet den Port sofort, lädt die
## Welt danach aber noch rund zehn Sekunden. Wer in dieser Lücke verbindet, steht
## zwar in der Verbindung, aber am anderen Ende gibt es noch keinen GameManager,
## der `_client_ready` hören könnte — die Nachricht verpufft und der Spieler flog
## mit „Host hat das Spiel verlassen" wieder raus. Darum mehrfach anklopfen statt
## einmal, und erst danach aufgeben.
const ANMELDE_VERSUCHE := 12
const ANMELDE_ABSTAND := 2.0

func _anmelden_beim_server() -> void:
	for _versuch in ANMELDE_VERSUCHE:
		if not is_inside_tree() or multiplayer.is_server() \
				or _players_nodes.has(multiplayer.get_unique_id()):
			return
		if multiplayer.multiplayer_peer == null \
				or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
			# Verbindung noch im Aufbau oder schon wieder weg — kurz warten und
			# erneut sehen; abgelehnt wird getrennt über _net_abgelehnt gemeldet.
			await get_tree().create_timer(ANMELDE_ABSTAND).timeout
			continue
		_client_ready.rpc_id(1, KoopDaten.version())
		await get_tree().create_timer(ANMELDE_ABSTAND).timeout
	# Antwortet der Server auch dann nicht (etwa ein älterer Stand, der die
	# Nachricht nicht versteht), nicht ewig in einer leeren Welt stehen
	if is_inside_tree():
		_pruefe_eigenen_spieler()

## Server lehnt den Beitritt ab (z. B. andere Version) — beim Client.
@rpc("authority", "reliable")
func _net_abgelehnt(schluessel: String, werte: Array) -> void:
	Net.trennen_mit_meldung(schluessel, werte)

@rpc("any_peer", "reliable")
func _client_ready(version: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	# Der Client klopft mehrfach an, bis sein Spieler da ist (_anmelden_beim_server).
	# Wer schon angemeldet ist, darf kein zweites Mal eingesetzt werden.
	if _spawn_index_by_peer.has(sender):
		return
	# Unterschiedliche Stände verstehen ihre Nachrichten nicht — sauber ablehnen,
	# statt den Spieler in einer halb synchronen Welt stehen zu lassen.
	if version != KoopDaten.version():
		_net_abgelehnt.rpc_id(sender, "NET_VERSION_MISMATCH", [KoopDaten.version(), version])
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
	# Namen, Farben und Abteilungen der anderen (Lobby)
	_net_spieler_info.rpc_id(sender, _spieler_info)
	for mid in _messes.keys():
		_add_mess.rpc_id(sender, mid, (_messes[mid] as Node3D).position, int(_mess_kind.get(mid, 0)))
	for gid in _guest_sim.keys():
		var gt := str(_guest_sim[gid].get("typ", ""))
		if _guest_sim[gid].has("stamm"):
			gt = "stamm|" + str(_guest_sim[gid].stamm)
		_add_guest.rpc_id(sender, gid, _guest_sim[gid].pos, gt)
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		_add_staff.rpc_id(sender, sid, st.pos, int(st.role), int(st.level))
	for pid in _packages.keys():
		var pk = _packages[pid]
		_add_package.rpc_id(sender, pid, (pk as Node3D).position, int(pk.kind), int(pk.amount))
	for aid in _abgelegt.keys():
		var ab: Dictionary = _abgelegt[aid]
		_add_abgelegt.rpc_id(sender, aid, ab.pos, int(ab.art), int(ab.typ), float(ab.fill))
	for nr in range(1, _lager_gekauft + 1):
		var platz: Vector3 = LAGERREGAL_PLAETZE[nr - 1]
		_add_lagerregal.rpc_id(sender, nr, platz.x, platz.y, platz.z)
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
	_lobby_ids.erase(peer_id)
	if _held_deko.has(peer_id):
		_deko_abstellen(peer_id)
	_remove_player.rpc(peer_id)
	# Abteilung wird frei — NPC-Personal dafür kann wieder jeder buchen
	if _spieler_info.has(peer_id):
		_spieler_info.erase(peer_id)
		_net_spieler_info.rpc(_spieler_info)
	_broadcast_meta()
	# Laufende Abstimmung neu auswerten — ohne den Spieler kann die Mehrheit kippen
	_abstimmung_pruefen(false)

# ================================================= Bierpreis
## Zelt-Computer: Bierpreis in 10-%-Schritten ändern — auch während der Schicht.
## Billig lockt mehr Gäste (Wirtschaft.preis_andrang), bringt aber weniger je Maß.
@rpc("any_peer", "reliable", "call_local")
func net_set_bierpreis(schritte: int) -> void:
	if not multiplayer.is_server():
		return
	var neu := snappedf(_bierpreis + 0.1 * float(clampi(schritte, -5, 5)), 0.1)
	var raum := bierpreis_grenzen()
	_bierpreis = clampf(neu, raum.x, raum.y)
	_broadcast_meta()

func open_computer_ui() -> void:
	_hud.open_computer()

func open_booking_ui() -> void:
	_hud.open_booking()

## Wo der Gast an seinem Platz ist: sitzend auf der Bank, Stehgäste (Figuren.ist_stehgast)
## ein Stück dahinter — mit Blick zum Tisch wie die Sitzenden.
func _platz_pos_fuer(gast_id: int, si: int) -> Vector3:
	var s: Dictionary = _seats[si]
	var p: Vector3 = s.pos
	if Figuren.ist_stehgast(gast_id):
		p += (s.away as Vector3) * STEHABSTAND
	return p

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

## Klo-Container in der Zeltecke: nur, wenn die Toilette gekauft ist. Ausgeblendet
## ohne Kollision (PROCESS_MODE_DISABLED nimmt den Körper aus der Physik).
func _klo_anzeigen() -> void:
	var klo := get_node_or_null("KloContainer") as Node3D
	if klo == null:
		return
	var an := _has_toilet and _tent_stage > 0
	klo.visible = an
	klo.process_mode = Node.PROCESS_MODE_INHERIT if an else Node.PROCESS_MODE_DISABLED

## „Zu vermieten"-Schild am Zelteingang: nur solange das Zelt noch frei ist.
func _vermietung_aktualisieren() -> void:
	for schild in get_tree().get_nodes_in_group("zelt_vermietung"):
		schild.frei_setzen(_tent_stage == 0)

## Zelt kiralamaya göre masaları aktif/pasif yap + koltukları kur.
func _apply_tent() -> void:
	_vermietung_aktualisieren()
	_klo_anzeigen()
	_zeltname_anzeigen()
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

## Zelt mieten (Stufe 1) — der Name kommt aus dem Mietdialog (scenes/ui/zelt_mieten.tscn).
@rpc("any_peer", "reliable", "call_local")
func net_book_tent(zelt_name := "") -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION or _tent_stage != 0:
		return
	if not _afford(TENT_BOOK_COST):
		_fehler("MSG_NO_MONEY", ["OFFER_TENT_RENT", _eur(TENT_BOOK_COST)])
		return
	Game.add_money(-TENT_BOOK_COST)
	_tent_stage = 1
	_active_count = 0
	_zelt_name = zeltname_pruefen(zelt_name)
	_apply_tent()
	_melde("MSG_TENT_RENTED", [_zelt_name if _zelt_name != "" else "TENT_NAME_DEFAULT"], 2)
	if tutorial_active() and _quest_step <= 2:
		_dreck_verteilen()
	_broadcast_meta()

## Mietdialog öffnen (vom Schild und aus dem Wiesenbüro)
func open_rent_ui() -> void:
	_hud.open_rent()

## Zeltname vom Spieler: ohne Steuerzeichen/Zeilenumbrüche, getrimmt, höchstens
## ZELTNAME_MAX Zeichen. "" = Standardname (TENT_NAME_DEFAULT, in der Spielersprache).
static func zeltname_pruefen(roh: String) -> String:
	var s := ""
	for i in roh.length():
		if roh.unicode_at(i) >= 32:
			s += roh[i]
	s = s.strip_edges()
	if s.length() > ZELTNAME_MAX:
		s = s.substr(0, ZELTNAME_MAX).strip_edges()
	return s

## Zeltname groß am Eingang und über der Theke (Label3D in der Gruppe "zeltname").
## Zu lange Namen werden kleiner gesetzt, damit sie auf Schild/Giebel passen:
## metadata/breite = höchste Breite in Metern, metadata/pixel_basis = normale Größe.
func _zeltname_anzeigen() -> void:
	var text := _zelt_name if _zelt_name != "" else String(TranslationServer.translate("TENT_NAME_DEFAULT"))
	for knoten in get_tree().get_nodes_in_group("zeltname"):
		var l := knoten as Label3D
		if l == null:
			continue
		l.visible = _tent_stage > 0
		l.text = text
		var basis := float(l.get_meta("pixel_basis", l.pixel_size))
		var breite := float(l.get_meta("breite", 0.0))
		var schrift: Font = l.font if l.font else ThemeDB.fallback_font
		var px := schrift.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size).x
		l.pixel_size = basis if breite <= 0.0 or px * basis <= breite else breite / px

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
	# Steht dort schon ein verschobener Tisch: auf den nächsten freien Platz
	if _tisch_freistellen(_active_count - 1):
		_rebuild_seats()
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
	_klo_anzeigen()
	_melde("MSG_TOILET_DONE", [], 2)
	_broadcast_meta()

## Blase der sitzenden Gäste. Ohne Klo → Urinfleck in der Ecke.
func _update_bladder(g: Dictionary, id: int, delta: float) -> void:
	if int(g.mode) == 3:
		# Wartet vor besetztem Klo: wird es frei, hinein — sonst irgendwann ins Zelt
		if bool(g.get("klo_wartet", false)):
			if _klo_gast < 0:
				g.klo_wartet = false
				_klo_setzen(id)
				g.tgt = TOILET_POINT
			else:
				g.warte_t = float(g.get("warte_t", 0.0)) - delta
				if float(g.warte_t) <= 0.0:
					g.klo_wartet = false
					g.wild = true
					g.tgt = _wildpinkel_punkt(g)
			return
		# Erst ankommen — Pfütze und Pinkelzeit beginnen am Ziel, nicht beim Losgehen
		var bis_ziel: Vector3 = (g.tgt as Vector3) - (g.pos as Vector3)
		bis_ziel.y = 0.0
		if bis_ziel.length() > 0.3 or not _nur_noch_ziel(g):
			return
		if (not _has_toilet or bool(g.get("wild", false))) and not bool(g.get("pfuetze", false)):
			g.pfuetze = true
			_spawn_mess_at((g.tgt as Vector3) + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4)), 1)
			_urin_count += 1
		g.pee_t = float(g.pee_t) - delta
		if float(g.pee_t) <= 0.0:
			g.mode = 1
			g.wild = false
			if _klo_gast == id:
				_klo_setzen(-1)
			g.tgt = _platz_pos_fuer(id, int(g.seat))
			g.bladder = randf_range(BLADDER_MIN, BLADDER_MAX)
		return
	g.bladder = float(g.bladder) - delta
	if float(g.bladder) > 0.0:
		return
	# Muss mal: freies Klo → hinein · besetzt → kurz anstellen · kein Klo → in die Ecke
	g.mode = 3
	g.pee_t = PEE_DURATION
	g.ostate = 0
	g.pfuetze = false
	g.wild = false
	if not _has_toilet:
		# Verteilt in der Nähe des eigenen Tisches — nicht alle in dieselbe Ecke
		g.tgt = _wildpinkel_punkt(g)
	elif _klo_gast < 0:
		_klo_setzen(id)
		g.tgt = TOILET_POINT
	else:
		g.klo_wartet = true
		g.warte_t = KLO_WARTEN
		g.tgt = TOILET_POINT + Vector3(randf_range(-2.2, -1.0), 0.0, randf_range(-1.2, 1.2))

## Wer ist auf dem Klo? Allen Mitspielern melden, damit die Lampe stimmt.
func _klo_setzen(gast_id: int) -> void:
	if _klo_gast == gast_id:
		return
	_klo_gast = gast_id
	_net_klo.rpc(_klo_gast >= 0)

@rpc("authority", "reliable", "call_local")
func _net_klo(besetzt: bool) -> void:
	var klo := get_node_or_null("KloContainer")
	if klo and klo.has_method("set_besetzt"):
		klo.set_besetzt(besetzt)

## Klo besetzt und zu lange gewartet: irgendwo in der Nähe des Tisches ins Zelt —
## nicht hinter die Theke. Die Putzkräfte haben dadurch wieder Arbeit.
func _wildpinkel_punkt(g: Dictionary) -> Vector3:
	var basis: Vector3 = g.pos
	if int(g.seat) >= 0 and int(g.seat) < _seats.size():
		var s: Dictionary = _seats[int(g.seat)]
		basis = (s.pos as Vector3) + (s.away as Vector3) * 2.2
	var p := basis + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(-1.5, 1.5))
	return _auf_ebene(p, ebene_von(basis))

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
const QUEST_COUNT := 14
## Seit Version 4 gibt es Schritt 2 „Putze das Zelt" — ältere Stände ab Schritt 2
## rücken eins weiter.
## Seit Version 3 führt Schritt 0 über das Gespräch mit dem Wiesnchef (Einleitung).
## Seit Version 2 gibt es die Schritte „auf den Lieferwagen warten" und „Pakete
## ins Regal räumen" — ältere Spielstände ab Schritt 3 rücken eins weiter.
const QUEST_VERSION := 4

func _quest_done(step: int) -> bool:
	match step:
		# Dem Wiesnchef „Ja" gesagt (oder das Zelt schon gemietet)
		0: return _folge_geschafft or _tent_stage > 0
		1: return _tent_stage > 0
		# Der Dreck im übernommenen Zelt ist weggefegt
		2: return _tent_stage > 0 and not _dreck_uebrig() and not _dreck_nachlegen and not _muell_offen()
		3: return _active_count >= 2
		4: return int(_stock.get(WARE_BIER, 0)) > 0 or not _pending.is_empty()
		# Lieferwagen ist da: Pakete liegen vor dem Zelt (oder schon eingeräumt)
		5: return not _packages.is_empty() or int(_stock.get(WARE_BIER, 0)) > 0
		# alle Pakete eingeräumt
		6: return int(_stock.get(WARE_BIER, 0)) > 0 and _packages.is_empty()
		7: return _shift_num >= 1
		8: return _served >= 1 or _quest_served_once
		9: return _shift_num >= 1 and _phase == Phase.INTERMISSION
		10: return _has_staff(ROLE_KELLNER)
		11: return _lic.values().has(true)
		12: return _has_toilet
		13: return _ever_artist
	return false

## Liegt noch Dreck aus dem verlassenen Zelt herum? (Mess.DRECK)
func _dreck_uebrig() -> bool:
	for k in _mess_kind.values():
		if int(k) >= Mess.DRECK and int(k) < Mess.SABOTAGE:
			return true
	return false

## Wo im übernommenen Zelt Dreck liegt (Boden, freie Fläche vor der Theke)
const DRECK_PLAETZE := [
	Vector3(-8, 0, -4), Vector3(-4.5, 0, -2.5), Vector3(0, 0, -3.5), Vector3(4.5, 0, -2), Vector3(8, 0, -4.5),
	Vector3(-9, 0, 2), Vector3(-5, 0, 3.5), Vector3(-1, 0, 1.5), Vector3(3, 0, 3), Vector3(7.5, 0, 1.5),
	Vector3(-7, 0, 8), Vector3(-2.5, 0, 7), Vector3(2, 0, 9), Vector3(6.5, 0, 7.5), Vector3(0, 0, 12),
]

## Abdeckplanen über den Möbeln (Mess.DECKE + Art → Größe in mess.gd)
const DECKEN_PLAETZE := {
	10: Vector3(-4.7, 0, -9.15), 11: Vector3(4.7, 0, -9.15), 12: Vector3(6.4, 0, -13.3),
	13: Vector3(9.95, 0, 2.0), 14: Vector3(-11.2, 0, -3.5),
}

## Beim Übernehmen im Tutorial: das verlassene Zelt ist verdreckt und zugedeckt
var _dreck_nachlegen := false

func _dreck_verteilen() -> void:
	for k: int in DECKEN_PLAETZE:
		_spawn_mess_at(DECKEN_PLAETZE[k], k)
	for i in DRECK_PLAETZE.size():
		var p: Vector3 = DRECK_PLAETZE[i] + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		_spawn_mess_at(p, Mess.DRECK + int(Mess.DRECK_ARTEN[i % Mess.DRECK_ARTEN.size()]))

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
	_folge_geschafft = true
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
	var stages := get_tree().get_nodes_in_group("stage")
	if stages.is_empty():
		return
	var pts: Array = stages[0].artist_points()
	if pts.is_empty():
		return
	# Künstler zur Publikumsseite drehen (Bühnen-Vorderseite = lokales +Z)
	var fwd: Vector3 = (stages[0] as Node3D).global_transform.basis.z
	var yaw := atan2(-fwd.x, -fwd.z)
	# Ohne Buchung steht trotzdem einer auf der Bühne und tanzt
	var n: int = mini(int(ARTIST_COUNT.get(_artist_tier, 1)), pts.size())
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
	# Mit Künstler auf der Bühne laufen die Stücke mit Gesang (scripts/sfx.gd)
	if _sfx_node:
		_sfx_node.kuenstler(tier)

@rpc("authority", "reliable", "call_local")
func _remove_artists() -> void:
	for a in _artist_nodes:
		if is_instance_valid(a):
			a.queue_free()
	_artist_nodes.clear()
	if _sfx_node:
		_sfx_node.kuenstler(0)

## Massenschlägerei: nach so vielen Sekunden flieht die Band, danach bleibt die
## Musik bis Schichtende aus.
const BAND_FLUCHT_NACH := 5.0
## true, sobald die Band vor einer Schlägerei geflohen ist (bei allen Mitspielern)
var _band_weg := false
var _band_flucht_geplant := false

## Von scripts/pruegel/massenschlaegerei.gd beim Start aufgerufen.
func schlaegerei_gemeldet(_ort: Vector3) -> void:
	if not multiplayer.is_server() or _band_weg or _band_flucht_geplant:
		return
	_band_flucht_geplant = true
	get_tree().create_timer(BAND_FLUCHT_NACH).timeout.connect(func() -> void:
		_band_flucht_geplant = false
		if not _band_weg:
			_net_band_flieht.rpc())

@rpc("authority", "reliable", "call_local")
func _net_band_flieht() -> void:
	_band_weg = true
	var stages := get_tree().get_nodes_in_group("stage")
	for a in _artist_nodes:
		if not is_instance_valid(a) or not a.has_method("fliehen"):
			continue
		# Vorn von der Bühne runter, quer durchs Zelt zum Ausgang und weg
		var weg: Array[Vector3] = []
		if not stages.is_empty():
			var b := stages[0] as Node3D
			var runter: Vector3 = (a as Node3D).global_position + b.global_transform.basis.z * 2.6
			weg.append(Vector3(runter.x, 0.1, runter.z))
		weg.append(ENTRANCE + Vector3(randf_range(-1.0, 1.0), 0.0, -1.0))
		weg.append(ENTRANCE + Vector3(randf_range(-3.0, 3.0), 0.0, 8.0))
		a.fliehen(weg)
	if _sfx_node:
		_sfx_node.musik_ausblenden(1.5)

@rpc("authority", "reliable", "call_local")
func _net_band_zurueck() -> void:
	_band_weg = false

# ================================================= Schießbude (Kirmes-Minispiel)
## scripts/kirmes/schiessstand.gd: Spieler zahlt, schießt 10 Schuss, bekommt einen
## Preis. Geld läuft über den Server; wer nicht bezahlt hat, bekommt keinen Preis.
const SCHIESS_PREIS := 2
## Treffer ab … → Preis in Euro und Name (Übersetzungsschlüssel)
const SCHIESS_GEWINNE := [[10, 20, "PREIS_TEDDY"], [7, 8, "PREIS_HERZ"], [4, 3, "PREIS_ROSE"]]
var _schiessen_bezahlt := {}   # Peer-ID -> Pfad der Bude, solange eine Runde läuft

## bude: Pfad der Schießbude vom GameManager aus (für den Budenbesitzer)
@rpc("any_peer", "reliable", "call_local")
func net_schiessen_bezahlen(bude: NodePath = NodePath()) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _schiessen_bezahlt.has(s) or _schiessen_bezahlt.values().has(bude) and not bude.is_empty():
		return
	# Preis kommt vom Stand (Schießbude, Dosenwerfen, Hau den Lukas)
	var preis := SCHIESS_PREIS
	var stand := get_node_or_null(bude) if not bude.is_empty() else null
	if stand and "preis" in stand:
		preis = int(stand.preis)
	if not _afford(preis):
		_fehler("MSG_NO_MONEY", ["WORLD_KIRMES_SPIEL", _eur(preis)])
		return
	Game.add_money(-preis)
	_schiessen_bezahlt[s] = bude
	if not bude.is_empty():
		_net_bude_besetzt.rpc(bude, true)
	if s == multiplayer.get_unique_id():
		_net_schiessen_los()
	else:
		_net_schiessen_los.rpc_id(s)

## Beim Schützen: das Spiel an der Bude starten, vor der er steht.
@rpc("authority", "reliable", "call_local")
func _net_schiessen_los() -> void:
	var p = _players_nodes.get(multiplayer.get_unique_id())
	if p and p.has_method("schiessen_starten"):
		p.schiessen_starten()

@rpc("any_peer", "reliable", "call_local")
func net_schiessen_ende(treffer: int) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if not _schiessen_bezahlt.has(s):
		return
	var bude: NodePath = _schiessen_bezahlt[s]
	_schiessen_bezahlt.erase(s)
	if not bude.is_empty():
		_net_bude_besetzt.rpc(bude, false)
	treffer = clampi(treffer, 0, 10)
	_stats.geschossen = int(_stats.get("geschossen", 0)) + 1
	for gewinn: Array in SCHIESS_GEWINNE:
		if treffer >= int(gewinn[0]):
			Game.add_money(int(gewinn[1]))
			_stats.schiess_preise = int(_stats.get("schiess_preise", 0)) + 1
			_schiess_meldung(s, "MSG_KIRMES_GEWINN", [treffer, str(gewinn[2]), _eur(int(gewinn[1]))], 2)
			return
	_schiess_meldung(s, "MSG_KIRMES_NIETE", [treffer], 0)

## Bei allen: Budenbesitzer geht zur Kasse (an) oder zurück hinter die Theke.
@rpc("authority", "reliable", "call_local")
func _net_bude_besetzt(bude: NodePath, an: bool) -> void:
	var b := get_node_or_null(bude)
	if b and b.has_method("besetzt_setzen"):
		b.besetzt_setzen(an)

func _schiess_meldung(peer: int, key: String, args: Array, art: int) -> void:
	if peer == multiplayer.get_unique_id():
		_net_banner(key, args, art)
	else:
		_net_banner.rpc_id(peer, key, args, art)

# ================================================= Massenschlägerei (ab Tag 5)
## Abends kann im vollen Zelt eine Massenschlägerei ausbrechen. Der Server wählt
## die Beteiligten (sitzende Gäste am Boden rund um einen Tisch) und entscheidet
## die Folgen; auf jedem Rechner werden die Gäste zu Raufbolden
## (scenes/pruegel/raufbold.tscn) im Knäuel (scenes/pruegel/massenschlaegerei.tscn).
## Das Getümmel selbst ist nur Darstellung. Spieler werfen Raufbolde mit E raus —
## das mildert den Beliebtheitsverlust und beendet die Schlägerei früher.
const RAUFBOLD_SCENE := preload("res://scenes/pruegel/raufbold.tscn")
const SCHLAEGEREI_SCENE := preload("res://scenes/pruegel/massenschlaegerei.tscn")
const SCHLAEGEREI_AB_TAG := 5
## Die erste Massenschlägerei kommt ab Tag 5 sicher, danach ist sie selten
const MASSEN_CHANCE := 0.08                   # je Schicht, nachdem es eine gab
const SCHLAEGEREI_UHR := Vector2(18.5, 21.0)  # Ausbruch irgendwann in diesem Zeitraum
const SCHLAEGEREI_SPAETESTENS := 21.75        # zu wenig Gäste: bis dahin erneut versuchen
const SCHLAEGEREI_MIN_GAESTE := 10            # so viele sitzende Gäste müssen da sein
const SCHLAEGEREI_MAX := 22
## Eine Massenschlägerei war nach einer halben Minute vorbei, bevor man
## überhaupt drin war (Rückmeldung 22.09.). Schwer aufzulösen bleibt sie durch
## das Zappeln beim Packen, nicht durch die Dauer.
const SCHLAEGEREI_DAUER := 40.0
const SCHLAEGEREI_POP := 20.0                 # Verlust ohne Rauswürfe — deutlich
const SCHLAEGEREI_DRECK := 5
## Einzelne Schlägereien (zwei Gäste) sind ab Tag 5 normal: je Schicht so viele
const EINZEL_JE_SCHICHT := Vector2i(1, 3)
const EINZEL_UHR := Vector2(16.5, 21.5)
const EINZEL_DAUER := 20.0
const EINZEL_POP := 3.0
const RAUSWURF_POP := 0.5                     # je rausgeworfenem Raufbold
const RAUSWURF_TEMPO := Vector2(11.0, 4.5)    # waagerecht, senkrecht
## Gab es in diesem Spielstand schon eine Massenschlägerei? (gespeichert)
var _massen_gehabt := false
var _einzel_uhren: Array = []
## Laufende Einzelstreits: [{ids: [a, b], t: Restzeit, raus: Anzahl}]
var _einzelstreits: Array = []
var _schlaegerei_uhr := -1.0
var _schlaegerei_ids: Array = []
var _schlaegerei_ort := Vector3.ZERO
var _schlaegerei_t := 0.0
var _schlaegerei_raus := 0
## Gast-ID -> Raufbold (auf allen Rechnern)
var _raufbolde := {}
## Spieler-Peer -> Gast-ID, die er gerade auf dem Arm hat
var _gepackt := {}
## Spieler-Peer -> Restzeit, bis der Gepackte sich losreißt
var _gepackt_t := {}
## Spieler-Peer -> Peer des Mitspielers, den er auf dem Arm hat
var _gepackt_spieler := {}
var _gepackt_spieler_t := {}
## So lange zappelt ein Gepackter, bevor er sich befreit
const ZAPPEL_ZEIT := Vector2(3.5, 7.0)
var _schlaegerei_knoten: Node3D

## Beim Schichtbeginn: ob und wann heute eine Schlägerei ausbricht.
func _schlaegerei_planen() -> void:
	_schlaegerei_uhr = -1.0
	_einzel_uhren = []
	if _day < SCHLAEGEREI_AB_TAG or _tent_stage == 0:
		return
	if not _massen_gehabt or randf() < MASSEN_CHANCE:
		_schlaegerei_uhr = randf_range(SCHLAEGEREI_UHR.x, SCHLAEGEREI_UHR.y)
	for k in randi_range(EINZEL_JE_SCHICHT.x, EINZEL_JE_SCHICHT.y):
		_einzel_uhren.append(randf_range(EINZEL_UHR.x, EINZEL_UHR.y))
	_einzel_uhren.sort()

func schlaegerei_laeuft() -> bool:
	return not _schlaegerei_ids.is_empty()

func _update_schlaegerei(delta: float) -> void:
	var uhr := _clock_hour()
	for streit: Dictionary in _einzelstreits.duplicate():
		streit.t = float(streit.t) - delta
		if float(streit.t) <= 0.0 or int(streit.raus) >= 2:
			_einzelstreit_beenden(streit)
	if schlaegerei_laeuft():
		_schlaegerei_t -= delta
		if _schlaegerei_t <= 0.0 or _schlaegerei_raus >= _schlaegerei_ids.size():
			_schlaegerei_beenden()
		return
	if _schlaegerei_uhr >= 0.0 and uhr >= _schlaegerei_uhr:
		_schlaegerei_uhr = -1.0
		# Zu wenige Gäste: gleich noch einmal versuchen — die erste kommt sicher
		if not schlaegerei_ausloesen() and uhr + 0.25 < SCHLAEGEREI_SPAETESTENS:
			_schlaegerei_uhr = uhr + 0.25
		return
	if not _einzel_uhren.is_empty() and uhr >= float(_einzel_uhren[0]):
		_einzel_uhren.pop_front()
		einzelstreit_ausloesen()

## Zwei Gäste am Nachbartisch geraten aneinander (Server). false ohne passende Gäste.
func einzelstreit_ausloesen() -> bool:
	if not multiplayer.is_server() or schlaegerei_laeuft():
		return false
	var sitzend := []
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		if int(g.mode) == 1 and ebene_von(g.pos) == 0:
			sitzend.append(id)
	if sitzend.size() < 2:
		return false
	var a: int = sitzend.pick_random()
	sitzend.erase(a)
	var pa: Vector3 = _guest_sim[a].pos
	sitzend.sort_custom(func(x: int, y: int) -> bool:
		return (_guest_sim[x].pos as Vector3).distance_squared_to(pa) < (_guest_sim[y].pos as Vector3).distance_squared_to(pa))
	var b: int = sitzend[0]
	for id in [a, b]:
		var g: Dictionary = _guest_sim[id]
		g.mode = 7
		g.ostate = 0
		g.tgt = g.pos
		_guest_sim[id] = g
		_assigned.erase(id)
	_einzelstreits.append({"ids": [a, b], "t": EINZEL_DAUER, "raus": 0})
	_stats.einzelstreits = int(_stats.get("einzelstreits", 0)) + 1
	_melde("MSG_EINZELSTREIT_START", [], 1)
	_net_einzelstreit_start.rpc(a, b)
	return true

@rpc("authority", "reliable", "call_local")
func _net_einzelstreit_start(a: int, b: int) -> void:
	var ra := _raufbold_erzeugen(a, Vector3.ZERO)
	var rb := _raufbold_erzeugen(b, Vector3.ZERO)
	ra.streit_mit(rb)

func _einzelstreit_beenden(streit: Dictionary) -> void:
	_einzelstreits.erase(streit)
	var verlust := EINZEL_POP * (1.0 - 0.5 * float(int(streit.raus)) / 2.0)
	_popularity = maxf(POP_MIN, _popularity - verlust)
	var ids: Array = streit.ids
	if _guest_sim.has(ids[0]):
		_spawn_mess_near(_guest_sim[ids[0]].pos)
	for id in ids:
		if _guest_sim.has(id):
			_despawn_guest(id)
	_net_raufbolde_weg.rpc(PackedInt32Array(ids))

## Einzelstreit vorbei: die beiden hauen ab und verschwinden draußen.
@rpc("authority", "reliable", "call_local")
func _net_raufbolde_weg(ids: PackedInt32Array) -> void:
	for id in ids:
		var r = _raufbolde.get(id)
		_raufbolde.erase(id)
		if r == null or not is_instance_valid(r):
			continue
		r.remove_from_group("interactable")
		if r.kaempft() or r.ist_frei():
			r.gegner = null
			r._setze(r.Zustand.FLUCHT)
		get_tree().create_timer(12.0).timeout.connect(func() -> void:
			if is_instance_valid(r):
				r.queue_free())

## Gast wird auf diesem Rechner zum Raufbold: Gast ausblenden, gleiche Figur prügelt.
func _raufbold_erzeugen(id: int, ort: Vector3) -> Node3D:
	var pos := ort
	var c = _guests.get(id)
	if c and is_instance_valid(c):
		pos = (c as Node3D).global_position
		c.visible = false
		c.remove_from_group("interactable")
	var r := RAUFBOLD_SCENE.instantiate()
	_customers_container.add_child(r)
	r.global_position = Vector3(pos.x, 0.0, pos.z)
	r.rotation.y = randf() * TAU
	r.figur_setzen(Figuren.fuer_gast(id))
	r.gast_id = id
	r.flucht_ziel = ENTRANCE + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(7.0, 11.0))
	r.add_to_group("interactable")
	if multiplayer.is_server():
		r.gelandet.connect(_raufbold_gelandet)
	_raufbolde[id] = r
	return r

## Startet eine Schlägerei (Server). false, wenn zu wenige Gäste sitzen.
func schlaegerei_ausloesen() -> bool:
	if not multiplayer.is_server() or schlaegerei_laeuft():
		return false
	var sitzend := []
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		if int(g.mode) == 1 and ebene_von(g.pos) == 0:
			sitzend.append(id)
	if sitzend.size() < SCHLAEGEREI_MIN_GAESTE:
		return false
	var ort: Vector3 = _guest_sim[sitzend.pick_random()].pos
	sitzend.sort_custom(func(a: int, b: int) -> bool:
		return (_guest_sim[a].pos as Vector3).distance_squared_to(ort) < (_guest_sim[b].pos as Vector3).distance_squared_to(ort))
	var ids := PackedInt32Array()
	for id: int in sitzend.slice(0, SCHLAEGEREI_MAX):
		var g: Dictionary = _guest_sim[id]
		g.mode = 7   # prügelt — keine Bestellungen, bleibt stehen
		g.ostate = 0
		g.tgt = g.pos
		_guest_sim[id] = g
		_assigned.erase(id)
		ids.append(id)
	_schlaegerei_ids = Array(ids)
	_schlaegerei_ort = Vector3(ort.x, 0.0, ort.z)
	_schlaegerei_t = SCHLAEGEREI_DAUER
	_schlaegerei_raus = 0
	_massen_gehabt = true
	_stats.schlaegereien = int(_stats.get("schlaegereien", 0)) + 1
	_melde("MSG_SCHLAEGEREI_START", [], 1)
	_net_schlaegerei_start.rpc(ids, _schlaegerei_ort)
	return true

@rpc("authority", "reliable", "call_local")
func _net_schlaegerei_start(ids: PackedInt32Array, ort: Vector3) -> void:
	var kandidaten := []
	for id in ids:
		kandidaten.append(_raufbold_erzeugen(id, ort))
	_schlaegerei_knoten = SCHLAEGEREI_SCENE.instantiate()
	add_child(_schlaegerei_knoten)
	# Der Server beendet — das Knäuel selbst soll nicht vorher auseinandergehen
	_schlaegerei_knoten.dauer = SCHLAEGEREI_DAUER + 10.0
	_schlaegerei_knoten.starten(kandidaten, ort, kandidaten.size())

## Spieler wirft einen Raufbold raus (E). Richtung: wohin der Spieler schaut.
@rpc("any_peer", "reliable", "call_local")
func net_rauswerfen(gast_id: int) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	# Schon jemanden auf dem Arm? Dann wirft dieser Druck ihn weg — dafür braucht
	# es kein Ziel mehr im Blick.
	if _gepackt.has(s):
		_werfen(s)
		return
	if not _guest_sim.has(gast_id) or not _im_streit(gast_id):
		return
	if _gepackt.values().has(gast_id):
		return   # hat schon ein anderer
	var pl = _players_nodes.get(s)
	if pl == null or not is_instance_valid(pl):
		return
	# Abstand zum Raufbold, nicht zum Gasteintrag: der Gast bleibt beim Prügeln
	# auf seinem Sitzplatz stehen, während der Raufbold ins Knäuel läuft.
	var r = _raufbolde.get(gast_id)
	if r == null or not is_instance_valid(r):
		return
	if (pl as Node3D).global_position.distance_to((r as Node3D).global_position) > 2.6:
		return
	_gepackt[s] = gast_id
	_gepackt_t[s] = randf_range(ZAPPEL_ZEIT.x, ZAPPEL_ZEIT.y)
	_net_gepackt.rpc(gast_id, s)

## Läuft dieser Gast gerade in einer Schlägerei mit?
func _im_streit(gast_id: int) -> bool:
	for streit: Dictionary in _einzelstreits:
		if (streit.ids as Array).has(gast_id):
			return true
	return _schlaegerei_ids.has(gast_id)

## Raufbold auf den Arm: bei allen Spielern zappelt er beim Träger.
@rpc("authority", "reliable", "call_local")
func _net_gepackt(gast_id: int, traeger: int) -> void:
	var r = _raufbolde.get(gast_id)
	if r == null or not is_instance_valid(r):
		return
	r.traeger = _players_nodes.get(traeger)
	r.packen()
	var p = _players_nodes.get(traeger)
	if p and is_instance_valid(p) and p.has_method("raufbold_auf_dem_arm"):
		p.raufbold_auf_dem_arm(true)

## Er hat sich losgerissen — zurück in die Schlägerei.
@rpc("authority", "reliable", "call_local")
func _net_losgerissen(gast_id: int, traeger: int = 0) -> void:
	var r = _raufbolde.get(gast_id)
	if r and is_instance_valid(r):
		r.traeger = null
		r.loslassen()
	_arme_leer_melden(traeger)

## Der Wurf. Ob er draußen landet, entscheidet der Server beim Aufschlag.
@rpc("authority", "reliable", "call_local")
func _net_geworfen(gast_id: int, tempo: Vector3, traeger: int = 0) -> void:
	var r = _raufbolde.get(gast_id)
	if r and is_instance_valid(r):
		r.traeger = null
		r.werfen(tempo)
	_arme_leer_melden(traeger)

## Mitspieler packen und werfen — dieselbe Mechanik wie beim Raufbold. Ein
## zweiter Druck wirft; wer sich losreißt, steht einfach wieder frei da.
@rpc("any_peer", "reliable")
func net_spieler_packen(ziel: int) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if _gepackt_spieler.has(s):
		_spieler_werfen(s)
		return
	if s == ziel or not _players_nodes.has(s) or not _players_nodes.has(ziel):
		return
	if _gepackt_spieler.values().has(ziel):
		return   # hat schon ein anderer
	var a: Node3D = _players_nodes[s]
	var b: Node3D = _players_nodes[ziel]
	if not is_instance_valid(a) or not is_instance_valid(b):
		return
	if a.global_position.distance_to(b.global_position) > 2.4:
		return
	_gepackt_spieler[s] = ziel
	_gepackt_spieler_t[s] = randf_range(ZAPPEL_ZEIT.x, ZAPPEL_ZEIT.y)
	_net_traegt_spieler.rpc(s, true)

## Beim Träger merken, damit sein Hinweis „werfen" zeigt und E wirft.
@rpc("authority", "reliable", "call_local")
func _net_traegt_spieler(peer: int, ja: bool) -> void:
	var p = _players_nodes.get(peer)
	if p and is_instance_valid(p) and p.has_method("spieler_auf_dem_arm"):
		p.spieler_auf_dem_arm(ja)

func _spieler_werfen(traeger: int) -> void:
	if not _gepackt_spieler.has(traeger):
		return
	var ziel: int = _gepackt_spieler[traeger]
	_gepackt_spieler.erase(traeger)
	_gepackt_spieler_t.erase(traeger)
	_net_traegt_spieler.rpc(traeger, false)
	var pl = _players_nodes.get(traeger)
	var zp = _players_nodes.get(ziel)
	if zp == null or not is_instance_valid(zp):
		return
	var vorn := Vector3(0, 0, 1)
	if pl and is_instance_valid(pl):
		vorn = -(pl as Node3D).global_transform.basis.z
		vorn.y = 0.0
		vorn = vorn.normalized() if vorn.length() > 0.01 else Vector3(0, 0, 1)
	zp.getragen_geworfen.rpc_id(ziel, vorn * RAUSWURF_TEMPO.x + Vector3.UP * RAUSWURF_TEMPO.y)

## Getragene mitführen und Zappeln mitzählen (Server).
func _update_gepackt(delta: float) -> void:
	for traeger: int in _gepackt_spieler.keys().duplicate():
		var ziel: int = _gepackt_spieler[traeger]
		var pl = _players_nodes.get(traeger)
		var zp = _players_nodes.get(ziel)
		if pl == null or zp == null or not is_instance_valid(pl) or not is_instance_valid(zp):
			_gepackt_spieler.erase(traeger)
			_gepackt_spieler_t.erase(traeger)
			_net_traegt_spieler.rpc(traeger, false)
			continue
		var vorn := -(pl as Node3D).global_transform.basis.z
		vorn.y = 0.0
		var ort: Vector3 = (pl as Node3D).global_position + vorn.normalized() * 1.0 + Vector3(0, 0.45, 0)
		zp.getragen_stellen.rpc_id(ziel, ort, (pl as Node3D).rotation.y + PI)
		_gepackt_spieler_t[traeger] = float(_gepackt_spieler_t[traeger]) - delta
		if float(_gepackt_spieler_t[traeger]) <= 0.0:
			_gepackt_spieler.erase(traeger)
			_gepackt_spieler_t.erase(traeger)
			_net_traegt_spieler.rpc(traeger, false)
	for traeger: int in _gepackt.keys().duplicate():
		var gast_id: int = _gepackt[traeger]
		var pl = _players_nodes.get(traeger)
		if pl == null or not is_instance_valid(pl) or not _guest_sim.has(gast_id):
			_gepackt.erase(traeger)
			_gepackt_t.erase(traeger)
			_net_losgerissen.rpc(gast_id, traeger)
			continue
		# Wo er hängt, macht der Raufbold selbst (raufbold.gd, _beim_traeger) —
		# die Gastposition bleibt liegen, sonst zöge sie die Gastsimulation
		# jedes Bild wieder zum Prügelplatz zurück.
		_gepackt_t[traeger] = float(_gepackt_t[traeger]) - delta
		if float(_gepackt_t[traeger]) <= 0.0:
			_gepackt.erase(traeger)
			_gepackt_t.erase(traeger)
			_net_losgerissen.rpc(gast_id, traeger)

## Wirft, was dieser Spieler auf dem Arm hat.
func _werfen(traeger: int) -> void:
	if not _gepackt.has(traeger):
		return
	var gast_id: int = _gepackt[traeger]
	_gepackt.erase(traeger)
	_gepackt_t.erase(traeger)
	var vorn := Vector3(0, 0, 1)
	var pl = _players_nodes.get(traeger)
	if pl:
		vorn = -(pl as Node3D).global_transform.basis.z
		vorn.y = 0.0
		vorn = vorn.normalized() if vorn.length() > 0.01 else Vector3(0, 0, 1)
	_net_geworfen.rpc(gast_id, vorn * RAUSWURF_TEMPO.x + Vector3.UP * RAUSWURF_TEMPO.y, traeger)

## Ein geworfener Raufbold ist aufgeschlagen (nur Server): außerhalb des Zelts
## ist er draußen und kommt nicht wieder, drinnen rappelt er sich auf und
## mischt weiter mit.
func _raufbold_gelandet(r: Node3D) -> void:
	if not multiplayer.is_server():
		return
	var gast_id: int = int(r.gast_id)
	if not _guest_sim.has(gast_id) or not _im_streit(gast_id):
		return
	var p: Vector3 = r.global_position
	if p.x > ZELT_MIN.x and p.x < ZELT_MAX.x and p.z > ZELT_MIN.z and p.z < ZELT_MAX.z:
		return   # drinnen gelandet — er macht weiter
	for streit: Dictionary in _einzelstreits:
		if (streit.ids as Array).has(gast_id):
			streit.raus = int(streit.raus) + 1
	if _schlaegerei_ids.has(gast_id):
		_schlaegerei_raus += 1
	_pop_erhoehen(RAUSWURF_POP)
	_rausgeworfen += 1
	_despawn_guest(gast_id)
	_net_rauswurf.rpc(gast_id, Vector3.ZERO)

@rpc("authority", "reliable", "call_local")
func _net_rauswurf(gast_id: int, tempo: Vector3) -> void:
	var r = _raufbolde.get(gast_id)
	if r and is_instance_valid(r):
		r.remove_from_group("interactable")
		if r.packen():
			r.get_node("Kipper").rotation = Vector3.ZERO
			r.werfen(tempo)

## Ende (Zeit um, alle rausgeworfen, Feierabend): Beliebtheit, Dreck, Gäste gehen.
func _schlaegerei_beenden() -> void:
	if not multiplayer.is_server() or not schlaegerei_laeuft():
		return
	var ids := _schlaegerei_ids.duplicate()
	_schlaegerei_ids = []
	var anteil := float(_schlaegerei_raus) / float(maxi(1, ids.size()))
	var verlust := SCHLAEGEREI_POP * (1.0 - 0.5 * anteil)
	_popularity = maxf(POP_MIN, _popularity - verlust)
	for k in SCHLAEGEREI_DRECK:
		_spawn_mess_near(_schlaegerei_ort + Vector3(randf_range(-2.0, 2.0), 0.1, randf_range(-2.0, 2.0)))
	for id in ids:
		if _guest_sim.has(id):
			_despawn_guest(id)
	_net_schlaegerei_ende.rpc()
	_melde("MSG_SCHLAEGEREI_ENDE", [_schlaegerei_raus, roundi(verlust)], 1)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _net_schlaegerei_ende() -> void:
	if _schlaegerei_knoten and is_instance_valid(_schlaegerei_knoten):
		_schlaegerei_knoten.beenden()
	_schlaegerei_knoten = null
	for id in _raufbolde.keys():
		var r = _raufbolde[id]
		if r and is_instance_valid(r):
			r.remove_from_group("interactable")
			# Rappeln sich auf, hauen ab — draußen verschwinden sie
			get_tree().create_timer(12.0).timeout.connect(func() -> void:
				if is_instance_valid(r):
					r.queue_free())
	_raufbolde.clear()


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
			_van_pos = VAN_REIN[0][0]
			_van_weg = VAN_REIN.slice(1)
			_van_yaw = PI   # nach Süden, die Allee herunter
			_van_state = 1
			_van_show.rpc(true, _van_pos, _van_yaw)
			break
	if _van_state == 0:
		return
	match _van_state:
		1:
			if _van_fahren(delta):
				_van_state = 2
				_van_timer = 1.6
				_drop_cargo()
				_van_abladen.rpc()
				_van_honk.rpc()
		2:
			_van_timer -= delta
			if _van_timer <= 0.0:
				_van_state = 3
				_van_weg = VAN_RAUS.duplicate()
		3:
			if _van_fahren(delta):
				_van_state = 0
				_van_show.rpc(false, _van_pos, _van_yaw)
	if _van_state != 0:
		_van_move.rpc(_van_pos, _van_yaw)

## Einen Schritt die Wegpunkte entlang. true = letzter Punkt erreicht.
## Vor dem Halt und beim Rangieren (rückwärts) fährt er langsam; rückwärts
## schaut die Schnauze entgegen der Fahrtrichtung.
func _van_fahren(delta: float) -> bool:
	if _van_weg.is_empty():
		return true
	var ziel: Vector3 = _van_weg[0][0]
	var rueck: bool = _van_weg[0][1]
	var zu := ziel - _van_pos
	var d := zu.length()
	if d <= 0.3:
		_van_weg.pop_front()
		return _van_weg.is_empty()
	var tempo := VAN_SPEED
	var bis_halt := d if _van_weg.size() == 1 else 99.0
	if _van_state == 1 and bis_halt < 12.0:
		tempo = lerpf(VAN_LANGSAM, VAN_SPEED, bis_halt / 12.0)
	if rueck:
		tempo = VAN_LANGSAM * 1.4
	elif _van_state == 3 and _van_weg.size() > 1:
		tempo = VAN_LANGSAM * 1.6
	_van_pos += zu / d * minf(tempo * delta, d)
	var blick := atan2(-zu.x, -zu.z) if rueck else atan2(zu.x, zu.z)
	_van_yaw = lerp_angle(_van_yaw, blick, clampf(delta * 3.0, 0.0, 1.0))
	return false

func _drop_cargo() -> void:
	var n := 0
	for c in _van_cargo:
		for p in int(c.packs):
			var id := _pkg_next
			_pkg_next += 1
			var off := Vector3(randf_range(-1.4, 1.4), 0.0, randf_range(-0.7, 0.7))
			_add_package.rpc(id, DROP_POINT + off, int(c.kind), PACK_UNITS)
			n += 1
	_van_cargo = []
	_melde("MSG_GOODS_DELIVERED", [n])

@rpc("authority", "reliable", "call_local")
func _van_show(on: bool, pos: Vector3, yaw: float = PI) -> void:
	if on:
		if _van_node == null:
			_van_node = VAN_SCENE.instantiate()
			add_child(_van_node)
		_van_node.position = pos
		_van_node.rotation.y = yaw
	else:
		if _van_node and is_instance_valid(_van_node):
			_van_node.queue_free()
		_van_node = null

@rpc("authority", "unreliable", "call_local")
func _van_move(pos: Vector3, yaw: float = PI) -> void:
	if _van_node and is_instance_valid(_van_node):
		_van_node.position = pos
		_van_node.rotation.y = yaw

## Staubwolke beim Abladen (bei allen)
@rpc("authority", "reliable", "call_local")
func _van_abladen() -> void:
	if _van_node and is_instance_valid(_van_node) and _van_node.has_method("abladen"):
		_van_node.abladen()
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
	# Lager voll: Paket wieder vor den Spieler legen statt es verschwinden zu lassen
	if int(_stock[kind]) + amount > lager_kapazitaet():
		var s := multiplayer.get_remote_sender_id()
		if s == 0:
			s = 1
		var pl = _players_nodes.get(s)
		var ort: Vector3 = (pl as Node3D).global_position if pl else DROP_POINT
		var id := _pkg_next
		_pkg_next += 1
		_add_package.rpc(id, _ablageort(s, ort), kind, amount)
		_fehler("MSG_LAGER_VOLL", [lager_kapazitaet()])
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

## Ein Spieler hat selbst eine Maß ausgetrunken (scripts/player.gd). Die geht
## genauso vom Lager ab wie eine verkaufte — Geld gibt es dafür natürlich keins.
## Vorher kostete der Zapfhahn für einen selbst nichts, nur Verkaufen zählte.
@rpc("any_peer", "reliable", "call_local")
func net_selbst_getrunken() -> void:
	if not multiplayer.is_server():
		return
	_consume_stock(1)

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
	# Ohne Essenslizenz hätte der Koch nichts zu tun
	if role == ROLE_KOCH and _foods_avail().is_empty():
		_fehler("MSG_COOK_LICENSE")
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
	var eig: String = EIGENSCHAFTEN.keys().pick_random()
	_staff_sim[id] = {
		"role": role, "level": 1, "pos": start, "tgt": start, "yaw": 0.0,
		"state": 0, "timer": 0.0, "orders": [], "idx": 0, "eig": eig,
		"name": _personal_name(), "seit": _day, "lohn": 1.0, "anliegen": "", "energie": 1.0
	}
	_add_staff.rpc(id, start, role, 1)
	_melde("MSG_STAFF_HIRED", [STAFF_KEYS[role], "EIG_" + eig.to_upper(), _eur(_staff_wage(role, 1, eig))], 2)
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
		out.append({"role": int(s.role), "level": int(s.level), "eig": str(s.get("eig", "normal")),
			"name": str(s.get("name", "")), "seit": int(s.get("seit", 1)), "lohn": float(s.get("lohn", 1.0)),
			"anliegen": str(s.get("anliegen", "")), "unzufrieden": bool(s.get("unzufrieden", false))})
	return out

## Beim Laden: Mitarbeiter ohne Kosten wiederherstellen.
func _restore_staff(role: int, level: int, eig := "normal", mehr: Dictionary = {}) -> void:
	if not STAFF_HIRE_COST.has(role):
		return
	if not EIGENSCHAFTEN.has(eig):
		eig = "normal"
	var id := _staff_next
	_staff_next += 1
	var start: Vector3 = _staff_start(role)
	_staff_sim[id] = {
		"role": role, "level": clampi(level, 1, STAFF_MAX_LEVEL), "pos": start, "tgt": start,
		"yaw": 0.0, "state": 0, "timer": 0.0, "orders": [], "idx": 0, "eig": eig,
		"name": str(mehr.get("name", _personal_name())), "seit": int(mehr.get("seit", _day)),
		"lohn": float(mehr.get("lohn", 1.0)), "anliegen": str(mehr.get("anliegen", "")), "energie": 1.0,
		"unzufrieden": bool(mehr.get("unzufrieden", false)),
	}
	_add_staff.rpc(id, start, role, clampi(level, 1, STAFF_MAX_LEVEL))

func _staff_wage(role: int, level: int, eig := "normal") -> int:
	return int(round(float(STAFF_WAGE_BASE[role]) * (1.0 + 0.3 * (float(level) - 1.0))
		* float(EIGENSCHAFTEN.get(eig, EIGENSCHAFTEN.normal).lohn)))

func _total_wages() -> int:
	var w := 0
	for s in _staff_sim.values():
		w += roundi(float(_staff_wage(int(s.role), int(s.level), str(s.get("eig", "normal")))) * float(s.get("lohn", 1.0)))
	return w

func _staff_tempo(s: Dictionary) -> float:
	var t := float(EIGENSCHAFTEN.get(str(s.get("eig", "normal")), EIGENSCHAFTEN.normal).tempo)
	# Müdigkeit zum Abend hin, Unzufriedene arbeiten langsamer
	t *= 0.75 + 0.25 * float(s.get("energie", 1.0))
	if bool(s.get("unzufrieden", false)):
		t *= 0.85
	return t

## Nachts: Charmeure heben die Beliebtheit, Schluckspechte leeren Fässer.
func _eigenschaften_nacht() -> void:
	for s in _staff_sim.values():
		match str(s.get("eig", "")):
			"charmeur":
				_pop_erhoehen(CHARMEUR_POP)
			"schluckspecht":
				_stock[WARE_BIER] = maxi(0, int(_stock[WARE_BIER]) - SCHLUCKSPECHT_BIER)

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
	# Über die Treppe, wenn das Ziel auf der anderen Ebene liegt
	var wp := _wegpunkt(s, 0.45)
	var to: Vector3 = wp - s.pos
	to.y = 0
	var d := to.length()
	if d <= 0.35 and _nur_noch_ziel(s):
		return true
	if d < 0.0001:
		return false
	var dir := to / d
	# Tische umlaufen — aber nur solange das Ziel weit weg ist, sonst käme
	# der Kellner nie an einem Sitzplatz an (der liegt direkt am Tisch).
	if d > 2.6:
		dir = _avoid_tables(s.pos, dir)
	# Und an allem entlang, was wirklich im Weg steht (Theke, Regale, Deko).
	# Das letzte Stück bleibt frei, sonst käme niemand an der Theke an.
	if d > 1.2:
		dir = _um_hindernis(s.pos, dir)
	# Blickrichtung weich nachziehen und IMMER vorwärts laufen,
	# sonst schlurfen die Mitarbeiter seitlich oder rückwärts.
	var want := atan2(-dir.x, -dir.z)
	s.yaw = lerp_angle(float(s.yaw), want, clampf(delta * 7.0, 0.0, 1.0))
	var fwd := Vector3(-sin(float(s.yaw)), 0.0, -cos(float(s.yaw)))
	var sp: float = STAFF_BASE_SPEED * (0.7 + 0.06 * float(s.level)) * _staff_tempo(s)
	if fwd.dot(dir) > 0.2:
		var schritt := minf(sp * delta, d)
		var pos: Vector3 = s.pos
		# Höhe wandert anteilig mit — auf der Treppe ergibt das die Steigung
		pos.y += (wp.y - pos.y) * (schritt / d)
		s.pos = pos + fwd * schritt
	return false
## So weit voraus schaut das Personal nach Hindernissen
const HINDERNIS_SICHT := 1.1

## Führt der nächste Schritt in ein Möbel? Dann daran entlang statt hindurch.
## Das Personal wird nur gerechnet (kein CharacterBody), lief also bisher mitten
## durch die Schanktheke. Hier fragen wir dieselbe Kollision ab, an der auch
## Spieler hängen bleiben — damit gilt sie automatisch für alles, was Kollision
## hat, auch für später hingestelltes Zeug.
func _um_hindernis(pos: Vector3, dir: Vector3) -> Vector3:
	var raum := get_world_3d().direct_space_state
	if raum == null:
		return dir
	var start := pos + Vector3(0, 0.9, 0)
	var abf := PhysicsRayQueryParameters3D.create(start, start + dir * HINDERNIS_SICHT)
	abf.collide_with_areas = false
	var treffer := raum.intersect_ray(abf)
	if treffer.is_empty():
		return dir
	var n: Vector3 = treffer.normal
	n.y = 0.0
	if n.length() < 0.01:
		return dir
	n = n.normalized()
	# An der Fläche entlang weiterlaufen …
	var entlang := dir - n * dir.dot(n)
	entlang.y = 0.0
	if entlang.length() < 0.15:
		# … frontal davor: seitlich ausweichen, Richtung bleibt sonst stehen
		entlang = Vector3(-n.z, 0.0, n.x)
	return entlang.normalized()

func _avoid_tables(pos: Vector3, dir: Vector3) -> Vector3:
	var out := dir
	for bt in _beertables:
		var c: Vector3 = (bt as Node3D).global_position
		if absf(c.y - pos.y) > 1.5:
			continue   # Tisch auf der anderen Ebene
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
		if _phase == Phase.SHIFT:
			s.energie = maxf(0.3, float(s.get("energie", 1.0)) - MUEDE_JE_SEKUNDE * delta)
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
				var sorte := 0
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
							if sorte == 0:
								sorte = int(_guest_sim[gid].otype)
				if mit_essen:
					t += _food_prep_time()
				s.timer = t
				# Selbst zapfen: sichtbar nach hinten ans Fass gehen, dort warten
				s.state = 4 if sorte > 0 else 2
				if sorte > 0:
					s.tgt = _fass_platz(sorte)
		4:
			if _staff_move(s, delta):
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
			s.tgt = _platz_pos_fuer(gid2, seat)
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

## Koch: kocht an seiner Kochstelle Brezn und Würstl, trägt die Portion zur
## Ausgabe und geht zurück. Braucht eine Essenslizenz (net_hire_staff sperrt sonst).
func _update_koch(s: Dictionary, delta: float) -> void:
	var sorten := _foods_avail()
	match int(s.state):
		1:
			s.tgt = KOCH_ABLAGE
			if _staff_move(s, delta):
				_ausgabe_hinzufuegen(2, int(s.get("typ", 1)))
				s.state = 0
		_:
			s.tgt = KITCHEN_POINT
			if not _staff_move(s, delta) or sorten.is_empty():
				return
			var lv := int(s.level)
			var platz := mini(6, AUSGABE_MAX_ESSEN + (lv - 1))
			if _ausgabe_gesamt(2) >= mini(platz, int(_stock[WARE_ESSEN])):
				return
			s.timer = float(s.timer) - delta
			if float(s.timer) > 0.0:
				return
			s.timer = KOCH_ZEIT / (1.0 + 0.2 * float(lv - 1))
			s.typ = _naechste_sorte(2, sorten)
			s.state = 1

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

## Stellplätze je Sorte auf der Ausgabe (scenes/ausgabe.tscn): 16 Krüge bzw.
## 16 Teller, als 4 × 4 auf dem Tresen (tools/bake_ausgabe.gd)
const AUSGABE_JE_SORTE := {1: 16, 2: 16}

## Stellt ein Stück auf den Platz seiner Sorte. false, wenn der Platz voll ist.
func _ausgabe_hinzufuegen(art: int, typ: int) -> bool:
	var schluessel := "%d_%d" % [art, typ]
	if int(_ausgabe.get(schluessel, 0)) >= int(AUSGABE_JE_SORTE.get(art, 3)):
		return false
	_ausgabe[schluessel] = int(_ausgabe.get(schluessel, 0)) + 1
	if art == 2:
		_essen_gekocht += 1
	_ausgabe_senden()
	return true

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

## Spieler stellt einen vollen Krug auf die Ausgabe (vordere Theke). Die Fässer
## stehen hinten am Rückwandregal: zapfen, vorne abstellen, Kellner holen ab.
## Vier Biersorten und drei Gerichte, je 16 Stellplätze (scenes/ausgabe.tscn)
const AUSGABE_PLAETZE_KRUEGE := 64
const AUSGABE_PLAETZE_ESSEN := 48

@rpc("any_peer", "reliable", "call_local")
func net_put_ausgabe(typ: int, art: int = 1) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	art = 2 if art == 2 else 1
	typ = clampi(typ, 1, 4 if art == 1 else 3)
	# Wer Essen hinstellt, hat gekocht — das zählte vorher als Zapfen mit
	_leistung(s, "gekocht" if art == 2 else "gezapft")
	var gesamt: int = AUSGABE_PLAETZE_ESSEN if art == 2 else AUSGABE_PLAETZE_KRUEGE
	if _ausgabe_gesamt(art) >= gesamt:
		_fehler("MSG_AUSGABE_FULL", [gesamt])
		return
	if not _ausgabe_hinzufuegen(art, typ):
		_fehler("MSG_AUSGABE_SORTE_VOLL", [AUSGABE_JE_SORTE[art]])
		return
	if s == multiplayer.get_unique_id():
		_net_ausgabe_abgestellt()
	else:
		_net_ausgabe_abgestellt.rpc_id(s)

## Beim abstellenden Spieler: Krug aus der Hand (nächster Krug rückt nach).
@rpc("authority", "reliable", "call_local")
func _net_ausgabe_abgestellt() -> void:
	var p = _players_nodes.get(multiplayer.get_unique_id())
	if p and p.has_method("krug_abgestellt"):
		p.krug_abgestellt()

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
	_stamm_bedient(g)
	g.served_t = SERVED_SHOW
	_guest_sim[gid] = g
	_served += 1
	_stats.served += 1
	g.drinks = int(g.get("drinks", 0)) + 1
	_rausch_nach_bedienung(g)
	_quest_served_once = true
	_pop_erhoehen(POP_SERVE * _typ_pop(g))
	var hyg :=HYGIENE_MIN_ANTEIL + (1.0 - HYGIENE_MIN_ANTEIL) * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind), int(g.otype)) * hyg * (1.0 + DEKO_BONUS * _upg_deko) * _typ_umsatz(g))
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
func _net_staff(ids: PackedInt32Array, sx: PackedFloat32Array, sy: PackedFloat32Array, sz: PackedFloat32Array, syaw: PackedFloat32Array, scarry: PackedInt32Array) -> void:
	for i in range(ids.size()):
		var n = _staff.get(ids[i])
		if n:
			n.set_net(Vector3(sx[i], sy[i] if i < sy.size() else 0.1, sz[i]), syaw[i])
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
	if key in LIC_SPAET and not spaetlizenz_frei():
		_fehler("WHY_LIC_LATE")
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
	var raum := bierpreis_grenzen()
	if key in ESSEN_LIZENZEN:
		var essen_raum := essenpreis_grenzen()
		_melde("MSG_LIC_ESSENRAUM", [roundi(essen_raum.x * 100.0), roundi(essen_raum.y * 100.0)])
	else:
		_melde("MSG_LIC_PREISRAUM", [roundi(raum.x * 100.0), roundi(raum.y * 100.0)])
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
	# Allein (oder nur ein Spieler auf dem Server): sofort. Sonst stimmen alle ab.
	if _players_nodes.size() <= 1:
		_tag_starten()
		return
	if not _abstimmung.is_empty():
		return   # läuft schon
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	_abstimmung = {"starter": s, "ja": {s: true}, "nein": {}, "rest": ABSTIMMUNG_ZEIT}
	_melde("MSG_VOTE_STARTED", [_spieler_bezeichnung(s)])
	_abstimmung_pruefen(false)

## Uyu → ertesi sabah 08:00. Die Uhr steht, bis ein Spieler das Zelt eröffnet.
## Der Tag wechselt erst hier, beim Schlafen — vorher stand nach Feierabend
## schon der nächste Tag im Kalender und oben in der Leiste, obwohl niemand
## geschlafen hatte.
func _tag_starten() -> void:
	_day += 1   # endlos: Tag 17, 18, 19 … — kein Rücksprung mehr
	_stats.days += 1
	_broadcast_meta()
	net_sleep_fade.rpc(_day)
	_spieler_zum_wohnwagen()
	_start_shift()
	_melde("MSG_DAY_START", [_day])

## Nach dem Schlafen stehen alle wieder vor dem Wohnwagen — vorher wachte man
## da auf, wo man abends stehen geblieben war, im Koop also quer über die Wiesn
## verstreut. Nebeneinander, damit niemand im anderen steht.
func _spieler_zum_wohnwagen() -> void:
	var wagen := _eigener_wohnwagen()
	if wagen == null:
		return
	var tuer := wagen.interact_point() - Vector3(0, 1.0, 0)
	var seitwaerts := wagen.global_transform.basis.x
	var anzahl := _players_nodes.size()
	var i := 0
	for peer: int in _players_nodes.keys():
		var p: Node = _players_nodes[peer]
		if p == null or not is_instance_valid(p):
			continue
		var versatz := seitwaerts * (float(i) - float(anzahl - 1) * 0.5) * 1.2
		var ziel: Vector3 = tuer + versatz
		# Blick zum Wagen: so sieht man morgens gleich die Tür
		var hin: Vector3 = wagen.global_position - ziel
		p.versetzen.rpc_id(peer, Vector3(ziel.x, 0.2, ziel.z), atan2(-hin.x, -hin.z))
		i += 1

func _eigener_wohnwagen() -> Caravan:
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Caravan and (n as Caravan).is_mine:
			return n as Caravan
	return null

## Anzeigename eines Spielers in Meldungen: Name aus der Lobby, sonst „Spieler 2".
func _spieler_bezeichnung(peer: int) -> String:
	var n := str((_spieler_info.get(peer, {}) as Dictionary).get("name", ""))
	if n != "":
		return n
	var nummer := int(_spawn_index_by_peer.get(peer, 0)) + 1
	return tr("PLAYER_N") % nummer

# ================================================= Lobby
func open_lobby_ui() -> void:
	if _hud and _hud.has_method("open_lobby"):
		_hud.lobby_aktualisieren(_spieler_info)
		_hud.open_lobby()

## Lobby-Wahl eines Spielers speichern und allen schicken.
@rpc("any_peer", "reliable", "call_local")
func net_lobby_setzen(spielername: String, farbe: int, figur: int = -1, lobby_id: String = "") -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if lobby_id != "":
		_lobby_ids[s] = lobby_id.substr(0, 32)
	var n := zeltname_pruefen(spielername)
	if n.length() > SPIELERNAME_MAX:
		n = n.substr(0, SPIELERNAME_MAX).strip_edges()
	# Figur aus dem Warteraum; -1 = bisherige behalten (Lobby-Fenster im Spiel)
	if figur < 0:
		figur = int((_spieler_info.get(s, {}) as Dictionary).get("figur", 0))
	_spieler_info[s] = {"name": n, "farbe": clampi(farbe, 0, 5),
		"figur": clampi(figur, 0, Figuren.ALLE.size() - 1)}
	_net_spieler_info.rpc(_spieler_info)

@rpc("authority", "reliable", "call_local")
func _net_spieler_info(info: Dictionary) -> void:
	_spieler_info = info
	for peer in info.keys():
		var p = _players_nodes.get(int(peer))
		if p and p.has_method("set_info"):
			var d: Dictionary = info[peer]
			p.set_info(str(d.get("name", "")), int(d.get("farbe", 0)), int(d.get("figur", 0)))
	if _hud and _hud.has_method("lobby_aktualisieren"):
		_hud.lobby_aktualisieren(info)

## Ergebnis einer Abstimmung: 1 = Tag starten, -1 = abbrechen, 0 = noch offen.
## Mehrheit aller Spieler — wer nicht abstimmt, zählt nicht als Ja.
static func abstimmung_ergebnis(ja: int, nein: int, gesamt: int, abgelaufen: bool) -> int:
	if ja * 2 > gesamt:
		return 1
	if nein * 2 >= gesamt or abgelaufen:
		return -1
	return 0

@rpc("any_peer", "reliable", "call_local")
func net_abstimmen(ja: bool) -> void:
	if not multiplayer.is_server() or _abstimmung.is_empty():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var dafuer: Dictionary = _abstimmung.ja
	var dagegen: Dictionary = _abstimmung.nein
	dafuer.erase(s)
	dagegen.erase(s)
	if ja:
		dafuer[s] = true
	else:
		dagegen[s] = true
	_abstimmung_pruefen(false)

## Auswerten und allen den Stand schicken. Aufgerufen bei jeder Stimme, jede Sekunde
## und wenn ein Spieler das Spiel verlässt.
func _abstimmung_pruefen(abgelaufen: bool) -> void:
	if _abstimmung.is_empty():
		return
	# Nur Stimmen von Spielern zählen, die noch da sind
	for liste: Dictionary in [_abstimmung.ja, _abstimmung.nein]:
		for peer in liste.keys():
			if not _players_nodes.has(peer):
				liste.erase(peer)
	var gesamt := maxi(1, _players_nodes.size())
	var ja := (_abstimmung.ja as Dictionary).size()
	var nein := (_abstimmung.nein as Dictionary).size()
	var ergebnis := abstimmung_ergebnis(ja, nein, gesamt, abgelaufen)
	var starter := _spieler_bezeichnung(int(_abstimmung.starter))
	if ergebnis == 0:
		# Jeder bekommt seinen eigenen Stand (hat er schon abgestimmt?)
		var rest := ceili(float(_abstimmung.rest))
		for peer in _players_nodes.keys():
			var gestimmt: bool = (_abstimmung.ja as Dictionary).has(peer) or (_abstimmung.nein as Dictionary).has(peer)
			if peer == multiplayer.get_unique_id():
				_net_abstimmung(true, starter, ja, nein, gesamt, rest, gestimmt)
			else:
				_net_abstimmung.rpc_id(peer, true, starter, ja, nein, gesamt, rest, gestimmt)
		return
	_abstimmung = {}
	_net_abstimmung.rpc(false, "", ja, nein, gesamt, 0, false)
	if ergebnis == 1 and _phase == Phase.INTERMISSION:
		_melde("MSG_VOTE_YES", [ja, gesamt])
		_tag_starten()
	else:
		_melde("MSG_VOTE_NO", [ja, gesamt])

@rpc("authority", "reliable", "call_local")
func _net_abstimmung(aktiv: bool, starter: String, ja: int, nein: int, gesamt: int, rest: int, gestimmt: bool) -> void:
	if _hud and _hud.has_method("zeige_abstimmung"):
		_hud.zeige_abstimmung(aktiv, starter, ja, nein, gesamt, rest, gestimmt)

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
		var idx: int = _held[s]
		_held.erase(s)
		# Oben auf der Empore rastet der Tisch längs ein — das zählt nicht als verschoben
		if _tisch_freistellen(idx):
			_fehler("MSG_TABLE_VERSCHOBEN")
		_rebuild_seats()
	elif index >= 0 and index < _beertables.size() and not _held.values().has(index) and not _held_deko.has(s):
		_held[s] = index
	_broadcast_meta()

## Getragenen Tisch um 45° drehen (Prost-Taste). Die Sitzplätze drehen mit.
@rpc("any_peer", "reliable", "call_local")
func net_rotate_table() -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if not _held.has(s):
		return
	var bt := _beertables[int(_held[s])] as Node3D
	bt.rotation.y = wrapf(bt.rotation.y + PI / 4.0, -PI, PI)

## Trägt dieser Spieler gerade einen Tisch? (Clients: aus dem Büro-Stand)
func haelt_tisch(peer_id: int) -> bool:
	return _haelt_tisch.has(str(peer_id))

## Liegt der Punkt im Zelt? Für Interaktionen: nichts durch die Zeltwand greifen.
func im_zelt(p: Vector3) -> bool:
	return p.x > WAND_X * -1.0 and p.x < WAND_X and p.z > WAND_HINTEN and p.z < WAND_VORN

## Tischplätze: mindestens so weit auseinander, frei von Theke, Bühne, Büro, Klo,
## Lager und Eingang. Rechtecke: Mitte x/z, halbe Breite x/z (schon mit Tischgröße).
const TISCH_MINDESTABSTAND := 2.8
const TISCH_BEREICH_MIN := Vector2(-10.0, -7.3)
const TISCH_BEREICH_MAX := Vector2(10.0, 9.2)
const TISCH_SPERREN := [
	[Vector2(10.0, 2.0), Vector2(3.2, 4.2)],    # Bühne
	[Vector2(-8.0, 7.0), Vector2(3.6, 3.6)],    # Büroraum
	[Vector2(10.4, 9.6), Vector2(2.6, 2.6)],    # Klo-Container
	[Vector2(-11.2, -5.0), Vector2(2.4, 3.0)],  # Lager
	[Vector2(0.0, 10.0), Vector2(1.8, 1.6)],    # Eingang
	[Vector2(-11.35, 3.25), Vector2(2.4, 4.6)], # Treppe West
	[Vector2(11.35, -6.75), Vector2(2.4, 4.6)], # Treppe Ost
	[Vector2(-7.95, -6.5), Vector2(1.5, 1.05)], # Emporenstützen
	[Vector2(-7.95, -1.5), Vector2(1.5, 1.05)],
	[Vector2(-7.95, 3.5), Vector2(1.5, 1.05)],
	[Vector2(7.95, -6.5), Vector2(1.5, 1.05)],
	[Vector2(7.95, 8.5), Vector2(1.5, 1.05)],
]

## Auf welcher Ebene steht der Tisch? (0 Boden, 1/2 Empore)
static func tisch_ebene(bt: Node3D) -> int:
	return ebene_von(bt.position + Vector3(0, 0.1, 0))

func _tischplatz_frei(p: Vector2, ausser: int, ebene := 0) -> bool:
	if ebene > 0:
		# Empore: Tischmitte auf der festen Linie, nicht über Treppenloch und Austritt
		var s := -1.0 if ebene == 1 else 1.0
		if absf(p.x - s * EMPORE_TISCH_X) > 0.05:
			return false
		var im_bereich := false
		for bereich: Vector2 in EMPORE_TISCH_Z[ebene - 1]:
			if p.y >= bereich.x - 0.001 and p.y <= bereich.y + 0.001:
				im_bereich = true
		if not im_bereich:
			return false
	else:
		if p.x < TISCH_BEREICH_MIN.x or p.x > TISCH_BEREICH_MAX.x or p.y < TISCH_BEREICH_MIN.y or p.y > TISCH_BEREICH_MAX.y:
			return false
		for sperre: Array in TISCH_SPERREN:
			var d: Vector2 = (p - (sperre[0] as Vector2)).abs()
			if d.x < (sperre[1] as Vector2).x and d.y < (sperre[1] as Vector2).y:
				return false
		# Aufgestellte Einrichtung am Boden (Regal, Fass …) — nicht hineinstellen
		for e: Dictionary in _einrichtung.values():
			var art := str(e.get("art", ""))
			if Katalog.ARTEN.has(art) and str(Katalog.ARTEN[art].get("platz", "boden")) == "boden":
				if p.distance_to(Vector2(float(e.x), float(e.z))) < 1.8:
					return false
	for i in _beertables.size():
		if i == ausser or tisch_ebene(_beertables[i]) != ebene:
			continue
		var q := (_beertables[i] as Node3D).position
		if p.distance_to(Vector2(q.x, q.z)) < TISCH_MINDESTABSTAND:
			return false
	return true

## Nächster freier Platz zum Wunschpunkt (Raster 0,5 m). Auf der Empore nur entlang
## der Tischlinie.
func _freier_tischplatz(wunsch: Vector2, ausser: int, ebene := 0) -> Vector2:
	if ebene > 0:
		var s := -1.0 if ebene == 1 else 1.0
		wunsch.x = s * EMPORE_TISCH_X
	if _tischplatz_frei(wunsch, ausser, ebene):
		return wunsch
	var bester := wunsch
	var beste_d := INF
	var kandidaten := []
	if ebene > 0:
		for bereich: Vector2 in EMPORE_TISCH_Z[ebene - 1]:
			var z := bereich.x
			while z <= bereich.y + 0.001:
				kandidaten.append(Vector2(wunsch.x, z))
				z += 0.5
			kandidaten.append(Vector2(wunsch.x, bereich.y))
	else:
		var x := TISCH_BEREICH_MIN.x
		while x <= TISCH_BEREICH_MAX.x:
			var z := TISCH_BEREICH_MIN.y
			while z <= TISCH_BEREICH_MAX.y:
				kandidaten.append(Vector2(x, z))
				z += 0.5
			x += 0.5
	for p: Vector2 in kandidaten:
		var d := p.distance_squared_to(wunsch)
		if d < beste_d and _tischplatz_frei(p, ausser, ebene):
			beste_d = d
			bester = p
	return bester

## Tisch auf einen freien Platz rücken. true, wenn er verschoben werden musste.
## Auf der Empore steht er längs; ist oben kein Platz mehr, kommt er nach unten.
func _tisch_freistellen(idx: int) -> bool:
	if idx < 0 or idx >= _beertables.size():
		return false
	var bt := _beertables[idx] as Node3D
	var ebene := tisch_ebene(bt)
	var wunsch := Vector2(bt.position.x, bt.position.z)
	var p := _freier_tischplatz(wunsch, idx, ebene)
	if ebene > 0 and not _tischplatz_frei(p, idx, ebene):
		ebene = 0
		p = _freier_tischplatz(wunsch, idx, 0)
		bt.position = Vector3(p.x, 0.0, p.y)
		return true
	bt.position = Vector3(p.x, ebene_boden(ebene), p.y)
	if ebene > 0:
		bt.rotation.y = PI / 2.0
		return absf(p.y - wunsch.y) > 0.8
	return p.distance_to(wunsch) > 0.01

# ================================================= Lagerregale (Test 13.09.)
## Jedes Regal fasst Lager.KAPAZITAET je Ware. Zwei stehen von Anfang an im Zelt,
## weitere kauft man im Wiesenbüro. Außerhalb der Schicht lassen sich alle mit E
## aufnehmen, mit der Prost-Taste drehen und woanders abstellen.
const LAGER_SCENE := preload("res://scenes/lager.tscn")
const LAGERREGAL_KOSTEN := 350
const LAGERREGAL_MAX := 4
## Plätze für gekaufte Regale (frei von Büro, Bühne, Theke): x, z, Drehung
const LAGERREGAL_PLAETZE := [Vector3(-11.2, -8.0, -PI / 2.0), Vector3(-11.2, -11.4, -PI / 2.0)]
var _lager_gekauft := 0
var _held_lager := {}        # peer_id -> Regal-Index (Server)
var _haelt_lager := {}       # vom Server: Peer-ID (Text) -> Index

## Alle Lagerregale in fester Reihenfolge (nach Knotenname).
func _lagerregale() -> Array:
	var regale := get_tree().get_nodes_in_group("lager")
	regale.sort_custom(func(a, b): return String(a.name) < String(b.name))
	return regale

func lager_kapazitaet() -> int:
	return maxi(1, _lagerregale().size()) * Lager.KAPAZITAET

func haelt_lager(peer_id: int) -> bool:
	return _haelt_lager.has(str(peer_id))

## Für den Büro-Stand: wer trägt welches Regal (Peer-ID als Text).
func _haelt_lager_stand() -> Dictionary:
	var stand := {}
	for pid in _held_lager.keys():
		stand[str(pid)] = int(_held_lager[pid])
	return stand

@rpc("any_peer", "reliable", "call_local")
func net_buy_lagerregal() -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	if _tent_stage == 0:
		_fehler("MSG_NEED_TENT")
		return
	if _lagerregale().size() >= LAGERREGAL_MAX:
		_fehler("WHY_MAX_REGALE", [LAGERREGAL_MAX])
		return
	if _kredit_sperrt() or not _reserve_ok(LAGERREGAL_KOSTEN):
		return
	if not _afford(LAGERREGAL_KOSTEN):
		_fehler("MSG_NO_MONEY", ["OFFER_LAGERREGAL", _eur(LAGERREGAL_KOSTEN)])
		return
	Game.add_money(-LAGERREGAL_KOSTEN)
	var platz: Vector3 = LAGERREGAL_PLAETZE[mini(_lager_gekauft, LAGERREGAL_PLAETZE.size() - 1)]
	_lager_gekauft += 1
	_add_lagerregal.rpc(_lager_gekauft, platz.x, platz.y, platz.z)
	_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))
	_melde("MSG_LAGERREGAL_GEKAUFT", [lager_kapazitaet()], 2)
	_broadcast_meta()

## Gekauftes Regal bei allen anlegen (Name LagerKauf1 … — sortiert hinter Lager, Lager2).
@rpc("authority", "reliable", "call_local")
func _add_lagerregal(nr: int, x: float, z: float, rot: float) -> void:
	var name_neu := "LagerKauf%d" % nr
	if has_node(name_neu):
		return
	var regal := LAGER_SCENE.instantiate()
	regal.name = name_neu
	regal.position = Vector3(x, 0.0, z)
	regal.rotation.y = rot
	add_child(regal)

## Regal aufnehmen oder abstellen (außerhalb der Schicht, mit leeren Händen).
@rpc("any_peer", "reliable", "call_local")
func net_move_lager(index: int) -> void:
	if not multiplayer.is_server() or _phase != Phase.INTERMISSION:
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var regale := _lagerregale()
	if _held_lager.has(s):
		var idx: int = _held_lager[s]
		_held_lager.erase(s)
		if idx >= 0 and idx < regale.size():
			var r := regale[idx] as Node3D
			r.position = _neben_treppe(Vector3(clampf(r.position.x, -WAND_X + 0.6, WAND_X - 0.6), 0.0,
				clampf(r.position.z, WAND_HINTEN + 0.6, WAND_VORN - 0.6)))
	elif index >= 0 and index < regale.size() and not _held_lager.values().has(index) \
			and not _held.has(s) and not _held_deko.has(s):
		_held_lager[s] = index
	_broadcast_meta()

@rpc("any_peer", "reliable", "call_local")
func net_rotate_lager() -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	if not _held_lager.has(s):
		return
	var regale := _lagerregale()
	var idx: int = _held_lager[s]
	if idx < regale.size():
		(regale[idx] as Node3D).rotation.y = wrapf((regale[idx] as Node3D).rotation.y + PI / 2.0, -PI, PI)

## Getragene Regale vor dem Spieler mitführen (aus _update_held_tables).
func _update_held_lager() -> void:
	var regale := _lagerregale()
	for peer in _held_lager.keys():
		var idx: int = _held_lager[peer]
		var pl = _players_nodes.get(peer)
		if pl == null or idx < 0 or idx >= regale.size():
			continue
		var p: Vector3 = (pl as Node3D).global_position - (pl as Node3D).global_transform.basis.z * 2.0
		(regale[idx] as Node3D).position = Vector3(p.x, 0.0, p.z)

## Lage aller Regale für Clients und Spielstand: [[x, z, rot], …]
func _lager_lagen() -> Array:
	var lagen := []
	for r in _lagerregale():
		lagen.append([(r as Node3D).position.x, (r as Node3D).position.z, (r as Node3D).rotation.y])
	return lagen

@rpc("authority", "unreliable")
func _net_lager(lagen: Array) -> void:
	var regale := _lagerregale()
	for i in mini(lagen.size(), regale.size()):
		var l: Array = lagen[i]
		(regale[i] as Node3D).position = Vector3(float(l[0]), 0.0, float(l[1]))
		(regale[i] as Node3D).rotation.y = float(l[2])

func _update_held_tables() -> void:
	for peer in _held.keys():
		var idx: int = _held[peer]
		var pl = _players_nodes.get(peer)
		if pl == null or idx < 0 or idx >= _beertables.size():
			continue
		var fwd: Vector3 = -pl.global_transform.basis.z
		var p: Vector3 = pl.global_position + fwd * 2.5
		# Wer oben auf der Empore trägt, stellt oben ab
		_beertables[idx].position = Vector3(p.x, ebene_boden(ebene_von((pl as Node3D).global_position)), p.z)
	_update_held_lager()
	# Getragene Einrichtung schwebt vor dem Spieler mit
	for peer in _held_deko.keys():
		var did: int = _held_deko[peer]
		var pl = _players_nodes.get(peer)
		var n: Node3D = _einrichtung_nodes.get(did)
		if pl == null or n == null:
			continue
		var fwd: Vector3 = -pl.global_transform.basis.z
		var p: Vector3 = pl.global_position + fwd * DEKO_ABSTAND
		var e: Dictionary = _einrichtung[did]
		# Wanddeko rastet schon beim Tragen an der nahen Wand ein
		var lage := _deko_platz(str(e.art), p.x, p.z, float(e.rot), true)
		e.x = lage.x
		e.z = lage.z
		e.rot = lage.rot
		n.position = Vector3(lage.x, lage.y, lage.z)
		n.rotation.y = lage.rot

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
	# Neben dem Eingang (freie Fläche zwischen den Tischreihen)
	var x := -2.4 + float(_einrichtung.size() % 5) * 1.2
	var lage := _deko_platz(art, x, 10.3, 0.0)
	_einrichtung[did] = {"art": art, "x": lage.x, "z": lage.z, "rot": lage.rot}
	_add_einrichtung.rpc(did, art, float(lage.x), float(lage.z), float(lage.rot))
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
	n.position = Vector3(x, Katalog.hoehe(art), z)
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
	var lage := _deko_platz(str(e.art), float(e.x), float(e.z), float(e.rot))
	e.x = lage.x
	e.z = lage.z
	e.rot = lage.rot
	_set_einrichtung.rpc(did, float(e.x), float(e.z), float(e.rot))

## Wo ein Gegenstand wirklich hinkommt: im Zelt, Wanddeko an der nächsten Wand
## (Vorderseite ins Zelt), Decken- und Wanddeko auf ihrer Höhe aus dem Katalog.
## frei = beim Tragen: weit weg von jeder Wand noch nicht einrasten.
## Liefert {x, z, rot, y}.
func _deko_platz(art: String, x: float, z: float, rot: float, frei := false) -> Dictionary:
	x = clampf(x, ZELT_MIN.x, ZELT_MAX.x)
	z = clampf(z, ZELT_MIN.z, ZELT_MAX.z)
	if Katalog.platz(art) == "decke":
		x = clampf(x, -EMPORE_KANTE + 0.5, EMPORE_KANTE - 0.5)   # nicht in die Emporen hängen
	else:
		var neben := _neben_treppe(Vector3(x, 0.0, z))
		x = neben.x
	if Katalog.platz(art) == "wand":
		var abstand := {"west": x + WAND_X, "ost": WAND_X - x, "hinten": z - WAND_HINTEN, "vorn": WAND_VORN - z}
		var naechste := "west"
		for w: String in abstand:
			if float(abstand[w]) < float(abstand[naechste]):
				naechste = w
		if not frei or float(abstand[naechste]) <= WAND_FANG:
			match naechste:
				"west":
					x = -WAND_X
					rot = PI / 2.0
				"ost":
					x = WAND_X
					rot = -PI / 2.0
				"hinten":
					z = WAND_HINTEN
					rot = 0.0
				"vorn":
					z = WAND_VORN
					rot = PI
	return {"x": x, "z": z, "rot": rot, "y": Katalog.hoehe(art)}

@rpc("authority", "reliable", "call_local")
func _set_einrichtung(did: int, x: float, z: float, rot: float) -> void:
	var n: Node3D = _einrichtung_nodes.get(did)
	if n:
		n.position = Vector3(x, Katalog.hoehe(n.art), z)
		n.rotation.y = rot

@rpc("authority", "unreliable")
func _net_einrichtung_pos(ids: PackedInt32Array, xs: PackedFloat32Array, zs: PackedFloat32Array, rots: PackedFloat32Array) -> void:
	for i in ids.size():
		var n: Node3D = _einrichtung_nodes.get(ids[i])
		if n:
			n.position = Vector3(xs[i], Katalog.hoehe(n.art), zs[i])
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
	_rausch_nach_bedienung(g)
	_quest_served_once = true
	_pop_erhoehen(POP_SERVE * _typ_pop(g))
	var waiter_npc := _npc_roles.has(ROLE_WAITER)
	var hyg := HYGIENE_MIN_ANTEIL + (1.0 - HYGIENE_MIN_ANTEIL) * (_hygiene / 100.0)
	var reward := int(_reward_for(int(g.okind), int(g.otype)) * hyg * (1.0 + DEKO_BONUS * _upg_deko) * _typ_umsatz(g))
	var tip := 0 if waiter_npc else randi_range(TRINKGELD_MIN, TRINKGELD_MAX)
	# Kombo: wer schnell hintereinander bedient, bekommt mehr Trinkgeld
	var bediener := multiplayer.get_remote_sender_id()
	if bediener == 0:
		bediener = 1
	_leistung(bediener, "bedient")
	_stamm_bedient(g)
	var jetzt := Time.get_ticks_msec()
	var k: Dictionary = _kombo.get(bediener, {"n": 0, "t": 0})
	var kombo := int(k.n) + 1 if jetzt - int(k.t) <= KOMBO_FENSTER_MS else 1
	_kombo[bediener] = {"n": kombo, "t": jetzt}
	_stats.kombo_max = maxi(int(_stats.get("kombo_max", 0)), kombo)
	tip += mini(KOMBO_MAX, (kombo - 1) * KOMBO_BONUS)
	tip += _typ_trinkgeld(g)
	if _ereignis == "promi":
		tip *= 2
	if kombo >= 3:
		_net_kombo.rpc_id(bediener, kombo)
	if waiter_npc:
		reward = int(reward * 0.5)
	if rausch_stufe(g) >= 1:
		tip = roundi(float(tip) * (1.0 + BESCHWIPST_TRINKGELD))   # beschwipst gibt mehr
	_last_earn += reward + tip
	Game.add_score(reward)
	_add_income(reward + tip)
	_net_betrag.rpc(g.pos, reward + tip, false)

## Verkaufspreis je Bestellung. Einkauf: Bier 4€, Zutaten 5€ pro Einheit —
## damit bleibt genug Marge, um Miete und Löhne zu tragen.
func _reward_for(okind: int, otype := 1) -> int:
	var sorte := float(PREIS_FAKTOR_SORTE.get("%d_%d" % [okind, otype], 1.0))
	if okind == 2:
		return roundi(float(Wirtschaft.verkaufspreis(Wirtschaft.ESSEN_BASIS, _day)) * sorte * _essenpreis)
	# Bier: Tagespreis × selbst gewählter Bierpreis
	var happy := 0.7 if _happy_hour() else 1.0
	return roundi(float(Wirtschaft.verkaufspreis(Wirtschaft.BIER_BASIS, _day)) * _bierpreis * happy * sorte)

func CustomerReward() -> int:
	return 15
func _process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_vermittler_melden(delta)
	if Net.dedicated and _players_nodes.is_empty():
		_leer_pruefen(delta)
		return
	_leer_seit = 0.0
	_ziel_senden(delta)
	if _dreck_nachlegen and _messes_container:
		_dreck_nachlegen = false
		if _quest_step == 2 and _tent_stage > 0 and not _dreck_uebrig():
			_dreck_verteilen()
	# Abstimmung „Nächster Tag?": Restzeit jede Sekunde an alle, am Ende auswerten
	if not _abstimmung.is_empty():
		var vorher := ceili(float(_abstimmung.rest))
		_abstimmung.rest = float(_abstimmung.rest) - delta
		if float(_abstimmung.rest) <= 0.0:
			_abstimmung_pruefen(true)
		elif ceili(float(_abstimmung.rest)) != vorher:
			_abstimmung_pruefen(false)
	if _phase == Phase.SHIFT:
		# Die Uhr läuft erst ab der Eröffnung: vorher ist Zeit zum Einräumen,
		# Putzen und Bauen, ohne dass der Tag wegläuft.
		if _zelt_offen:
			_phase_time -= delta
		_shift_process(delta)
		_huber_schicht(delta)
		_saboteur_schicht(delta)
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
	# Zelt noch nicht eröffnet: keine Gäste, und die Uhr steht — nach
	# AUTO_OEFFNEN_WARTEN öffnet es von selbst
	if not _zelt_offen:
		_zelt_wartet += delta
		if _zelt_wartet >= AUTO_OEFFNEN_WARTEN:
			_zelt_eroeffnen("", true)
	_guest_spawn_timer -= delta
	if _zelt_offen and _guest_spawn_timer <= 0.0:
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
		andrang *= _ereignis_andrang()
		andrang *= float(ANDRANG_FAKTOR[_schwierigkeit])
		andrang *= 1.0 + SAISON_ANDRANG * float(_saison_nr - 1)   # jede Wiesn voller
		# Koop: mit mehr Spielern kommen mehr Gäste, sonst ist es zu leicht
		andrang *= 1.0 + KOOP_ANDRANG_JE_SPIELER * float(maxi(1, _players_nodes.size()) - 1)
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
	_update_ereignis(delta)
	_update_schlaegerei(delta)
	_update_gepackt(delta)
	_update_staff(delta)
	_update_complaints(delta)
	_update_hygiene(delta)

## Gästetyp nach Gewicht (GAST_TYPEN).
func _gast_typ_waehlen() -> String:
	# Sondertage laut Kalender
	if _ereignis == "tracht" and randf() < 0.55:
		return "tracht"
	if _ereignis == "italiener" and randf() < 0.45:
		return "tourist"
	var summe := 0
	for w in GAST_TYPEN.values():
		summe += int(w)
	var r := randi() % summe
	for t: String in GAST_TYPEN:
		r -= int(GAST_TYPEN[t])
		if r < 0:
			return t
	return ""

## Volle Geduld dieses Gasts (Grundgeduld × Typ).
func _geduld_max(g: Dictionary) -> float:
	var betrunken := BETRUNKEN_GEDULD if rausch_stufe(g) >= 2 else 1.0
	return _geduld() * float(TYP_GEDULD.get(str(g.get("typ", "")), 1.0)) * betrunken

## Getränk steigt zu Kopf, Essen macht nüchterner. Betrunkene werfen manchmal den
## Krug um: Pfütze, und sie bestellen gleich wieder.
func _rausch_nach_bedienung(g: Dictionary) -> void:
	var vorher := rausch_stufe(g)
	var r := float(g.get("rausch", 0.0))
	if int(g.okind) == 2:
		g.rausch = maxf(0.0, r - RAUSCH_ESSEN)
		return
	g.rausch = minf(100.0, r + float(RAUSCH_JE_SORTE.get(int(g.otype), 18.0)))
	if vorher >= 2 and randf() < UMWERF_CHANCE:
		_spawn_mess_near(g.pos)
		g.ostate = 0
		g.cooldown = randf_range(2.0, 5.0)
		_stats.umgeworfen = int(_stats.get("umgeworfen", 0)) + 1

## Spieler bringt einem angetrunkenen Gast Wasser.
@rpc("any_peer", "reliable", "call_local")
func net_wasser_geben(id: int) -> void:
	if not multiplayer.is_server() or not _guest_sim.has(id):
		return
	var g: Dictionary = _guest_sim[id]
	if float(g.get("rausch", 0.0)) <= 0.0:
		return
	g.rausch = maxf(0.0, float(g.rausch) - RAUSCH_WASSER)
	_pop_erhoehen(WASSER_POP)
	_stats.wasser = int(_stats.get("wasser", 0)) + 1
	if int(g.mode) == 8 and rausch_stufe(g) < 3:
		g.mode = 1   # wieder wach
		g.tgt = _platz_pos_fuer(id, int(g.seat))
	_guest_sim[id] = g
	_net_betrag.rpc(g.pos, 0, true)

## Spieler bringt eine Bierleiche heim: sie hakt sich ein und läuft hinterher.
@rpc("any_peer", "reliable", "call_local")
func net_heimbringen(id: int) -> void:
	if not multiplayer.is_server() or not _guest_sim.has(id):
		return
	var g: Dictionary = _guest_sim[id]
	if int(g.mode) != 8:
		return
	var s := multiplayer.get_remote_sender_id()
	g.mode = 9
	g.folgt = s if s != 0 else 1
	_assigned.erase(id)
	_guest_sim[id] = g

## Bierleiche schläft, Heimgebrachte folgen dem Spieler. true = Gast ist weg.
func _rausch_aktualisieren(g: Dictionary, id: int, delta: float) -> bool:
	match int(g.mode):
		1:
			g.rausch = maxf(0.0, float(g.get("rausch", 0.0)) - RAUSCH_ABBAU * delta)
			if rausch_stufe(g) >= 3:
				g.mode = 8
				g.ostate = 0
				g.leiche_t = BIERLEICHE_KOTZEN
				_assigned.erase(id)
				_melde("MSG_BIERLEICHE", [], 1)
		8:
			g.tgt = g.pos
			g.leiche_t = float(g.get("leiche_t", BIERLEICHE_KOTZEN)) - delta
			if float(g.leiche_t) <= 0.0:
				g.leiche_t = BIERLEICHE_KOTZEN
				_net_guest_vomit.rpc(id)
				_spawn_mess_at(g.pos as Vector3, 0)
				_popularity = maxf(POP_MIN, _popularity - BIERLEICHE_POP)
				_stats.gekotzt = int(_stats.get("gekotzt", 0)) + 1
		9:
			var pl = _players_nodes.get(int(g.get("folgt", 0)))
			if pl == null or not is_instance_valid(pl):
				g.mode = 2
				g.tgt = ENTRANCE
				return false
			var pp: Vector3 = (pl as Node3D).global_position
			var hinter: Vector3 = pp + (pl as Node3D).global_transform.basis.z * 1.1
			g.tgt = Vector3(hinter.x, ebene_boden(ebene_von(pp)) + 0.1, hinter.z)
			# Zu zweit geht es schneller
			var helfer := false
			for p in _players_nodes.values():
				if p != pl and is_instance_valid(p) and ((p as Node3D).global_position - (g.pos as Vector3)).length() < 3.0:
					helfer = true
			g.tempo = 1.8 if helfer else 1.15
			var pos: Vector3 = g.pos
			if not im_zelt(pos) or (pos.z > WAND_VORN - 1.2 and absf(pos.x) < 3.2):
				var tip := HEIMBRINGEN_TRINKGELD
				_add_income(tip)
				_last_earn += tip
				_net_betrag.rpc(pos, tip, true)
				_stats.heimgebracht = int(_stats.get("heimgebracht", 0)) + 1
				_despawn_guest(id)
				return true
	return false

func _typ_umsatz(g: Dictionary) -> float:
	return 2.0 if str(g.get("typ", "")) == "vip" else 1.0

func _typ_trinkgeld(g: Dictionary) -> int:
	return int(TYP_TRINKGELD.get(str(g.get("typ", "")), 0))

func _typ_pop(g: Dictionary) -> float:
	return float(TYP_POP.get(str(g.get("typ", "")), 1.0))

## Ist heute der letzte Wiesn-Tag?
func ist_finale() -> bool:
	return Wirtschaft.saison_tag(_day) == Wirtschaft.SAISON_TAGE

## Bewertung 1–5 Maßkrüge aus Gewinn, Beliebtheit und verpassten Bestellungen.
func saison_wertung(s: Dictionary) -> int:
	var tage := maxi(1, int(s.get("tage", 1)))
	var punkte := 0
	var netto_tag := float(s.get("netto", 0)) / float(tage)
	if netto_tag >= 800.0:
		punkte += 2
	elif netto_tag >= 300.0:
		punkte += 1
	var pop := float(s.get("pop_summe", 0)) / float(tage)
	if pop >= 80.0:
		punkte += 2
	elif pop >= 50.0:
		punkte += 1
	var alle := int(s.get("bedient", 0)) + int(s.get("verpasst", 0))
	if alle > 0 and float(s.get("verpasst", 0)) / float(alle) <= 0.1:
		punkte += 1
	return clampi(punkte, 1, 5)

## Finale vorbei: Bewertung zeigen, nächste Wiesn beginnt.
func _saison_abschluss() -> void:
	var wertung := saison_wertung(_saison)
	var tage := maxi(1, int(_saison.tage))
	net_popup.rpc("POPUP_SAISON", [_saison_nr, _eur(int(_saison.umsatz)), _eur(int(_saison.netto)),
		int(_saison.bedient), roundi(float(_saison.pop_summe) / float(tage)),
		"★".repeat(wertung) + "☆".repeat(5 - wertung)])
	_stats.saisons = int(_stats.get("saisons", 0)) + 1
	_stats.beste_wertung = maxi(int(_stats.get("beste_wertung", 0)), wertung)
	_saison_nr += 1
	_saison = {"umsatz": 0, "netto": 0, "bedient": 0, "verpasst": 0, "pop_summe": 0, "tage": 0}

## Morgens: vielleicht ein Tagesereignis ankündigen. erzwingen = Ereignis-ID (Tests).
func _ereignis_waehlen(erzwingen := "") -> void:
	_ereignis = ""
	_ereignis_erledigt = false
	_prosit_timer = PROSIT_ALLE
	_fass_kaputt = 0
	# Letzter Wiesn-Tag: immer Finale mit Star-Act gratis
	if erzwingen == "" and ist_finale():
		_ereignis = "finale"
		_artist_tier = 3
		_melde("EREIGNIS_FINALE_START", [], 2)
		return
	# Laut Kalender (Plan für die Saison)
	var geplant := plan_fuer(_day) if erzwingen == "" else erzwingen
	if geplant == "" or (geplant == "fass" and _drinks_avail().size() < 2):
		return
	_ereignis = geplant
	if _ereignis == "fass":
		var sorten := _drinks_avail()
		sorten.erase(1)   # Helles bleibt immer
		_fass_kaputt = int(sorten.pick_random()) if not sorten.is_empty() else 0
	_melde("EREIGNIS_%s_START" % _ereignis.to_upper(), [], 2)
	_stats.ereignisse = int(_stats.get("ereignisse", 0)) + 1
	if _ereignis == "regen":
		_regen_voll = randf() < REGEN_VOLL_CHANCE
		if _regen_voll:
			_melde("MSG_REGEN_VOLL", [], 2)

func _happy_hour() -> bool:
	var uhr := _clock_hour()
	return _ereignis == "happy" and uhr >= HAPPY_VON and uhr < HAPPY_BIS

func _ereignis_andrang() -> float:
	match _ereignis:
		"anstich", "tracht": return 1.3
		"familie": return 1.1
		"italiener": return 1.35
	if _ereignis == "bus":
		return 1.5
	if _ereignis == "finale":
		return FINALE_ANDRANG
	if _ereignis == "regen":
		return 1.4 if _regen_voll else 0.8
	if _happy_hour():
		return 1.4
	return 1.0

func _update_ereignis(delta: float) -> void:
	match _ereignis:
		"kontrolle":
			if not _ereignis_erledigt and _clock_hour() >= KONTROLLE_UM:
				_ereignis_erledigt = true
				if _hygiene < KONTROLLE_GRENZE:
					Game.add_money(-KONTROLLE_STRAFE)
					_popularity = maxf(POP_MIN, _popularity - 5.0)
					_melde("MSG_KONTROLLE_STRAFE", [_eur(KONTROLLE_STRAFE)], 1)
				else:
					_popularity = minf(100.0, _popularity + KONTROLLE_BONUS)
					_melde("MSG_KONTROLLE_OK", [int(KONTROLLE_BONUS)], 2)
		"prosit":
			if _clock_hour() < GUEST_START_HOUR:
				return
			_prosit_timer -= delta
			if _prosit_timer <= 0.0:
				_prosit_timer = PROSIT_ALLE
				# „Ein Prosit": alle am Platz wollen gleich nachbestellen
				for id in _guest_sim.keys():
					var g: Dictionary = _guest_sim[id]
					if int(g.mode) == 1 and int(g.ostate) == 0:
						g.cooldown = randf_range(0.0, 2.0)
						_guest_sim[id] = g
				_melde("MSG_PROSIT", [], 2)

## Feierabend bei allen: großer Text oben, die Musik blendet aus (net_meta).
@rpc("authority", "reliable", "call_local")
func _net_feierabend() -> void:
	if _hud:
		_hud.grosser_text("MSG_FEIERABEND_GROSS")

## Regen sichtbar machen (auf allen Rechnern, aus dem Tagesereignis)
func _regen_anzeigen() -> void:
	var r := get_node_or_null("Regen")
	if r and r.has_method("setze"):
		r.setze(_ereignis == "regen")
	_apply_crowd(_clock_hour())
	_night_t = -1.0   # Licht und Himmel neu setzen
	_apply_daylight(_clock_hour())

const PING_SZENE := preload("res://scenes/ui/ping_marker.tscn")

## Ping (Spaß-Plan 5.3): Spieler markiert etwas, alle sehen es 5 Sekunden.
@rpc("any_peer", "reliable", "call_local")
func net_ping(ziel: Vector3, art: int) -> void:
	if not multiplayer.is_server():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	_net_ping.rpc(ziel, clampi(art, 0, 3), int(_spawn_index_by_peer.get(s, 0)))

@rpc("authority", "reliable", "call_local")
func _net_ping(ziel: Vector3, art: int, farbe: int) -> void:
	var m := PING_SZENE.instantiate()
	add_child(m)
	m.global_position = ziel
	m.zeige(art, farbe)
	if _sfx_node:
		_sfx_node.play_oder("ping", "ding", -10.0)

@rpc("authority", "reliable", "call_local")
func _net_kombo(n: int) -> void:
	if _hud:
		_hud.zeige_kombo(n)

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
	# Welche Plätze je Tisch schon belegt sind — am Platz selbst, nicht an der
	# Anzahl: sonst bekommt nach einem Wechsel der Nächste denselben Platz.
	var belegt_je_tisch := {}
	for g: Dictionary in _guest_sim.values():
		if int(g.mode) == 5 and int(g.seat) < _seats.size():
			var t := int(_seats[int(g.seat)].table)
			if not belegt_je_tisch.has(t):
				belegt_je_tisch[t] = {}
			belegt_je_tisch[t][int(g.get("tanz_platz", -1))] = true
	for id in _guest_sim.keys():
		var g: Dictionary = _guest_sim[id]
		if int(g.mode) != 1 or int(g.ostate) != 0 or int(g.get("drinks", 0)) < 1:
			continue
		var seat: Dictionary = _seats[int(g.seat)]
		var ti := int(seat.table)
		var belegt: Dictionary = belegt_je_tisch.get(ti, {})
		if belegt.size() >= tanz_max(ti) or randf() > 0.35 or ti >= _beertables.size():
			continue
		var platz := -1
		for i in mini(tanz_max(ti), TANZ_PLAETZE.size()):
			if not belegt.has(i):
				platz = i
				break
		if platz < 0:
			continue
		var bt := _beertables[ti] as Node3D
		var versatz: Vector2 = TANZ_PLAETZE[platz]
		var ziel: Vector3 = bt.global_position + bt.global_transform.basis.x * versatz.x 			+ bt.global_transform.basis.z * versatz.y
		g.mode = 5
		g.tanz_platz = platz
		g.tanz_t = randf_range(TANZ_DAUER_MIN, TANZ_DAUER_MAX)
		_stats.tanzen = int(_stats.get("tanzen", 0)) + 1
		g.tgt = Vector3(ziel.x, bt.global_position.y + 0.1, ziel.z)
		_guest_sim[id] = g
		belegt[platz] = true
		belegt_je_tisch[ti] = belegt
	# Vor der Bühne: auf den freien Plätzen (kein Tisch im Weg) am Boden tanzen
	var plaetze := buehnen_tanzplaetze()
	var vergeben := {}
	for g: Dictionary in _guest_sim.values():
		if int(g.mode) == 6:
			vergeben[int(g.get("bplatz", -1))] = true
	for id in _guest_sim.keys():
		if vergeben.size() >= plaetze.size():
			break
		var g: Dictionary = _guest_sim[id]
		if int(g.mode) != 1 or int(g.ostate) != 0 or int(g.get("drinks", 0)) < 1 or randf() > 0.25:
			continue
		for i in plaetze.size():
			if not vergeben.has(i):
				vergeben[i] = true
				g.mode = 6
				g.bplatz = i
				g.tanz_t = randf_range(TANZ_DAUER_MIN, TANZ_DAUER_MAX)
				g.tgt = plaetze[i]
				_stats.tanzen = int(_stats.get("tanzen", 0)) + 1
				_guest_sim[id] = g
				break

## Tanzplätze vor der Bühne (zwei Reihen), ohne die, an denen ein Tisch steht.
func buehnen_tanzplaetze() -> Array:
	var stages := get_tree().get_nodes_in_group("stage")
	if stages.is_empty():
		return []
	var b := stages[0] as Node3D
	var mitte := b.global_position
	var vorn := b.global_transform.basis.z.normalized()
	# Vorderseite = zur Zeltmitte hin
	if vorn.dot(Vector3(-mitte.x, 0.0, -mitte.z)) < 0.0:
		vorn = -vorn
	var seite := b.global_transform.basis.x.normalized()
	var out := []
	# Versetzt statt in Reih und Glied: jede Reihe ist um eine halbe Lücke
	# verschoben, dazu ein fester kleiner Versatz je Platz. Fest gerechnet und
	# nicht gewürfelt, damit ein Platz beim nächsten Durchlauf derselbe bleibt.
	var reihen := [2.7, 3.6, 4.6]
	for r in reihen.size():
		var reihe: float = reihen[r]
		var schritt := 1.5
		var versatz := schritt * 0.5 if r % 2 == 1 else 0.0
		for i in 5:
			var k := (float(i) - 2.0) * schritt + versatz
			# Kleiner fester Zickzack, damit keine Linie entsteht
			var tiefe := reihe + (0.35 if (i + r) % 2 == 0 else -0.25)
			var p: Vector3 = mitte + vorn * tiefe + seite * k
			var frei := true
			for bt in _beertables:
				var d: Vector3 = (bt as Node3D).global_position - p
				d.y = 0.0
				if d.length() < 1.9:
					frei = false
					break
			if frei:
				out.append(Vector3(p.x, 0.1, p.z))
	return out

## Blickrichtung beim Tanzen vor der Bühne. Die meisten schauen zur Bühne, jeder
## dritte dreht sich zu seinem Nachbarn — sonst steht dort eine Reihe gleich
## ausgerichteter Figuren.
func _tanz_blick(g: Dictionary) -> float:
	var platz := int(g.get("bplatz", 0))
	var ziel := Vector3.ZERO
	if platz % 3 == 1:
		for anderer: Dictionary in _guest_sim.values():
			if int(anderer.get("mode", 0)) == 6 and int(anderer.get("bplatz", -1)) == platz - 1:
				ziel = anderer.pos
				break
	if ziel == Vector3.ZERO:
		var stages := get_tree().get_nodes_in_group("stage")
		if stages.is_empty():
			return float(g.yaw)
		ziel = (stages[0] as Node3D).global_position
	var zum: Vector3 = ziel - (g.pos as Vector3)
	zum.y = 0.0
	if zum.length() < 0.2:
		return float(g.yaw)
	return atan2(-zum.x, -zum.z)

## Blickrichtung beim Tanzen auf dem Tisch: zum Gegenüber, sonst zum anderen
## Tänzer auf dem Tisch, sonst in den Zeltraum hinaus.
func _tanz_blick_tisch(g: Dictionary) -> float:
	var platz := int(g.get("tanz_platz", -1))
	if platz < 0 or int(g.seat) >= _seats.size():
		return float(g.yaw)
	var ti := int(_seats[int(g.seat)].table)
	var partner: int = TANZ_PARTNER[platz] if platz < TANZ_PARTNER.size() else -1
	var ziel := Vector3.ZERO
	var ersatz := Vector3.ZERO
	for anderer: Dictionary in _guest_sim.values():
		if int(anderer.get("mode", 0)) != 5 or int(anderer.get("tanz_platz", -1)) == platz:
			continue
		if int(anderer.get("seat", -1)) >= _seats.size() or int(_seats[int(anderer.seat)].table) != ti:
			continue
		if int(anderer.get("tanz_platz", -1)) == partner:
			ziel = anderer.pos
			break
		ersatz = anderer.pos
	if ziel == Vector3.ZERO:
		ziel = ersatz
	if ziel == Vector3.ZERO:
		# Allein auf dem Tisch: zur Zeltmitte schauen, nicht in die Wand
		ziel = Vector3(0.0, float((g.pos as Vector3).y), 0.0)
	var zum: Vector3 = ziel - (g.pos as Vector3)
	zum.y = 0.0
	if zum.length() < 0.2:
		return float(g.yaw)
	return atan2(-zum.x, -zum.z)

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
	_kombo.clear()
	_ereignis_waehlen()
	_schlaegerei_planen()
	# Ausgabe bleibt: vor der Schicht vorgezapfte Krüge verschwinden nicht mehr
	_ausgabe_senden()
	_last_earn = 0
	_guest_spawn_timer = randf_range(ERSTE_GAESTE_MIN, ERSTE_GAESTE_MAX)
	_hygiene = 100.0
	_night = false
	_nachts_geschlossen = false
	_apply_night_visual(false)
	_did_shift = true
	for s in _held_deko.keys():
		_deko_abstellen(s)
	_held.clear()
	_held_lager.clear()
	_rebuild_seats()   # taşınmış masalara göre koltukları güncelle
	_clear_messes()
	_shift_num += 1
	_bank_mahnen()
	_muell_stapel = 0   # Müllabfuhr war da
	_personal_morgen()
	_tag_leistung.clear()
	_stamm_heute = ""
	_huber_morgen()
	_tagesziel_waehlen()
	_npc_roles = {}          # E3: Aushilfs-NPCs entfallen — echtes Personal übernimmt
	_assigned.clear()
	_net_band_zurueck.rpc()   # neue Schicht: Band wieder da, Musik wieder an
	_spawn_artists()          # E5: gebuchter Künstler betritt die Bühne
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		st.state = 0
		st.orders = []
		st.idx = 0
		st.timer = 0.0
		_staff_sim[sid] = st
	# Kirmes offen, Zelt noch zu — ein Spieler eröffnet es am Eingang (net_zelt_eroeffnen)
	_zelt_offen = _tent_stage == 0
	_zelt_wartet = 0.0
	_broadcast_meta()   # banner'ı net_sleep gönderir (gün başlangıcı mesajı)
	_eroeffnung_anzeigen()
	if not _zelt_offen:
		_melde("MSG_ZELT_WARTET")

## Günü bitir. reason: 0 = 22:00 normal, 1 = çok şikayet, 2 = oyuncu erken kapattı.
func _end_shift(reason := 0) -> void:
	if schlaegerei_laeuft():
		_schlaegerei_beenden()
	for streit: Dictionary in _einzelstreits.duplicate():
		_einzelstreit_beenden(streit)
	_einzel_uhren = []
	_schlaegerei_uhr = -1.0
	# Nur einmal pro Tag: mehrere verpasste Bestellungen im selben Moment riefen
	# das doppelt auf — Tag +2, Miete und Löhne doppelt (Spielbot, 30 Tage).
	if _phase != Phase.SHIFT:
		return
	var closed_at: float = _clock_hour()          # faz değişmeden önce oku
	var hours_left: float = maxf(0.0, DAY_END_HOUR - closed_at)
	_phase = Phase.INTERMISSION
	_phase_time = 0.0
	_night = false
	_nachts_geschlossen = true
	_apply_night_visual(false)
	# Gäste stehen nicht alle auf einmal auf: erst Musik aus und großer Text,
	# dann brechen sie nach und nach auf (aufbruch_t in _update_guests)
	for gid in _guest_sim.keys():
		_guest_sim[gid].aufbruch_t = randf_range(4.0, 14.0)
		_guest_sim[gid].ostate = 0
	_net_feierabend.rpc()
	# Dreck bleibt nach Feierabend liegen — putzen geht jetzt auch außerhalb der
	# Schicht; was bis zum nächsten Schichtstart übrig ist, räumt _start_shift weg
	_clear_artists()          # E5: Auftritt vorbei
	# Übriges bleibt auf der Ausgabe stehen — auch außerhalb der Schicht abgestellte
	# Krüge verschwinden nicht mehr (Test 13.09.)
	_ereignis = ""
	_fass_kaputt = 0
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
	_eigenschaften_nacht()
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
		"gekocht": _essen_gekocht, "rausgeworfen": _rausgeworfen,
		"loan": _kredit_heute,
		"ehren": _auszeichnungen(),
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
	# Wiesn-Zahlen sammeln, am Finale bewerten
	_saison.umsatz = int(_saison.umsatz) + _last_earn
	_saison.netto = int(_saison.netto) + net_profit
	_saison.bedient = int(_saison.bedient) + _served
	_saison.verpasst = int(_saison.verpasst) + _missed
	_saison.pop_summe = int(_saison.pop_summe) + roundi(_popularity)
	_saison.tage = int(_saison.tage) + 1
	# Tag ohne eine einzige Pfütze (und mit Betrieb) — Meilenstein SAUBER_5
	if _urin_count == 0 and _served >= 10:
		_stats.tage_sauber = int(_stats.get("tage_sauber", 0)) + 1
	if ist_finale():
		_saison_abschluss()
	_clean_tips = 0
	_interest_paid = 0
	_kredit_heute = 0
	_goods_cost = 0
	_urin_count = 0
	_essen_gekocht = 0
	_rausgeworfen = 0
	_complaints = 0
	_left_guests = 0
	_tagesziel_auswerten()
	_huber_abrechnen()
	if not _saboteur.is_empty():
		_saboteur = {}
		_net_saboteur_weg.rpc()
	for e: Array in _auszeichnungen():
		_melde("MSG_EHRE_" + str(e[0]).to_upper(), [str(e[1]), int(e[2])], 2)
	_bank_abbuchen()
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
	weg.append(_platz_pos_fuer(id, si))
	var start: Vector3 = HAUPTTOR + Vector3(randf_range(-1.5, 1.5), 0.0, randf_range(0.0, 1.5))
	var typ := _gast_typ_waehlen()
	if typ == "vip" and _popularity < VIP_AB_BELIEBTHEIT:
		typ = ""   # VIPs kommen erst in ein beliebtes Zelt
	_guest_sim[id] = {
		"seat": si, "mode": 0, "pos": start, "tgt": weg.pop_front(), "weg": weg, "yaw": 0.0, "typ": typ,
		"ostate": 0, "okind": 1, "otype": 1, "patience": _geduld() * float(TYP_GEDULD.get(typ, 1.0)),
		"cooldown": randf_range(8.0, 20.0), "served_t": 0.0,
		"bladder": randf_range(BLADDER_MIN, BLADDER_MAX), "pee_t": 0.0,
		"drinks": 0, "puke_t": 0.0, "puked": false
	}
	# Benannter Stammgast (Opa Alois, Vroni …) — einer pro Tag, nach dem Tutorial
	var stamm := _stammgast_waehlen()
	if stamm != "":
		_guest_sim[id].typ = "stamm"
		_guest_sim[id].stamm = stamm
		_guest_sim[id].patience = _geduld() * float(TYP_GEDULD.stamm)
		_add_guest.rpc(id, start, "stamm|" + stamm)
		_melde("MSG_STAMM_" + stamm.to_upper() + "_DA", [], 0)
		return
	_add_guest.rpc(id, start, typ)

func _update_guests(delta: float) -> void:
	for id in _guest_sim.keys().duplicate():
		var g: Dictionary = _guest_sim[id]
		if _phase == Phase.SHIFT and _rausch_aktualisieren(g, id, delta):
			continue   # heimgebracht
		var pos: Vector3 = g.pos
		# Zwischenziele über die Treppe, wenn das Ziel auf der anderen Ebene liegt
		var wp := _wegpunkt(g, 0.2)
		var am_ziel := _nur_noch_ziel(g)
		var to: Vector3 = wp - pos
		to.y = 0
		var d := to.length()
		if d > 0.15 or not am_ziel:
			if d > 0.0001:
				var schritt := minf(CUST_SPEED * float(g.get("tempo", 1.0)) * delta, d)
				pos.y += (wp.y - pos.y) * (schritt / d)   # Treppe: Höhe anteilig
				pos += to / d * schritt
				g.yaw = atan2(-to.x, -to.z)
		else:
			pos.y = wp.y
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
		# Oturan misafir: sipariş döngüsü. Wer vor der Bühne tanzt, bestellt auch —
		# der hat den größten Durst. Kellner und Spieler bedienen ihn genauso, die
		# schauen nur auf ostate.
		if (g.mode == 1 or (g.mode == 6 and bool(g.get("tanz_da", false)))) and _phase == Phase.SHIFT:
			_guest_order(g, id, delta)
		# Feierabend: nach kurzer Wartezeit aufstehen und zum Ausgang gehen
		if g.has("aufbruch_t"):
			g.aufbruch_t = float(g.aufbruch_t) - delta
			if float(g.aufbruch_t) <= 0.0 and int(g.mode) != 2:
				g.erase("aufbruch_t")
				# Beim Aufbruch bleibt oft noch etwas am Platz liegen
				if randf() < GAST_MUELL_BEIM_GEHEN:
					_gast_muell(g)
				g.mode = 2
				g.tgt = ENTRANCE
				g.ostate = 0
		if float(g.get("verpasst_t", 0.0)) > 0.0:
			g.verpasst_t = float(g.verpasst_t) - delta
		# Tanzt auf dem Tisch oder vor der Bühne — erst am Ziel, danach zurück auf den Platz
		var tanzte := bool(g.get("tanz_da", false))
		g.tanz_da = (g.mode == 5 or g.mode == 6) and d <= 0.3 and am_ziel
		# Vor der Bühne beim Ankommen ausrichten: die meisten schauen zur Bühne,
		# jeder dritte zu seinem Nachbarn. Einmal beim Ankommen, nicht jedes Bild.
		if g.mode == 6 and bool(g.tanz_da) and not tanzte:
			g.yaw = _tanz_blick(g)
		# Auf dem Tisch: zum Gegenüber drehen. Nicht nur beim Ankommen, weil der
		# Partner oft erst später hochsteigt — dann dreht sich der Erste nach.
		if g.mode == 5 and bool(g.tanz_da):
			g.yaw = lerp_angle(float(g.yaw), _tanz_blick_tisch(g), clampf(delta * 3.0, 0.0, 1.0))
		if g.mode == 5 or g.mode == 6:
			g.tanz_t = float(g.get("tanz_t", 0.0)) - delta
			if float(g.tanz_t) <= 0.0:
				g.mode = 0
				g.tanz_platz = -1   # Platz auf dem Tisch wird frei
				g.weg = []
				g.tgt = _platz_pos_fuer(id, int(g.seat))
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
			node.set_order(g.ostate, g.okind, g.otype, clampf(g.patience / _geduld_max(g), 0.0, 1.0))
			# Host/Solo bekommen _net_guests nicht (kein call_local) — direkt setzen
			node.set_tanz(bool(g.tanz_da), int(g.mode) == 6)
			node.set_laune(_laune(g))
			node.set_rausch(rausch_stufe(g))

func _guest_order(g: Dictionary, id: int, delta: float) -> void:
	if g.ostate == 0:
		g.cooldown -= delta
		if g.cooldown <= 0.0:
			g.ostate = 1
			var foods: Array = _foods_avail()
			var typ := str(g.get("typ", ""))
			# Ohne Essenslizenz nur Getränke; Touristen essen gern, Trachtler trinken nur Helles
			var essen_chance := 0.7 if typ == "tourist" else 0.4
			if _ereignis == "familie":
				essen_chance = 0.75   # Familientag: mehr Essen, weniger Bier
			if foods.is_empty() or randf() >= essen_chance:
				g.okind = 1
				g.otype = 1 if typ == "tracht" else _drinks_avail().pick_random()
			else:
				g.okind = 2
				g.otype = foods.pick_random()
			_stamm_wunsch(g)
			g.patience = _geduld_max(g)
	elif g.ostate == 1:
		g.patience -= delta * (PATIENCE_NIGHT_MULT if _night else 1.0)
		if g.patience <= 0.0:
			g.ostate = 0
			g.cooldown = randf_range(ORDER_COOLDOWN_MIN, ORDER_COOLDOWN_MAX)
			_missed += 1
			_stamm_verpasst(g)
			Game.add_score(-MISS_PENALTY)
			g.verpasst_t = 3.0   # kurz 😤 über dem Kopf
			var abzug := minf(POP_MISS * _typ_pop(g), maxf(0.0, POP_MISS_TAG_MAX - _pop_verlust_heute))
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
	# Gäste hinterlassen laufend Müll am Tisch: Servietten, Scherben, Laub von
	# draußen. Das ist der Grund, warum man während der Schicht immer wieder
	# fegen und die Säcke zur Tonne tragen muss.
	if int(g.mode) == 1 and randf() < GAST_MUELL_JE_SEK * delta:
		_gast_muell(g)
	if rausch_stufe(g) >= 2 and randf() < MESS_CHANCE_PER_SEC * delta:
		var seat: Dictionary = _seats[int(g.seat)]
		g.mode = 4
		g.ostate = 0
		g.puked = false
		g.kotzt = false
		# Verteilt rund um den Tisch statt immer an derselben Stelle (Test 13.09.)
		var weg: Vector3 = (seat.get("away", Vector3.FORWARD) as Vector3).rotated(Vector3.UP, randf_range(-1.1, 1.1))
		var ziel: Vector3 = (seat.pos as Vector3) + weg * randf_range(2.2, 4.0)
		g.tgt = _auf_ebene(ziel, ebene_von(seat.pos))

func _despawn_guest(id: int) -> void:
	if _klo_gast == id:
		_klo_setzen(-1)
	if _guest_sim.has(id):
		var si: int = _guest_sim[id].seat
		if si >= 0 and si < _seats.size():
			_seats[si].guest = -1
		_guest_sim.erase(id)
	_remove_guest.rpc(id)

@rpc("authority", "reliable", "call_local")
func _add_guest(id: int, pos: Vector3, typ: String = "") -> void:
	if _guests.has(id):
		return
	var c := CUSTOMER_SCENE.instantiate()
	c.cust_id = id
	c.typ = typ
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
	_spawn_mess_at(p + off, 0)

## kind: 0 = Erbrochenes, 1 = Urin. Auf der Empore bleibt der Fleck oben (und nicht
## über dem Treppenloch).
func _spawn_mess_at(p: Vector3, kind: int) -> void:
	var id := _mess_next
	_mess_next += 1
	_mess_clean[id] = 0.0
	_mess_kind[id] = kind
	var ebene := ebene_von(p)
	if ebene > 0:
		p.x = signf(p.x) * clampf(absf(p.x), EMPORE_KANTE + 0.3, EMPORE_LAUF_MAX)
	_add_mess.rpc(id, Vector3(p.x, ebene_boden(ebene) + 0.02, p.z), kind)

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
			if m.has_method("entfernen"):
				m.entfernen()   # Plane fällt erst zusammen
			else:
				m.queue_free()
		_messes.erase(id)
	_mess_clean.erase(id)
	_mess_kind.erase(id)

func _clear_messes() -> void:
	for mid in _messes.keys().duplicate():
		_remove_mess.rpc(mid)

@rpc("any_peer", "reliable", "call_local")
func net_clean(id: int) -> void:
	# Putzen geht auch außerhalb der Schicht (Reste vom Vortag wegmachen)
	if not multiplayer.is_server():
		return
	if not _messes.has(id):
		return
	var putzer := multiplayer.get_remote_sender_id()
	if putzer == 0:
		putzer = 1
	var putz_faktor := 1.0
	# Dreck fegen und Planen abziehen dauern ein paar Sekunden (≈ 3 s)
	if int(_mess_kind.get(id, 0)) >= Mess.DRECK:
		putz_faktor *= DRECK_TEMPO
	_mess_clean[id] = float(_mess_clean.get(id, 0.0)) + CLEAN_PER_CALL * putz_faktor
	if _mess_clean[id] >= 1.0:
		var art_dreck := int(_mess_kind.get(id, 0))
		# Trinkgeld fürs Saubermachen — nur wenn ein Spieler selbst putzt.
		# Planen abziehen ist kein Putzen: dafür gibt es nichts.
		if art_dreck < Mess.DECKE or art_dreck >= Mess.SABOTAGE:
			var tip := randi_range(CLEAN_TIP_MIN, CLEAN_TIP_MAX)
			_add_income(tip)
			_last_earn += tip
			_clean_tips += tip
			_stats.cleaned += 1
			_leistung(putzer, "geputzt")
			_net_betrag.rpc((_messes[id] as Node3D).global_position, tip, true)
		if art_dreck >= Mess.DRECK and art_dreck < Mess.DECKE:
			_muellsack_hinlegen((_messes[id] as Node3D).global_position)
		_remove_mess.rpc(id)

# ================================================= senkron
func _broadcast_sync() -> void:
	# Misafirler
	var cids := PackedInt32Array()
	var cx := PackedFloat32Array()
	var cy := PackedFloat32Array()
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
		cy.append(g.pos.y)
		cz.append(g.pos.z)
		cyaw.append(g.yaw)
		cstate.append(g.ostate)
		ckind.append(g.okind)
		ctype.append(g.otype)
		cratio.append(clampf(g.patience / _geduld_max(g), 0.0, 1.0))
		# Bit 0 tanzt (am Ziel), Bit 1–2 Laune, Bit 3 am Boden vor der Bühne
		ctanz.append((1 if bool(g.get("tanz_da", false)) else 0) | (_laune(g) << 1) | (8 if int(g.mode) == 6 else 0) | (rausch_stufe(g) << 4))
	_net_guests.rpc(cids, cx, cy, cz, cyaw, cstate, ckind, ctype, cratio, ctanz)
	# Personal
	var sids := PackedInt32Array()
	var sx := PackedFloat32Array()
	var sy := PackedFloat32Array()
	var sz := PackedFloat32Array()
	var syaw := PackedFloat32Array()
	var scarry := PackedInt32Array()
	for sid in _staff_sim.keys():
		var st: Dictionary = _staff_sim[sid]
		sids.append(sid)
		sx.append(st.pos.x)
		sy.append(st.pos.y)
		sz.append(st.pos.z)
		syaw.append(st.yaw)
		# Krüge in der Hand: nur beim Ausliefern
		var carr := 0
		if int(st.role) == ROLE_KELLNER and int(st.state) == 3:
			carr = maxi(0, (st.orders as Array).size() - int(st.idx))
		elif int(st.role) == ROLE_KOCH and int(st.state) == 1:
			carr = 1   # Koch trägt eine Portion zur Ausgabe
		scarry.append(carr)
	if sids.size() > 0:
		_net_staff.rpc(sids, sx, sy, sz, syaw, scarry)
	# Çevre
	var ids := PackedInt32Array()
	var pr := PackedFloat32Array()
	for mid in _messes.keys():
		ids.append(mid)
		pr.append(float(_mess_clean.get(mid, 0.0)))
	_net_env.rpc(Game.money, Game.score, _clock_hour(), _hygiene, _popularity, ids, pr, _night or _nachts_geschlossen)
	# Bira masası konumları (taşıma senkronu)
	var bx := PackedFloat32Array()
	var by := PackedFloat32Array()
	var bz := PackedFloat32Array()
	var brot := PackedFloat32Array()
	for bt in _beertables:
		bx.append((bt as Node3D).position.x)
		by.append((bt as Node3D).position.y)
		bz.append((bt as Node3D).position.z)
		brot.append((bt as Node3D).rotation.y)
	_net_tables.rpc(bx, by, bz, brot)
	_net_lager.rpc(_lager_lagen())
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
func _net_tables(bx: PackedFloat32Array, by: PackedFloat32Array, bz: PackedFloat32Array, brot: PackedFloat32Array) -> void:
	for i in range(_beertables.size()):
		if i < bx.size():
			(_beertables[i] as Node3D).position = Vector3(bx[i], by[i] if i < by.size() else 0.0, bz[i])
		if i < brot.size():
			(_beertables[i] as Node3D).rotation.y = brot[i]

@rpc("authority", "unreliable")
func _net_guests(cids: PackedInt32Array, cx: PackedFloat32Array, cy: PackedFloat32Array, cz: PackedFloat32Array, cyaw: PackedFloat32Array, cstate: PackedInt32Array, ckind: PackedInt32Array, ctype: PackedInt32Array, cratio: PackedFloat32Array, ctanz: PackedByteArray) -> void:
	for i in range(cids.size()):
		var c = _guests.get(cids[i])
		if c:
			c.set_net(Vector3(cx[i], cy[i] if i < cy.size() else 0.1, cz[i]), cyaw[i])
			c.set_order(cstate[i], ckind[i], ctype[i], cratio[i])
			var bits: int = ctanz[i] if i < ctanz.size() else 0
			c.set_tanz(bits & 1 == 1, bits & 8 == 8)
			c.set_laune((bits >> 1) & 3)
			c.set_rausch((bits >> 4) & 3)

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
	if not multiplayer.is_server():
		_nachts_geschlossen = night and clock < 0.0
	# Wie lange dauert es noch bis 22:00? Die Schlussnummer des Künstlers muss so
	# früh anfangen, dass sie vorher durch ist (scripts/sfx.gd restzeit).
	if _sfx_node:
		var rest: float = (DAY_END_HOUR - clock) / (DAY_END_HOUR - DAY_START_HOUR) * SHIFT_TIME
		_sfx_node.restzeit(rest if clock >= 0.0 else INF)
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
	for sid: int in _staff_sim:
		var s: Dictionary = _staff_sim[sid]
		staff.append([int(s.role), int(s.level), str(s.get("eig", "normal")), str(s.get("name", "")),
			int(s.get("seit", 1)), str(s.get("anliegen", "")), sid,
			roundi(float(_staff_wage(int(s.role), int(s.level), str(s.get("eig", "normal")))) * float(s.get("lohn", 1.0))),
			bool(s.get("unzufrieden", false)), float(s.get("energie", 1.0))])
	var haelt := {}
	for pid in _held_deko.keys():
		haelt[str(pid)] = int(_held_deko[pid])
	var haelt_tisch := {}
	for pid in _held.keys():
		haelt_tisch[str(pid)] = int(_held[pid])
	var preis := bierpreis_grenzen()
	return {
		"stage": _tent_stage, "tables": _active_count, "limit": int(TENT_TABLE_LIMIT[_tent_stage]),
		"seats": _seats.size(), "rent": _daily_rent(), "mkt": _upg_marketing, "deko": _upg_deko,
		"toilet": _has_toilet, "lic": _lic.duplicate(), "staff": staff, "artist": _artist_tier,
		"pending": _pending.size(), "bier": int(_stock[WARE_BIER]), "essen": int(_stock[WARE_ESSEN]),
		"haelt": haelt, "bierpreis": _bierpreis, "einrichtung": _einrichtung.size(),
		"deko_wert": deko_wert(), "gemuet": gemuetlichkeit(),
		"haelt_tisch": haelt_tisch, "preis_min": preis.x, "preis_max": preis.y,
		"essenpreis": _essenpreis, "essen_min": essenpreis_grenzen().x, "essen_max": essenpreis_grenzen().y,
		"zelt_offen": _zelt_offen,
		"haelt_lager": _haelt_lager_stand(), "regale": _lagerregale().size(),
		"ereignis": _ereignis, "saison_nr": _saison_nr,
		"shift": _phase == Phase.SHIFT,
		"stats": _stats.duplicate(), "ms": _meilensteine.duplicate(), "day": _day,
		"kredit": _kredit_rest,
		"bank_naechste": bank_naechste(), "bank_rest": bank_rest(),
		"muell": _muell_stapel,
		"huber_wette": _huber_wette,
		"duell_offen": duell_moeglich(),
		"plan": _kalender_plan(),
		"duell_gewonnen": _duell_saison == _saison_nr,
		"tagesziel": _tagesziel,
		"zelt_name": _zelt_name,
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
	if not multiplayer.is_server():
		_has_toilet = bool(buero.get("toilet", false))
		_zelt_name = str(buero.get("zelt_name", ""))
	_klo_anzeigen()
	_zeltname_anzeigen()
	_quest_step = quest_step   # auch bei Clients — der Zielmarker braucht ihn
	_theke_anzeigen(buero.get("lic", {}))
	_muellplatz_zeigen(int(buero.get("muell", 0)))
	_haelt_deko = buero.get("haelt", {})
	_haelt_tisch = buero.get("haelt_tisch", {})
	_haelt_lager = buero.get("haelt_lager", {})
	if not multiplayer.is_server():
		_zelt_offen = bool(buero.get("zelt_offen", true))
	_eroeffnung_anzeigen()
	var ereignis_neu := str(buero.get("ereignis", ""))
	if ereignis_neu != _ereignis or multiplayer.is_server():
		if not multiplayer.is_server():
			_ereignis = ereignis_neu
		_regen_anzeigen()
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
		if phase == Phase.SHIFT and not _band_weg:
			_sfx_node.play_music()
		else:
			_sfx_node.musik_ausblenden(5.0)   # Feierabend: sanft leiser statt abrupt aus

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
const LIC_KEYS := {"weizen": "LIC_WEIZEN", "radler": "LIC_RADLER", "brezn": "LIC_BREZN", "sosis": "LIC_SOSIS",
	"festbier": "LIC_FESTBIER", "hendl": "LIC_HENDL"}
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
		g.rausch = maxf(0.0, float(g.get("rausch", 0.0)) - RAUSCH_NACH_KOTZEN)
		_stats.gekotzt = int(_stats.get("gekotzt", 0)) + 1
		_spawn_mess_at(g.pos as Vector3, 0)
	if float(g.puke_t) <= 0.0:
		g.mode = 1
		g.kotzt = false
		g.tgt = _platz_pos_fuer(id, int(g.seat))

## Kurze Schwarzblende beim Schlafen (bei allen Spielern).
@rpc("authority", "reliable", "call_local")
func net_sleep_fade(tag: int = 0) -> void:
	if _hud and _hud.has_method("play_sleep_fade"):
		_hud.play_sleep_fade(tag)

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
	_melde("MSG_PLEITE_HUBER", [], 1)
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

# ================================================= Einleitung (Story)
## Einleitung (Brief von Onkel Sepp) bei allen starten. mehrere: Koop — Anrede „ihr".
@rpc("authority", "reliable", "call_local")
func net_kino_start(mehrere: bool) -> void:
	var kino := get_node_or_null("Kino")
	if kino and kino.has_method("starten"):
		kino.starten(mehrere)

## Wiesnchef im Büro: Ein Spieler hat „Ja, ich übernehm das Zelt" gesagt —
## Schritt 0 ist erledigt, der Rundgang schickt ihn zum Zelt (bei allen).
@rpc("any_peer", "reliable", "call_local")
func net_chef_zusage() -> void:
	if not multiplayer.is_server() or _folge_geschafft:
		return
	_folge_geschafft = true
	_broadcast_meta()

# ================================================= Tagesziele + Sepps Schulden
## Wie viele Bankraten (Wirtschaft.BANK_RATEN) schon bezahlt sind
var _bank_bezahlt := 0
## Heutiges Ziel: {typ, ziel, lohn}; leer = keins (Tutorial läuft noch)
var _tagesziel := {}
var _ziel_gesendet := -1
var _ziel_takt := 0.0

## Nächste offene Rate [Tag, Betrag] oder []
## Betrag einer Rate nach Schwierigkeit, auf 100 € gerundet
func _bank_betrag(i: int) -> int:
	return roundi(float(Wirtschaft.BANK_RATEN[i][1]) * float(Wirtschaft.BANK_FAKTOR[_schwierigkeit]) / 100.0) * 100

func bank_naechste() -> Array:
	if _bank_bezahlt >= Wirtschaft.BANK_RATEN.size():
		return []
	return [int(Wirtschaft.BANK_RATEN[_bank_bezahlt][0]), _bank_betrag(_bank_bezahlt)]

func bank_rest() -> int:
	var r := 0
	for i in range(_bank_bezahlt, Wirtschaft.BANK_RATEN.size()):
		r += _bank_betrag(i)
	return r

## Morgens bei Schichtbeginn ein Ziel auslosen (erst nach dem Tutorial)
func _tagesziel_waehlen() -> void:
	_tagesziel = {}
	if tutorial_active():
		return
	var d := _day
	var arten := [
		{"typ": "bedienen", "ziel": 15 + 7 * d},
		{"typ": "umsatz", "ziel": (500 + 180 * d) / 50 * 50},
		{"typ": "sauber", "ziel": 0},
		{"typ": "verpasst", "ziel": 3},
		{"typ": "beschwerden", "ziel": 0},
	]
	_tagesziel = arten.pick_random()
	_tagesziel["lohn"] = Wirtschaft.ZIEL_LOHN_BASIS + Wirtschaft.ZIEL_LOHN_JE_TAG * d
	_ziel_gesendet = -1
	net_ziel_neu.rpc(_tagesziel)

## Aktueller Stand des Ziels (Zähler, den die Anzeige zeigt)
func _ziel_stand() -> int:
	match str(_tagesziel.get("typ", "")):
		"bedienen": return _served
		"umsatz": return _last_earn
		"sauber": return _urin_count
		"verpasst": return _missed
		"beschwerden": return _complaints
	return 0

func _ziel_erreicht() -> bool:
	var s := _ziel_stand()
	var z := int(_tagesziel.get("ziel", 0))
	match str(_tagesziel.get("typ", "")):
		"bedienen", "umsatz": return s >= z
		# „nicht mehr als": nur wenn auch wirklich Betrieb war
		"sauber", "verpasst", "beschwerden": return s <= z and _served >= 10
	return false

## Abends: Belohnung auszahlen
func _tagesziel_auswerten() -> void:
	if _tagesziel.is_empty():
		return
	if _ziel_erreicht():
		var lohn := int(_tagesziel.get("lohn", 0))
		Game.add_money(lohn)
		_popularity = minf(100.0, _popularity + Wirtschaft.ZIEL_BELIEBTHEIT)
		_melde("MSG_ZIEL_GESCHAFFT", [_eur(lohn)], 2)
	else:
		_melde("MSG_ZIEL_VERFEHLT", [], 1)
	_tagesziel = {}

## Abends nach Miete und Löhnen: fällige Rate abbuchen
func _bank_abbuchen() -> void:
	var r := bank_naechste()
	if r.is_empty() or _day < int(r[0]) or _saison_nr > 1:
		return
	Game.add_money(-int(r[1]))
	_bank_bezahlt += 1
	if _bank_bezahlt >= Wirtschaft.BANK_RATEN.size():
		net_popup.rpc("POPUP_BANK_FREI", [_eur(int(r[1]))])
	else:
		_melde("MSG_BANK_BEZAHLT", [_eur(int(r[1])), _eur(bank_rest())], 0)

## Neuer Tag: an eine Rate heute oder morgen erinnern
func _bank_mahnen() -> void:
	var r := bank_naechste()
	if r.is_empty() or _saison_nr > 1:
		return
	var tage := int(r[0]) - _day
	if tage == 0:
		net_popup.rpc("POPUP_BANK_HEUTE", [_eur(int(r[1])), _eur(bank_rest())])
	elif tage == 1:
		_melde("MSG_BANK_MORGEN", [_eur(int(r[1]))], 1)

## Stand an alle, sobald er sich ändert (höchstens zweimal pro Sekunde)
func _ziel_senden(delta: float) -> void:
	_ziel_takt -= delta
	if _ziel_takt > 0.0:
		return
	_ziel_takt = 0.5
	var s := _ziel_stand() if not _tagesziel.is_empty() else -1
	if s != _ziel_gesendet:
		_ziel_gesendet = s
		net_ziel_stand.rpc(s)

@rpc("authority", "unreliable_ordered", "call_local")
func net_ziel_stand(stand: int) -> void:
	if _hud and _hud.has_method("set_ziel_stand"):
		_hud.set_ziel_stand(stand)

## Was der Wiesnchef nach dem Tutorial erzählt: heutiges Ziel und die Schulden.
## Fertig übersetzte Zeilen; mehrere = Anrede „ihr".
func chef_tageszeilen(mehrere: bool, z: Dictionary) -> Array[String]:
	var a := "_IHR" if mehrere else "_DU"
	var zeilen: Array[String] = []
	var ziel: Dictionary = z.get("tagesziel", {})
	if ziel.is_empty():
		zeilen.append(tr("CHEF_ZIEL_KEINS" + a))
	else:
		zeilen.append(tr("CHEF_ZIEL" + a) % [Texte.tagesziel_text(ziel), Texte.euro(int(ziel.get("lohn", 0)))])
	var r: Array = z.get("bank_naechste", [])
	if r.is_empty():
		zeilen.append(tr("CHEF_BANK_FREI" + a))
	else:
		zeilen.append(tr("CHEF_BANK" + a) % [Texte.euro(int(r[1])), int(r[0]), Texte.euro(int(z.get("bank_rest", 0)))])
	if int(z.get("kredit", 0)) > 0:
		zeilen.append(tr("CHEF_KREDIT" + a) % Texte.euro(int(z.get("kredit", 0))))
	return zeilen

## Neues Tagesziel: Meldung bei allen (Text in der eigenen Sprache)
@rpc("authority", "reliable", "call_local")
func net_ziel_neu(ziel: Dictionary) -> void:
	if _hud:
		_hud.melde_text(tr("MSG_ZIEL_NEU") % Texte.tagesziel_text(ziel), 0)

# ================================================= Theke nach Lizenzen
## Fässer, Essensstationen und Ausgabeplätze erscheinen erst mit der Lizenz.
## Am Anfang: Helles neben den leeren Krügen (und Wasser für Betrunkene).
## Läuft bei allen (net_meta), Lizenzen aus dem Büro-Zustand.
const LIZENZ_FUER_BIER := {2: "weizen", 3: "radler", 4: "festbier"}
const LIZENZ_FUER_ESSEN := {1: "brezn", 2: "sosis", 3: "hendl"}

func _theke_anzeigen(lic: Dictionary) -> void:
	var stationen := get_node_or_null("Stations")
	if stationen:
		for s in stationen.get_children():
			var frei := true
			if s is KegStation and LIZENZ_FUER_BIER.has(int(s.beer_type)):
				frei = bool(lic.get(LIZENZ_FUER_BIER[int(s.beer_type)], false))
			elif "food_type" in s:
				frei = bool(lic.get(LIZENZ_FUER_ESSEN.get(int(s.food_type), ""), false))
			(s as Node3D).visible = frei
	for a in get_tree().get_nodes_in_group("ausgabe"):
		var plaetze := a.get_node_or_null("Plaetze")
		if plaetze == null:
			continue
		for p in plaetze.get_children():
			var art := int(p.get_meta("art", 1))
			var typ := int(p.get_meta("typ", 1))
			var frei := true
			if art == 1 and LIZENZ_FUER_BIER.has(typ):
				frei = bool(lic.get(LIZENZ_FUER_BIER[typ], false))
			elif art != 1:
				frei = bool(lic.get(LIZENZ_FUER_ESSEN.get(typ, ""), false))
			(p as Node3D).visible = frei

## Wo ein Kellner steht, wenn er selbst zapft: hinter dem Fass der Sorte
func _fass_platz(sorte: int) -> Vector3:
	var st := get_node_or_null("Stations")
	if st:
		for k in st.get_children():
			if k is KegStation and int(k.beer_type) == sorte:
				return Vector3((k as Node3D).global_position.x, 0.1, ZAPFER_POINT.z)
	return ZAPFER_POINT

# ================================================= Müllsäcke (Zelt putzen)
## Jeder weggefegte Dreckhaufen wird ein Müllsack (Package, Sorte MUELL). Die
## Säcke gehören zum Müllplatz vor dem Zelt (scenes/muellplatz.tscn); morgens
## holt die Müllabfuhr sie ab. Der Putzschritt ist erst fertig, wenn alle
## Säcke draußen stehen.
var _muell_erzeugt := 0
var _muell_entsorgt := 0
var _muell_stapel := 0

func _muellsack_hinlegen(pos: Vector3) -> void:
	var id := _pkg_next
	_pkg_next += 1
	_muell_erzeugt += 1
	_add_package.rpc(id, pos, MUELL, 1)

@rpc("any_peer", "reliable", "call_local")
func net_muell_abgeben() -> void:
	if not multiplayer.is_server():
		return
	# Es kann nie mehr entsorgt werden, als gefegt wurde. Ohne diese Schranke
	# lief der Zähler hoch, wenn zwei Spieler gleichzeitig abgaben.
	if _muell_entsorgt >= _muell_erzeugt:
		return
	_muell_entsorgt += 1
	_muell_stapel += 1
	_net_muell_geworfen.rpc()
	_broadcast_meta()

## Ein Spieler hat zu viel getrunken und übergibt sich (scripts/player.gd).
## Den Fleck legt der Server an — sonst läge er nur auf dem eigenen Rechner und
## die Mitspieler hätten nichts zu putzen. Die Stelle nimmt der Server aus der
## Figur, nicht aus der Nachricht.
@rpc("any_peer", "reliable", "call_local")
func net_spieler_kotzt() -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	var pl: Node = _players_nodes.get(sender if sender > 0 else 1)
	if pl == null or not is_instance_valid(pl):
		return
	_spawn_mess_at((pl as Node3D).global_position, 0)
	_stats.gekotzt = int(_stats.get("gekotzt", 0)) + 1

## Deckel auf, Sack hinein — bei allen Spielern (scripts/muellplatz.gd).
@rpc("authority", "reliable", "call_local")
func _net_muell_geworfen() -> void:
	for m in get_tree().get_nodes_in_group("muellplatz"):
		if m.has_method("einwerfen"):
			m.einwerfen()

func _muell_offen() -> bool:
	return _muell_entsorgt < _muell_erzeugt

func _muellplatz_zeigen(n: int) -> void:
	for m in get_tree().get_nodes_in_group("muellplatz"):
		m.anzahl_setzen(n)

# ================================================= Huber: Wetten und Sabotage
## Huber (scripts/npc_huber.gd) bietet ab Tag 3 jeden dritten Tag morgens eine
## Wette an (Annehmen im Gespräch), abends wird abgerechnet. Ab Tag 5 sabotiert
## er ab und zu während der Schicht: ein auslaufendes Fass (Bierlache, kostet
## Bier bis sie weggeputzt ist) oder eine Stinkbombe (Flecken, Sauberkeit sinkt).
const HUBER_WETTE_AB := 3
const SABOTAGE_AB := 5
const SABOTAGE_ABSTAND := 3
const LECK_TAKT := 2.5
var _huber_wette := {}
var _sabotage_t := -1.0
var _letzte_sabotage := 0
var _leck_t := 0.0

func _huber_morgen() -> void:
	_huber_wette = {}
	_sabotage_t = -1.0
	if tutorial_active():
		return
	var d := _day
	if d >= HUBER_WETTE_AB and d % 3 == 0:
		var arten := [
			{"typ": "mass", "ziel": int(ceil(float(15 + 7 * d) * 1.1))},
			{"typ": "sauber", "ziel": 0},
			{"typ": "beschwerde", "ziel": 0},
		]
		_huber_wette = arten.pick_random()
		_huber_wette["einsatz"] = 150 + 50 * d
		_huber_wette["angenommen"] = false
		_melde("MSG_HUBER_WETTE", [], 0)
	if d >= SABOTAGE_AB and d - _letzte_sabotage >= SABOTAGE_ABSTAND and randf() < 0.6:
		_letzte_sabotage = d
		_sabotage_t = randf_range(60.0, 180.0)

## Spieler nimmt Hubers Wette an (true) oder lehnt ab
@rpc("any_peer", "reliable", "call_local")
func net_huber_wette(annehmen: bool) -> void:
	if not multiplayer.is_server() or _huber_wette.is_empty() or bool(_huber_wette.get("angenommen", false)):
		return
	if annehmen:
		_huber_wette["angenommen"] = true
		_melde("MSG_HUBER_WETTE_AN", [_eur(int(_huber_wette.einsatz))], 0)
	else:
		_huber_wette = {}
	_broadcast_meta()

## Abends: Wette abrechnen
func _huber_abrechnen() -> void:
	if _huber_wette.is_empty():
		return
	if bool(_huber_wette.get("angenommen", false)):
		var einsatz := int(_huber_wette.einsatz)
		var gewonnen := false
		match str(_huber_wette.typ):
			"mass": gewonnen = _served >= int(_huber_wette.ziel)
			"sauber": gewonnen = _urin_count == 0 and _served >= 10
			"beschwerde": gewonnen = _complaints == 0 and _served >= 10
		if gewonnen:
			Game.add_money(einsatz)
			_popularity = minf(100.0, _popularity + 2.0)
			_melde("MSG_HUBER_WETTE_GEWONNEN", [_eur(einsatz)], 2)
		else:
			Game.add_money(-einsatz)
			_melde("MSG_HUBER_WETTE_VERLOREN", [_eur(einsatz)], 1)
	_huber_wette = {}

## Während der Schicht: Sabotage auslösen und das Leck Bier kosten lassen
func _huber_schicht(delta: float) -> void:
	if _sabotage_t > 0.0:
		_sabotage_t -= delta
		if _sabotage_t <= 0.0:
			_saboteur_losschicken()
	var leck := false
	for k in _mess_kind.values():
		if int(k) >= Mess.SABOTAGE:
			leck = true
			break
	if not leck:
		return
	_leck_t += delta
	if _leck_t >= LECK_TAKT:
		_leck_t = 0.0
		if int(_stock[WARE_BIER]) > 0:
			_stock[WARE_BIER] = int(_stock[WARE_BIER]) - 1
			_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))

func _sabotieren() -> void:
	if randf() < 0.5:
		var fass := _fass_platz(1)
		_spawn_mess_at(Vector3(fass.x + randf_range(-0.4, 0.4), 0.0, fass.z + 0.8), Mess.SABOTAGE)
		_melde("MSG_SABOTAGE_FASS", [], 1)
	else:
		for i in 4:
			_spawn_mess_at(Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-5.0, 10.0)), 0)
		_hygiene = maxf(0.0, _hygiene - 25.0)
		_melde("MSG_SABOTAGE_STINK", [], 1)

# ================================================= Finale: Maß-Wettschleppen
## Am letzten Wiesn-Tag fordert Huber zum Duell um Sepps Ehre (scripts/wettschleppen.gd).
## Starten über das Gespräch mit Huber; Hubers Zeit legt der Server fest (je
## Schwierigkeit), das Ergebnis meldet der Herausforderer. Gewonnen: Sepps Ehre
## gerettet, viel Beliebtheit, Brief zum Abschluss. Verloren: Huber triumphiert,
## Beliebtheit sinkt, am selben Tag darf man es nochmal versuchen.
## Hubers Zeit = Streckenlänge / Gehtempo mit 10 Maß × Faktor je Schwierigkeit:
## Gemütlich reicht ruhiges Gehen, Normal braucht geschickte kurze Sprints (Balken
## im Blick), Wiesn-Wahnsinn fast durchgehend — dann schwappt auch mal was über.
const DUELL_GEHTEMPO := 3.4
const DUELL_FAKTOR := [1.05, 0.8, 0.7]   # Gemütlich · Normal · Wiesn-Wahnsinn
const DUELL_POP_SIEG := 15.0
const DUELL_POP_NIEDERLAGE := 5.0
var _duell := {}
## Saison, in der Sepps Ehre gerettet wurde (0 = noch nie)
var _duell_saison := 0

func duell_moeglich() -> bool:
	return ist_finale() and _duell.is_empty() and _duell_saison != _saison_nr and _tent_stage > 0

@rpc("any_peer", "reliable", "call_local")
func net_duell_start() -> void:
	if not multiplayer.is_server() or not duell_moeglich():
		return
	var s := multiplayer.get_remote_sender_id()
	if s == 0:
		s = 1
	var w := get_tree().get_first_node_in_group("wettschleppen")
	var laenge: float = w.strecken_laenge() if w else 55.0
	var zeit := laenge / DUELL_GEHTEMPO * float(DUELL_FAKTOR[_schwierigkeit]) * randf_range(0.97, 1.03)
	_duell = {"peer": s, "huber": zeit}
	_net_duell_start.rpc(s, zeit)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _net_duell_start(peer: int, huber_zeit: float) -> void:
	var w := get_tree().get_first_node_in_group("wettschleppen")
	if w:
		w.starten(peer, huber_zeit)

@rpc("any_peer", "reliable", "call_local")
func net_duell_ende(zeit: float, verschuettet: int) -> void:
	if not multiplayer.is_server() or _duell.is_empty():
		return
	var gesamt := zeit + float(verschuettet) * 2.5
	var huber_zeit := float(_duell.huber)
	var gewonnen := verschuettet < 10 and gesamt < huber_zeit
	if gewonnen:
		_duell_saison = _saison_nr
		_popularity = minf(100.0, _popularity + DUELL_POP_SIEG)
		_stats.duell_siege = int(_stats.get("duell_siege", 0)) + 1
	else:
		_popularity = maxf(POP_MIN, _popularity - DUELL_POP_NIEDERLAGE)
	_duell = {}
	_net_duell_ergebnis.rpc(gewonnen, gesamt, huber_zeit, verschuettet)
	_broadcast_meta()

@rpc("authority", "reliable", "call_local")
func _net_duell_ergebnis(gewonnen: bool, gesamt: float, huber_zeit: float, verschuettet: int) -> void:
	var w := get_tree().get_first_node_in_group("wettschleppen")
	if w:
		w.beenden()
	var mehrere := multiplayer.get_peers().size() > 0
	var a := "_IHR" if mehrere else "_DU"
	_hud.melde_text(tr("MSG_DUELL_ERGEBNIS") % [gesamt, verschuettet, huber_zeit], 2 if gewonnen else 1)
	var dialog := get_tree().get_first_node_in_group("dialog")
	var zeilen: Array[String] = []
	for k in (["HUBER_BESIEGT_1", "HUBER_BESIEGT_2"] if gewonnen else ["HUBER_SIEGT_1", "HUBER_SIEGT_2"]):
		zeilen.append(tr(k + a))
	if dialog == null:
		return
	# Nach dem Sieg: Sepps letzter Brief (scripts/ui/kino.gd)
	var danach := Callable()
	if gewonnen:
		danach = func() -> void:
			var kino := get_node_or_null("Kino")
			if kino and kino.has_method("brief_zeigen"):
				kino.brief_zeigen(mehrere, "BRIEF_ENDE", 2, "BRIEF_ENDE_TITEL")
	dialog.zeigen(tr("HUBER_NAME"), zeilen, danach)

# ================================================= Wiesn-Kalender
## Die Tagesereignisse einer Saison stehen im Voraus fest (Kalender, Taste K,
## scenes/ui/kalender.tscn): feste Sondertage plus zufällige Ereignisse ab Tag 3.
## Geplant zu Saisonbeginn, gespeichert und an alle geschickt (Büro-Zustand „plan").
const SONDERTAGE := {1: "anstich", 5: "tracht", 8: "familie", 10: "italiener", 11: "italiener", 16: "finale"}
var _plan: Array = []

## Plan für die laufende Saison anlegen, falls noch keiner da ist
func _plan_pruefen() -> void:
	if _plan.size() == Wirtschaft.SAISON_TAGE and int(_plan_saison) == _saison_nr:
		return
	_plan = []
	_plan_saison = _saison_nr
	for tag in range(1, Wirtschaft.SAISON_TAGE + 1):
		if SONDERTAGE.has(tag):
			_plan.append(SONDERTAGE[tag])
		elif tag >= EREIGNIS_AB_TAG and randf() <= EREIGNIS_CHANCE:
			_plan.append(str(EREIGNISSE.pick_random()))
		else:
			_plan.append("")

var _plan_saison := 0

## Ereignis laut Plan für einen Spieltag ("" = keins)
func plan_fuer(tag: int) -> String:
	_plan_pruefen()
	var i := Wirtschaft.saison_tag(tag) - 1
	return str(_plan[i]) if i >= 0 and i < _plan.size() else ""

func _kalender_plan() -> Array:
	_plan_pruefen()
	return _plan

# ================================================= Personal mit Charakter
## Jeder Mitarbeiter hat einen Namen, arbeitet seit Tag X, wird zum Abend hin
## müde (langsamer) und hat ab und zu ein Anliegen:
##   "lohn"  — will mehr Lohn; einmal ignoriert → unzufrieden (langsamer),
##             zweimal → kündigt
##   "huber" — Huber will ihn abwerben (Tage 5–10); nicht gehalten → morgen weg
## Lohn erhöhen und entlassen im Wiesenbüro (Reiter Personal, Teamliste).
const PERSONAL_NAMEN := ["Anna", "Thomas", "Julia", "Stefan", "Sabine", "Michael", "Laura", "Markus", "Katrin",
	"Andreas", "Lisa", "Florian", "Claudia", "Tobias", "Sandra", "Daniel", "Nina", "Martin", "Petra", "Jonas"]
const LOHN_WUNSCH_AB := 4        # so viele Tage im Dienst, bevor jemand mehr will
const LOHN_WUNSCH_CHANCE := 0.25
const LOHN_PLUS := 0.15          # +15 % beim Erhöhen
const HALTEN_PLUS := 0.2         # +20 %, um ihn vor Huber zu halten
const ABWERBEN_CHANCE := 0.2
const MUEDE_JE_SEKUNDE := 0.0015 # volle Schicht (300 s) → Energie ≈ 0,55

func _personal_name() -> String:
	var vergeben := []
	for s in _staff_sim.values():
		vergeben.append(str(s.get("name", "")))
	var frei := PERSONAL_NAMEN.filter(func(n: String) -> bool: return not vergeben.has(n))
	return str(frei.pick_random()) if not frei.is_empty() else str(PERSONAL_NAMEN.pick_random())

## Morgens: ausgeschlafen, offene Anliegen werden ernst, neue kommen dazu
func _personal_morgen() -> void:
	var weg := []
	for sid: int in _staff_sim:
		var s: Dictionary = _staff_sim[sid]
		s.energie = 1.0
		match str(s.get("anliegen", "")):
			"huber":
				weg.append(sid)
				_melde("MSG_PERSONAL_ABGEWORBEN", [str(s.get("name", "")), STAFF_KEYS[int(s.role)]], 1)
				continue
			"lohn":
				if bool(s.get("unzufrieden", false)):
					weg.append(sid)
					_melde("MSG_PERSONAL_KUENDIGT", [str(s.get("name", ""))], 1)
					continue
				s.unzufrieden = true
				_melde("MSG_PERSONAL_UNZUFRIEDEN", [str(s.get("name", ""))], 1)
				continue
		if tutorial_active():
			continue
		if _day - int(s.get("seit", _day)) >= LOHN_WUNSCH_AB and randf() < LOHN_WUNSCH_CHANCE:
			s.anliegen = "lohn"
			s.seit_wunsch = _day
			_melde("MSG_PERSONAL_LOHNWUNSCH", [str(s.get("name", "")), _eur(_lohn_plus(sid, LOHN_PLUS))], 0)
	for sid in weg:
		_personal_weg(sid)
	# Huber wirbt ab (Akt 2) — höchstens einen am Tag
	var tag := Wirtschaft.saison_tag(_day)
	if not tutorial_active() and tag >= 5 and tag <= 10 and randf() < ABWERBEN_CHANCE:
		var kandidaten := _staff_sim.keys().filter(func(k: int) -> bool: return str(_staff_sim[k].get("anliegen", "")) == "")
		if not kandidaten.is_empty():
			var sid: int = kandidaten.pick_random()
			_staff_sim[sid].anliegen = "huber"
			_melde("MSG_PERSONAL_HUBER", [str(_staff_sim[sid].get("name", "")), _eur(_lohn_plus(sid, HALTEN_PLUS))], 1)

## Mehrkosten pro Tag, wenn der Lohn um anteil steigt
func _lohn_plus(sid: int, anteil: float) -> int:
	var s: Dictionary = _staff_sim[sid]
	return roundi(float(_staff_wage(int(s.role), int(s.level), str(s.get("eig", "normal")))) * float(s.get("lohn", 1.0)) * anteil)

## Wiesenbüro: Anliegen erfüllen (Lohn erhöhen bzw. vor Huber halten)
@rpc("any_peer", "reliable", "call_local")
func net_personal_lohn(sid: int) -> void:
	if not multiplayer.is_server() or not _staff_sim.has(sid):
		return
	var s: Dictionary = _staff_sim[sid]
	var anliegen := str(s.get("anliegen", ""))
	if anliegen == "":
		return
	s.lohn = float(s.get("lohn", 1.0)) * (1.0 + (HALTEN_PLUS if anliegen == "huber" else LOHN_PLUS))
	s.anliegen = ""
	s.unzufrieden = false
	_melde("MSG_PERSONAL_ZUFRIEDEN", [str(s.get("name", ""))], 2)
	_broadcast_meta()

## Wiesenbüro: entlassen
@rpc("any_peer", "reliable", "call_local")
func net_personal_entlassen(sid: int) -> void:
	if not multiplayer.is_server() or not _staff_sim.has(sid) or _phase != Phase.INTERMISSION:
		return
	_melde("MSG_PERSONAL_ENTLASSEN", [str(_staff_sim[sid].get("name", ""))], 0)
	_personal_weg(sid)
	_broadcast_meta()

func _personal_weg(sid: int) -> void:
	for gid in _assigned.keys().duplicate():
		if int(_assigned[gid]) == sid:
			_assigned.erase(gid)
	_staff_sim.erase(sid)
	_remove_staff.rpc(sid)

@rpc("authority", "reliable", "call_local")
func _remove_staff(id: int) -> void:
	var n = _staff.get(id)
	if n and is_instance_valid(n):
		n.queue_free()
	_staff.erase(id)

# ================================================= Koop: Auszeichnungen am Abend
## Wer hat heute am meisten bedient, gezapft, geputzt? Nur im Koop, abends als
## Meldung und im Wiesn-Kurier (Bilanz "ehren").
var _tag_leistung := {}   # Peer -> {"bedient": n, "gezapft": n, "geputzt": n}

func _leistung(peer: int, art: String) -> void:
	if not _tag_leistung.has(peer):
		_tag_leistung[peer] = {"bedient": 0, "gezapft": 0, "geputzt": 0, "gekocht": 0}
	_tag_leistung[peer][art] = int(_tag_leistung[peer][art]) + 1

## [[Art, Name, Anzahl], …] — die Besten des Tages (nur mit mehreren Spielern)
func _auszeichnungen() -> Array:
	var ehren := []
	if _tag_leistung.size() < 2 and multiplayer.get_peers().is_empty():
		return ehren
	for art in ["bedient", "gezapft", "geputzt", "gekocht"]:
		var bester := -1
		var n := 0
		for peer: int in _tag_leistung:
			var w := int(_tag_leistung[peer][art])
			if w > n:
				n = w
				bester = peer
		if bester >= 0:
			var info: Dictionary = _spieler_info.get(bester, {})
			ehren.append([art, str(info.get("name", "Spieler %d" % bester)), n])
	return ehren

# ================================================= Hubers Saboteur
## Statt sofort zu sabotieren, schickt Huber jemanden ins Zelt (scripts/saboteur.gd).
## Kommt er ans Ziel, passiert die Sabotage; wird er vorher erwischt, gibt es
## Geld und Beliebtheit.
const SABOTEUR_SZENE := preload("res://scenes/saboteur.tscn")
const Saboteur := preload("res://scripts/saboteur.gd")
const SABOTEUR_WEG_FASS := [Vector3(0, 0, 13), Vector3(-6, 0, 6), Vector3(-10, 0, 0), Vector3(-10, 0, -11.3), Vector3(-4, 0, -12.4)]
const SABOTEUR_WEG_STINK := [Vector3(0, 0, 13), Vector3(-6, 0, 6), Vector3(-2, 0, 1)]
const SABOTEUR_LOHN := 200
const SABOTEUR_POP := 4.0
var _saboteur := {}          # {"art": "fass"/"stink", "rest": Sekunden bis zum Ziel}
var _saboteur_knoten: Node3D = null

func _saboteur_losschicken() -> void:
	var art := "fass" if randf() < 0.5 else "stink"
	var weg: Array = SABOTEUR_WEG_FASS if art == "fass" else SABOTEUR_WEG_STINK
	_saboteur = {"art": art, "rest": Saboteur.dauer(weg)}
	_net_saboteur_start.rpc(weg)
	_melde("MSG_SABOTEUR_DA", [], 1)

@rpc("authority", "reliable", "call_local")
func _net_saboteur_start(weg: Array) -> void:
	if _saboteur_knoten and is_instance_valid(_saboteur_knoten):
		_saboteur_knoten.queue_free()
	_saboteur_knoten = SABOTEUR_SZENE.instantiate()
	add_child(_saboteur_knoten)
	_saboteur_knoten.starten(weg)

## Server, jede Schicht-Sekunde: kommt er an, passiert die Sabotage
func _saboteur_schicht(delta: float) -> void:
	if _saboteur.is_empty():
		return
	_saboteur.rest = float(_saboteur.rest) - delta
	if float(_saboteur.rest) > 0.0:
		return
	var art := str(_saboteur.art)
	_saboteur = {}
	if art == "fass":
		var fass := _fass_platz(1)
		_spawn_mess_at(Vector3(fass.x + randf_range(-0.4, 0.4), 0.0, fass.z + 0.8), Mess.SABOTAGE)
		_melde("MSG_SABOTAGE_FASS", [], 1)
	else:
		for i in 4:
			_spawn_mess_at(Vector3(randf_range(-8.0, 8.0), 0.0, randf_range(-5.0, 10.0)), 0)
		_hygiene = maxf(0.0, _hygiene - 25.0)
		_melde("MSG_SABOTAGE_STINK", [], 1)
	_net_saboteur_weg.rpc()

@rpc("any_peer", "reliable", "call_local")
func net_saboteur_fangen() -> void:
	if not multiplayer.is_server() or _saboteur.is_empty():
		return
	_saboteur = {}
	_add_income(SABOTEUR_LOHN)
	_pop_erhoehen(SABOTEUR_POP)
	_melde("MSG_SABOTEUR_ERWISCHT", [_eur(SABOTEUR_LOHN)], 2)
	_net_saboteur_weg.rpc()

@rpc("authority", "reliable", "call_local")
func _net_saboteur_weg() -> void:
	if _saboteur_knoten and is_instance_valid(_saboteur_knoten):
		_saboteur_knoten.fliehen()

# ================================================= Stammgäste mit Namen
## Sechs Stammgäste kommen nach dem Tutorial immer wieder (höchstens einer am Tag).
## Jeder hat einen Wunsch (Alois: Helles, Franz: Hendl, Giulia: Radler …). Dreimal
## zufrieden bedient → Belohnung auf seine Art, verpasst → zählt zurück.
## Stand im Spielstand ("stamm"), Anzeige im Wiesn-Kurier und über dem Kopf.
const STAMMGAESTE := ["alois", "vroni", "kathi", "franz", "giulia", "wiggerl"]
const STAMM_ZIEL := 3
const STAMM_CHANCE := 0.03   # je neuem Gast, bis heute einer da war
var _stamm := {}             # key -> {"gut": n, "belohnt": bool}
var _stamm_heute := ""

func _stammgast_waehlen() -> String:
	if tutorial_active() or _stamm_heute != "" or randf() > STAMM_CHANCE:
		return ""
	var offen := STAMMGAESTE.filter(func(k: String) -> bool: return not bool(_stamm.get(k, {}).get("belohnt", false)))
	if offen.is_empty():
		offen = STAMMGAESTE.duplicate()
	_stamm_heute = str(offen.pick_random())
	return _stamm_heute

func _stamm_wunsch(g: Dictionary) -> void:
	match str(g.get("stamm", "")):
		"alois", "wiggerl":
			g.okind = 1
			g.otype = 1
		"giulia":
			g.okind = 1
			g.otype = 3 if _drinks_avail().has(3) else 1
		"franz":
			var essen := _foods_avail()
			if not essen.is_empty():
				g.okind = 2
				g.otype = 3 if essen.has(3) else essen.pick_random()

func _stamm_bedient(g: Dictionary) -> void:
	var k := str(g.get("stamm", ""))
	if k == "":
		return
	var s: Dictionary = _stamm.get(k, {"gut": 0, "belohnt": false})
	if bool(s.belohnt):
		return
	s.gut = int(s.gut) + 1
	_stamm[k] = s
	if int(s.gut) >= STAMM_ZIEL:
		s.belohnt = true
		_stamm_belohnung(k)
	else:
		_melde("MSG_STAMM_ZUFRIEDEN", ["STAMM_NAME_" + k.to_upper(), int(s.gut), STAMM_ZIEL], 2)

func _stamm_verpasst(g: Dictionary) -> void:
	var k := str(g.get("stamm", ""))
	if k == "" or bool(_stamm.get(k, {}).get("belohnt", false)):
		return
	var s: Dictionary = _stamm.get(k, {"gut": 0, "belohnt": false})
	s.gut = maxi(0, int(s.gut) - 1)
	_stamm[k] = s
	_melde("MSG_STAMM_VERAERGERT", ["STAMM_NAME_" + k.to_upper()], 1)

## Belohnung je Stammgast
func _stamm_belohnung(k: String) -> void:
	match k:
		"alois":
			_pop_erhoehen(6.0)
		"vroni":
			_pop_erhoehen(4.0)
			_add_income(250)
		"kathi":
			_pop_erhoehen(10.0)
		"franz":
			_stock[WARE_ESSEN] = int(_stock[WARE_ESSEN]) + 20
			_push_stock.rpc(int(_stock[WARE_BIER]), int(_stock[WARE_ESSEN]))
		"giulia":
			_add_income(400)
		"wiggerl":
			_add_income(300)
			_pop_erhoehen(3.0)
	_melde("MSG_STAMM_BELOHNUNG_" + k.to_upper(), [], 2)

## Nach Loslassen oder Wurf: kein Spieler trägt mehr einen Raufbold. Es kann
## immer nur einer je Raufbold sein, darum reicht das Zurücksetzen bei allen.
func _arme_leer_melden(traeger: int) -> void:
	var p = _players_nodes.get(traeger)
	if p and is_instance_valid(p) and p.has_method("raufbold_auf_dem_arm"):
		p.raufbold_auf_dem_arm(false)

## Ein Gast lässt etwas am Tisch liegen (Serviette, Scherben, Laub). Landet
## neben seinem Platz, nicht auf dem Tisch.
func _gast_muell(g: Dictionary) -> void:
	var seat: Dictionary = _seats[int(g.seat)] if _seats.size() > int(g.seat) else {}
	var ort: Vector3 = seat.get("pos", g.pos) as Vector3
	var weg := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
	if weg.length() < 0.2:
		weg = Vector3(0.8, 0.0, 0.0)
	_spawn_mess_at(ort + weg.normalized() * randf_range(0.7, 1.4),
		Mess.DRECK + int(Mess.DRECK_ARTEN.pick_random()))
