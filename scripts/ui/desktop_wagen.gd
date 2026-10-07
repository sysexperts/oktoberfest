extends Control
## Wohnwagen-App des Desktops (ab Kapitel 3): Bett verbessern und Einrichtung kaufen. Einkauf nur nach Feierabend,
## der Server bucht (GameManager.net_wagen_kauf). Aufbau: scenes/ui/desktop_wagen.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const Look := preload("res://scripts/charakter_look.gd")
const CreatorSkript := preload("res://scripts/ui/charakter_creator.gd")
const ITEMS := ["sofa", "poster", "pflanze", "regal"]
const FARBEN := ["blau", "rot", "gruen"]
const FARB_KNOEPFE := {"blau": "Blau", "rot": "Rot", "gruen": "Gruen"}

var _gm: Node
var _hud: Node

func _ready() -> void:
	%Bett.pressed.connect(func() -> void: _gm.net_wagen_kauf.rpc_id(1, "bett"))
	for id: String in ITEMS:
		var k: Button = get_node("%" + id.capitalize())
		k.pressed.connect(func() -> void: _gm.net_wagen_kauf.rpc_id(1, id))
	for f: String in FARBEN:
		var fk: Button = get_node("%Farbe" + FARB_KNOEPFE[f])
		fk.pressed.connect(func() -> void: _gm.net_wagen_farbe.rpc_id(1, f))
	%Spiegel.text = tr("WAGEN_SPIEGEL")
	%Spiegel.pressed.connect(_spiegel)

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_anzeigen()

func _process(_delta: float) -> void:
	if visible:
		_anzeigen()

func _anzeigen() -> void:
	if _gm == null:
		return
	var z: Dictionary = _hud.get("_zustand") if _hud != null else {}
	var wagen: Dictionary = Caravan.zustand_von(z, multiplayer.get_unique_id())
	var bett := int(wagen.get("bett", 1))
	var items: Array = wagen.get("items", [])
	%Prestige.text = tr("WAGEN_PRESTIGE") % int(z.get("wagen_prestige", 0))
	%BettInfo.text = tr("WAGEN_BETT") + ": " + tr("WAGEN_BETT_INFO") % [bett, (bett - 1) * 3]
	var naechste := bett + 1
	if _gm.WAGEN_BETT_PREIS.has(naechste):
		%Bett.text = tr("WAGEN_BETT_AUF") % Texte.euro(int(_gm.WAGEN_BETT_PREIS[naechste]))
		%Bett.disabled = false
	else:
		%Bett.text = tr("WAGEN_BETT_MAX")
		%Bett.disabled = true
	for id: String in ITEMS:
		var k: Button = get_node("%" + id.capitalize())
		var name := tr("WAGEN_" + id.to_upper())
		if items.has(id):
			k.text = tr("WAGEN_GEKAUFT") % name
			k.disabled = true
		else:
			k.text = tr("WAGEN_KAUFEN") % [name, Texte.euro(int(_gm.WAGEN_ITEMS[id]))]
			k.disabled = false
	var besitz: Array = wagen.get("farben", ["blau"])
	for f: String in FARBEN:
		var fk: Button = get_node("%Farbe" + FARB_KNOEPFE[f])
		var fname := tr("WAGEN_FARBE_" + f.to_upper())
		if _meine_farbe(z, wagen) == f:
			fk.text = tr("WAGEN_FARBE_AKTIV") % fname
			fk.disabled = true
		elif besitz.has(f):
			fk.text = tr("WAGEN_FARBE_WECHSELN") % fname
			fk.disabled = false
		else:
			fk.text = tr("WAGEN_KAUFEN") % [fname, Texte.euro(int(_gm.WAGEN_FARBEN[f]))]
			fk.disabled = false

## Farbe des eigenen Wagens: der Host steht in „wagen.farbe“, Mitspieler in „wagen_plaetze“
func _meine_farbe(z: Dictionary, wagen: Dictionary) -> String:
	return str(wagen.get("farbe", "blau"))

## Spiegel im Wohnwagen: der Creator öffnet sich, der neue Look geht an den Server und an alle Mitspieler
func _spiegel() -> void:
	CreatorSkript.zeigen(get_tree().root, func() -> void:
		if _gm and _gm.has_method("net_look_setzen"):
			_gm.net_look_setzen.rpc_id(1, Look.zu_code(Look.laden())))
