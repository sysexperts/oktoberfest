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
##   Warteraum (scenes/ui/steam_warteraum.tscn) öffnet sich bei lobby_betreten;
##   erst dort startet der Host das Spiel (Net.host_steam), die Gäste folgen
##   (Net.join_steam), sobald die Lobbydaten "start" = 1 zeigen.
##   Host:  lobby_erstellen() → lobby_created → Warteraum
##   Gast:  Einladung im Overlay annehmen (join_requested) oder Spiel per
##          "+connect_lobby <id>" starten lassen → lobby_beitreten() →
##          lobby_joined → Warteraum
## Die Statustexte (#Status_…) liegen in docs/steam/ und müssen in Steamworks
## hochgeladen werden, bevor Steam sie anzeigt.

signal bereit
## Beim Erstellen oder Beitreten ging etwas schief — schluessel ist ein Übersetzungsschlüssel.
signal lobby_fehler(schluessel: String, werte: Array)
## Wir sind in einer Lobby (erstellt oder beigetreten) — der Warteraum öffnet sich.
## Das Spiel selbst startet erst, wenn der Host dort „Spiel starten" drückt.
signal lobby_betreten(id: int)
## Mitglieder, Lobbydaten, Profilbilder oder Freundesstatus haben sich geändert.
signal lobby_aktualisiert

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
## Beitrittscode der eigenen Lobby (z. B. "BREZN-57"), "" ohne Lobby. Liegt als
## Lobbydaten "code" bei Steam — wer ihn eingibt, findet die Lobby über Steams
## Lobbysuche, ganz ohne eigenen Server.
var lobby_code := ""

const CODE_WOERTER := ["BREZN", "KRUG", "ZELT", "GAUDI", "PROST", "DIRNDL", "MASS", "HENDL", "WIESN", "RADI"]

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
	_steam.connect("lobby_match_list", _on_lobby_match_list)
	for signal_name: String in ["lobby_data_update", "lobby_chat_update", "avatar_loaded", "persona_state_change"]:
		if _steam.has_signal(signal_name):
			_steam.connect(signal_name, _on_lobby_geaendert)
	start_lobby = lobby_aus_argumenten(OS.get_cmdline_args())
	# Sprache wie in Steam eingestellt (bei "auto" in den Spieleinstellungen)
	var sp := str(_steam.call("getCurrentGameLanguage"))
	Einstellungen.steam_sprache = {"german": "de", "turkish": "tr"}.get(sp, "en")
	Einstellungen.anwenden()
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

# ------------------------------------------------------------ Controller-Typ
## Welche Art Controller haengt dran? "playstation", "xbox", "deck" oder "".
##
## Warum ueber Steam und nicht ueber den Geraetenamen: Steam Input legt sich
## zwischen Controller und Spiel und meldet ein PlayStation-Pad meist als Xbox.
## Das Spiel wuerde dann Xbox-Knoepfe anzeigen, obwohl ein DualSense in der Hand
## liegt. Steam selbst kennt den echten Typ — hier wird er erfragt.
##
## Zahlen aus ESteamInputType (Steamworks SDK).
const STEAM_PAD_TYP := {
	2: "xbox",        # Xbox 360
	3: "xbox",        # Xbox One
	5: "playstation", # PS4 (DUALSHOCK 4)
	12: "playstation",# PS3
	13: "playstation",# PS5 (DualSense)
	14: "deck",       # Steam Deck
}
var _input_bereit := false

func pad_typ() -> String:
	if not aktiv or not _steam.has_method("getConnectedControllers"):
		return ""
	if not _input_bereit:
		if _steam.has_method("inputInit"):
			_steam.call("inputInit", false)
		_input_bereit = true
	var handles: Variant = _steam.call("getConnectedControllers")
	if not (handles is Array) or (handles as Array).is_empty():
		return ""
	var typ := int(_steam.call("getInputTypeForHandle", (handles as Array)[0]))
	return str(STEAM_PAD_TYP.get(typ, ""))

# ------------------------------------------------------------ Bildschirmtastatur
## Steams schwebende Tastatur über einem Eingabefeld — am Steam Deck die einzige
## Möglichkeit, einen Namen einzutippen. Das Feld wird in Bildschirmkoordinaten
## übergeben, damit Steam sie nicht darüber legt.
##
## Gibt false zurück, wenn Steam nicht läuft, die Bibliothek diese Funktion nicht
## kennt (ältere GodotSteam-Fassungen) oder gerade mit Maus und Tastatur gespielt
## wird. Der Aufrufer muss nichts prüfen.
func tastatur_zeigen(feld: Control) -> bool:
	if not aktiv or feld == null or not Einstellungen.am_pad:
		return false
	if not _steam.has_method("showFloatingGamepadTextInput"):
		return false
	var r := feld.get_global_rect()
	# 0 = einzeilig
	return bool(_steam.call("showFloatingGamepadTextInput", 0,
		int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y)))

func tastatur_verstecken() -> void:
	if aktiv and _steam.has_method("dismissFloatingGamepadTextInput"):
		_steam.call("dismissFloatingGamepadTextInput")

# ------------------------------------------------------------ Errungenschaften (5.4)
## Schaltet eine Steam-Errungenschaft frei. API-Name = Meilenstein-ID aus
## scripts/meilensteine.gd — in Steamworks genauso anlegen (docs/steam/errungenschaften.md).
## Doppelt freischalten schadet nicht. Ohne Steam: false.
func errungenschaft(id: String) -> bool:
	if not aktiv:
		return false
	var ok := bool(_steam.call("setAchievement", id))
	_steam.call("storeStats")
	return ok

# ------------------------------------------------------------ Lobbys (5.3)
## Freundes-Lobby erstellen. Das Ergebnis kommt über lobby_created.
func lobby_erstellen() -> bool:
	if not aktiv:
		return false
	# Öffentlich, damit die Codesuche sie findet. In keiner Liste sichtbar,
	# denn das Spiel sucht nur mit exaktem Code.
	var oeffentlich := ClassDB.class_get_integer_constant("Steam", "LOBBY_TYPE_PUBLIC")
	_steam.call("createLobby", oeffentlich, Net.MAX_PLAYERS)
	return true

## "brezn 57", "BREZN-57" → "BREZN57" (so steht er in den Lobbydaten)
static func code_normal(code: String) -> String:
	var aus := ""
	for z in code.to_upper():
		if (z >= "A" and z <= "Z") or (z >= "0" and z <= "9"):
			aus += z
	return aus

static func code_neu() -> String:
	return "%s-%02d" % [CODE_WOERTER[randi() % CODE_WOERTER.size()], randi() % 100]

## Lobby per Code suchen und beitreten. Fehler kommen über lobby_fehler.
func lobby_per_code(code: String) -> bool:
	var c := code_normal(code)
	if not aktiv or c.length() < 3:
		return false
	_steam.call("addRequestLobbyListStringFilter", "code", c,
		ClassDB.class_get_integer_constant("Steam", "LOBBY_COMPARISON_EQUAL"))
	_steam.call("addRequestLobbyListDistanceFilter",
		ClassDB.class_get_integer_constant("Steam", "LOBBY_DISTANCE_FILTER_WORLDWIDE"))
	_steam.call("addRequestLobbyListResultCountFilter", 1)
	_steam.call("requestLobbyList")
	return true

func _on_lobby_match_list(lobbies: Array) -> void:
	if lobbies.is_empty():
		lobby_fehler.emit("NET_CODE_UNKNOWN", [])
		return
	lobby_beitreten(int(lobbies[0]))

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
	lobby_code = ""

func _on_lobby_created(ergebnis: int, id: int) -> void:
	if ergebnis != ERGEBNIS_OK or id == 0:
		lobby_fehler.emit("NET_STEAM_LOBBY_FAILED", [])
		return
	lobby_id = id
	_steam.call("setLobbyJoinable", id, true)
	# Der Gast prüft das vor dem Verbinden — andere Stände verstehen sich nicht
	_steam.call("setLobbyData", id, "version", Net.version_text())
	lobby_code = code_neu()
	_steam.call("setLobbyData", id, "code", code_normal(lobby_code))
	# Mit Bindestrich, so zeigt ihn der Warteraum auch den Gästen
	_steam.call("setLobbyData", id, "code_text", lobby_code)
	_mitspielen_ermoeglichen()
	lobby_betreten.emit(id)

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
	lobby_betreten.emit(id)

# ------------------------------------------------------------ Warteraum
## Alles, was der Warteraum (scripts/ui/steam_warteraum.gd) von Steam braucht.
## Ohne Steam liefern die Funktionen leere Werte.
const FREUND_FLAG_DIREKT := 4 ## k_EFriendFlagImmediate: echte Freunde, keine Gruppen
var _avatare := {}
var _avatar_angefragt := {}

func _on_lobby_geaendert(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
	lobby_aktualisiert.emit()

func eigene_id() -> int:
	return int(_steam.call("getSteamID")) if aktiv else 0

func lobby_host_id() -> int:
	return int(_steam.call("getLobbyOwner", lobby_id)) if aktiv and lobby_id != 0 else 0

func bin_lobby_host() -> bool:
	return aktiv and lobby_id != 0 and lobby_host_id() == eigene_id()

## Wer in der Lobby ist: [{id, name, ich, host, figur (-1 = noch keine), bereit}]
func lobby_mitglieder() -> Array:
	var liste: Array = []
	if not aktiv or lobby_id == 0:
		return liste
	var host := lobby_host_id()
	var ich := eigene_id()
	for i in int(_steam.call("getNumLobbyMembers", lobby_id)):
		var sid := int(_steam.call("getLobbyMemberByIndex", lobby_id, i))
		var figur := str(_steam.call("getLobbyMemberData", lobby_id, sid, "figur"))
		liste.append({
			"id": sid,
			"name": str(_steam.call("getFriendPersonaName", sid)),
			"ich": sid == ich,
			"host": sid == host,
			"figur": int(figur) if figur != "" else -1,
			"bereit": str(_steam.call("getLobbyMemberData", lobby_id, sid, "bereit")) == "1",
		})
	return liste

func mitglied_setzen(schluessel: String, wert: String) -> void:
	if aktiv and lobby_id != 0:
		_steam.call("setLobbyMemberData", lobby_id, schluessel, wert)

func lobby_wert(schluessel: String) -> String:
	return str(_steam.call("getLobbyData", lobby_id, schluessel)) if aktiv and lobby_id != 0 else ""

## Nur der Host darf Lobbydaten setzen.
func lobby_setzen(schluessel: String, wert: String) -> void:
	if aktiv and lobby_id != 0:
		_steam.call("setLobbyData", lobby_id, schluessel, wert)

## Steam-Profilbild als Textur, null solange Steam es noch lädt (dann kommt
## lobby_aktualisiert). Der Aufrufer zeigt bis dahin den Anfangsbuchstaben.
func avatar_textur(sid: int) -> Texture2D:
	if _avatare.has(sid):
		return _avatare[sid]
	if not aktiv or not _steam.has_method("getMediumFriendAvatar"):
		return null
	var handle := int(_steam.call("getMediumFriendAvatar", sid))
	if handle <= 0:
		# Fremde Profile erst anfordern; Steam meldet sich mit avatar_loaded
		if not _avatar_angefragt.has(sid) and _steam.has_method("requestUserInformation"):
			_avatar_angefragt[sid] = true
			_steam.call("requestUserInformation", sid, false)
		return null
	var groesse: Variant = _steam.call("getImageSize", handle)
	var rgba: Variant = _steam.call("getImageRGBA", handle)
	if not (groesse is Dictionary) or not (rgba is Dictionary):
		return null
	var b := int((groesse as Dictionary).get("width", 0))
	var h := int((groesse as Dictionary).get("height", 0))
	var daten: PackedByteArray = (rgba as Dictionary).get("buffer", PackedByteArray())
	if b <= 0 or h <= 0 or daten.size() != b * h * 4:
		return null
	var tex := ImageTexture.create_from_image(Image.create_from_data(b, h, false, Image.FORMAT_RGBA8, daten))
	_avatare[sid] = tex
	return tex

## Freunde, die gerade erreichbar sind: [{id, name, status, im_spiel}]. status:
## "spielt" (dieses Spiel), "online", "abwesend". Offline-Freunde fehlen.
func freunde() -> Array:
	var liste: Array = []
	if not aktiv:
		return liste
	for i in int(_steam.call("getFriendCount", FREUND_FLAG_DIREKT)):
		var sid := int(_steam.call("getFriendByIndex", i, FREUND_FLAG_DIREKT))
		var zustand := int(_steam.call("getFriendPersonaState", sid))
		if zustand == 0:
			continue
		var spiel: Variant = _steam.call("getFriendGamePlayed", sid)
		var spielt := spiel is Dictionary and int((spiel as Dictionary).get("id", 0)) == app_id
		var status := "spielt" if spielt else ("online" if zustand == 1 or zustand >= 5 else "abwesend")
		liste.append({"id": sid, "name": str(_steam.call("getFriendPersonaName", sid)), "status": status})
	var rang := {"spielt": 0, "online": 1, "abwesend": 2}
	liste.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return rang[a["status"]] < rang[b["status"]] or (rang[a["status"]] == rang[b["status"]] and str(a["name"]) < str(b["name"])))
	return liste

func freund_einladen(sid: int) -> void:
	if aktiv and lobby_id != 0:
		_steam.call("inviteUserToLobby", lobby_id, sid)

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
