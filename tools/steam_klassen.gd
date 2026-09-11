extends SceneTree
## Prüft, ob die GodotSteam-Erweiterung (addons/godotsteam) geladen wird, die
## Klassen da sind, die Plan 5.2/5.3 brauchen, und ob die Funktionen, die
## autoload/steam_dienst.gd aufruft, in dieser GodotSteam-Version existieren.
## Startet Steam dabei nicht.
## Aufruf: godot --headless --path . --script res://tools/steam_klassen.gd

## Was steam_dienst.gd über call() aufruft — ein Tippfehler dort fiele sonst
## erst im Steam-Client auf.
const GENUTZTE_FUNKTIONEN := ["steamInitEx", "restartAppIfNecessary", "getPersonaName",
	"setRichPresence", "clearRichPresence"]

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
		print("FUNKTION %-24s %s" % [f, "da" if da else "FEHLT"])
	print("ERGEBNIS: %s" % ["BESTANDEN" if fehlt == 0 else "FEHLGESCHLAGEN (%d fehlen)" % fehlt])
	quit(0 if fehlt == 0 else 1)
