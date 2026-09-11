extends RefCounted
## Alle kaufbaren Einrichtungsgegenstände fürs Zelt.
##
## Neuer Gegenstand: Szene unter scenes/einrichtung/ anlegen (Wurzel mit
## scripts/einrichtung.gd, Modell als Kind), hier eintragen, eine Angebotszeile
## im Wiesenbüro-Reiter „Einrichtung" (scenes/ui/wiesenbuero.tscn) mit dem Namen
## aus "zeile" anlegen und DECO_<ART> / DECO_<ART>_INFO in locale/texte.csv.
## Ohne class_name, einbinden per preload.

## art -> Szene, Preis, Symbol, Zeile im Wiesenbüro
const ARTEN := {
	"laterne": {"szene": preload("res://scenes/einrichtung/laterne.tscn"), "preis": 150, "symbol": "🏮", "zeile": "EinrLaterne"},
	"stehlampe": {"szene": preload("res://scenes/einrichtung/stehlampe.tscn"), "preis": 90, "symbol": "💡", "zeile": "EinrStehlampe"},
	"lichterkette": {"szene": preload("res://scenes/einrichtung/lichterkette.tscn"), "preis": 220, "symbol": "✨", "zeile": "EinrLichterkette"},
	"blumen": {"szene": preload("res://scenes/einrichtung/blumen.tscn"), "preis": 60, "symbol": "🌷", "zeile": "EinrBlumen"},
	"busch": {"szene": preload("res://scenes/einrichtung/busch.tscn"), "preis": 70, "symbol": "🌳", "zeile": "EinrBusch"},
}

static func name_key(art: String) -> String:
	return "DECO_%s" % art.to_upper()

static func info_key(art: String) -> String:
	return "DECO_%s_INFO" % art.to_upper()
