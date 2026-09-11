extends Node
## Net — startet Spiele: solo, als Host oder als Client.
## Das Menü ruft nur diese Funktionen auf und wechselt danach die Szene nicht selbst.
## Verwaltet außerdem die Spielstand-Plätze (der GameManager liest und schreibt
## den Stand, Net weiß, welcher Platz gerade gilt).

const DEFAULT_PORT := 8642
const MAX_PLAYERS := 4
const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const LADE_SZENE := "res://scenes/ui/ladebildschirm.tscn"

## Spielstände: drei Plätze. SAVE_FORMAT steigt, wenn sich der Aufbau so ändert,
## dass ein älteres Spiel den Stand nicht mehr richtig lesen könnte — solche
## Stände werden dann angezeigt, aber nicht geladen.
const SAVE_DIR := "user://saves/"
const SLOTS := 3
const SAVE_FORMAT := 1
## Bis Version 101 gab es nur diesen einen Stand — wird einmalig Platz 1.
const ALTER_SPIELSTAND := "user://oktoberfest_save.json"

signal connection_failed()

var player_name: String = "Spieler"
var dedicated := false ## true ise oyuncu spawn edilmez (headless dedicated server)
## Vom Menü gesetzt: vorhandenen Spielstand verwerfen und frisch beginnen.
var neues_spiel := false
## Allein spielen, ganz ohne Netzwerk — keine Firewall-Abfrage.
var solo := false
## Spielstand-Platz des laufenden Spiels (1..SLOTS).
var slot := 1
## Welche Szene der Ladebildschirm laden soll (wechsle_zu).
var ziel_szene := ""

## Szenenwechsel über den Ladebildschirm: lädt im Hintergrund, zeigt Fortschritt.
## Nur für Solo — beim Hosten und Beitreten gleich wechseln, sonst könnten
## Netzwerknachrichten ankommen, bevor die Spielszene da ist.
func wechsle_zu(pfad: String) -> void:
	ziel_szene = pfad
	get_tree().change_scene_to_file(LADE_SZENE)

func _ready() -> void:
	_alten_spielstand_uebernehmen()
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
## platz: Spielstand-Platz, 0 = den aktuellen behalten.
func start_solo(neu: bool, platz: int = 0) -> void:
	if platz > 0:
		slot = platz
	solo = true
	neues_spiel = neu
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	wechsle_zu(GAME_SCENE)

## Wer hostet, spielt mit seinem zuletzt benutzten Stand weiter.
func host_game(port: int = DEFAULT_PORT) -> Error:
	solo = false
	neues_spiel = false
	slot = maxi(1, letzter_slot())
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

# ------------------------------------------------------------ Spielstände
## Pfad eines Platzes; 0 = aktueller Platz.
func speicherstand_pfad(platz: int = 0) -> String:
	return SAVE_DIR + "slot_%d.json" % (platz if platz > 0 else slot)

## Kurzinfo zu einem Platz fürs Menü, ohne das Spiel zu laden. Leer = kein Stand.
## zu_neu: stammt aus einer neueren Spielversion und wird nicht geladen.
func speicherstand_info(platz: int = 0) -> Dictionary:
	var pfad := speicherstand_pfad(platz)
	if not FileAccess.file_exists(pfad):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(pfad))
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	var stand: Dictionary = d
	return {
		"day": int(stand.get("day", 1)),
		"money": int(stand.get("money", 0)),
		"saved_at": int(stand.get("saved_at", 0)),
		"zu_neu": int(stand.get("format", 0)) > SAVE_FORMAT,
	}

## Zuletzt gespeicherter ladbarer Platz — für „Weiterspielen". 0 = keiner.
func letzter_slot() -> int:
	var bester := 0
	var zeit := -1
	for platz in range(1, SLOTS + 1):
		var info := speicherstand_info(platz)
		if info.is_empty() or info.zu_neu:
			continue
		if int(info.saved_at) > zeit:
			zeit = int(info.saved_at)
			bester = platz
	return bester

## Der alte Einzelstand wird Platz 1 — aber nur, wenn Platz 1 noch frei ist.
func _alten_spielstand_uebernehmen() -> void:
	if not FileAccess.file_exists(ALTER_SPIELSTAND):
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	if FileAccess.file_exists(speicherstand_pfad(1)):
		return
	DirAccess.rename_absolute(ProjectSettings.globalize_path(ALTER_SPIELSTAND),
		ProjectSettings.globalize_path(speicherstand_pfad(1)))
