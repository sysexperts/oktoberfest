extends Node
## Steam-Anbindung (Plan 5.2/5.3): Start, Statusanzeige in der Freundesliste,
## Steam-Name, Lobbys zum gemeinsamen Spielen mit Freunden.
## Läuft nur im Steam-Build (Merkmal "steam") und nie auf dem dedizierten Server.
##
## Zugriff ausschließlich über Engine.get_singleton("Steam"), nie über den
## Klassennamen: Die GodotSteam-Bibliotheken liegen neben der .exe, nicht im
## Paket. Spieler des Direkt-Builds bekommen Updates nur als Paket und haben sie
## nicht — ein "Steam." im Code würde dort das ganze Skript unladbar machen.
##
## Ablauf Koop über Steam:
##   Host:  lobby_erstellen() → lobby_created → Net.host_steam(lobby)
##   Gast:  Einladung im Overlay annehmen (join_requested) oder Spiel per
##          "+connect_lobby <id>" starten lassen → lobby_beitreten() →
##          lobby_joined → Net.join_steam(lobby)
## Die Statustexte (#Status_…) liegen in docs/steam/ und müssen in Steamworks
## hochgeladen werden, bevor Steam sie anzeigt.

signal bereit
## Beim Erstellen oder Beitreten ging etwas schief — schluessel ist ein Übersetzungsschlüssel.
signal lobby_fehler(schluessel: String, werte: Array)

## Steams öffentliche Test-App „Spacewar" — gilt, bis die eigene App-ID in den
## Projekteinstellungen unter steam/app_id steht.
const TEST_APP_ID := 480
## Steam-Antwortcodes: EResult OK beim Erstellen, EChatRoomEnterResponse Success beim Beitreten
const ERGEBNIS_OK := 1
const BETRETEN_OK := 1

var aktiv := false
var app_id := TEST_APP_ID
## Warum Steam nicht aktiv ist (für Log und Tests).
var grund := ""
## Lobby, in der wir gerade sind (0 = keine).
var lobby_id := 0
## Lobby aus dem Startbefehl (+connect_lobby) — das Hauptmenü tritt ihr bei.
var start_lobby := 0

var _steam: Object

func _ready() -> void:
	app_id = int(ProjectSettings.get_setting("steam/app_id", TEST_APP_ID))
	if not soll_starten(OS.has_feature("steam"), OS.get_cmdline_user_args().has("--server"),
			Engine.has_singleton("Steam")):
		grund = "kein Steam-Build" if not OS.has_feature("steam") else "Steam-Bibliothek fehlt oder Server"
		return
	starten()

## Wann Steam überhaupt gestartet wird — als reine Funktion, damit sie testbar ist.
static func soll_starten(steam_build: bool, dedizierter_server: bool, bibliothek_da: bool) -> bool:
	return steam_build and not dedizierter_server and bibliothek_da

## Startet Steam das Spiel über eine Einladung, steht "+connect_lobby <id>" im Startbefehl.
static func lobby_aus_argumenten(args: PackedStringArray) -> int:
	var i := args.find("+connect_lobby")
	if i < 0 or i + 1 >= args.size():
		return 0
	return maxi(0, args[i + 1].to_int())

func starten() -> bool:
	_steam = Engine.get_singleton("Steam")
	# Nicht über den Steam-Client gestartet? Dann startet Steam das Spiel richtig
	# neu. Mit der Test-App 480 sinnlos, deshalb nur mit eigener App-ID.
	if app_id != TEST_APP_ID and bool(_steam.call("restartAppIfNecessary", app_id)):
		get_tree().quit()
		return false
	# true = GodotSteam verarbeitet Steams Rückmeldungen selbst (kein run_callbacks nötig)
	var antwort: Variant = _steam.call("steamInitEx", app_id, true)
	var status := int((antwort as Dictionary).get("status", -1)) if antwort is Dictionary else -1
	if status != 0:
		grund = str((antwort as Dictionary).get("verbal", "keine Antwort")) if antwort is Dictionary else "keine Antwort"
		print("[Steam] nicht gestartet (%d): %s — das Spiel läuft ohne Steam weiter" % [status, grund])
		return false
	aktiv = true
	grund = ""
	_steam.connect("lobby_created", _on_lobby_created)
	_steam.connect("lobby_joined", _on_lobby_joined)
	_steam.connect("join_requested", _on_join_requested)
	start_lobby = lobby_aus_argumenten(OS.get_cmdline_args())
	var name := spielername()
	if name != "":
		Net.player_name = name
	print("[Steam] aktiv als %s (App %d)%s" % [name, app_id,
		" · Einladung in Lobby %d" % start_lobby if start_lobby > 0 else ""])
	bereit.emit()
	return true

func spielername() -> String:
	return str(_steam.call("getPersonaName")) if aktiv else ""

## Statusanzeige in der Freundesliste. token: #Status_… aus docs/steam/,
## tag: wird für %tag% eingesetzt (Spieltag), -1 = ohne.
func status_setzen(token: String, tag := -1) -> void:
	if not aktiv:
		return
	if tag >= 0:
		_steam.call("setRichPresence", "tag", str(tag))
	_steam.call("setRichPresence", "steam_display", token)

func status_loeschen() -> void:
	if aktiv:
		_steam.call("clearRichPresence")

# ------------------------------------------------------------ Lobbys (5.3)
## Freundes-Lobby erstellen. Das Ergebnis kommt über lobby_created.
func lobby_erstellen() -> bool:
	if not aktiv:
		return false
	var nur_freunde := ClassDB.class_get_integer_constant("Steam", "LOBBY_TYPE_FRIENDS_ONLY")
	_steam.call("createLobby", nur_freunde, Net.MAX_PLAYERS)
	return true

func lobby_beitreten(id: int) -> bool:
	if not aktiv or id <= 0:
		return false
	_steam.call("joinLobby", id)
	return true

## Overlay mit der Freundesliste zum Einladen öffnen.
func freunde_einladen() -> void:
	if aktiv and lobby_id != 0:
		_steam.call("activateGameOverlayInviteDialog", lobby_id)

func lobby_verlassen() -> void:
	if not aktiv or lobby_id == 0:
		return
	_steam.call("leaveLobby", lobby_id)
	_steam.call("setRichPresence", "connect", "")
	lobby_id = 0

func _on_lobby_created(ergebnis: int, id: int) -> void:
	if ergebnis != ERGEBNIS_OK or id == 0:
		lobby_fehler.emit("NET_STEAM_LOBBY_FAILED", [])
		return
	lobby_id = id
	_steam.call("setLobbyJoinable", id, true)
	# Der Gast prüft das vor dem Verbinden — andere Stände verstehen sich nicht
	_steam.call("setLobbyData", id, "version", Net.version_text())
	_mitspielen_ermoeglichen()
	if Net.host_steam(id) != OK:
		lobby_verlassen()
		lobby_fehler.emit("NET_STEAM_LOBBY_FAILED", [])

func _on_lobby_joined(id: int, _rechte: int, _gesperrt: bool, antwort: int) -> void:
	if antwort != BETRETEN_OK:
		lobby_fehler.emit("NET_STEAM_JOIN_FAILED", [])
		return
	lobby_id = id
	# Der Host bekommt lobby_joined für seine eigene Lobby auch — er hostet schon
	if int(_steam.call("getLobbyOwner", id)) == int(_steam.call("getSteamID")):
		return
	var host_version := str(_steam.call("getLobbyData", id, "version"))
	if host_version != "" and host_version != Net.version_text():
		lobby_verlassen()
		lobby_fehler.emit("NET_VERSION_MISMATCH", [host_version, Net.version_text()])
		return
	_mitspielen_ermoeglichen()
	if Net.join_steam(id) != OK:
		lobby_verlassen()
		lobby_fehler.emit("NET_STEAM_JOIN_FAILED", [])

## Einladung im Overlay angenommen, während das Spiel läuft. Aus einem laufenden
## Spiel erst ins Hauptmenü (speichert als Host), das tritt dann bei.
func _on_join_requested(id: int, _freund: int) -> void:
	var szene := get_tree().current_scene
	if szene != null and szene.has_method("net_book_tent"):
		start_lobby = id
		Net.zum_menue()
	else:
		lobby_beitreten(id)

## "Spiel beitreten" in der Steam-Freundesliste zeigt auf diese Lobby.
func _mitspielen_ermoeglichen() -> void:
	_steam.call("setRichPresence", "connect", "+connect_lobby %d" % lobby_id)
