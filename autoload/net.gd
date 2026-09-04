extends Node
## Net — multiplayer bootstrap singleton (host-as-server, ENet).
## Menü buradan host/join başlatır, sonra oyun sahnesine geçer.

const DEFAULT_PORT := 8642
const MAX_PLAYERS := 4
const GAME_SCENE := "res://scenes/main.tscn"
const BUILD := "v3" ## Menüde gösterilir — hangi sürümü çalıştırdığını doğrulamak için

signal connection_failed()

var player_name: String = "Oyuncu"
var dedicated := false ## true ise oyuncu spawn edilmez (headless dedicated server)

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

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	get_tree().change_scene_to_file(GAME_SCENE)
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
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
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func disconnect_game() -> void:
	multiplayer.multiplayer_peer = null

func is_host() -> bool:
	return multiplayer.multiplayer_peer == null or multiplayer.is_server()
