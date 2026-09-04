extends Node
## Net — multiplayer bootstrap singleton (Faz 3'te doldurulacak).
## Host-as-server modeli: ENetMultiplayerPeer + high-level multiplayer API.

const DEFAULT_PORT := 8642
const MAX_PLAYERS := 4

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	return OK

func disconnect_game() -> void:
	multiplayer.multiplayer_peer = null
