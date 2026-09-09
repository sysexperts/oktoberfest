extends Control
## Ana menü: genel sunucuya bağlan, kendi host'unu aç veya IP ile katıl.

## Bizim sabit sunucumuz — kimse IP yazmak zorunda kalmasın.
const SERVER_IP := "185.248.140.225"

var _ip_edit: LineEdit
var _status: Label

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.custom_minimum_size = Vector2(340, 0)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "🍺 Oktoberfest Simulator"
	title.add_theme_font_size_override("font_size", 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var ver := Label.new()
	ver.text = "Build %s" % Net.BUILD
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	ver.add_theme_font_size_override("font_size", 14)
	vbox.add_child(ver)

	var server_btn := Button.new()
	server_btn.text = "▶  Sunucuya Bağlan"
	server_btn.custom_minimum_size = Vector2(0, 56)
	server_btn.add_theme_font_size_override("font_size", 22)
	server_btn.pressed.connect(_on_server)
	vbox.add_child(server_btn)

	var sep0 := HSeparator.new()
	vbox.add_child(sep0)

	var host_btn := Button.new()
	host_btn.text = "Host Aç (Oyun Kur)"
	host_btn.custom_minimum_size = Vector2(0, 44)
	host_btn.pressed.connect(_on_host)
	vbox.add_child(host_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "Host IP (ör. 127.0.0.1)"
	_ip_edit.text = "127.0.0.1"
	vbox.add_child(_ip_edit)

	var join_btn := Button.new()
	join_btn.text = "IP ile Katıl"
	join_btn.custom_minimum_size = Vector2(0, 44)
	join_btn.pressed.connect(_on_join)
	vbox.add_child(join_btn)

	_status = Label.new()
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
	vbox.add_child(_status)

	if not Net.connection_failed.is_connected(_on_failed):
		Net.connection_failed.connect(_on_failed)

## Tek tıkla bizim sunucuya — IP yazmaya gerek yok.
func _on_server() -> void:
	_verbinde(SERVER_IP)

func _on_host() -> void:
	var err := Net.host_game()
	if err != OK:
		_status.text = "Host açılamadı (hata %d). Port meşgul olabilir." % err

func _on_join() -> void:
	var ip := _ip_edit.text.strip_edges()
	if ip.is_empty():
		_status.text = "Lütfen bir IP gir."
		return
	_verbinde(ip)

func _verbinde(ip: String) -> void:
	_status.text = "Bağlanılıyor: %s ..." % ip
	var err := Net.join_game(ip)
	if err != OK:
		_status.text = "Bağlantı başlatılamadı (hata %d)." % err

func _on_failed() -> void:
	_status.text = "Bağlantı başarısız. IP/port'u ve host'un açık olduğunu kontrol et."
