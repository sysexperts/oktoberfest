extends SceneTree
## Prüft, ob die GodotSteam-Erweiterung (addons/godotsteam) geladen wird, die
## Klassen da sind, die Plan 5.2/5.3 brauchen, und ob die Funktionen, die
## autoload/steam_dienst.gd aufruft, in dieser GodotSteam-Version existieren.
## Startet Steam dabei nicht.
## Aufruf: godot --headless --path . --script res://tools/steam_klassen.gd

## Was steam_dienst.gd über call() aufruft — ein Tippfehler dort fiele sonst
## erst im Steam-Client auf.
const GENUTZTE_FUNKTIONEN := ["steamInitEx", "restartAppIfNecessary", "getPersonaName",
	"setRichPresence", "clearRichPresence",
	# Lobbys (5.3)
	"createLobby", "joinLobby", "leaveLobby", "getLobbyOwner", "getSteamID", "setLobbyJoinable",
	"setLobbyData", "getLobbyData", "activateGameOverlayInviteDialog"]
## Signale, die steam_dienst.gd verbindet
const GENUTZTE_SIGNALE := ["lobby_created", "lobby_joined", "join_requested"]
## Methoden von SteamMultiplayerPeer, die net.gd aufruft
const PEER_FUNKTIONEN := ["host_with_lobby", "connect_to_lobby"]

func _init() -> void:
	for klasse in ["Steam", "SteamMultiplayerPeer"]:
		print("KLASSE %-22s %s" % [klasse, "da" if ClassDB.class_exists(klasse) else "FEHLT"])
	if not Engine.has_singleton("Steam"):
		print("Steam-Singleton: FEHLT")
		quit(1)
		return
	var steam := Engine.get_singleton("Steam")
	print("Steam-Singleton: da · GodotSteam ", steam.call("get_godotsteam_version") if steam.has_method("get_godotsteam_version") else "?")
	var fehlt := 0
	for f: String in GENUTZTE_FUNKTIONEN:
		var da := steam.has_method(f)
		if not da:
			fehlt += 1
		print("FUNKTION %-32s %s" % [f, "da" if da else "FEHLT"])
	for s: String in GENUTZTE_SIGNALE:
		var da := steam.has_signal(s)
		if not da:
			fehlt += 1
		print("SIGNAL   %-32s %s" % [s, "da" if da else "FEHLT"])
	for f: String in PEER_FUNKTIONEN:
		var da := ClassDB.class_has_method("SteamMultiplayerPeer", f)
		if not da:
			fehlt += 1
		print("PEER     %-32s %s" % [f, "da" if da else "FEHLT"])
	print("ERGEBNIS: %s" % ["BESTANDEN" if fehlt == 0 else "FEHLGESCHLAGEN (%d fehlen)" % fehlt])
	quit(0 if fehlt == 0 else 1)
