extends SceneTree
## Prüft, ob die GodotSteam-Erweiterung (addons/godotsteam) geladen wird und die
## Klassen da sind, die Plan 5.2/5.3 brauchen. Startet Steam dabei nicht.
## Aufruf: godot --headless --path . --script res://tools/steam_klassen.gd

func _init() -> void:
	for klasse in ["Steam", "SteamMultiplayerPeer"]:
		print("KLASSE %-22s %s" % [klasse, "da" if ClassDB.class_exists(klasse) else "FEHLT"])
	if Engine.has_singleton("Steam"):
		var steam := Engine.get_singleton("Steam")
		print("Steam-Singleton: da · GodotSteam ", steam.call("get_godotsteam_version") if steam.has_method("get_godotsteam_version") else "?")
	else:
		print("Steam-Singleton: FEHLT")
	quit()
