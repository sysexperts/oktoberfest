extends RefCounted
## Alle kaufbaren Einrichtungsgegenstände fürs Zelt.
##
## Neuer Gegenstand: Szene unter scenes/einrichtung/ anlegen (Wurzel mit
## scripts/einrichtung.gd, Modell als Kind), hier eintragen, eine Angebotszeile
## im Wiesenbüro-Reiter „Einrichtung" (scenes/ui/wiesenbuero.tscn) mit dem Namen
## aus "zeile" anlegen und DECO_<ART> / DECO_<ART>_INFO in locale/texte.csv.
## Ohne class_name, einbinden per preload.
##
## "platz": wo der Gegenstand hinkommt
##   boden — steht frei im Zelt
##   wand  — rastet an der nächsten Zeltwand ein, Vorderseite (+Z) zeigt ins Zelt
##   decke — hängt frei unter dem Dach
## "hoehe": Höhe des Szenenursprungs über dem Boden (Wand: Aufhängung, Decke:
## Aufhängepunkt; das Modell sitzt in der Szene darunter bzw. davor).

## art -> Szene, Preis, Symbol, Zeile im Wiesenbüro, Platz, Höhe
const ARTEN := {
	"laterne": {"szene": preload("res://scenes/einrichtung/laterne.tscn"), "preis": 150, "symbol": "🏮", "zeile": "EinrLaterne", "platz": "boden", "hoehe": 0.0},
	"stehlampe": {"szene": preload("res://scenes/einrichtung/stehlampe.tscn"), "preis": 90, "symbol": "💡", "zeile": "EinrStehlampe", "platz": "boden", "hoehe": 0.0},
	"lichterkette": {"szene": preload("res://scenes/einrichtung/lichterkette.tscn"), "preis": 220, "symbol": "✨", "zeile": "EinrLichterkette", "platz": "boden", "hoehe": 0.0},
	"blumen": {"szene": preload("res://scenes/einrichtung/blumen.tscn"), "preis": 60, "symbol": "🌷", "zeile": "EinrBlumen", "platz": "boden", "hoehe": 0.0},
	"busch": {"szene": preload("res://scenes/einrichtung/busch.tscn"), "preis": 70, "symbol": "🌳", "zeile": "EinrBusch", "platz": "boden", "hoehe": 0.0},
	"regal": {"szene": preload("res://scenes/einrichtung/regal.tscn"), "preis": 180, "symbol": "🗄", "zeile": "EinrRegal", "platz": "boden", "hoehe": 0.0},
	"fass": {"szene": preload("res://scenes/einrichtung/fass.tscn"), "preis": 100, "symbol": "🛢", "zeile": "EinrFass", "platz": "boden", "hoehe": 0.0},
	"kronleuchter": {"szene": preload("res://scenes/einrichtung/kronleuchter.tscn"), "preis": 450, "symbol": "🕯", "zeile": "EinrKronleuchter", "platz": "decke", "hoehe": 3.7},
	"lichtergirlande": {"szene": preload("res://scenes/einrichtung/lichtergirlande.tscn"), "preis": 220, "symbol": "💫", "zeile": "EinrLichtergirlande", "platz": "decke", "hoehe": 3.6},
	"haengelaterne": {"szene": preload("res://scenes/einrichtung/haengelaterne.tscn"), "preis": 150, "symbol": "🪔", "zeile": "EinrHaengelaterne", "platz": "decke", "hoehe": 3.6},
	"hopfen": {"szene": preload("res://scenes/einrichtung/hopfen.tscn"), "preis": 120, "symbol": "🌿", "zeile": "EinrHopfen", "platz": "wand", "hoehe": 2.4},
	"riesenbrezel": {"szene": preload("res://scenes/einrichtung/riesenbrezel.tscn"), "preis": 200, "symbol": "🥨", "zeile": "EinrRiesenbrezel", "platz": "wand", "hoehe": 2.2},
	"banner": {"szene": preload("res://scenes/einrichtung/banner.tscn"), "preis": 180, "symbol": "🚩", "zeile": "EinrBanner", "platz": "wand", "hoehe": 2.0},
	"wimpel": {"szene": preload("res://scenes/einrichtung/wimpel.tscn"), "preis": 90, "symbol": "🎏", "zeile": "EinrWimpel", "platz": "wand", "hoehe": 2.6},
}

static func name_key(art: String) -> String:
	return "DECO_%s" % art.to_upper()

static func info_key(art: String) -> String:
	return "DECO_%s_INFO" % art.to_upper()

## "boden", "wand" oder "decke"
static func platz(art: String) -> String:
	return str((ARTEN.get(art, {}) as Dictionary).get("platz", "boden"))

static func hoehe(art: String) -> float:
	return float((ARTEN.get(art, {}) as Dictionary).get("hoehe", 0.0))
