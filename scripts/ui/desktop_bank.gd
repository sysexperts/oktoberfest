extends Control
## Bank-App des Desktops: Kontostand, Rettungskredit und Kontoauszug (eine Zeile je Tagesabrechnung).
## Zahlen kommen aus Game.money, dem Zustand des HUD und GameManager.konto_verlauf. Aufbau: scenes/ui/desktop_bank.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
const ROTSTIL := preload("res://scenes/ui/bank_streifen_rot.tres")
const ZEILE := preload("res://scenes/ui/konto_zeile.tscn")

var _gm: Node
var _gruen: StyleBox
var _gruen_text: Color
var _hud: Node
var _stand := -999999999
var _kredit := -1
var _zeilen := -1

func einrichten(gm: Node, hud: Node) -> void:
	_gruen = %Kredit.get_theme_stylebox("panel")
	_gruen_text = %KreditStand.get_theme_color("font_color")
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_stand = -999999999
	_kredit = -1
	_zeilen = -1
	_pruefen()

func _process(_delta: float) -> void:
	if visible:
		_pruefen()

func _verlauf() -> Array:
	return _gm.get("konto_verlauf") if _gm != null else []

func _pruefen() -> void:
	var verlauf := _verlauf()
	var zustand: Dictionary = _hud.get("_zustand") if _hud != null else {}
	var kredit := int(zustand.get("kredit", 0))
	if Game.money != _stand or kredit != _kredit or verlauf.size() != _zeilen:
		_stand = Game.money
		_kredit = kredit
		_zeilen = verlauf.size()
		_anzeigen(verlauf)

func _anzeigen(verlauf: Array) -> void:
	%Stand.text = Texte.euro(_stand)
	%Tag.text = tr("BANK_TAG") % int(_gm.get("_day"))
	%TrendPille.visible = not verlauf.is_empty()
	if not verlauf.is_empty():
		%Trend.text = tr("BANK_LETZTER_TAG") % _mit_vorzeichen(_ergebnis(verlauf[verlauf.size() - 1]))
	var tage: Array = []
	var werte: Array = []
	for b: Dictionary in verlauf.slice(maxi(0, verlauf.size() - 7)):
		tage.append(int(b.get("day", 0)))
		werte.append(_ergebnis(b))
	%Diagramm.setze(tage, werte)
	if _kredit > 0:
		%KreditStand.text = Texte.euro(_kredit)
		%KreditStand.add_theme_color_override("font_color", Color(1, 0.55, 0.52))
		%KreditInfo.text = tr("BANK_KREDIT_OFFEN") % roundi(Wirtschaft.KREDIT_ANTEIL * 100.0)
		%Kredit.add_theme_stylebox_override("panel", ROTSTIL)
	else:
		%KreditStand.text = tr("BANK_KREDIT_KEINER")
		%KreditStand.add_theme_color_override("font_color", _gruen_text)
		%KreditInfo.text = tr("BANK_KREDIT_INFO")
		%Kredit.add_theme_stylebox_override("panel", _gruen)
	for k in %Liste.get_children():
		k.queue_free()
	%Leer.visible = verlauf.is_empty()
	for i in range(verlauf.size() - 1, -1, -1):
		var b: Dictionary = verlauf[i]
		var z := ZEILE.instantiate()
		%Liste.add_child(z)
		var plus := _ergebnis(b)
		z.setze(tr("BANK_TAG") % int(b.get("day", 0)), Texte.euro(_einnahmen(b)), Texte.euro(-_ausgaben(b)), _mit_vorzeichen(plus), plus >= 0)

func _mit_vorzeichen(betrag: int) -> String:
	return ("+" if betrag > 0 else "") + Texte.euro(betrag)

## Einnahmen eines Tages: Verkauf, Tagesziel-Lohn, gewonnene Wette
func _einnahmen(b: Dictionary) -> int:
	return int(b.get("earn", 0)) + maxi(0, int(b.get("ziel", 0))) + maxi(0, int(b.get("wette", 0)))

## Ausgaben: Miete, Löhne, Ware, Zinsen, Kredit-Tilgung, Bankrate, verlorene Wette
func _ausgaben(b: Dictionary) -> int:
	return int(b.get("rent", 0)) + int(b.get("wages", 0)) + int(b.get("goods", 0)) + int(b.get("interest", 0)) \
		+ int(b.get("loan", 0)) + int(b.get("bank", 0)) + maxi(0, -int(b.get("wette", 0)))

func _ergebnis(b: Dictionary) -> int:
	return _einnahmen(b) - _ausgaben(b)
