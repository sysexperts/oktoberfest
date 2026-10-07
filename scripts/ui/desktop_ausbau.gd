extends Control
## Ausbau-App des Desktops (ab Kapitel 5): große Investitionen fürs Zelt, einmal kaufen und dauerhaft wirksam.
## Der Server bucht (GameManager.net_ausbau_kauf). Aufbau: scenes/ui/desktop_ausbau.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const IDS := ["biergarten", "vip", "theke2", "buehne", "handel", "konrad"]

func _name(id: String) -> String:
	return id[0].to_upper() + id.substr(1)

var _gm: Node
var _hud: Node

func _ready() -> void:
	for id: String in IDS:
		var k: Button = get_node("%" + _name(id))
		k.pressed.connect(func() -> void: _gm.net_ausbau_kauf.rpc_id(1, id))

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
	var da: Array = z.get("ausbau", [])
	for id: String in IDS:
		var k: Button = get_node("%" + _name(id))
		var t: Label = get_node("%" + _name(id) + "Text")
		t.text = tr("AUSBAU_" + id.to_upper()) + " – " + tr("AUSBAU_" + id.to_upper() + "_INFO")
		if da.has(id):
			k.text = tr("AUSBAU_DA")
			k.disabled = true
		else:
			k.text = tr("AUSBAU_KAUFEN") % Texte.euro(int(_gm.AUSBAU[id]))
			k.disabled = false
