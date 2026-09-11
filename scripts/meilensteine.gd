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
]

## Lebenszeit-Zähler, die der Spielstand mitführt (GameManager._stats).
const ZAEHLER := ["served", "earned", "days", "cleaned"]

## Aktuelle Zahl zu einer Meilenstein-Art.
## stats: Lebenszeit-Zähler · zustand: GameManager._buero_state (Zelt, Personal, Lizenzen).
static func wert_von(art: String, stats: Dictionary, zustand: Dictionary) -> int:
	match art:
		"tent_stage":
			return int(zustand.get("stage", 0))
		"waiter_level":
			var bester := 0
			for e: Array in zustand.get("staff", []):
				if int(e[0]) == 2:   # GameManager.ROLE_KELLNER
					bester = maxi(bester, int(e[1]))
			return bester
		"licenses":
			var n := 0
			for hat in (zustand.get("lic", {}) as Dictionary).values():
				if hat:
					n += 1
			return n
	return int(stats.get(art, 0))
