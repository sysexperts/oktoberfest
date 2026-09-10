class_name HUD
extends CanvasLayer
## Oyun içi arayüz. Aufbau liegt in scenes/ui/hud.tscn — Leiste oben links
## (Geld · Tag und Uhrzeit · Beliebtheit, darunter Lager und Sauberkeit),
## Aufgabe rechts, Fadenkreuz mit Hinweis, Wiesenbüro, Zelt-Computer,
## Hinweisfenster, Schlaf-Abblende.
## Die Werte kommen vom GameManager; hier wird nur angezeigt. Jeder Wert wird
## gemerkt, damit ein Sprachwechsel alles neu beschriften kann.

const Texte := preload("res://scripts/ui/texte.gd")
const ROT := Color(1, 0.42, 0.35)
const GOLD := Color(1, 0.839, 0.349)
const WEISS := Color(0.949, 0.933, 0.902)

@onready var _geld: Label = %Geld
@onready var _zeit: Label = %Zeit
@onready var _beliebtheit: ProgressBar = %Beliebtheit
@onready var _beliebtheit_wert: Label = %BeliebtheitWert
@onready var _lager: Label = %Lager
@onready var _sauberkeit: ProgressBar = %Sauberkeit
@onready var _sauberkeit_wert: Label = %SauberkeitWert
@onready var _rollen: Control = %Rollen
@onready var _aufgabe: Control = %Aufgabe
@onready var _banner: Label = %Banner
@onready var _hinweisfenster: Control = %Hinweisfenster
@onready var _buero: Control = %Wiesenbuero
@onready var _computer: Control = %Zeltcomputer

# Zuletzt gemeldete Werte
var _money := 0
var _clock := -1.0
var _night := false
var _day := 1
var _pop := 0.0
var _hygiene := 100.0
var _bier := 0
var _essen := 0
var _quest_step := -1
var _quest_total := 0
var _hint_key := ""
var _zustand := {}

var _banner_token := 0
var _erledigt_token := 0

func _ready() -> void:
	%HinweisfensterOk.pressed.connect(close_popup)
	_buero.einrichten(get_parent())
	_computer.einrichten(get_parent())
	Einstellungen.geaendert.connect(_alles_neu)
	_alles_neu()

func _alles_neu() -> void:
	set_money(_money)
	set_time(_clock, _night)
	set_popularity(_pop)
	set_hygiene(_hygiene)
	set_stock(_bier, _essen)
	set_quest(_quest_step, _quest_total)
	set_hint(_hint_key)
	set_buero(_zustand)

# ------------------------------------------------------------ Fadenkreuz
## Hinweis unter dem Fadenkreuz. key: Übersetzungsschlüssel, "" = ausblenden.
## Hinweise mit Taste sind Handlungen (hell), ohne Taste nur Auskunft (gedämpft).
func set_hint(key: String) -> void:
	_hint_key = key
	%Hinweis.visible = key != ""
	if key == "":
		return
	var hinweis: Label = %HinweisText
	hinweis.text = Texte.mit_tasten(key)
	var handlung := tr(key).contains("{")
	hinweis.add_theme_color_override("font_color", WEISS if handlung else Color(0.72, 0.7, 0.82))

# ------------------------------------------------------------ Leiste
func set_money(v: int) -> void:
	_money = v
	_geld.text = "💶 " + Texte.euro(v)
	# Dispo: bis -1000 € erlaubt, Rückzahlung kostet 5 % Zinsen
	_geld.add_theme_color_override("font_color", ROT if v < 0 else WEISS)
	_buero.setze_geld(v)

## Punkte werden nicht mehr angezeigt — Geld und Beliebtheit sagen mehr.
func set_score(_v: int) -> void:
	pass

## clock: Spieluhr (7.0 = 07:00). Negativ = Zelt geschlossen.
func set_time(clock: float, night: bool = false) -> void:
	_clock = clock
	_night = night
	var tag := tr("HUD_DAY") % _day
	if clock < 0.0:
		_zeit.text = "%s · %s" % [tag, tr("HUD_CLOSED")]
		_zeit.add_theme_color_override("font_color", Color(0.72, 0.75, 0.88))
		return
	var h := int(clock)
	var m := int((clock - float(h)) * 60.0)
	_zeit.text = "%s · %s %02d:%02d" % [tag, "🌙" if night else "🕗", h, m]
	_zeit.add_theme_color_override("font_color", Color(0.72, 0.78, 1) if night else WEISS)

func set_day(day: int, _total: int = 0) -> void:
	_day = day
	set_time(_clock, _night)

## Geöffnet/geschlossen steckt schon in der Uhrzeit (set_time mit -1).
func set_phase(_offen: bool) -> void:
	pass

func set_popularity(v: float) -> void:
	_pop = v
	_beliebtheit.value = v
	_beliebtheit_wert.text = "%d %%" % roundi(v)

func set_hygiene(v: float) -> void:
	_hygiene = v
	_sauberkeit.value = v
	_sauberkeit_wert.text = "%d %%" % roundi(v)
	var schmutzig := v <= 40.0
	_sauberkeit_wert.add_theme_color_override("font_color", ROT if schmutzig else WEISS)
	_balken_farbe(_sauberkeit, ROT if schmutzig else GOLD)

func set_stock(bier: int, essen: int) -> void:
	_bier = bier
	_essen = essen
	_lager.text = "🍺 %d · 🥨 %d" % [bier, essen]
	_lager.add_theme_color_override("font_color", WEISS if (bier > 0 or essen > 0) else ROT)

## Füllfarbe eines Balkens, ohne das Theme für alle anderen zu ändern.
func _balken_farbe(balken: ProgressBar, farbe: Color) -> void:
	var box := balken.get_theme_stylebox("fill")
	if not balken.has_theme_stylebox_override("fill"):
		box = box.duplicate()
		balken.add_theme_stylebox_override("fill", box)
	if box is StyleBoxFlat:
		(box as StyleBoxFlat).bg_color = farbe

# ------------------------------------------------------------ Zustand vom Server
## Zelt, Personal, Lizenzen, Rollen … (GameManager._buero_state).
func set_buero(z: Dictionary) -> void:
	_zustand = z
	_buero.setze_zustand(z)
	_computer.setze_zustand(z)
	# Rollenliste — nur im Koop sinnvoll
	var roles: Dictionary = z.get("roles", {})
	%RollenText.text = Texte.rollen(roles)
	_rollen.visible = not Net.solo and not roles.is_empty()

## Tagesbilanz (Zahlen, übersetzt wird hier).
func set_report(b: Dictionary) -> void:
	_buero.setze_bilanz(b)
	_computer.setze_bilanz(b)

# ------------------------------------------------------------ Aufgabe
## step: aktueller Tutorialschritt, total: Anzahl. step >= total = fertig.
func set_quest(step: int, total: int) -> void:
	var vorher := _quest_step
	_quest_step = step
	_quest_total = total
	# Haken nur für echten Fortschritt — nicht beim ersten Setzen nach dem Laden
	# und nicht, wenn Überspringen mitten im Tutorial ans Ende springt.
	var uebersprungen := step == total and vorher < total - 1
	if vorher >= 0 and vorher < total and step > vorher and not uebersprungen:
		_aufgabe_erledigt(vorher)
	_buero.tutorial_schritt(step)
	_aufgabe.visible = step >= 0 and step < total
	if not _aufgabe.visible:
		return
	%AufgabeNummer.text = tr("HUD_TASK") % [step + 1, total]
	%AufgabeTitel.text = tr("QUEST_%d_TITLE" % step)
	%AufgabeText.text = Texte.mit_tasten("QUEST_%d_TEXT" % step)

## Grüner Haken mit Ton, ein paar Sekunden über der nächsten Aufgabe.
func _aufgabe_erledigt(schritt: int) -> void:
	%ErledigtText.text = tr("HUD_TASK_DONE") % tr("QUEST_%d_TITLE" % schritt)
	%Erledigt.visible = true
	var sfx := get_parent().get_node_or_null("Sfx")
	if sfx:
		sfx.play("ding")
	_erledigt_token += 1
	var mein := _erledigt_token
	await get_tree().create_timer(3.0).timeout
	if mein == _erledigt_token:
		%Erledigt.visible = false

# ------------------------------------------------------------ Meldungen
func show_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = true
	_banner_token += 1
	var my := _banner_token
	await get_tree().create_timer(4.0).timeout
	if my == _banner_token:
		_banner.visible = false

## Modales Hinweisfenster (z. B. "erst Ware kaufen").
func show_popup(text: String) -> void:
	%HinweisfensterText.text = text
	_hinweisfenster.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%HinweisfensterOk.grab_focus()

func close_popup() -> void:
	_hinweisfenster.visible = false
	if not _computer.ist_offen() and not _buero.ist_offen():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_popup_open() -> bool:
	return _hinweisfenster.visible

## Kurze Schwarzblende beim Schlafen.
func play_sleep_fade() -> void:
	var fade: ColorRect = %Abblenden
	var zzz: Label = %Zzz
	fade.visible = true
	fade.color.a = 0.0
	zzz.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	tw.parallel().tween_property(zzz, "modulate:a", 1.0, 0.7)
	tw.tween_interval(0.8)
	tw.tween_property(fade, "color:a", 0.0, 0.9)
	tw.parallel().tween_property(zzz, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: fade.visible = false)

# ------------------------------------------------------------ Fenster (player.gd ruft das)
func open_booking() -> void:
	_buero.oeffnen()

func close_booking() -> void:
	_buero.schliessen()

func is_booking_open() -> bool:
	return _buero.ist_offen()

func open_computer() -> void:
	_computer.oeffnen()

func close_computer() -> void:
	_computer.schliessen()

func is_computer_open() -> bool:
	return _computer.ist_offen()
