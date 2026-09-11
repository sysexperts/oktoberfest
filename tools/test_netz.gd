extends Node
## Netztest (Plan 5.5), Client-Seite. Wird von tools/test_netz.sh gestartet,
## das daneben einen dedizierten Server auf 127.0.0.1 laufen lässt.
## Prüft nacheinander:
##   1 Beitritt zu einem leeren Port → Zeitlimit greift, Meldung NET_TIMEOUT
##   2 Beitritt zum Server → eigener Spieler erscheint
##   3 Server wird beendet (vom Skript) → zurück ins Menü, Meldung NET_HOST_LEFT
## Druckt "BEREIT", sobald das Skript den Server beenden soll.

const LEERER_PORT := 8699

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var fehler := 0
	var _fehlgeschlagen := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().create_timer(150.0).timeout.connect(func() -> void:
			print("ERGEBNIS: ABBRUCH nach Zeitlimit")
			get_tree().quit(2))
		Net.connection_failed.connect(func() -> void: _fehlgeschlagen = true)

		print("  -- Zeitlimit beim Beitritt")
		var start := Time.get_ticks_msec()
		Net.join_game("127.0.0.1", LEERER_PORT)
		while not _fehlgeschlagen and Time.get_ticks_msec() - start < 20000:
			await get_tree().process_frame
		var dauer := Time.get_ticks_msec() - start
		_check("Beitritt ohne Server scheitert", _fehlgeschlagen, "%d ms" % dauer)
		_check("Meldung Zeitlimit", Net.meldung == "NET_TIMEOUT", Net.meldung)
		_check("nach etwa 10 s, nicht ewig", dauer < 14000, "%d ms" % dauer)
		Net.meldung = ""

		print("  -- Beitritt zum Server")
		Net.join_game("127.0.0.1", Net.DEFAULT_PORT)
		start = Time.get_ticks_msec()
		var gespawnt := false
		while Time.get_ticks_msec() - start < 60000:
			var s := get_tree().current_scene
			if s != null and s.has_method("net_book_tent") and s.has_node("Players/%d" % multiplayer.get_unique_id()):
				gespawnt = true
				break
			await get_tree().process_frame
		_check("eigener Spieler erscheint", gespawnt, "%d ms" % (Time.get_ticks_msec() - start))
		if not gespawnt:
			_ende()
			return
		_check("keine Fehlmeldung beim Beitritt", Net.meldung == "", Net.meldung)

		print("  -- Server beenden")
		print("BEREIT")
		start = Time.get_ticks_msec()
		var gesehen := ""
		# Das Hauptmenü leert die Meldung beim Anzeigen — deshalb unterwegs mitlesen
		while Time.get_ticks_msec() - start < 60000:
			if Net.meldung != "":
				gesehen = Net.meldung
			var s := get_tree().current_scene
			if gesehen != "" and s != null and not s.has_method("net_book_tent"):
				break
			await get_tree().process_frame
		_check("Host weg: Meldung", gesehen == "NET_HOST_LEFT", gesehen)
		var s := get_tree().current_scene
		_check("Host weg: raus aus dem Spiel", s != null and not s.has_method("net_book_tent"), str(s.name) if s else "")
		_check("Host weg: kein Netz mehr", multiplayer.multiplayer_peer is OfflineMultiplayerPeer, "")
		_ende()

	func _ende() -> void:
		print("ERGEBNIS: %s (%d Fehler)" % ["BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN", fehler])
		get_tree().quit(0 if fehler == 0 else 1)

	func _check(name: String, ok: bool, info: String) -> void:
		if not ok:
			fehler += 1
		print("  [%s] %s  %s" % ["OK  " if ok else "FAIL", name, info])
