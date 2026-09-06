class_name HUD
extends CanvasLayer
## Oyun içi arayüz: para, skor, vardiya süresi + vardiya sonu özet ekranı.

var _money_label: Label
var _score_label: Label
var _time_label: Label
var _hygiene_label: Label
var _pop_label: Label
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
	top.add_child(_phase_label)
	top.add_child(_day_label)
	top.add_child(_money_label)
	top.add_child(_score_label)
	top.add_child(_time_label)
	top.add_child(_hygiene_label)
	top.add_child(_pop_label)

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

	_hint_label = _make_label("WASD · E: al/servis/temizle · Kiosk E: Zelt/Tisch · Wohnwagen E: uyu · Bilgisayar E: rol · Masaya E (mola): taşı · Q: Prost · C: kostüm")
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

func set_time(seconds: float, night: bool = false) -> void:
	_time_label.text = "%s %d" % ["🌙" if night else "⏱", int(ceil(seconds))]
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
	_phase_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3) if name == "VARDİYA" else Color(0.5, 0.85, 1))

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

	var buy_btn := Button.new()
	buy_btn.text = "🪑 Yeni Masa Al"
	buy_btn.custom_minimum_size = Vector2(0, 40)
	buy_btn.pressed.connect(_buy_table)
	vbox.add_child(buy_btn)

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

func _build_booking() -> void:
	_book_panel = PanelContainer.new()
	_book_panel.anchor_left = 0.5
	_book_panel.anchor_top = 0.5
	_book_panel.anchor_right = 0.5
	_book_panel.anchor_bottom = 0.5
	_book_panel.offset_left = -280
	_book_panel.offset_top = -200
	_book_panel.offset_right = 280
	_book_panel.offset_bottom = 200
	_book_panel.visible = false
	add_child(_book_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_book_panel.add_child(vbox)

	var title := Label.new()
	title.text = "🎪 Zelt Buchung & Aufbau"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_book_mgmt = Label.new()
	_book_mgmt.add_theme_font_size_override("font_size", 18)
	_book_mgmt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_book_mgmt)

	vbox.add_child(HSeparator.new())

	_add_book_button(vbox, "🎪 Zelt buchen (500€)", "net_book_tent")
	_add_book_button(vbox, "🪑 Tisch stellen (200€)", "net_buy_table")
	_add_book_button(vbox, "🗑️ Tisch verkaufen (+100€)", "net_sell_table")
	_add_book_button(vbox, "⬆️ Zelt upgraden", "net_upgrade_tent")

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.custom_minimum_size = Vector2(0, 40)
	close_btn.pressed.connect(close_booking)
	vbox.add_child(close_btn)

func _add_book_button(parent: Node, text: String, method: String) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(func(): _call_gm(method))
	parent.add_child(b)

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
