extends Node
## Net — startet Spiele: solo, als Host oder als Client.
## Das Menü ruft nur diese Funktionen auf und wechselt danach die Szene nicht selbst.

const DEFAULT_PORT := 8642
const MAX_PLAYERS := 4
const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
## Muss zu SAVE_PATH im GameManager passen.
const SAVE_PATH := "user://oktoberfest_save.json"

signal connection_failed()

var player_name: String = "Spieler"
var dedicated := false ## true ise oyuncu spawn edilmez (headless dedicated server)
## Vom Menü gesetzt: vorhandenen Spielstand verwerfen und frisch beginnen.
var neues_spiel := false
## Allein spielen, ganz ohne Netzwerk — keine Firewall-Abfrage.
var solo := false

func _ready() -> void:
	# Dedicated server modu: "-- --server" ile başlatılınca otomatik host
	if OS.get_cmdline_user_args().has("--server"):
		dedicated = true
		call_deferred("_start_dedicated")

func _start_dedicated() -> void:
	var err := host_game()
	if err == OK:
		print("[DEDICATED] Server açık, port %d" % DEFAULT_PORT)
	else:
		push_error("[DEDICATED] Server açılamadı: %d" % err)
		get_tree().quit(1)

## Einzelspieler ohne Netzwerk. Der OfflineMultiplayerPeer verhält sich wie ein
## Host ohne Mitspieler: is_server() ist wahr, die eigene ID ist 1.
func start_solo(neu: bool) -> void:
	solo = true
	neues_spiel = neu
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	get_tree().change_scene_to_file(GAME_SCENE)

func host_game(port: int = DEFAULT_PORT) -> Error:
	solo = false
	neues_spiel = false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file(GAME_SCENE)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	solo = false
	neues_spiel = false
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	# Bağlantı kurulunca oyun sahnesine geç
	if not multiplayer.connected_to_server.is_connected(_on_connected):
		multiplayer.connected_to_server.connect(_on_connected)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	return OK

func _on_connected() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	connection_failed.emit()

func disconnect_game() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	solo = false

## Zurück ins Hauptmenü, Verbindung sauber trennen.
func zum_menue() -> void:
	get_tree().paused = false
	disconnect_game()
	get_tree().change_scene_to_file(MENU_SCENE)

func is_host() -> bool:
	return multiplayer.multiplayer_peer == null or multiplayer.is_server()

## Versionsnummer aus den Projekteinstellungen — die einzige Quelle.
func version_text() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "dev"))

## Kurzinfo zum Spielstand fürs Menü, ohne das Spiel zu laden.
## Leer, wenn es keinen gibt.
func speicherstand_info() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return {"day": int((d as Dictionary).get("day", 1)), "money": int((d as Dictionary).get("money", 0))}
