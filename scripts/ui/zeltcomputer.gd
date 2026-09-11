extends Control
## Zelt-Computer: Bierpreis einstellen, Bilanz lesen, Zelt früher schließen.
## Aufbau liegt in scenes/ui/zeltcomputer.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")

var _gm: Node
var _z := {}
var _bilanz := {}

func _ready() -> void:
	visible = false
	%Billiger.pressed.connect(_preis.bind(-1))
	%Teurer.pressed.connect(_preis.bind(1))
	# Ware nachbestellen geht auch während der Schicht
	%BierEins.pressed.connect(_bestellen.bind(1, 1))
	%BierFuenf.pressed.connect(_bestellen.bind(1, 5))
	%EssenEins.pressed.connect(_bestellen.bind(2, 1))
	%EssenFuenf.pressed.connect(_bestellen.bind(2, 5))
	%ZeltSchliessen.pressed.connect(func() -> void:
		if _gm:
			_gm.net_close_tent.rpc_id(1))
	%Schliessen.pressed.connect(schliessen)
	Einstellungen.geaendert.connect(_neu)

func einrichten(gm: Node) -> void:
	_gm = gm

func setze_zustand(z: Dictionary) -> void:
	_z = z
	_neu()

func setze_bilanz(b: Dictionary) -> void:
	_bilanz = b
	_neu()

func oeffnen() -> void:
	visible = true
	_neu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func schliessen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

func _neu() -> void:
	%Status.text = Texte.buero_status(_z)
	# Gleiche Rechnung wie GameManager._reward_for und der Andrang in _shift_process
	var faktor := float(_z.get("bierpreis", 1.0))
	var tag := int(_z.get("day", 1))
	var mass := roundi(float(Wirtschaft.verkaufspreis(Wirtschaft.BIER_BASIS, tag)) * faktor)
	var essen := Wirtschaft.verkaufspreis(Wirtschaft.ESSEN_BASIS, tag)
	%PreisText.text = tr("COMP_PRICE_VALUE") % [Texte.euro(mass), Texte.euro(essen),
		roundi(faktor * 100.0), roundi(Wirtschaft.preis_andrang(faktor) * 100.0)]
	%Billiger.disabled = faktor <= Wirtschaft.BIERPREIS_MIN + 0.001
	%Teurer.disabled = faktor >= Wirtschaft.BIERPREIS_MAX - 0.001
	# Ware: gleiche Preise wie im Wiesenbüro (GameManager.net_order_goods)
	if _gm:
		%WareText.text = tr("COMP_GOODS_STOCK") % [int(_z.get("bier", 0)), int(_z.get("essen", 0)), int(_z.get("pending", 0))]
		var ohne_zelt := int(_z.get("stage", 0)) == 0
		var lic: Dictionary = _z.get("lic", {})
		var essen_ok := bool(lic.get("brezn", false)) or bool(lic.get("sosis", false))
		for d: Array in [[%BierEins, 1, 1, "🍺"], [%BierFuenf, 1, 5, "🍺"], [%EssenEins, 2, 1, "🥨"], [%EssenFuenf, 2, 5, "🥨"]]:
			var preis: int = Wirtschaft.paketpreis(int(_gm.PACK_COST[d[1]]), tag) * int(d[2])
			(d[0] as Button).text = "%s %s" % [d[3], tr("BTN_PACKS") % [int(d[2]), Texte.euro(preis)]]
			(d[0] as Button).disabled = ohne_zelt or (int(d[1]) == 2 and not essen_ok)
	# Früher schließen geht nur, solange das Zelt offen ist
	%ZeltSchliessen.disabled = not bool(_z.get("shift", false))
	%BilanzText.text = Texte.bilanz(_bilanz)

func _bestellen(art: int, pakete: int) -> void:
	if _gm:
		_gm.net_order_goods.rpc_id(1, art, pakete)

func _preis(schritte: int) -> void:
	if _gm:
		_gm.net_set_bierpreis.rpc_id(1, schritte)
