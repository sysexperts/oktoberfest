extends Node
## Ein Bot für den Koop-Probelauf (tools/test_koop_bots.sh startet vier davon).
## Spielt gegen den LIVE-Vermittler und ein echtes Code-Spiel auf dem Server den
## Ablauf einer neuen Gruppe durch: Warteraum → Spiel → Zelt, Tische, Ware,
## Personal, Abstimmung (erst Nein, dann Ja) → Schicht mit Gästen →
## ein Bot fliegt raus und kommt per Code zurück.
##
## Die Bots sprechen sich nicht ab — jeder wartet auf sichtbaren Spielstand
## (Zelt gemietet, Tische da …) und handelt dann nach seiner Rolle.
## Aufruf: godot --headless --path . res://tools/test_koop_bot.tscn -- --bot chef --datei <pfad>
const KoopDaten := preload("res://scripts/koop_daten.gd")
const Figuren := preload("res://scripts/figuren.gd")

const SERVER := "185.248.140.225"
const ROLLEN := {
	"chef": {"name": "Bot-Chef", "figur": 0},
	"koch": {"name": "Bot-Koch", "figur": 1},
	"lager": {"name": "Bot-Lager", "figur": 2},
	"putz": {"name": "Bot-Putz", "figur": 1},
}
const ZELTNAME := "Bot-Zelt"
const ROLE_REINIGUNG := 3

func _ready() -> void:
	var lauf := Lauf.new()
	get_tree().root.add_child.call_deferred(lauf)

class Lauf extends Node:
	var rolle := ""
	var ich := {}
	var datei := ""
	var fehler := 0
	var code := ""
	var id := ""
	var gm: Node

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		var args := OS.get_cmdline_user_args()
		rolle = args[args.find("--bot") + 1]
		datei = args[args.find("--datei") + 1]
		ich = ROLLEN[rolle]
		get_tree().create_timer(900.0).timeout.connect(func() -> void:
			_log("ABBRUCH nach Zeitlimit")
			_ende())
		await _warteraum()
		if code == "":
			return _ende()
		if not await _beitreten():
			return _ende()
		await _spielen()
		_ende()

	# ------------------------------------------------------------ Warteraum
	func _warteraum() -> void:
		_log("-- Warteraum")
		if rolle == "chef":
			var r := await _post("erstellen", {"name": ich.name, "version": KoopDaten.version()})
			_pruefe("Raum erstellt", r.get("ok", false), str(r.get("fehler", "")))
			if not r.get("ok", false):
				return
			id = str(r.id)
			code = str(r.raum.code)
			r = await _post("setzen", {"code": code, "id": id, "figur": ich.figur})
			_pruefe("eigene Wahl gesetzt", r.get("ok", false), str(r.get("fehler", "")))
			var f := FileAccess.open(datei, FileAccess.WRITE)
			f.store_string(code)
			f.close()
			_log("Code " + code)
			# Auf alle warten (und dabei Lebenszeichen senden)
			var raum := {}
			for i in 150:
				r = await _post("raum", {"code": code, "id": id})
				if r.get("ok", false):
					raum = r.raum
					if (raum.spieler as Array).size() >= 4:
						break
				await _warte(1.0)
			_pruefe("alle vier im Warteraum", (raum.get("spieler", []) as Array).size() == 4, _namen(raum))
			r = await _post("los", {"code": code, "id": id})
			_pruefe("Los angenommen", r.get("ok", false), str(r.get("fehler", "")))
			return
		# Gäste: kurz versetzt beitreten
		await _warte({"koch": 1.0, "lager": 2.5, "putz": 4.0}[rolle])
		for i in 90:
			if FileAccess.file_exists(datei):
				code = FileAccess.get_file_as_string(datei).strip_edges()
				if code != "":
					break
			await _warte(1.0)
		_pruefe("Code vom Chef bekommen", code != "", "")
		if code == "":
			return
		if rolle == "lager":
			var falsch := await _post("beitreten", {"code": "FALSCH-00", "name": ich.name, "version": KoopDaten.version()})
			_pruefe("falscher Code abgelehnt", str(falsch.get("fehler", "")) == "LOBBY_ERR_CODE", str(falsch.get("fehler", "")))
		if rolle == "putz":
			var alt := await _post("beitreten", {"code": code, "name": ich.name, "version": "1"})
			_pruefe("alte Version abgelehnt", str(alt.get("fehler", "")) == "LOBBY_ERR_VERSION", str(alt.get("fehler", "")))
		# Kleinbuchstaben ohne Bindestrich — so tippen Leute Codes ab
		var getippt := code.to_lower().replace("-", "") if rolle == "koch" else code
		var r := await _post("beitreten", {"code": getippt, "name": ich.name, "version": KoopDaten.version()})
		_pruefe("mit Code beigetreten", r.get("ok", false), str(r.get("fehler", "")) + " " + getippt)
		if not r.get("ok", false):
			code = ""
			return
		id = str(r.id)
		r = await _post("setzen", {"code": code, "id": id, "figur": ich.figur})
		_pruefe("eigene Wahl gesetzt", r.get("ok", false), str(r.get("fehler", "")))

	func _namen(raum: Dictionary) -> String:
		var n: Array[String] = []
		for s: Dictionary in raum.get("spieler", []):
			n.append("%s/%s" % [s.name, s.figur])
		return ", ".join(n)

	## Warten, bis das Spiel läuft, dann verbinden. Gibt true zurück, wenn der
	## eigene Spieler im Spiel steht.
	func _beitreten(nachzuegler := false) -> bool:
		var port := 0
		for i in 120:
			var r := await _post("raum", {"code": code, "id": id})
			if r.get("ok", false):
				var status := str(r.raum.status)
				var dabei := false
				for s: Dictionary in r.raum.spieler:
					if s.get("ich", false):
						dabei = s.get("im_spiel", false)
				if status == "laeuft" and not dabei and nachzuegler:
					r = await _post("los", {"code": code, "id": id})
					dabei = r.get("ok", false)
				if status == "laeuft" and dabei:
					port = int(r.raum.port)
					break
			await _warte(1.0)
		_pruefe("Spiel läuft auf dem Server", port > 0, "Port %d" % port)
		if port == 0:
			return false
		KoopDaten.lobby_wahl = {"name": ich.name, "figur": ich.figur, "id": id}
		Net.meldung = ""
		Net.join_game(SERVER, port)
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < 60000:
			await get_tree().process_frame
			var s := get_tree().current_scene
			if s and s.has_method("net_book_tent") and (s._players_nodes as Dictionary).has(multiplayer.get_unique_id()):
				gm = s
				break
			if Net.meldung != "":
				break
		_pruefe("im Spiel angekommen", gm != null, "%d ms %s" % [Time.get_ticks_msec() - t0, Net.meldung])
		return gm != null

	# ------------------------------------------------------------ Spiel
	func _spielen() -> void:
		_log("-- Spiel")
		# 1 Alle da, Namen und Figuren stimmen
		var ok := await _bis(func() -> bool: return gm._players_nodes.size() == 4 and gm._spieler_info.size() == 4, 90.0)
		_pruefe("vier Spieler im Spiel", ok, "%d Spieler, %d Infos" % [gm._players_nodes.size(), gm._spieler_info.size()])
		await _warte(1.0)
		_figuren_und_namen_pruefen()

		# 2 Chef mietet das Zelt mit Namen
		if rolle == "chef":
			gm.net_book_tent.rpc_id(1, ZELTNAME)
		ok = await _bis(func() -> bool: return gm._tent_stage == 1, 30.0)
		_pruefe("Zelt gemietet (bei allen)", ok, "Stufe %d" % gm._tent_stage)
		ok = await _bis(func() -> bool: return gm._zelt_name == ZELTNAME, 10.0)
		var schild := ""
		for l in get_tree().get_nodes_in_group("zeltname"):
			schild = (l as Label3D).text
		_pruefe("Zeltname am Eingang", ok and schild == ZELTNAME, schild)

		# 3 Koch stellt zwei Tische auf
		if rolle == "koch":
			gm.net_buy_table.rpc_id(1)
			await _warte(0.6)
			gm.net_buy_table.rpc_id(1)
		ok = await _bis(func() -> bool: return gm._active_count >= 2, 30.0)
		_pruefe("zwei Tische", ok, "%d" % gm._active_count)

		# 4 Lager bestellt Bier
		if rolle == "lager":
			gm.net_order_goods.rpc_id(1, 1, 2)
		ok = await _bis(func() -> bool: return int(_zustand().get("pending", 0)) >= 1 or int(_zustand().get("bier", 0)) > 0, 30.0)
		_pruefe("Bier bestellt", ok, "offen %s, Bier %s" % [_zustand().get("pending", 0), _zustand().get("bier", 0)])

		# 5 Personal: jeder Spieler darf im Wiesenbüro einstellen
		await _warte(1.0)
		if rolle == "putz":
			gm.net_hire_staff.rpc_id(1, ROLE_REINIGUNG)
		ok = await _bis(func() -> bool: return _putzkraefte() == 1, 10.0)
		_pruefe("Spieler stellt Personal ein", ok, "%d Putzkräfte, Geld %d" % [_putzkraefte(), _hud()._money])

		# 6 Abstimmung 1: Chef will schlafen, Koch und Lager sagen Nein → kein Tag
		await _warte(1.0)
		if rolle == "chef":
			gm.net_sleep.rpc_id(1)
		ok = await _bis(func() -> bool: return _hud().is_vote_open(), 15.0)
		_pruefe("Abstimmung 1 erscheint", ok, "")
		if rolle in ["koch", "lager"]:
			await _warte(1.0)
			gm.net_abstimmen.rpc_id(1, false)
		ok = await _bis(func() -> bool: return not _hud().is_vote_open(), 40.0)
		await _warte(1.0)
		_pruefe("Mehrheit Nein: kein neuer Tag", ok and gm._phase == gm.Phase.INTERMISSION, "Phase %d" % gm._phase)

		# 7 Abstimmung 2: Koch und Lager sagen Ja → Tag startet für alle
		await _warte(2.0)
		if rolle == "chef":
			gm.net_sleep.rpc_id(1)
		ok = await _bis(func() -> bool: return _hud().is_vote_open(), 15.0)
		_pruefe("Abstimmung 2 erscheint", ok, "")
		if rolle in ["koch", "lager"]:
			await _warte(1.0)
			gm.net_abstimmen.rpc_id(1, true)
		ok = await _bis(func() -> bool: return gm._phase == gm.Phase.SHIFT, 20.0)
		_pruefe("Mehrheit Ja: Schicht beginnt", ok, "Phase %d" % gm._phase)
		var t_schicht := Time.get_ticks_msec()

		# 7b Zelt ist nach dem Aufstehen noch zu — der Chef sticht am Eingang an
		ok = await _bis(func() -> bool: return not gm._zelt_offen, 10.0)
		_pruefe("Zelt nach Tagesstart noch zu", ok, "")
		if rolle == "chef":
			await _warte(2.0)
			gm.net_zelt_eroeffnen.rpc_id(1)
		ok = await _bis(func() -> bool: return gm._zelt_offen, 15.0)
		_pruefe("Zelt eröffnet (bei allen)", ok, "")

		# 8 Putz fliegt raus und kommt mit dem Code zurück
		if rolle == "putz":
			await _warte_bis_ms(t_schicht + 20000)
			await _neu_beitreten()
		# 9 Nach 100 s Schicht: Gäste da, alle wieder vollzählig
		await _warte_bis_ms(t_schicht + 100000)
		ok = await _bis(func() -> bool: return gm._guests.size() > 0, 30.0)
		_pruefe("Gäste kommen ins Zelt", ok, "%d Gäste" % gm._guests.size())
		ok = await _bis(func() -> bool: return gm._players_nodes.size() == 4 and gm._spieler_info.size() == 4, 30.0)
		_pruefe("nach Rausfliegen wieder vier mit Namen", ok, "%d Spieler, Namen %s" % [gm._players_nodes.size(), _info_namen()])
		_figuren_und_namen_pruefen()
		_log("Geld %d, Uhr %.2f, Bier %s, Essen %s" % [_hud()._money, _hud()._clock, _zustand().get("bier", 0), _zustand().get("essen", 0)])
		await _warte(3.0)
		Net.disconnect_game()
		await _post("verlassen", {"code": code, "id": id})

	func _neu_beitreten() -> void:
		_log("-- rausfliegen und mit Code zurück")
		Net.disconnect_game()
		get_tree().change_scene_to_file("res://scenes/ui/hauptmenue.tscn")
		gm = null
		await _warte(3.0)
		var r := await _post("beitreten", {"code": code, "name": ich.name, "version": KoopDaten.version()})
		_pruefe("Wiederbeitritt: Platz im Warteraum", r.get("ok", false), str(r.get("fehler", "")))
		if not r.get("ok", false):
			# Platz wird erst frei, wenn das Spiel den Abgang meldet (bis ~55 s)
			for i in 12:
				await _warte(6.0)
				r = await _post("beitreten", {"code": code, "name": ich.name, "version": KoopDaten.version()})
				if r.get("ok", false):
					break
			_pruefe("Wiederbeitritt nach Abgangsmeldung", r.get("ok", false), str(r.get("fehler", "")))
			if not r.get("ok", false):
				return
		id = str(r.id)
		r = await _post("setzen", {"code": code, "id": id, "figur": ich.figur})
		_pruefe("Wiederbeitritt: Wahl gesetzt", r.get("ok", false), str(r.get("fehler", "")))
		await _beitreten(true)

	func _figuren_und_namen_pruefen() -> void:
		var falsch: Array[String] = []
		for peer in gm._players_nodes.keys():
			if int(peer) == multiplayer.get_unique_id():
				continue
			var info: Dictionary = gm._spieler_info.get(peer, {})
			var p: Node = gm._players_nodes[peer]
			var soll: String = Figuren.ALLE[int(info.get("figur", 0))].resource_path
			var ist: String = p.get_node("Model").scene_file_path
			var schild: Label3D = p.get_node("Namensschild")
			if ist != soll or not schild.visible or not schild.text.contains(str(info.get("name", "?"))):
				falsch.append("%s: %s / '%s'" % [info.get("name", peer), ist.get_file(), schild.text])
		_pruefe("Mitspieler mit richtiger Figur und Namensschild", falsch.is_empty(), ", ".join(falsch))

	func _info_namen() -> String:
		var n: Array[String] = []
		for d: Dictionary in gm._spieler_info.values():
			n.append(str(d.get("name", "")))
		n.sort()
		return ",".join(n)

	func _putzkraefte() -> int:
		var n := 0
		for s: Array in _zustand().get("staff", []):
			if int(s[0]) == ROLE_REINIGUNG:
				n += 1
		return n

	func _hud() -> Node:
		return gm.get_node("HUD")

	func _zustand() -> Dictionary:
		return _hud()._zustand

	# ------------------------------------------------------------ Werkzeug
	func _bis(bedingung: Callable, sekunden: float) -> bool:
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < sekunden * 1000.0:
			if gm == null or not is_instance_valid(gm):
				return false
			if bedingung.call():
				return true
			await get_tree().process_frame
		return bedingung.call() if gm and is_instance_valid(gm) else false

	func _warte(sekunden: float) -> void:
		await get_tree().create_timer(sekunden).timeout

	func _warte_bis_ms(ms: int) -> void:
		var rest := ms - Time.get_ticks_msec()
		if rest > 0:
			await _warte(rest / 1000.0)

	func _post(pfad: String, daten: Dictionary) -> Dictionary:
		var http := HTTPRequest.new()
		http.timeout = 10.0
		add_child(http)
		http.request(KoopDaten.LOBBY_URL + pfad, PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(daten))
		var antwort: Array = await http.request_completed
		http.queue_free()
		var d: Variant = JSON.parse_string((antwort[3] as PackedByteArray).get_string_from_utf8())
		return d if d is Dictionary else {"ok": false, "fehler": "HTTP %d/%d" % [antwort[0], antwort[1]]}

	func _log(text: String) -> void:
		print("[%s] %s" % [rolle, text])

	func _pruefe(name: String, ok: bool, info := "") -> void:
		print("[%s]   [%s] %s  %s" % [rolle, "OK  " if ok else "FAIL", name, info])
		if not ok:
			fehler += 1

	func _ende() -> void:
		print("[%s] ERGEBNIS: %s (%d Fehler)" % [rolle, "BESTANDEN" if fehler == 0 else "FEHLGESCHLAGEN", fehler])
		get_tree().quit(1 if fehler else 0)
