extends RefCounted
## Meilensteine fürs Endlosspiel. Sie werden später 1:1 zu Steam-Errungenschaften
## (Plan 5.4) — die IDs deshalb nie umbenennen, nur neue anhängen.
## Texte: MS_<id>_TITLE / MS_<id>_TEXT in locale/texte.csv.
##
## wert: welche Zahl zählt (siehe wert_von) · ziel: ab wann erreicht ·
## belohnung: Euro, die es beim Erreichen einmalig gibt.
## Ohne class_name (Server-Klassencache), Einbinden per preload.

const LISTE := [
	{"id": "ERSTE_MASS", "wert": "served", "ziel": 1, "belohnung": 50},
	{"id": "UMSATZ_1000", "wert": "earned", "ziel": 1000, "belohnung": 200},
	{"id": "TAG_7", "wert": "days", "ziel": 7, "belohnung": 300},
	{"id": "MASS_100", "wert": "served", "ziel": 100, "belohnung": 300},
	{"id": "ZELT_2", "wert": "tent_stage", "ziel": 2, "belohnung": 500},
	{"id": "PUTZ_50", "wert": "cleaned", "ziel": 50, "belohnung": 300},
	{"id": "ALLE_LIZENZEN", "wert": "licenses", "ziel": 4, "belohnung": 800},
	{"id": "UMSATZ_10000", "wert": "earned", "ziel": 10000, "belohnung": 1000},
	{"id": "KELLNER_5", "wert": "waiter_level", "ziel": 5, "belohnung": 1000},
	{"id": "TAG_30", "wert": "days", "ziel": 30, "belohnung": 1500},
	{"id": "MASS_1000", "wert": "served", "ziel": 1000, "belohnung": 2000},
	{"id": "ZELT_3", "wert": "tent_stage", "ziel": 3, "belohnung": 2000},
	{"id": "UMSATZ_100000", "wert": "earned", "ziel": 100000, "belohnung": 5000},
	{"id": "TANZ_50", "wert": "tanzen", "ziel": 50, "belohnung": 400},
	{"id": "KOTZE_100", "wert": "gekotzt", "ziel": 100, "belohnung": 500},
	{"id": "KOMBO_10", "wert": "kombo_max", "ziel": 10, "belohnung": 600},
	{"id": "SAUBER_5", "wert": "tage_sauber", "ziel": 5, "belohnung": 800},
	{"id": "DEKO_10", "wert": "einrichtung", "ziel": 10, "belohnung": 500},
	{"id": "EREIGNIS_10", "wert": "ereignisse", "ziel": 10, "belohnung": 700},
	{"id": "PERSONAL_8", "wert": "personal", "ziel": 8, "belohnung": 1000},
	{"id": "KAPITEL_2", "wert": "kapitel", "ziel": 2, "belohnung": 300},
	{"id": "KAPITEL_3", "wert": "kapitel", "ziel": 3, "belohnung": 500},
	{"id": "KAPITEL_4", "wert": "kapitel", "ziel": 4, "belohnung": 700},
	{"id": "KAPITEL_5", "wert": "kapitel", "ziel": 5, "belohnung": 1000},
	{"id": "GESCHICHTE_FERTIG", "wert": "kapitel", "ziel": 6, "belohnung": 2000},
	{"id": "GEFALLEN_5", "wert": "meister:MEISTER_GEFALLEN", "ziel": 5, "belohnung": 500},
	{"id": "GEFALLEN_9", "wert": "meister:MEISTER_GEFALLEN", "ziel": 9, "belohnung": 1500},
	{"id": "KIRMES_3", "wert": "meister:MEISTER_KIRMES", "ziel": 3, "belohnung": 500},
	{"id": "KIRMES_7", "wert": "meister:MEISTER_KIRMES", "ziel": 7, "belohnung": 1500},
	{"id": "SABOTAGE_1", "wert": "sab_ok", "ziel": 1, "belohnung": 400},
	{"id": "SABOTAGE_10", "wert": "sab_ok", "ziel": 10, "belohnung": 1500},
	{"id": "CASINO_ROULETTE", "wert": "roulette", "ziel": 1, "belohnung": 300},
	{"id": "CASINO_BLACKJACK", "wert": "blackjack", "ziel": 1, "belohnung": 300},
	{"id": "MEISTERBIER", "wert": "meisterfaesser", "ziel": 1, "belohnung": 1000},
	{"id": "FEST_1", "wert": "feste", "ziel": 1, "belohnung": 800},
	{"id": "FEST_WELT", "wert": "meister:MEISTER_FEST", "ziel": 4, "belohnung": 3000},
	{"id": "FAKE_GEMELDET", "wert": "fakes_gemeldet", "ziel": 1, "belohnung": 300},
	{"id": "PERSONAL_ALLE", "wert": "meister:MEISTER_PERSONAL", "ziel": 6, "belohnung": 1500},
	{"id": "WAGEN_VOLL", "wert": "meister:MEISTER_WAGEN", "ziel": 6, "belohnung": 1000},
	{"id": "AUSBAU_1", "wert": "meister:MEISTER_AUSBAU", "ziel": 1, "belohnung": 800},
	{"id": "AUSBAU_ALLE", "wert": "meister:MEISTER_AUSBAU", "ziel": 11, "belohnung": 4000},
	{"id": "WUNSCH_5", "wert": "wuensche", "ziel": 5, "belohnung": 500},
	{"id": "GRUPPEN_10", "wert": "gruppen", "ziel": 10, "belohnung": 600},
	{"id": "ZWISCHENFALL_10", "wert": "zwischenfaelle", "ziel": 10, "belohnung": 500},
	{"id": "WETTBEWERB_3", "wert": "wettbewerbe", "ziel": 3, "belohnung": 800},
	{"id": "ANSTICH_5", "wert": "anstiche", "ziel": 5, "belohnung": 600},
	{"id": "FEST_MEISTER", "wert": "meister_titel", "ziel": 1, "belohnung": 5000},
]

## Lebenszeit-Zähler, die der Spielstand mitführt (GameManager._stats).
const ZAEHLER := ["served", "earned", "days", "cleaned", "saisons", "beste_wertung",
	"tanzen", "gekotzt", "kombo_max", "tage_sauber", "ereignisse"]

## Aktuelle Zahl zu einer Meilenstein-Art.
## stats: Lebenszeit-Zähler · zustand: GameManager._buero_state (Zelt, Personal, Lizenzen).
static func wert_von(art: String, stats: Dictionary, zustand: Dictionary) -> int:
	# Meister-Liste: "meister:MEISTER_SCHLUESSEL" liefert den erreichten Stand dieses Eintrags
	if art.begins_with("meister:"):
		for e: Array in zustand.get("meister", []):
			if str(e[0]) == art.substr(8):
				return int(e[1])
		return 0
	match art:
		"kapitel":
			return int((zustand.get("story", {}) as Dictionary).get("kapitel", 1))
		"tent_stage":
			return int(zustand.get("stage", 0))
		"waiter_level":
			var bester := 0
			for e: Array in zustand.get("staff", []):
				if int(e[0]) == 2:   # GameManager.ROLE_KELLNER
					bester = maxi(bester, int(e[1]))
			return bester
		"einrichtung":
			return int(zustand.get("einrichtung", 0))
		"personal":
			return (zustand.get("staff", []) as Array).size()
		"licenses":
			var n := 0
			for hat in (zustand.get("lic", {}) as Dictionary).values():
				if hat:
					n += 1
			return n
	return int(stats.get(art, 0))
