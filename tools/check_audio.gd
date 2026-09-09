extends SceneTree
## Prüft: gibt es die Busse, findet Sfx seine Klänge, greift der Rückfall?
func _init() -> void:
	print("Busse: ", range(AudioServer.bus_count).map(func(i): return AudioServer.get_bus_name(i)))
	var s := Sfx.new()
	root.add_child(s)
	_los(s)

func _los(s: Node) -> void:
	await process_frame
	await process_frame
	var d = s.get("_streams")
	print("Klänge geladen: %d -> %s" % [d.size(), str(d.keys())])
	var pl = s.get("_playlist")
	print("Musikstücke gefunden: %d" % pl.size())
	print("Musik-Bus: %s   Ambiente-Bus: %s" % [s.get("_music_player").bus, s.get("_crowd_player").bus])
	s.play("cheer")
	await process_frame
	print("Abspielen ohne Fehler: ok")
	quit()
