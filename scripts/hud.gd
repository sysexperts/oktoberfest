class_name HUD
extends CanvasLayer
## Oyun içi arayüz: para, skor, vardiya süresi + vardiya sonu özet ekranı.

var _money_label: Label
var _score_label: Label
var _time_label: Label
var _hygiene_label: Label
var _pop_label: Label
var _stock_label: Label
var _phase_label: Label
var _day_label: Label
var _roster_label: Label
var _hint_label: Label
var _book_panel: PanelContainer
var _book_mgmt: Label
var _book_open := false
var _summary_panel: PanelContainer
var _summary_label: Label
var _restart_pressed := false
var _comp_panel: PanelContainer
var _comp_roster: Label
var _comp_mgmt: Label
var _banner_label: Label
var _banner_token := 0
var _comp_open := false
var _last_roster := ""

func _ready() -> void:
	var top := HBoxContainer.new()
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.offset_left = 16
	top.offset_top = 12
	top.add_theme_constant_override("separation", 32)
	add_child(top)

	_phase_label = _make_label("MOLA")
	_day_label = _make_label("📅 1/16")
	_money_label = _make_label("💶 0€")
	_score_label = _make_label("⭐ 0")
	_time_label = _make_label("⏱ 0")
	_hygiene_label = _make_label("🧼 100%")
	_pop_label = _make_label("🎉 35%")
	_stock_label = _make_label("📦 0/0")
	top.add_child(_phase_label)
	top.add_child(_day_label)
	top.add_child(_money_label)
	top.add_child(_score_label)
	top.add_child(_time_label)
	top.add_child(_hygiene_label)
	top.add_child(_pop_label)
	top.add_child(_stock_label)

	# Rol listesi (sağ üst)
	_roster_label = _make_label("")
	_roster_label.anchor_left = 1.0
	_roster_label.anchor_right = 1.0
	_roster_label.offset_left = -320
	_roster_label.offset_right = -16
	_roster_label.offset_top = 12
	_roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_roster_label.add_theme_font_size_override("font_size", 18)
	add_child(_roster_label)

	# Nişangah (ekran merkezi)
	var crosshair := Label.new()
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 28)
	crosshair.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	crosshair.add_theme_color_override("font_outline_color", Color.BLACK)
	crosshair.add_theme_constant_override("outline_size", 4)
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.offset_left = -9
	crosshair.offset_top = -18
	add_child(crosshair)

	_hint_label = _make_label("WASD · E: al/servis/temizle · Kiosk E: Zelt/Tisch/Upgrade · 🚐 Wohnwagen E: uyu → gün başlar (07:00) · 💻 Bilgisayar E: rol + zelti kapat · Masaya E (kapalıyken): taşı · Q: Prost · C: kostüm")
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_left = 0.0
	_hint_label.offset_left = 16
	_hint_label.offset_top = -40
	add_child(_hint_label)

	_build_summary()
	_build_computer()
	_build_booking()

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 24)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	return l

func set_money(v: int) -> void:
	_money_label.text = "💶 %d€" % v

func set_score(v: int) -> void:
	_score_label.text = "⭐ %d" % v

## clock: oyun içi saat (7.0 = 07:00). Negatifse zelt kapalı.
func set_time(clock: float, night: bool = false) -> void:
	if clock < 0.0:
		_time_label.text = "🚪 KAPALI"
		_time_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
		return
	var h := int(clock)
	var m := int((clock - float(h)) * 60.0)
	_time_label.text = "%s %02d:%02d" % ["🌙" if night else "🕗", h, m]
	_time_label.add_theme_color_override("font_color", Color(0.7, 0.75, 1) if night else Color.WHITE)

func show_banner(text: String) -> void:
	if _banner_label == null:
		_banner_label = _make_label("")
		_banner_label.anchor_left = 0.5
		_banner_label.anchor_top = 0.28
		_banner_label.anchor_right = 0.5
		_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_banner_label.add_theme_font_size_override("font_size", 34)
		_banner_label.offset_left = -400
		_banner_label.offset_right = 400
		add_child(_banner_label)
	_banner_label.text = text
	_banner_label.visible = true
	_banner_token += 1
	var my := _banner_token
	await get_tree().create_timer(4.0).timeout
	if my == _banner_token and _banner_label:
		_banner_label.visible = false

func set_hygiene(v: float) -> void:
	_hygiene_label.text = "🧼 %d%%" % int(round(v))
	_hygiene_label.add_theme_color_override("font_color", Color.WHITE if v > 40 else Color(1, 0.4, 0.3))

func set_popularity(v: float) -> void:
	_pop_label.text = "🎉 %d%%" % int(round(v))

func set_day(day: int, total: int) -> void:
	if _day_label:
		_day_label.text = "📅 %d/%d" % [day, total]

func set_phase(name: String) -> void:
	_phase_label.text = name
	_phase_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if name.begins_with("ZELT AÇIK") else Color(0.5, 0.85, 1))

func set_roster(text: String) -> void:
	_last_roster = text
	_roster_label.text = text
	if _comp_roster:
		_comp_roster.text = text

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
	title.text = "💻 Vardiya Bilgisayarı — Sıradaki vardiya için rol seç"
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

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_comp_mgmt = Label.new()
	_comp_mgmt.add_theme_font_size_override("font_size", 18)
	_comp_mgmt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_comp_mgmt)

	var close_tent_btn := Button.new()
	close_tent_btn.text = "🚪 Zelti şimdi kapat (popülerlik cezası)"
	close_tent_btn.custom_minimum_size = Vector2(0, 44)
	close_tent_btn.pressed.connect(func(): _call_gm("net_close_tent"))
	vbox.add_child(close_tent_btn)

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.pressed.connect(close_computer)
	vbox.add_child(close_btn)

func _buy_table() -> void:
	var gm := get_parent()
	if gm and gm.has_method("net_buy_table"):
		gm.net_buy_table.rpc_id(1)

func set_mgmt(text: String) -> void:
	if _comp_mgmt:
		_comp_mgmt.text = text
	if _book_mgmt:
		_book_mgmt.text = text

## E2: Wiesenbüro — ein Menü mit Reitern (Zelt · Lizenzen · Personal · Künstler · Ware).
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

	# --- Reiter: Zelt ---
	var t_zelt := VBoxContainer.new()
	t_zelt.name = "🎪 Zelt"
	t_zelt.add_theme_constant_override("separation", 8)
	tabs.add_child(t_zelt)
	_add_book_button(t_zelt, "🎪 Zelt mieten (500€)", "net_book_tent")
	_add_book_button(t_zelt, "🪑 Tisch stellen (200€)", "net_buy_table")
	_add_book_button(t_zelt, "🗑️ Tisch verkaufen (+100€)", "net_sell_table")
	_add_book_button(t_zelt, "⬆️ Zelt vergrößern", "net_upgrade_tent")
	_add_book_button(t_zelt, "📣 Werbung (mehr Gäste)", "net_buy_marketing")
	_add_book_button(t_zelt, "🎨 Deko (mehr Einnahmen)", "net_buy_deko")

	# --- Reiter: Lizenzen ---
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

	# --- Reiter, die noch kommen ---
	# --- Reiter: Personal ---
	var t_staff := VBoxContainer.new()
	t_staff.name = "👷 Personal"
	t_staff.add_theme_constant_override("separation", 6)
	tabs.add_child(t_staff)
	var st_info := Label.new()
	st_info.text = "Level 1–10. Kellner trägt Lv = Anzahl Krüge.\nLohn wird pro Schicht abgezogen."
	st_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_staff.add_child(st_info)
	_add_staff_row(t_staff, "👨‍🍳 Koch", 1, 600)
	_add_staff_row(t_staff, "🍺 Kellner", 2, 500)
	_add_staff_row(t_staff, "🧹 Reinigung", 3, 400)
	# --- Reiter: Künstler ---
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
	# --- Reiter: Ware ---
	var t_ware := VBoxContainer.new()
	t_ware.name = "📦 Ware"
	t_ware.add_theme_constant_override("separation", 6)
	tabs.add_child(t_ware)
	var w_info := Label.new()
	w_info.text = "1 Paket = 10 Einheiten. Lieferung nach ~1 Minute\nper Wagen — dann Pakete ins Lager tragen!"
	w_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_ware.add_child(w_info)
	_add_order_row(t_ware, "🍺 Bier", 1, 60)
	_add_order_row(t_ware, "🥨 Zutaten", 2, 80)

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(close_booking)
	vbox.add_child(close_btn)

func _add_soon_tab(tabs: TabContainer, tab_name: String, text: String) -> void:
	var box := VBoxContainer.new()
	box.name = tab_name
	tabs.add_child(box)
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	box.add_child(l)

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

func set_stock(bier: int, essen: int) -> void:
	if _stock_label:
		_stock_label.text = "📦 %d/%d" % [bier, essen]
		_stock_label.add_theme_color_override("font_color",
			Color.WHITE if (bier > 0 or essen > 0) else Color(1, 0.4, 0.3))

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

func _build_summary() -> void:
	_summary_panel = PanelContainer.new()
	_summary_panel.anchor_left = 0.5
	_summary_panel.anchor_top = 0.5
	_summary_panel.anchor_right = 0.5
	_summary_panel.anchor_bottom = 0.5
	_summary_panel.offset_left = -220
	_summary_panel.offset_top = -160
	_summary_panel.offset_right = 220
	_summary_panel.offset_bottom = 160
	_summary_panel.visible = false
	add_child(_summary_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	_summary_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🍺 Vardiya Bitti!"
	title.add_theme_font_size_override("font_size", 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_summary_label = Label.new()
	_summary_label.add_theme_font_size_override("font_size", 22)
	_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_summary_label)

	var btn := Button.new()
	btn.text = "Tekrar Oyna"
	btn.pressed.connect(func(): _restart_pressed = true)
	vbox.add_child(btn)

func show_summary(served: int, missed: int, money: int, score: int) -> void:
	_summary_label.text = "Servis edilen: %d\nKaçırılan: %d\nKazanç: %d€\nSkor: %d" % [served, missed, money, score]
	_summary_panel.visible = true
	_hint_label.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func restart_requested() -> bool:
	return _restart_pressed
