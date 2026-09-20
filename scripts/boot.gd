extends Node
## Boot / Launcher — läuft beim Start. Fragt version.json auf dem Server ab und
## lädt nach, was veraltet ist.
##
## Die Spieldaten liegen in zwei Paketen, damit ein Update nicht jedes Mal das
## ganze Spiel überträgt (bis v204 war es ein einziges game.pck mit 815 MB —
## eine geänderte Textzeile kostete jeden Spieler 815 MB):
##
##   inhalt.pck   Modelle, Figuren, Erweiterungen — rund 780 MB, ändert sich fast
##                nie (in den Deploys v183–v204 kein einziges Mal)
##   spiel.pck    Szenen, Skripte, Texte, Oberfläche, Klänge — rund 60 MB, geht
##                bei jedem Deploy raus
##
## Die Reihenfolge in PAKETE zählt doppelt: erst wird in dieser Reihenfolge
## heruntergeladen, dann in dieser Reihenfolge geladen. spiel.pck kommt zuletzt
## und gewinnt damit bei Dateien, die in beiden Paketen liegen.
##
## Alte .exe (Programm-Generation ≤ 3) kennen dieses Skript nicht — sie führen
## ihr eigenes, eingebautes boot.gd aus und fragen weiter nach game.pck. Für sie
## bleibt in version.json der eingefrorene Schlüssel "version" stehen und auf dem
## Server das letzte volle game.pck liegen; scripts/menu_eingang.gd zeigt ihnen
## den Hinweis zum Neu-Herunterladen.

const BASIS_URL := "https://survival.vapur-it.de/"
const VERSION_URL := BASIS_URL + "version.json"
const MENU := "res://scenes/menu.tscn"
const UPDATER_UI := "res://scenes/ui/updater.tscn"

## schluessel: Feld in version.json und Name der Merkdatei in user://
const PAKETE := [
	{"schluessel": "inhalt", "datei": "inhalt.pck"},
	{"schluessel": "spiel", "datei": "spiel.pck"},
]

## Version des in diese .exe eingebauten Builds, aus den Projekteinstellungen.
## Ein heruntergeladenes Paket, das älter ist als die .exe, wird nie geladen.
var BASE_VERSION := int(str(ProjectSettings.get_setting("application/config/version", "6")))

var _http: HTTPRequest
var _label: Label
var _ui: Control
## Noch zu ladende Pakete: [{"paket": …, "version": int}, …]
var _offen: Array = []

func _ready() -> void:
	# Dedicated server modunda updater'a girme — Net autoload host'u başlatır.
	if OS.get_cmdline_user_args().has("--server"):
		return
	# Steam-Build (Plan 5.1): Steam liefert Updates selbst. Nichts von unserem
	# Server nachladen und nie ein früher heruntergeladenes Paket benutzen —
	# nachgeladener Code fällt beim Steam-Review auf und umgeht Steams Versionen.
	if OS.has_feature("steam"):
		get_tree().change_scene_to_file.call_deferred(MENU)
		return
	_altes_paket_entsorgen()
	_build_ui()
	_http = HTTPRequest.new()
	add_child(_http)
	_check_version()

## Das alte Einzelpaket aus der Zeit vor der Aufteilung belegt 815 MB im
## Benutzerordner und wird nicht mehr gelesen — einmal aufräumen.
func _altes_paket_entsorgen() -> void:
	var da := DirAccess.open("user://")
	if da == null:
		return
	for datei in ["game.pck", "game.pck.tmp", "version.txt"]:
		if da.file_exists(datei):
			da.remove(datei)

func _build_ui() -> void:
	# Richtige Oberfläche mit Logo und Fortschritt; sie liegt in derselben .exe
	# wie dieses Skript. Falls sie doch fehlt, bleibt der schlichte Text übrig —
	# ein Updater ohne Anzeige wäre schlimmer als ein hässlicher.
	if ResourceLoader.exists(UPDATER_UI):
		_ui = load(UPDATER_UI).instantiate()
		add_child(_ui)
		return
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_label = Label.new()
	_label.text = tr("GAME_TITLE")
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_CENTER)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)

func _status(t: String) -> void:
	if _ui:
		_ui.status(t)
	elif _label:
		_label.text = tr("GAME_TITLE") + "\n\n" + t

## Während des Paketdownloads den echten Fortschritt anzeigen — ohne Anzeige
## wirkt das Fenster eingefroren.
func _process(_delta: float) -> void:
	if _ui != null and _http != null and _http.download_file != "":
		_ui.fortschritt(_http.get_downloaded_bytes(), _http.get_body_size())

# ------------------------------------------------------------ Versionen merken
func _merkdatei(schluessel: String) -> String:
	return "user://%s.txt" % schluessel

func _lokal(schluessel: String) -> int:
	var pfad := _merkdatei(schluessel)
	if FileAccess.file_exists(pfad):
		var f := FileAccess.open(pfad, FileAccess.READ)
		if f:
			return int(f.get_as_text().strip_edges())
	return 0

## Was tatsächlich gilt: das Neuere aus .exe und heruntergeladenem Paket.
func _effektiv(schluessel: String) -> int:
	return maxi(BASE_VERSION, _lokal(schluessel))

# ------------------------------------------------------------ Abfrage
func _check_version() -> void:
	_status(tr("STATUS_UPDATE_SEARCH"))
	_http.request_completed.connect(_on_version, CONNECT_ONE_SHOT)
	if _http.request(VERSION_URL) != OK:
		_finish()

func _on_version(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		_finish()
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(data) != TYPE_DICTIONARY:
		_finish()
		return
	_offen.clear()
	for p: Dictionary in PAKETE:
		var schluessel: String = p["schluessel"]
		# Fehlt der Schlüssel, bietet der Server das Paket nicht an — dann bleibt
		# es beim Stand aus der .exe, statt ins Leere zu laden.
		var server_v := int((data as Dictionary).get(schluessel, 0))
		if server_v > _effektiv(schluessel):
			_offen.append({"paket": p, "version": server_v})
	_naechstes()

# ------------------------------------------------------------ Herunterladen
func _naechstes() -> void:
	if _offen.is_empty():
		_finish()
		return
	var auftrag: Dictionary = _offen.pop_front()
	var paket: Dictionary = auftrag["paket"]
	var server_v: int = auftrag["version"]
	_status(tr("STATUS_UPDATE_LOAD") % server_v)
	if _ui:
		_ui.fortschritt_an()
	_http.download_file = "user://%s.tmp" % paket["datei"]
	_http.request_completed.connect(_on_download.bind(paket, server_v), CONNECT_ONE_SHOT)
	if _http.request(BASIS_URL + str(paket["datei"])) != OK:
		_http.download_file = ""
		_finish()

func _on_download(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray,
		paket: Dictionary, server_v: int) -> void:
	_http.download_file = ""
	if _ui:
		_ui.fortschritt_aus()
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		# Halbe Datei wegräumen und mit dem bisherigen Stand weitermachen —
		# lieber ein Spiel in der alten Version als gar keins.
		var da_weg := DirAccess.open("user://")
		if da_weg:
			da_weg.remove("%s.tmp" % paket["datei"])
		_finish()
		return
	var datei: String = paket["datei"]
	var da := DirAccess.open("user://")
	if da:
		if da.file_exists(datei):
			da.remove(datei)
		da.rename("%s.tmp" % datei, datei)
	var f := FileAccess.open(_merkdatei(str(paket["schluessel"])), FileAccess.WRITE)
	if f:
		f.store_string(str(server_v))
	_naechstes()

# ------------------------------------------------------------ Laden und starten
func _finish() -> void:
	# In der Reihenfolge aus PAKETE laden: das zuletzt geladene gewinnt bei
	# Dateien, die in mehreren Paketen stecken.
	for p: Dictionary in PAKETE:
		var pfad := "user://%s" % p["datei"]
		if FileAccess.file_exists(pfad) and _lokal(str(p["schluessel"])) >= BASE_VERSION:
			ProjectSettings.load_resource_pack(pfad, true)
	_status(tr("STATUS_STARTING"))
	get_tree().change_scene_to_file(MENU)
