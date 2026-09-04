class_name HUD
extends CanvasLayer
## Oyun içi arayüz: para, skor, vardiya süresi + vardiya sonu özet ekranı.

var _money_label: Label
var _score_label: Label
var _time_label: Label
var _hint_label: Label
var _summary_panel: PanelContainer
var _summary_label: Label
var _restart_pressed := false

func _ready() -> void:
	var top := HBoxContainer.new()
	top.anchor_left = 0.0
	top.anchor_top = 0.0
	top.offset_left = 16
	top.offset_top = 12
	top.add_theme_constant_override("separation", 32)
	add_child(top)

	_money_label = _make_label("💶 0€")
	_score_label = _make_label("⭐ 0")
	_time_label = _make_label("⏱ 0")
	top.add_child(_money_label)
	top.add_child(_score_label)
	top.add_child(_time_label)

	_hint_label = _make_label("WASD: hareket · Shift: koş · E: al/bırak/servis · Fıçıda E'yi basılı tut")
	_hint_label.anchor_top = 1.0
	_hint_label.anchor_left = 0.0
	_hint_label.offset_left = 16
	_hint_label.offset_top = -40
	add_child(_hint_label)

	_build_summary()

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

func restart_requested() -> bool:
	return _restart_pressed
