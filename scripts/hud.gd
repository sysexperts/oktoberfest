class_name HUD
extends CanvasLayer
## Oyun içi arayüz: para, skor, vardiya süresi + vardiya sonu özet ekranı.

var _money_label: Label
var _score_label: Label
var _time_label: Label
var _phase_label: Label
var _roster_label: Label
var _hint_label: Label
var _summary_panel: PanelContainer
var _summary_label: Label
var _restart_pressed := false
var _comp_panel: PanelContainer
var _comp_roster: Label
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
	_money_label = _make_label("💶 0€")
	_score_label = _make_label("⭐ 0")
	_time_label = _make_label("⏱ 0")
	top.add_child(_phase_label)
	top.add_child(_money_label)
	top.add_child(_score_label)
	top.add_child(_time_label)

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

	_hint_label = _make_label("WASD · Fare: bak · E: al/servis · Fıçıda E basılı tut · Molada bilgisayarda E: rol seç · Q: Prost · Esc: fare")
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_left = 0.0
	_hint_label.offset_left = 16
	_hint_label.offset_top = -40
	add_child(_hint_label)

	_build_summary()
	_build_computer()

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

func set_time(seconds: float) -> void:
	_time_label.text = "⏱ %d" % int(ceil(seconds))

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

	var close_btn := Button.new()
	close_btn.text = "Kapat (Esc)"
	close_btn.pressed.connect(close_computer)
	vbox.add_child(close_btn)

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
