class_name HUD
extends CanvasLayer
## Oyun içi arayüz. Aufbau liegt in scenes/ui/hud.tscn — Leiste oben links
## (Geld · Tag und Uhrzeit · Beliebtheit, darunter Lager und Sauberkeit),
## Aufgabe rechts, Fadenkreuz, Hinweisfenster, Schlaf-Abblende.
## Die Werte kommen vom GameManager; hier wird nur angezeigt. Jeder Wert wird
## gemerkt, damit ein Sprachwechsel alles neu beschriften kann.
##
## Noch im Code: Zelt-Computer und Wiesenbüro (werden mit Plan-Punkt 2.4 Szenen).

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
@onready var _rollen_text: Label = %RollenText
@onready var _aufgabe: Control = %Aufgabe
@onready var _banner: Label = %Banner
@onready var _hinweisfenster: Control = %Hinweisfenster

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

var _banner_token := 0
var _book_panel: PanelContainer
var _book_mgmt: Label
var _book_open := false
var _comp_panel: PanelContainer
var _comp_roster: Label
var _comp_mgmt: Label
var _comp_open := false
var _last_roster := ""
var _report_label: Label
var _comp_report: Label
var _last_report := ""

func _ready() -> void:
	%HinweisfensterOk.pressed.connect(close_popup)
	_build_computer()
	_build_booking()
	# Hinweisfenster und Abblende müssen über den Code-Panels liegen
	move_child(_hinweisfenster, -1)
	move_child(%Abblenden, -1)
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

# ------------------------------------------------------------ Rechts
## Rollenliste — nur im Koop sinnvoll.
func set_roster(text: String) -> void:
	_last_roster = text
	_rollen_text.text = text
	_rollen.visible = text != "" and not Net.solo
	if _comp_roster:
		_comp_roster.text = text

## step: aktueller Tutorialschritt, total: Anzahl. step >= total = fertig.
func set_quest(step: int, total: int) -> void:
	_quest_step = step
	_quest_total = total
	_aufgabe.visible = step >= 0 and step < total
	if not _aufgabe.visible:
		return
	%AufgabeNummer.text = tr("HUD_TASK") % [step + 1, total]
	%AufgabeTitel.text = tr("QUEST_%d_TITLE" % step)
	%AufgabeText.text = Texte.mit_tasten("QUEST_%d_TEXT" % step)

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
	if not _comp_open and not _book_open:
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

# ------------------------------------------------------------ Zelt-Computer
func _build_computer() -> void:
	_comp_panel = PanelContainer.new()
	_comp_panel.anchor_left = 0.5
	_comp_panel.anchor_top = 0.5
	_comp_panel.anchor_right = 0.5
	_comp_panel.anchor_bottom = 0.5
	_comp_panel.offset_left = -260
	_comp_panel.offset_top = -180
	_comp_panel.offset_right = 260
	_comp_panel.offset_bottom = 180
	_comp_panel.visible = false
	add_child(_comp_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_comp_panel.add_child(vbox)

	var title := Label.new()
	title.text = "💻 Zelt-Computer — Rollen · Bilanz · Zelt schließen"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_comp_roster = Label.new()
	_comp_roster.add_theme_font_size_override("font_size", 20)
	_comp_roster.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_comp_roster)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	_add_role_button(row, "👨‍🍳 Mutfak", 1)
	_add_role_button(row, "🧹 Temizlik", 2)
	_add_role_button(row, "🍺 Garson", 3)
	_add_role_button(row, "Vazgeç", 0)

	vbox.add_child(HSeparator.new())

	_comp_mgmt = Label.new()
	_comp_mgmt.add_theme_font_size_override("font_size", 18)
	_comp_mgmt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_comp_mgmt)

	vbox.add_child(HSeparator.new())

	# Tagesbilanz auch hier im Zelt nachlesbar
	_comp_report = Label.new()
	_comp_report.text = "Noch keine Schicht gespielt."
	_comp_report.add_theme_font_size_override("font_size", 16)
	_comp_report.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_comp_report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_comp_report)

	var close_tent_btn := Button.new()
	close_tent_btn.text = "🚪 Zelti şimdi kapat (popülerlik cezası)"
	close_tent_btn.custom_minimum_size = Vector2(0, 44)
	close_tent_btn.pressed.connect(func(): _call_gm("net_close_tent"))
	vbox.add_child(close_tent_btn)

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.pressed.connect(close_computer)
	vbox.add_child(close_btn)

func set_mgmt(text: String) -> void:
	if _comp_mgmt:
		_comp_mgmt.text = text
	if _book_mgmt:
		_book_mgmt.text = text

func _add_role_button(parent: Node, text: String, role: int) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(func(): _pick_role(role))
	parent.add_child(b)

func _pick_role(role: int) -> void:
	var gm := get_parent()
	if gm and gm.has_method("net_set_role"):
		gm.net_set_role.rpc_id(1, role)

func open_computer() -> void:
	_comp_roster.text = _last_roster
	_comp_panel.visible = true
	_comp_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_computer() -> void:
	_comp_panel.visible = false
	_comp_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_computer_open() -> bool:
	return _comp_open

# ------------------------------------------------------------ Wiesenbüro
## Ein Menü mit Reitern (Zelt · Lizenzen · Personal · Künstler · Ware · Bilanz).
func _build_booking() -> void:
	_book_panel = PanelContainer.new()
	_book_panel.anchor_left = 0.5
	_book_panel.anchor_top = 0.5
	_book_panel.anchor_right = 0.5
	_book_panel.anchor_bottom = 0.5
	_book_panel.offset_left = -330
	_book_panel.offset_top = -250
	_book_panel.offset_right = 330
	_book_panel.offset_bottom = 250
	_book_panel.visible = false
	add_child(_book_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_book_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🏛 WIESENBÜRO"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_book_mgmt = Label.new()
	_book_mgmt.add_theme_font_size_override("font_size", 16)
	_book_mgmt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_book_mgmt)

	var tabs := TabContainer.new()
	tabs.custom_minimum_size = Vector2(0, 300)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(tabs)

	var t_zelt := VBoxContainer.new()
	t_zelt.name = "🎪 Zelt"
	t_zelt.add_theme_constant_override("separation", 8)
	tabs.add_child(t_zelt)
	_add_book_button(t_zelt, "🎪 Zelt mieten (500€)", "net_book_tent")
	_add_book_button(t_zelt, "🪑 Tisch stellen (200€)", "net_buy_table")
	_add_book_button(t_zelt, "🗑️ Tisch verkaufen (+100€)", "net_sell_table")
	_add_book_button(t_zelt, "⬆️ Zelt vergrößern", "net_upgrade_tent")
	_add_book_button(t_zelt, "🚻 Toilette einbauen (1800€)", "net_buy_toilet")
	_add_book_button(t_zelt, "📣 Werbung (mehr Gäste)", "net_buy_marketing")
	_add_book_button(t_zelt, "🎨 Deko (mehr Einnahmen)", "net_buy_deko")

	var t_lic := VBoxContainer.new()
	t_lic.name = "📜 Lizenzen"
	t_lic.add_theme_constant_override("separation", 8)
	tabs.add_child(t_lic)
	var lic_info := Label.new()
	lic_info.text = "Ohne Lizenz verkaufst du nur 🍺 Helles."
	lic_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lic.add_child(lic_info)
	_add_lic_button(t_lic, "🍺 Weizen-Lizenz (800€)", "weizen")
	_add_lic_button(t_lic, "🍋 Radler-Lizenz (800€)", "radler")
	_add_lic_button(t_lic, "🥨 Brezn-Lizenz (1200€)", "brezn")
	_add_lic_button(t_lic, "🌭 Sosis-Lizenz (1200€)", "sosis")

	var t_staff := VBoxContainer.new()
	t_staff.name = "👷 Personal"
	t_staff.add_theme_constant_override("separation", 6)
	tabs.add_child(t_staff)
	var st_info := Label.new()
	st_info.text = "Level 1–5. Kellner trägt 1 / 2 / 4 / 8 / 12 Krüge.\nLohn wird pro Schicht abgezogen."
	st_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_staff.add_child(st_info)
	_add_staff_row(t_staff, "👨‍🍳 Koch", 1, 600)
	_add_staff_row(t_staff, "🍺 Kellner", 2, 500)
	_add_staff_row(t_staff, "🧹 Reinigung", 3, 400)

	var t_art := VBoxContainer.new()
	t_art.name = "🎤 Künstler"
	t_art.add_theme_constant_override("separation", 8)
	tabs.add_child(t_art)
	var a_info := Label.new()
	a_info.text = "Gilt für die nächste Schicht.\nMehr Andrang = mehr Gäste im Zelt."
	a_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_art.add_child(a_info)
	_add_artist_button(t_art, "🎸 Straßenmusiker (500€) — +15% Andrang", 1)
	_add_artist_button(t_art, "🎺 Blaskapelle (2000€) — +35% Andrang", 2)
	_add_artist_button(t_art, "⭐ Star-Act (6000€) — +60% Andrang", 3)

	var t_ware := VBoxContainer.new()
	t_ware.name = "📦 Ware"
	t_ware.add_theme_constant_override("separation", 6)
	tabs.add_child(t_ware)
	var w_info := Label.new()
	w_info.text = "1 Paket = 10 Einheiten. Lieferung nach ~1 Minute\nper Wagen — dann Pakete ins Lager tragen!"
	w_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_ware.add_child(w_info)
	_add_order_row(t_ware, "🍺 Bier", 1, 40)
	_add_order_row(t_ware, "🥨 Zutaten", 2, 50)

	var t_rep := VBoxContainer.new()
	t_rep.name = "📊 Bilanz"
	tabs.add_child(t_rep)
	_report_label = Label.new()
	_report_label.text = "Noch keine Schicht gespielt."
	_report_label.add_theme_font_size_override("font_size", 18)
	_report_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_report_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_report_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	t_rep.add_child(_report_label)

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(close_booking)
	vbox.add_child(close_btn)

func _add_book_button(parent: Node, text: String, method: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(func(): _call_gm(method))
	parent.add_child(b)

func _add_lic_button(parent: Node, text: String, key: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.pressed.connect(func(): _buy_license(key))
	parent.add_child(b)

func _buy_license(key: String) -> void:
	var gm := get_parent()
	if gm and gm.has_method("net_buy_license"):
		gm.rpc_id(1, "net_buy_license", key)

## Eine Zeile im Personal-Reiter: einstellen + aufstufen.
func _add_staff_row(parent: Node, label: String, role: int, cost: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var hire := Button.new()
	hire.text = "%s einstellen (%d€)" % [label, cost]
	hire.custom_minimum_size = Vector2(300, 38)
	hire.pressed.connect(func(): _gm_call_int("net_hire_staff", role))
	row.add_child(hire)
	var up := Button.new()
	up.text = "⬆️ aufstufen"
	up.custom_minimum_size = Vector2(150, 38)
	up.pressed.connect(func(): _gm_call_int("net_upgrade_staff", role))
	row.add_child(up)

func _gm_call_int(method: String, v: int) -> void:
	var gm := get_parent()
	if gm and gm.has_method(method):
		gm.rpc_id(1, method, v)

## Eine Zeile im Ware-Reiter: 1 / 5 / 10 Pakete bestellen.
func _add_order_row(parent: Node, label: String, kind: int, cost: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var l := Label.new()
	l.text = "%s (%d€/Paket)" % [label, cost]
	l.custom_minimum_size = Vector2(220, 38)
	row.add_child(l)
	for packs in [1, 5, 10]:
		var b := Button.new()
		b.text = "×%d" % packs
		b.custom_minimum_size = Vector2(70, 38)
		b.pressed.connect(func(): _order_goods(kind, packs))
		row.add_child(b)

func _add_artist_button(parent: Node, text: String, tier: int) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(func(): _gm_call_int("net_book_artist", tier))
	parent.add_child(b)

func _order_goods(kind: int, packs: int) -> void:
	var gm := get_parent()
	if gm and gm.has_method("net_order_goods"):
		gm.rpc_id(1, "net_order_goods", kind, packs)

func _call_gm(method: String) -> void:
	var gm := get_parent()
	if gm and gm.has_method(method):
		gm.callv("rpc_id", [1, method])

func open_booking() -> void:
	if _book_mgmt:
		_book_mgmt.text = _comp_mgmt.text if _comp_mgmt else ""
	_book_panel.visible = true
	_book_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_booking() -> void:
	_book_panel.visible = false
	_book_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_booking_open() -> bool:
	return _book_open

## Letzte Tagesbilanz merken, damit man sie jederzeit nachlesen kann.
func set_report(text: String) -> void:
	_last_report = text
	if _comp_report:
		_comp_report.text = text if text != "" else "Noch keine Schicht gespielt."
	if _report_label:
		_report_label.text = text if text != "" else "Noch keine Schicht gespielt."
