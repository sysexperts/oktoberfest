extends Node
## Boot / Launcher — açılışta çalışır. Sunucudaki version.json'u kontrol eder;
## yeni sürüm varsa sadece game.pck'yi indirir, yükler ve oyunu başlatır.
## Böylece güncellemelerde tüm oyunu yeniden indirmeye gerek kalmaz.

const VERSION_URL := "https://survival.vapur-it.de/version.json"
const PCK_URL := "https://survival.vapur-it.de/game.pck"
const BASE_VERSION := 6          # bu exe'nin içindeki gömülü içerik sürümü
const MENU := "res://scenes/menu.tscn"
const USER_PCK := "user://game.pck"
const USER_TMP := "user://game.pck.tmp"
const VER_FILE := "user://version.txt"

var _http: HTTPRequest
var _label: Label

func _ready() -> void:
	# Dedicated server modunda updater'a girme — Net autoload host'u başlatır.
	if OS.get_cmdline_user_args().has("--server"):
		return
	_build_ui()
	_http = HTTPRequest.new()
	add_child(_http)
	_check_version()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.075, 0.125)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_label = Label.new()
	_label.text = "🍺 Oktoberfest Simulator"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)

func _status(t: String) -> void:
	if _label:
		_label.text = "🍺 Oktoberfest Simulator\n\n" + t

func _local_version() -> int:
	if FileAccess.file_exists(VER_FILE):
		var f := FileAccess.open(VER_FILE, FileAccess.READ)
		if f:
			return int(f.get_as_text().strip_edges())
	return 0

func _effective_local() -> int:
	return maxi(BASE_VERSION, _local_version())

func _check_version() -> void:
	_status("Suche nach Updates…")
	_http.request_completed.connect(_on_version, CONNECT_ONE_SHOT)
	if _http.request(VERSION_URL) != OK:
		_finish()

func _on_version(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish()
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY or not data.has("version"):
		_finish()
		return
	var server_v := int(data["version"])
	if server_v > _effective_local():
		_download(server_v)
	else:
		_finish()

func _download(server_v: int) -> void:
	_status("Lade Update v%d…" % server_v)
	_http.download_file = USER_TMP
	_http.request_completed.connect(_on_download.bind(server_v), CONNECT_ONE_SHOT)
	if _http.request(PCK_URL) != OK:
		_http.download_file = ""
		_finish()

func _on_download(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray, server_v: int) -> void:
	_http.download_file = ""
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var da := DirAccess.open("user://")
		if da:
			if da.file_exists("game.pck"):
				da.remove("game.pck")
			da.rename("game.pck.tmp", "game.pck")
		var f := FileAccess.open(VER_FILE, FileAccess.WRITE)
		if f:
			f.store_string(str(server_v))
	_finish()

func _finish() -> void:
	# İndirilmiş güncel pck varsa yükle (gömülü içeriği override eder)
	if FileAccess.file_exists(USER_PCK) and _local_version() >= BASE_VERSION:
		ProjectSettings.load_resource_pack(USER_PCK, true)
	_status("Starte…")
	get_tree().change_scene_to_file(MENU)
