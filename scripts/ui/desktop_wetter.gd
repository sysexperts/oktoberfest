extends Control
## Wetter-und-Amt-App des Desktops: Wetter von heute, Vorhersage der nächsten Tage (mit angekündigten Ereignissen wie Regen
## oder Hygienekontrolle) und der Stand der Genehmigungen (Zelt, Toiletten, Lizenzen). Daten: HUD-Zustand (Plan, Zelt, Lizenzen).
## Aufbau: scenes/ui/desktop_wetter.tscn. Das Wetter selbst folgt dem Ereignisplan, Temperatur und Sonne/Wolken sind Dekoration.

const Texte := preload("res://scripts/ui/texte.gd")
const Wirtschaft := preload("res://scripts/wirtschaft.gd")
const TAG := preload("res://scenes/ui/wetter_tag.tscn")
const CHIP_GUT := preload("res://scenes/ui/amt_chip_gut.tres")
const CHIP_WARN := preload("res://scenes/ui/amt_chip_warn.tres")
const VORSCHAU_TAGE := 5
const LIZENZEN := 6

var _gm: Node
var _hud: Node
var _stand := ""

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_stand = ""
	_pruefen()

func _process(_delta: float) -> void:
	if visible:
		_pruefen()

## Nur neu aufbauen, wenn sich etwas geändert hat
func _pruefen() -> void:
	var z: Dictionary = _hud.get("_zustand") if _hud != null else {}
	var stand := "%s|%s|%s|%s|%s" % [z.get("day", 1), z.get("stage", 0), z.get("toilet", false), z.get("lic", {}), z.get("plan", [])]
	if stand == _stand:
		return
	_stand = stand
	_anzeigen(z)

## Ereignis laut Plan für einen Spieltag
func _ereignis(z: Dictionary, tag: int) -> String:
	var plan: Array = z.get("plan", [])
	var i := Wirtschaft.saison_tag(tag) - 1
	return str(plan[i]) if i >= 0 and i < plan.size() else ""

func _art(tag: int, ereignis: String) -> String:
	if ereignis == "regen":
		return "regen"
	return "sonne" if (tag * 37 + 11) % 10 < 6 else "wolkig"

func _temp(tag: int, art: String) -> int:
	return 15 + (tag * 3) % 9 + (3 if art == "sonne" else 0) - (5 if art == "regen" else 0)

func _ereignis_titel(ereignis: String) -> String:
	return tr("EREIGNIS_%s_TITEL" % ereignis.to_upper()) if ereignis != "" else ""

func _anzeigen(z: Dictionary) -> void:
	var heute := int(z.get("day", 1))
	var e := _ereignis(z, heute)
	var art := _art(heute, e)
	%Symbol.setze(art)
	%Temp.text = tr("WETTER_TEMP") % _temp(heute, art)
	%Zustand.text = tr("WETTER_" + art.to_upper())
	%Ereignis.text = _ereignis_titel(e) if e != "" else tr("WETTER_NORMAL")
	for k in %Tage.get_children():
		k.queue_free()
	var kontrolle := -1
	for i in range(1, VORSCHAU_TAGE + 1):
		var tag := heute + i
		var ev := _ereignis(z, tag)
		var a := _art(tag, ev)
		var karte := TAG.instantiate()
		%Tage.add_child(karte)
		karte.setze(tr("WETTER_TAG") % tag, a, tr("WETTER_TEMP") % _temp(tag, a), _ereignis_titel(ev))
		if ev == "kontrolle" and kontrolle < 0:
			kontrolle = tag
	if e == "kontrolle":
		kontrolle = heute
	%Kontrolle.visible = kontrolle > 0
	if kontrolle > 0:
		%KontrolleText.text = tr("AMT_KONTROLLE") % kontrolle
	_chip(%ZeltChip, %ZeltText, int(z.get("stage", 0)) > 0, "AMT_OK", "AMT_FEHLT")
	_chip(%ToiletteChip, %ToiletteText, bool(z.get("toilet", false)), "AMT_OK", "AMT_FEHLT")
	var lic := 0
	for k: String in (z.get("lic", {}) as Dictionary):
		if bool(z["lic"][k]):
			lic += 1
	_chip(%LizenzenChip, %LizenzenText, lic >= LIZENZEN, "", "", tr("AMT_LIZ_STAND") % [lic, LIZENZEN])

func _chip(chip: PanelContainer, text: Label, gut: bool, ja: String, nein: String, frei := "") -> void:
	chip.add_theme_stylebox_override("panel", CHIP_GUT if gut else CHIP_WARN)
	text.text = frei if frei != "" else tr(ja if gut else nein)
