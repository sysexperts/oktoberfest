extends Control
## Wiesenbüro: Zelt · Lizenzen · Personal · Künstler · Ware · Bilanz.
## Aufbau liegt in scenes/ui/wiesenbuero.tscn, jede Zeile ist ein angebot.tscn.
## Hier steht nur, was die Zeilen anzeigen und was ihre Knöpfe auslösen.
##
## Gesperrte Knöpfe nennen den Grund. Es sind dieselben Regeln, die der Server
## beim Kauf prüft (GameManager: _afford, _reserve_ok, Zeltstufe, Tischgrenze) —
## ändert sich dort etwas, muss es hier mitgeändert werden.

const Texte := preload("res://scripts/ui/texte.gd")
const REITER_TITEL := ["OFFICE_TAB_TENT", "OFFICE_TAB_LICENSES", "OFFICE_TAB_STAFF",
	"OFFICE_TAB_ACTS", "OFFICE_TAB_GOODS", "OFFICE_TAB_REPORT", "OFFICE_TAB_GOALS"]
const Meilensteine := preload("res://scripts/meilensteine.gd")
const MEILENSTEIN_ZEILE := preload("res://scenes/ui/meilenstein_zeile.tscn")
## Lizenz -> [Zeile, Symbol, Name]
const LIZENZEN := {
	"weizen": ["LizenzWeizen", "🍺", "LIC_WEIZEN"],
	"radler": ["LizenzRadler", "🍋", "LIC_RADLER"],
	"brezn": ["LizenzBrezn", "🥨", "LIC_BREZN"],
	"sosis": ["LizenzSosis", "🌭", "LIC_SOSIS"],
}
## Rolle -> [Zeile, Symbol, Name, Beschreibung]
const PERSONAL := {
	1: ["Koch", "👨‍🍳", "STAFF_COOK", "STAFF_INFO_COOK"],
	2: ["Kellner", "🍺", "STAFF_WAITER", "STAFF_INFO_WAITER"],
	3: ["Reinigung", "🧹", "STAFF_CLEANER", "STAFF_INFO_CLEANER"],
}
## Stufe -> [Zeile, Symbol]
const KUENSTLER := {1: ["Strassenmusiker", "🎸"], 2: ["Blaskapelle", "🎺"], 3: ["StarAct", "⭐"]}
## Sorte -> [Zeile, Symbol, Name]
const WARE := {1: ["Bier", "🍺", "GOODS_BEER"], 2: ["Zutaten", "🥨", "GOODS_FOOD"]}
const PAKETE := [1, 5, 10]
## Tutorialschritt -> [Reiter, Zeile]; Schritte wie in GameManager._quest_done.
const TUTORIAL_ZIEL := {
	0: [0, "ZeltMieten"], 1: [0, "TischStellen"], 2: [4, "Bier"],
	7: [2, "Kellner"], 8: [1, "LizenzWeizen"], 9: [0, "Toilette"], 10: [3, "Strassenmusiker"],
}

@onready var _reiter: TabContainer = %Reiter

var _gm: Node
## Zustand vom Server (GameManager._buero_state)
var _z := {}
var _bilanz := {}
var _geld := 0
var _schritt := -1

func _ready() -> void:
	visible = false
	%Schliessen.pressed.connect(schliessen)
	_verbinde("ZeltMieten", func(_i: int) -> void: _rpc("net_book_tent"))
	_verbinde("TischStellen", func(_i: int) -> void: _rpc("net_buy_table"))
	_verbinde("TischVerkaufen", func(_i: int) -> void: _rpc("net_sell_table"))
	_verbinde("ZeltVergroessern", func(_i: int) -> void: _rpc("net_upgrade_tent"))
	_verbinde("Toilette", func(_i: int) -> void: _rpc("net_buy_toilet"))
	_verbinde("Werbung", func(_i: int) -> void: _rpc("net_buy_marketing"))
	_verbinde("Deko", func(_i: int) -> void: _rpc("net_buy_deko"))
	for key: String in LIZENZEN:
		_verbinde(LIZENZEN[key][0], func(_i: int) -> void: _rpc("net_buy_license", [key]))
	for rolle: int in PERSONAL:
		_verbinde(PERSONAL[rolle][0], func(i: int) -> void:
			_rpc("net_hire_staff" if i == 0 else "net_upgrade_staff", [rolle]))
	for stufe: int in KUENSTLER:
		_verbinde(KUENSTLER[stufe][0], func(_i: int) -> void: _rpc("net_book_artist", [stufe]))
	for sorte: int in WARE:
		_verbinde(WARE[sorte][0], func(i: int) -> void: _rpc("net_order_goods", [sorte, PAKETE[i]]))
	Einstellungen.geaendert.connect(_neu)

func einrichten(gm: Node) -> void:
	_gm = gm
	_neu()

func setze_zustand(z: Dictionary) -> void:
	_z = z
	_neu()

func setze_geld(v: int) -> void:
	_geld = v
	if visible:
		_neu()

func setze_bilanz(b: Dictionary) -> void:
	_bilanz = b
	%BilanzText.text = Texte.bilanz(b)

## Tutorial: passende Zeile golden hervorheben, beim Öffnen deren Reiter zeigen.
func tutorial_schritt(schritt: int) -> void:
	_schritt = schritt
	for ziel: Array in TUTORIAL_ZIEL.values():
		_zeile(ziel[1]).hervorheben(TUTORIAL_ZIEL.get(schritt, []) == ziel)

func oeffnen() -> void:
	visible = true
	_neu()
	if TUTORIAL_ZIEL.has(_schritt):
		_reiter.current_tab = TUTORIAL_ZIEL[_schritt][0]
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func schliessen() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func ist_offen() -> bool:
	return visible

# ------------------------------------------------------------ Anzeige
func _neu() -> void:
	if _gm == null:
		return
	for i in mini(REITER_TITEL.size(), _reiter.get_tab_count()):
		_reiter.set_tab_title(i, tr(REITER_TITEL[i]))
	%Geld.text = "💶 " + Texte.euro(_geld)
	%Geld.add_theme_color_override("font_color", Color(1, 0.42, 0.35) if _geld < 0 else Color(0.949, 0.933, 0.902))
	%Status.text = Texte.buero_status(_z)
	var stufe := int(_z.get("stage", 0))
	var ohne_zelt := tr("WHY_NEED_TENT") if stufe == 0 else ""
	_reiter_zelt(stufe, ohne_zelt)
	_reiter_lizenzen()
	_reiter_personal()
	_reiter_kuenstler()
	_reiter_ware(ohne_zelt)
	_reiter_ziele()
	%BilanzText.text = Texte.bilanz(_bilanz)

func _reiter_zelt(stufe: int, ohne_zelt: String) -> void:
	var tische := int(_z.get("tables", 0))
	var limit := int(_z.get("limit", 0))

	var z := _zeile("ZeltMieten")
	z.setze("🎪 " + tr("OFFER_TENT_RENT"), tr("OFFER_TENT_RENT_INFO"))
	if stufe > 0:
		_erledigt(z, "DONE_RENTED")
	else:
		_einzelkauf(z, "BTN_RENT", int(_gm.TENT_BOOK_COST), "", false)

	z = _zeile("TischStellen")
	z.setze("🪑 " + tr("OFFER_TABLE"), tr("OFFER_TABLE_INFO") % [tische, limit])
	var sperre := ohne_zelt
	if sperre == "" and tische >= limit:
		sperre = tr("WHY_TABLE_LIMIT") % limit
	# Die ersten zwei Tische sind Pflicht — dafür gilt die Warenreserve nicht
	_einzelkauf(z, "BTN_PLACE", int(_gm.TABLE_COST), sperre, tische >= 2)

	z = _zeile("TischVerkaufen")
	z.setze("🗑 " + tr("OFFER_TABLE_SELL"), tr("OFFER_TABLE_SELL_INFO"))
	z.knopf(0, tr("BTN_SELL") % Texte.euro(int(_gm.TABLE_COST) / 2), tische <= 0)
	z.grund(tr("WHY_NO_TABLES") if tische <= 0 else "")

	z = _zeile("ZeltVergroessern")
	var naechste := stufe + 1
	if stufe == 0:
		z.setze("⬆ " + tr("OFFER_TENT_UPGRADE"), "")
		z.knopf(0, tr("BTN_UPGRADE_PLAIN"), true)
		z.grund(ohne_zelt)
	elif not _gm.TENT_UPGRADE_COST.has(naechste):
		z.setze("⬆ " + tr("OFFER_TENT_UPGRADE"), "")
		_erledigt(z, "WHY_MAX_TENT")
	else:
		z.setze("⬆ " + tr("OFFER_TENT_UPGRADE"), tr("OFFER_TENT_UPGRADE_INFO") % [
			tr("TENT_STAGE_%d" % naechste), int(_gm.TENT_TABLE_LIMIT[naechste])])
		_einzelkauf(z, "BTN_BUY", int(_gm.TENT_UPGRADE_COST[naechste]))

	z = _zeile("Toilette")
	z.setze("🚻 " + tr("OFFER_TOILET"), tr("OFFER_TOILET_INFO"))
	if bool(_z.get("toilet", false)):
		_erledigt(z, "DONE_INSTALLED")
	else:
		_einzelkauf(z, "BTN_BUY", int(_gm.TOILET_COST), ohne_zelt)

	var werbung := int(_z.get("mkt", 0))
	z = _zeile("Werbung")
	z.setze("📣 " + tr("OFFER_MARKETING"), tr("OFFER_MARKETING_INFO") % [werbung, roundi(float(_gm.MARKETING_BOOST))])
	_einzelkauf(z, "BTN_BUY", int(_gm.MARKETING_COST) * (werbung + 1))

	var deko := int(_z.get("deko", 0))
	z = _zeile("Deko")
	z.setze("🎨 " + tr("OFFER_DEKO"), tr("OFFER_DEKO_INFO") % [deko, roundi(float(_gm.DEKO_BONUS) * 100.0)])
	_einzelkauf(z, "BTN_BUY", int(_gm.DEKO_COST) * (deko + 1))

func _reiter_lizenzen() -> void:
	var lic: Dictionary = _z.get("lic", {})
	for key: String in LIZENZEN:
		var d: Array = LIZENZEN[key]
		var z := _zeile(d[0])
		z.setze("%s %s" % [d[1], tr(d[2])], tr("LIC_INFO"))
		if bool(lic.get(key, false)):
			_erledigt(z, "DONE_OWNED")
		else:
			_einzelkauf(z, "BTN_BUY", int(_gm.LIC_COST[key]))

func _reiter_personal() -> void:
	var stufen := {1: [], 2: [], 3: []}
	for e: Array in _z.get("staff", []):
		if stufen.has(int(e[0])):
			(stufen[int(e[0])] as Array).append(int(e[1]))
	for rolle: int in PERSONAL:
		var d: Array = PERSONAL[rolle]
		var z := _zeile(d[0])
		var lv: Array = stufen[rolle]
		lv.sort()
		var im_dienst: String = tr("STAFF_NONE") if lv.is_empty() else \
			tr("STAFF_COUNT") % [lv.size(), ", ".join(lv.map(func(x: int) -> String: return str(x)))]
		z.setze("%s %s" % [d[1], tr(d[2])], "%s\n%s · %s" % [
			tr(d[3]), tr("STAFF_WAGE") % Texte.euro(int(_gm.STAFF_WAGE_BASE[rolle])),
			tr("STAFF_EMPLOYED") % im_dienst])
		var einstellen := int(_gm.STAFF_HIRE_COST[rolle])
		var grund_einstellen := _kauf_grund(einstellen)
		z.knopf(0, tr("BTN_HIRE") % Texte.euro(einstellen), grund_einstellen != "")
		var aufstufbar := lv.filter(func(x: int) -> bool: return x < int(_gm.STAFF_MAX_LEVEL))
		var grund_aufstufen := ""
		if lv.is_empty():
			grund_aufstufen = tr("WHY_NO_STAFF")
			z.knopf(1, tr("BTN_UPGRADE_PLAIN"), true)
		elif aufstufbar.is_empty():
			grund_aufstufen = tr("WHY_STAFF_MAX")
			z.knopf(1, tr("BTN_UPGRADE_PLAIN"), true)
		else:
			var kosten := int(_gm.STAFF_UPGRADE_BASE) * int(aufstufbar.min())
			grund_aufstufen = _kauf_grund(kosten)
			z.knopf(1, tr("BTN_UPGRADE") % Texte.euro(kosten), grund_aufstufen != "")
		z.grund(grund_einstellen if grund_einstellen != "" else grund_aufstufen)

func _reiter_kuenstler() -> void:
	var gebucht := int(_z.get("artist", 0))
	for stufe: int in KUENSTLER:
		var d: Array = KUENSTLER[stufe]
		var z := _zeile(d[0])
		z.setze("%s %s" % [d[1], tr("ACT_%d" % stufe)], tr("ACT_INFO") % [
			roundi(float(_gm.ARTIST_DRAW[stufe]) * 100.0), roundi(float(_gm.ARTIST_POP[stufe]))])
		var sperre: String = tr("WHY_ACT_BOOKED") % tr("ACT_%d" % gebucht) if gebucht > 0 else ""
		_einzelkauf(z, "BTN_BOOK", int(_gm.ARTIST_COST[stufe]), sperre)

func _reiter_ware(ohne_zelt: String) -> void:
	for sorte: int in WARE:
		var d: Array = WARE[sorte]
		var z := _zeile(d[0])
		var preis := int(_gm.PACK_COST[sorte])
		var bestand := int(_z.get("bier" if sorte == 1 else "essen", 0))
		z.setze("%s %s" % [d[1], tr(d[2])], "%s\n%s" % [
			tr("GOODS_INFO") % [int(_gm.PACK_UNITS), Texte.euro(preis)],
			tr("GOODS_STOCK") % [bestand, int(_z.get("pending", 0))]])
		var erster_grund := ""
		for i in PAKETE.size():
			var kosten: int = preis * int(PAKETE[i])
			var g := _kauf_grund(kosten, ohne_zelt, false)
			z.knopf(i, tr("BTN_PACKS") % [PAKETE[i], Texte.euro(kosten)], g != "")
			if erster_grund == "":
				erster_grund = g
		z.grund(erster_grund)

## Meilensteine mit Fortschritt. Die Zeilen entstehen aus Meilensteine.LISTE —
## ein neuer Meilenstein erscheint so ohne Szenenänderung.
func _reiter_ziele() -> void:
	var liste: VBoxContainer = %ZieleListe
	if liste.get_child_count() != Meilensteine.LISTE.size():
		for c in liste.get_children():
			liste.remove_child(c)
			c.queue_free()
		for m in Meilensteine.LISTE:
			liste.add_child(MEILENSTEIN_ZEILE.instantiate())
	var stats: Dictionary = _z.get("stats", {})
	var erreicht: Array = _z.get("ms", [])
	for i in Meilensteine.LISTE.size():
		var m: Dictionary = Meilensteine.LISTE[i]
		liste.get_child(i).setze(tr("MS_%s_TITLE" % m.id), tr("MS_%s_TEXT" % m.id),
			Meilensteine.wert_von(m.wert, stats, _z), int(m.ziel),
			Texte.euro(int(m.belohnung)), erreicht.has(m.id))

# ------------------------------------------------------------ Helfer
## Warum ein Kauf gerade nicht geht — "" wenn er geht.
func _kauf_grund(kosten: int, sperre := "", mit_reserve := true) -> String:
	if sperre != "":
		return sperre
	var dispo := int(_gm.OVERDRAFT_LIMIT)
	if _geld - kosten < -dispo:
		return tr("WHY_MONEY") % Texte.euro(-dispo)
	if mit_reserve and _braucht_ware() and _geld - kosten < int(_gm.GOODS_RESERVE):
		return tr("WHY_RESERVE")
	return ""

func _einzelkauf(z: Node, knopf_schluessel: String, kosten: int, sperre := "", mit_reserve := true) -> void:
	var g := _kauf_grund(kosten, sperre, mit_reserve)
	z.knopf(0, tr(knopf_schluessel) % Texte.euro(kosten), g != "")
	z.grund(g)

func _erledigt(z: Node, schluessel: String) -> void:
	z.knopf(0, tr(schluessel), true)
	z.grund("")

## Kein Bier im Lager und keine Lieferung unterwegs (wie GameManager._needs_goods).
func _braucht_ware() -> bool:
	return int(_z.get("bier", 0)) <= 0 and int(_z.get("pending", 0)) == 0

func _zeile(name: String) -> Node:
	return get_node("%" + name)

func _verbinde(zeile: String, aktion: Callable) -> void:
	_zeile(zeile).gedrueckt.connect(aktion)

func _rpc(methode: String, args: Array = []) -> void:
	if _gm and _gm.has_method(methode):
		_gm.callv("rpc_id", [1, methode] + args)
