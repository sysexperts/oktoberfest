extends Node
## Tritt mit dem aktuellen Projektstand dem LIVE-Server bei und meldet, was passiert:
## eigener Spieler erscheint (BEITRITT OK) oder Meldung beim Zurück ins Menü.
## Für die Fehlersuche „lädt kurz, dann wieder im Menü". Schreibt keinen Spielstand
## (auf dem Client speichert nur der Server).
## Aufruf: godot --headless --path . res://tools/test_live_beitritt.tscn

const SERVER := "185.248.140.225"
const ZEITLIMIT := 45.0

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		print("[LIVE] Version dieses Clients: ", Net.version_text())
		var err := Net.join_game(SERVER)
		print("[LIVE] join_game: ", err)
		var t := 0.0
		while t < ZEITLIMIT:
			await get_tree().process_frame
			t += get_process_delta_time()
			var szene := get_tree().current_scene
			if szene and szene.has_method("net_book_tent") and szene.get("_players_nodes") is Dictionary:
				if (szene._players_nodes as Dictionary).has(multiplayer.get_unique_id()):
					print("[LIVE] BEITRITT OK — eigener Spieler nach %.1f s, Mitspieler: %d" % [t, (szene._players_nodes as Dictionary).size()])
					await get_tree().create_timer(3.0).timeout
					_ende()
					return
			if Net.meldung != "":
				print("[LIVE] ZURUECK INS MENUE nach %.1f s — Meldung: %s %s" % [t, Net.meldung, str(Net.meldung_werte)])
				_ende()
				return
		print("[LIVE] ZEITLIMIT — weder Spieler noch Meldung. Szene: ", get_tree().current_scene.name if get_tree().current_scene else "keine")
		_ende()

	func _ende() -> void:
		Net.disconnect_game()
		print("[LIVE] FERTIG")
		get_tree().quit()
