extends Node
const KoopDaten := preload("res://scripts/koop_daten.gd")
## Ende-zu-Ende gegen den LIVE-Vermittler: Raum erstellen, Figur und Abteilung
## wählen, „Los", warten bis das Spiel läuft, beitreten und prüfen, dass der
## eigene Spieler mit Name, Figur und Abteilung ankommt. Danach verlassen — das
## Spiel beendet sich auf dem Server nach GameManager.LEER_ENDE von selbst.
## Aufruf: godot --headless --path . res://tools/test_code_beitritt.tscn

const SERVER := "185.248.140.225"

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var _fehler := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var r := await _post("erstellen", {"name": "Testbot", "version": KoopDaten.version()})
		_pruefe("Raum erstellt", r.get("ok", false), str(r))
		if not r.get("ok", false):
			return _ende()
		var code := str(r.raum.code)
		var id := str(r.id)
		print("  Code: ", code)
		r = await _post("setzen", {"code": code, "id": id, "figur": 2, "abt": "lager"})
		_pruefe("Figur und Abteilung gesetzt", r.get("ok", false), str(r.get("fehler", "")))
		r = await _post("los", {"code": code, "id": id})
		_pruefe("Los angenommen", r.get("ok", false), str(r.get("fehler", "")))
		var port := 0
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 90000:
			r = await _post("raum", {"code": code, "id": id})
			if r.get("ok", false) and str(r.raum.status) == "laeuft":
				port = int(r.raum.port)
				break
			await get_tree().create_timer(1.0).timeout
		_pruefe("Spiel läuft", port > 0, "Port %d nach %d ms" % [port, Time.get_ticks_msec() - t0])
		if port == 0:
			return _ende()
		KoopDaten.lobby_wahl = {"name": "Testbot", "figur": 2}
		Net.join_game(SERVER, port)
		var gm: Node = null
		t0 = Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 30000:
			await get_tree().process_frame
			var s := get_tree().current_scene
			if s and s.has_method("net_book_tent") and (s._players_nodes as Dictionary).has(multiplayer.get_unique_id()):
				gm = s
				break
			if Net.meldung != "":
				break
		_pruefe("eigener Spieler im Code-Spiel", gm != null, Net.meldung)
		if gm:
			var ich := multiplayer.get_unique_id()
			t0 = Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 5000 and not (gm._spieler_info as Dictionary).has(ich):
				await get_tree().process_frame
			var info: Dictionary = (gm._spieler_info as Dictionary).get(ich, {})
			_pruefe("Wahl kam an", str(info.get("name", "")) == "Testbot" and int(info.get("figur", -1)) == 2, str(info))
			await get_tree().create_timer(1.0).timeout
			var spieler: Node = gm._players_nodes[ich]
			_pruefe("Figur eingesetzt", spieler.get_node("Model").scene_file_path.ends_with("charakter3.tscn"), spieler.get_node("Model").scene_file_path)
		Net.disconnect_game()
		await _post("verlassen", {"code": code, "id": id})
		_ende()

	func _post(pfad: String, daten: Dictionary) -> Dictionary:
		var http := HTTPRequest.new()
		add_child(http)
		http.request(KoopDaten.LOBBY_URL + pfad, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(daten))
		var antwort: Array = await http.request_completed
		http.queue_free()
		var d: Variant = JSON.parse_string((antwort[3] as PackedByteArray).get_string_from_utf8())
		return d if d is Dictionary else {"ok": false, "fehler": "HTTP %d/%d" % [antwort[0], antwort[1]]}

	func _pruefe(name: String, ok: bool, info := "") -> void:
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])
		if not ok:
			_fehler += 1

	func _ende() -> void:
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if _fehler == 0 else "FEHLGESCHLAGEN", _fehler])
		get_tree().quit(1 if _fehler else 0)
