extends Control
## Wohnwagen-App des Desktops (ab Kapitel 3): Bett verbessern und Einrichtung kaufen. Einkauf nur nach Feierabend,
## der Server bucht (GameManager.net_wagen_kauf). Aufbau: scenes/ui/desktop_wagen.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const ITEMS := ["sofa", "poster", "pflanze", "regal"]

var _gm: Node
var _hud: Node

func _ready() -> void:
	%Bett.pressed.connect(func() -> void: _gm.net_wagen_kauf.rpc_id(1, "bett"))
	for id: String in ITEMS:
		var k: Button = get_node("%" + id.capitalize())
		k.pressed.connect(func() -> void: _gm.net_wagen_kauf.rpc_id(1, id))

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
	var wagen: Dictionary = z.get("wagen", {"bett": 1, "items": []})
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
