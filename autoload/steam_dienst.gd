extends Node
## Steam-Anbindung (Plan 5.2): Start, Statusanzeige in der Freundesliste,
## Steam-Name. Läuft nur im Steam-Build (Merkmal "steam") und nie auf dem
## dedizierten Server.
##
## Zugriff ausschließlich über Engine.get_singleton("Steam"), nie über den
## Klassennamen: Die GodotSteam-Bibliotheken liegen neben der .exe, nicht im
## Paket. Spieler des Direkt-Builds bekommen Updates nur als Paket und haben sie
## nicht — ein "Steam." im Code würde dort das ganze Skript unladbar machen.
##
## Die Statustexte (#Status_…) liegen in docs/steam/ und müssen in Steamworks
## hochgeladen werden, bevor Steam sie anzeigt.

signal bereit

## Steams öffentliche Test-App „Spacewar" — gilt, bis die eigene App-ID in den
## Projekteinstellungen unter steam/app_id steht.
const TEST_APP_ID := 480

var aktiv := false
var app_id := TEST_APP_ID
## Warum Steam nicht aktiv ist (für Log und Tests).
var grund := ""

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
	var name := spielername()
	if name != "":
		Net.player_name = name
	print("[Steam] aktiv als %s (App %d)" % [name, app_id])
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
