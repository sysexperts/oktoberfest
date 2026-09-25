extends Control
## Zelt-Computer: Bierpreis einstellen, Ware nachbestellen, Bilanz lesen,
## Zelt früher schließen. Aufbau liegt in scenes/ui/zeltcomputer.tscn.
##
## Das Fenster ist auf 1180 px Breite entworfen. Auf kleinen Bildschirmen wird
## es in _passen() als Ganzes gleichmäßig verkleinert, damit das Bild genau so
## aussieht wie entworfen und trotzdem überall hineinpasst.

const Fokus := preload("res://scripts/ui/fokus.gd")
const Texte := preload("res://scripts/ui/texte.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")

## Luft zum Bildschirmrand
const RAND := 32.0

var _gm: Node
var _z := {}
var _bilanz := {}

func _ready() -> void:
	visible = false
	%Billiger.pressed.connect(_preis.bind(-1))
	%Teurer.pressed.connect(_preis.bind(1))
	# Essenspreis (GameManager.net_set_essenpreis)
	%EssenBilliger.pressed.connect(func() -> void:
		if _gm:
			_gm.net_set_essenpreis.rpc_id(1, -1))
	%EssenTeurer.pressed.connect(func() -> void:
		if _gm:
			_gm.net_set_essenpreis.rpc_id(1, 1))
	# Ware nachbestellen geht auch während der Schicht
	%BierEins.pressed.connect(_bestellen.bind(1, 1))
	%BierFuenf.pressed.connect(_bestellen.bind(1, 5))
	%EssenEins.pressed.connect(_bestellen.bind(2, 1))
	%EssenFuenf.pressed.connect(_bestellen.bind(2, 5))
	%ZeltSchliessen.pressed.connect(func() -> void:
		if _gm:
			_gm.net_close_tent.rpc_id(1))
	%Schliessen.pressed.connect(schliessen)
	%SchliessenX.pressed.connect(schliessen)
	# Mehrspieler: Name und Farbe ändern — öffnet die Lobby erneut
	%LobbyOeffnen.pressed.connect(func() -> void:
		schliessen()
		if _gm:
			_gm.open_lobby_ui())
	Einstellungen.geaendert.connect(_neu)
	get_viewport().size_changed.connect(_passen)
	%Panel.minimum_size_changed.connect(_passen)

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
	%LobbyOeffnen.visible = not Net.solo
	_neu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Fokus.erster(self)

func schliessen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

## Fenster gleichmäßig verkleinern, bis es auf den Bildschirm passt.
func _passen() -> void:
	var panel: Control = %Panel
	var noetig := panel.get_combined_minimum_size()
	if noetig.x <= 0.0 or noetig.y <= 0.0:
		return
	var platz := get_viewport_rect().size - Vector2(RAND, RAND) * 2.0
	var f := minf(1.0, minf(platz.x / noetig.x, platz.y / noetig.y))
	panel.pivot_offset = noetig * 0.5
	panel.scale = Vector2(f, f)

func _neu() -> void:
	%Status.text = Texte.buero_status(_z)
	# Gleiche Rechnung wie GameManager._reward_for und der Andrang in _shift_process
	var faktor := float(_z.get("bierpreis", 1.0))
	var tag := int(_z.get("day", 1))
	var mass := roundi(float(Wirtschaft.verkaufspreis(Wirtschaft.BIER_BASIS, tag)) * faktor)
	var essen := Wirtschaft.verkaufspreis(Wirtschaft.ESSEN_BASIS, tag)
	%WertMass.text = tr("COMP_VAL_MASS") % Texte.euro(mass)
	%WertSnack.text = Texte.euro(essen)
	%WertFaktor.text = tr("COMP_VAL_FACTOR") % [roundi(faktor * 100.0),
		roundi(Wirtschaft.preis_andrang(faktor) * 100.0)]
	# Spielraum wächst mit den Lizenzen (GameManager.bierpreis_grenzen)
	%Billiger.disabled = faktor <= float(_z.get("preis_min", Wirtschaft.BIERPREIS_MIN)) + 0.001
	%Teurer.disabled = faktor >= float(_z.get("preis_max", Wirtschaft.BIERPREIS_MAX)) - 0.001
	# Essenspreis: Spielraum wächst mit den Essenslizenzen (GameManager.essenpreis_grenzen)
	var essen_faktor := float(_z.get("essenpreis", 1.0))
	%WertEssen.text = tr("COMP_VAL_FOOD") % [Texte.euro(roundi(float(essen) * essen_faktor)),
		roundi(essen_faktor * 100.0)]
	%EssenBilliger.disabled = essen_faktor <= float(_z.get("essen_min", 1.0)) + 0.001
	%EssenTeurer.disabled = essen_faktor >= float(_z.get("essen_max", 1.0)) - 0.001
	%EssenBilliger.modulate.a = 0.35 if %EssenBilliger.disabled else 1.0
	%EssenTeurer.modulate.a = 0.35 if %EssenTeurer.disabled else 1.0
	# Ware: gleiche Preise wie im Festbüro (GameManager.net_order_goods)
	if _gm:
		%WareText.text = tr("COMP_GOODS_STOCK") % [int(_z.get("bier", 0)), int(_z.get("essen", 0)), int(_z.get("pending", 0))]
		var ohne_zelt := int(_z.get("stage", 0)) == 0
		var lic: Dictionary = _z.get("lic", {})
		var essen_ok := bool(lic.get("brezn", false)) or bool(lic.get("sosis", false)) or bool(lic.get("hendl", false))
		for d: Array in [[%BierEins, 1, 1, "bier"], [%BierFuenf, 1, 5, "bier"], [%EssenEins, 2, 1, "brezn"], [%EssenFuenf, 2, 5, "brezn"]]:
			var knopf: Button = d[0]
			var preis: int = Wirtschaft.paketpreis(int(_gm.PACK_COST[d[1]]), tag) * int(d[2])
			(knopf.get_node("Inhalt/Kreis/Sym") as TextureRect).texture = Symbole.bild(str(d[3]))
			(knopf.get_node("Inhalt/Text") as Label).text = tr("BTN_PACKS") % [int(d[2]), Texte.euro(preis)]
			knopf.disabled = ohne_zelt or (int(d[1]) == 2 and not essen_ok)
			(knopf.get_node("Inhalt") as Control).modulate.a = 0.4 if knopf.disabled else 1.0
	# Früher schließen geht nur, solange das Zelt offen ist
	%ZeltSchliessen.disabled = not bool(_z.get("shift", false))
	(%ZeltSchliessen.get_node("Inhalt") as Control).modulate.a = 0.4 if %ZeltSchliessen.disabled else 1.0
	%BilanzText.text = Texte.bilanz(_bilanz)
	# Kurze Bilanz steht als eine Zeile im Kopf, lange Berichte bekommen Rollbalken.
	# Die Zeilen zählen wir selbst — get_minimum_size() eines umbrechenden Labels
	# meldet vor dem Layout eine viel zu große Höhe und reißt ein Loch in die Karte.
	var zeilen := str(%BilanzText.text).count("\n") + 1
	%BilanzRollen.custom_minimum_size.y = clampf(22.0 * float(zeilen), 22.0, 150.0)
	_passen()

func _bestellen(art: int, pakete: int) -> void:
	if _gm:
		_gm.net_order_goods.rpc_id(1, art, pakete)

func _preis(schritte: int) -> void:
	if _gm:
		_gm.net_set_bierpreis.rpc_id(1, schritte)
