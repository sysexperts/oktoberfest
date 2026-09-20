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
	"laterne": {"szene": preload("res://scenes/einrichtung/laterne.tscn"), "preis": 150, "symbol": "lampe", "zeile": "EinrLaterne", "platz": "boden", "hoehe": 0.0},
	"stehlampe": {"szene": preload("res://scenes/einrichtung/stehlampe.tscn"), "preis": 90, "symbol": "lampe", "zeile": "EinrStehlampe", "platz": "boden", "hoehe": 0.0},
	"lichterkette": {"szene": preload("res://scenes/einrichtung/lichterkette.tscn"), "preis": 220, "symbol": "lampe", "zeile": "EinrLichterkette", "platz": "boden", "hoehe": 0.0},
	"blumen": {"szene": preload("res://scenes/einrichtung/blumen.tscn"), "preis": 60, "symbol": "pflanze", "zeile": "EinrBlumen", "platz": "boden", "hoehe": 0.0},
	"busch": {"szene": preload("res://scenes/einrichtung/busch.tscn"), "preis": 70, "symbol": "pflanze", "zeile": "EinrBusch", "platz": "boden", "hoehe": 0.0},
	"regal": {"szene": preload("res://scenes/einrichtung/regal.tscn"), "preis": 180, "symbol": "regal", "zeile": "EinrRegal", "platz": "boden", "hoehe": 0.0},
	"fass": {"szene": preload("res://scenes/einrichtung/fass.tscn"), "preis": 100, "symbol": "fass", "zeile": "EinrFass", "platz": "boden", "hoehe": 0.0},
	"kronleuchter": {"szene": preload("res://scenes/einrichtung/kronleuchter.tscn"), "preis": 450, "symbol": "lampe", "zeile": "EinrKronleuchter", "platz": "decke", "hoehe": 3.7},
	"lichtergirlande": {"szene": preload("res://scenes/einrichtung/lichtergirlande.tscn"), "preis": 220, "symbol": "lampe", "zeile": "EinrLichtergirlande", "platz": "decke", "hoehe": 3.6},
	"haengelaterne": {"szene": preload("res://scenes/einrichtung/haengelaterne.tscn"), "preis": 150, "symbol": "lampe", "zeile": "EinrHaengelaterne", "platz": "decke", "hoehe": 3.6},
	"hopfen": {"szene": preload("res://scenes/einrichtung/hopfen.tscn"), "preis": 120, "symbol": "pflanze", "zeile": "EinrHopfen", "platz": "wand", "hoehe": 2.4},
	"riesenbrezel": {"szene": preload("res://scenes/einrichtung/riesenbrezel.tscn"), "preis": 200, "symbol": "brezn", "zeile": "EinrRiesenbrezel", "platz": "wand", "hoehe": 2.2},
	"banner": {"szene": preload("res://scenes/einrichtung/banner.tscn"), "preis": 180, "symbol": "fahne", "zeile": "EinrBanner", "platz": "wand", "hoehe": 2.0},
	"wimpel": {"szene": preload("res://scenes/einrichtung/wimpel.tscn"), "preis": 90, "symbol": "fahne", "zeile": "EinrWimpel", "platz": "wand", "hoehe": 2.6},
	# Büromöbel (fürs Zeltbüro, gebacken mit tools/bake_moebel.gd)
	"aktenschrank": {"szene": preload("res://scenes/einrichtung/aktenschrank.tscn"), "preis": 160, "symbol": "regal", "zeile": "EinrAktenschrank", "platz": "boden", "hoehe": 0.0},
	"ordnerregal": {"szene": preload("res://scenes/einrichtung/ordnerregal.tscn"), "preis": 190, "symbol": "buch", "zeile": "EinrOrdnerregal", "platz": "boden", "hoehe": 0.0},
	"buerostuhl": {"szene": preload("res://scenes/einrichtung/buerostuhl.tscn"), "preis": 80, "symbol": "tisch", "zeile": "EinrBuerostuhl", "platz": "boden", "hoehe": 0.0},
	"topfpflanze": {"szene": preload("res://scenes/einrichtung/topfpflanze.tscn"), "preis": 70, "symbol": "pflanze", "zeile": "EinrTopfpflanze", "platz": "boden", "hoehe": 0.0},
	"wanduhr": {"szene": preload("res://scenes/einrichtung/wanduhr.tscn"), "preis": 110, "symbol": "uhr", "zeile": "EinrWanduhr", "platz": "wand", "hoehe": 2.0},
	"plakat": {"szene": preload("res://scenes/einrichtung/plakat.tscn"), "preis": 90, "symbol": "bild", "zeile": "EinrPlakat", "platz": "wand", "hoehe": 1.8},
	"bueroleuchte": {"szene": preload("res://scenes/einrichtung/bueroleuchte.tscn"), "preis": 240, "symbol": "lampe", "zeile": "EinrBueroleuchte", "platz": "decke", "hoehe": 3.6},
	"teppich": {"szene": preload("res://scenes/einrichtung/teppich.tscn"), "preis": 130, "symbol": "bild", "zeile": "EinrTeppich", "platz": "boden", "hoehe": 0.0},
	"wartebank": {"szene": preload("res://scenes/einrichtung/wartebank.tscn"), "preis": 120, "symbol": "kiste", "zeile": "EinrWartebank", "platz": "boden", "hoehe": 0.0},
	"garderobe": {"szene": preload("res://scenes/einrichtung/garderobe.tscn"), "preis": 100, "symbol": "person", "zeile": "EinrGarderobe", "platz": "boden", "hoehe": 0.0},
	"kaffeeecke": {"szene": preload("res://scenes/einrichtung/kaffeeecke.tscn"), "preis": 210, "symbol": "bier", "zeile": "EinrKaffeeecke", "platz": "boden", "hoehe": 0.0},
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
