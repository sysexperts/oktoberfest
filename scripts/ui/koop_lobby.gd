extends Control
const KoopDaten := preload("res://scripts/koop_daten.gd")
## Warteraum mit Einladungscode. Einer erstellt ein Spiel und bekommt einen Code,
## Freunde treten damit bei. Jeder wählt Name und Figur; der Gastgeber drückt
## „Los", der Server startet ein eigenes Spiel und alle verbinden sich. Die Räume
## verwaltet der Vermittler auf dem Server (tools/server/vermittler.py), gefragt
## wird jede Sekunde.
## Aufbau: scenes/ui/koop_lobby.tscn.

const Texte := preload("res://scripts/ui/texte.gd")
const Symbole := preload("res://scripts/ui/symbole.gd")
const MenueMusik := preload("res://scripts/ui/menue_musik.gd")
const MENUE := "res://scenes/ui/hauptmenue.tscn"
const SERVER_IP := "185.248.140.225"
const EINSTELLUNGS_DATEI := "user://koop.cfg"

## Vermittler-Adresse; Tests setzen sie auf einen lokalen Vermittler
var lobby_url := KoopDaten.LOBBY_URL

var _code := ""
var _id := ""
var _raum := {}
var _figur := 0
var _name_gesendet := ""
var _verbinde := false
## Wartende Aktionen: [pfad, daten, rückruf] — eine HTTPRequest gleichzeitig
var _warteschlange: Array = []
var _aktion_laeuft := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Eigene Szene: die Musik des Hauptmenüs endet beim Szenenwechsel, hier
	# läuft dasselbe Stück weiter.
	MenueMusik.starten(%MenueMusik)
	%Erstellen.pressed.connect(_erstellen)
	%Beitreten.pressed.connect(_beitreten)
	%CodeEingabe.text_submitted.connect(func(_t: String) -> void: _beitreten())
	%Zurueck.pressed.connect(_zum_menue)
	%Mehr.pressed.connect(func() -> void:
		KoopDaten.menue_koop = true
		_zum_menue())
	%Kopieren.pressed.connect(_kopieren)
	%Verlassen.pressed.connect(_verlassen)
	%Los.pressed.connect(_los)
	for i in %Figuren.get_child_count():
		(%Figuren.get_child(i) as Button).pressed.connect(_figur_waehlen.bind(i))
	%Takt.timeout.connect(_abfragen)
	%Abfrage.request_completed.connect(_on_abfrage)
	%Aktion.request_completed.connect(_on_aktion)
	if not Net.connection_failed.is_connected(_on_verbindung_fehlgeschlagen):
		Net.connection_failed.connect(_on_verbindung_fehlgeschlagen)
	Einstellungen.geaendert.connect(_anzeigen)
	var cfg := ConfigFile.new()
	if cfg.load(EINSTELLUNGS_DATEI) == OK:
		%StartName.text = str(cfg.get_value("koop", "name", ""))
	_zeige_start()

func _exit_tree() -> void:
	# Nicht ins Spiel gewechselt → Platz im Warteraum freigeben
	if _id != "" and not _verbinde:
		_senden_ohne_antwort("verlassen", {"code": _code, "id": _id})

# ------------------------------------------------------------ Ansichten
func _zeige_start() -> void:
	%Start.visible = true
	%Warteraum.visible = false
	%Takt.stop()
	%StartName.grab_focus.call_deferred()
	if not %StartName.focus_entered.is_connected(_tastatur):
		%StartName.focus_entered.connect(_tastatur)

func _zeige_warteraum() -> void:
	%Start.visible = false
	%Warteraum.visible = true
	%Takt.start()
	_anzeigen()

func _status(text: String, fehler := false) -> void:
	for l: Label in [%StartStatus, %Status]:
		l.text = text
		l.add_theme_color_override("font_color", Color(1, 0.55, 0.45) if fehler else Color(1, 0.9, 0.6))

# ------------------------------------------------------------ Start
func _eingegebener_name() -> String:
	var n := (%StartName.text as String).strip_edges()
	if n == "":
		_status(tr("KOOP_NEED_NAME"), true)
		%StartName.grab_focus()
		return ""
	var cfg := ConfigFile.new()
	cfg.set_value("koop", "name", n)
	cfg.save(EINSTELLUNGS_DATEI)
	return n

func _erstellen() -> void:
	var n := _eingegebener_name()
	if n == "":
		return
	_status(tr("KOOP_WORKING"))
	_anfrage("erstellen", {"name": n, "version": KoopDaten.version()}, _on_raum_betreten)

func _beitreten() -> void:
	var n := _eingegebener_name()
	if n == "":
		return
	var code := (%CodeEingabe.text as String).strip_edges()
	if code == "":
		_status(tr("KOOP_NEED_CODE"), true)
		%CodeEingabe.grab_focus()
		return
	_status(tr("KOOP_WORKING"))
	_anfrage("beitreten", {"code": code, "name": n, "version": KoopDaten.version()}, _on_raum_betreten)

func _on_raum_betreten(antwort: Dictionary) -> void:
	_id = str(antwort.get("id", ""))
	_raum = antwort.get("raum", {})
	_code = str(_raum.get("code", ""))
	var ich := _ich()
	_figur = int(ich.get("figur", 0))
	# Der Name steht seit der Startseite fest — im Warteraum wählt man nur die Figur
	_name_gesendet = str(ich.get("name", ""))
	_status("")
	_zeige_warteraum()

# ------------------------------------------------------------ Warteraum
func _ich() -> Dictionary:
	for s: Dictionary in _raum.get("spieler", []):
		if s.get("ich", false):
			return s
	return {}

func _anzeigen() -> void:
	if _raum.is_empty():
		return
	var spieler: Array = _raum.get("spieler", [])
	%Code.text = _code
	%SpielerTitel.text = tr("KOOP_PLAYERS") % [spieler.size(), int(_raum.get("max", 4))]
	for i in %Liste.get_child_count():
		var zeile := %Liste.get_child(i)
		var name_l := zeile.get_node("Rand/Zeile/Text/SpielerName") as Label
		var info_l := zeile.get_node("Rand/Zeile/Text/SpielerInfo") as Label
		var symbol_l := zeile.get_node("Rand/Zeile/Kreis/Symbol") as TextureRect
		var punkt := zeile.get_node("Rand/Zeile/Punkt") as Control
		if i < spieler.size():
			var s: Dictionary = spieler[i]
			name_l.text = str(s.name) + ("  " + tr("KOOP_YOU") if s.get("ich", false) else "")
			var teile: Array[String] = []
			if s.get("host", false):
				teile.append(tr("KOOP_HOST_TAG"))
			teile.append(tr("KOOP_FIG_%d" % clampi(int(s.get("figur", 0)), 0, 2)))
			if s.get("im_spiel", false) and str(_raum.get("status", "")) == "laeuft":
				teile.append(tr("KOOP_IN_GAME"))
			info_l.text = " • ".join(teile)
			Symbole.setze(symbol_l, "person")
			symbol_l.modulate = Color(1, 1, 1)
			punkt.visible = true
			zeile.modulate = Color.WHITE
		else:
			# Freier Platz: Pluszeichen statt Person, kein grüner Punkt
			name_l.text = tr("KOOP_EMPTY_SLOT")
			info_l.text = ""
			Symbole.setze(symbol_l, "plus")
			symbol_l.modulate = Color(1, 1, 1, 0.5)
			punkt.visible = false
			zeile.modulate = Color(1, 1, 1, 0.45)
	# Figuren
	for i in %Figuren.get_child_count():
		var knopf := %Figuren.get_child(i) as Button
		knopf.button_pressed = i == _figur
		(knopf.get_node("Inhalt/Vorschau") as Control).set("gewaehlt", i == _figur)
		(knopf.get_node("Abzeichen") as Control).visible = i == _figur
		var fname := knopf.get_node("Inhalt/FigurName") as Label
		fname.text = tr("KOOP_FIG_%d" % i)
		# Gewählte Karte: goldener Rand und Haken stehen in der Szene
		fname.add_theme_color_override("font_color", Color(0.98, 0.96, 0.93) if i == _figur else Color(0.82, 0.79, 0.75))
	# Los / Warten
	var status := str(_raum.get("status", "warten"))
	var bin_host := str(_raum.get("host", "")) == _id
	var ich := _ich()
	var host_name := ""
	for s: Dictionary in spieler:
		if s.get("host", false):
			host_name = str(s.name)
	%Los.visible = false
	%Warten.visible = false
	if _verbinde:
		%Warten.visible = true
		%Warten.text = tr("KOOP_CONNECTING")
	elif status == "warten":
		%Los.visible = bin_host
		%Los.text = tr("KOOP_START")
		%Warten.visible = not bin_host
		%Warten.text = tr("KOOP_WAIT_HOST") % host_name
	elif status == "startet":
		%Warten.visible = true
		%Warten.text = tr("KOOP_STARTING")
	elif status == "laeuft":
		if ich.get("im_spiel", false):
			_ins_spiel()
		else:
			%Los.visible = true
			%Los.text = tr("KOOP_ENTER")
	var fehler := str(_raum.get("fehler", ""))
	if fehler != "" and status == "warten":
		_status(tr(fehler), true)

func _figur_waehlen(i: int) -> void:
	_figur = i
	_anzeigen()
	_anfrage("setzen", {"code": _code, "id": _id, "figur": i}, _on_raum_stand)

func _kopieren() -> void:
	DisplayServer.clipboard_set(_code)
	%Kopieren.text = tr("KOOP_COPIED")
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(self):
			%Kopieren.text = tr("KOOP_COPY"))

func _los() -> void:
	_anfrage("los", {"code": _code, "id": _id}, _on_raum_stand)

func _verlassen() -> void:
	_senden_ohne_antwort("verlassen", {"code": _code, "id": _id})
	_id = ""
	_code = ""
	_raum = {}
	_zeige_start()

func _zum_menue() -> void:
	get_tree().change_scene_to_file(MENUE)

func _on_raum_stand(antwort: Dictionary) -> void:
	if antwort.has("raum"):
		_raum = antwort.raum
		var ich := _ich()
		_figur = int(ich.get("figur", _figur))
	_anzeigen()

## Spiel läuft und wir sind dabei: Wahl mitnehmen und verbinden.
func _ins_spiel() -> void:
	if _verbinde:
		return
	_verbinde = true
	%Takt.stop()
	KoopDaten.lobby_wahl = {"name": _name_gesendet, "figur": _figur, "id": _id}
	Net.player_name = _name_gesendet
	_anzeigen()
	if Net.join_game(SERVER_IP, int(_raum.get("port", 0))) != OK:
		_on_verbindung_fehlgeschlagen()

func _on_verbindung_fehlgeschlagen() -> void:
	if not _verbinde:
		return
	_verbinde = false
	KoopDaten.lobby_wahl = {}
	_status(tr(Net.meldung if Net.meldung != "" else "STATUS_CONNECT_FAILED"), true)
	Net.meldung = ""
	%Takt.start()
	_anzeigen()

# ------------------------------------------------------------ Vermittler
func _abfragen() -> void:
	if _id == "" or _verbinde:
		return
	var abfrage: HTTPRequest = %Abfrage
	if abfrage.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	abfrage.request(lobby_url + "raum", _kopf(), HTTPClient.METHOD_POST, JSON.stringify({"code": _code, "id": _id}))

func _on_abfrage(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	var antwort := _auswerten(result, code, body)
	if _id == "" or _verbinde:
		return
	if antwort.get("ok", false):
		_on_raum_stand(antwort)
	elif str(antwort.get("fehler", "")) in ["LOBBY_ERR_GONE", "LOBBY_ERR_CODE"]:
		_verlassen()
		_status(tr(str(antwort.fehler)), true)

func _anfrage(pfad: String, daten: Dictionary, rueckruf: Callable) -> void:
	_warteschlange.append([pfad, daten, rueckruf])
	_naechste_aktion()

func _senden_ohne_antwort(pfad: String, daten: Dictionary) -> void:
	# Eigene Anfrage — der Knoten kann gleich weg sein, die Anfrage geht trotzdem raus
	# Beim Szenenwechsel ist der Baum beschäftigt — erst im nächsten Moment anhängen
	var http := HTTPRequest.new()
	var url := lobby_url + pfad
	var kopf := _kopf()
	http.request_completed.connect(func(_a: int, _b: int, _c: PackedStringArray, _d: PackedByteArray) -> void: http.queue_free())
	http.ready.connect(func() -> void:
		if http.request(url, kopf, HTTPClient.METHOD_POST, JSON.stringify(daten)) != OK:
			http.queue_free())
	get_tree().root.add_child.call_deferred(http)

func _naechste_aktion() -> void:
	if _aktion_laeuft or _warteschlange.is_empty():
		return
	var a: Array = _warteschlange[0]
	_aktion_laeuft = true
	if %Aktion.request(lobby_url + str(a[0]), _kopf(), HTTPClient.METHOD_POST, JSON.stringify(a[1])) != OK:
		_on_aktion(HTTPRequest.RESULT_CANT_CONNECT, 0, PackedStringArray(), PackedByteArray())

func _on_aktion(result: int, code: int, _h: PackedStringArray, body: PackedByteArray) -> void:
	_aktion_laeuft = false
	if _warteschlange.is_empty():
		return
	var a: Array = _warteschlange.pop_front()
	var antwort := _auswerten(result, code, body)
	if antwort.get("ok", false):
		(a[2] as Callable).call(antwort)
	else:
		_status(tr(str(antwort.get("fehler", "LOBBY_ERR_SERVER"))), true)
		# Stand trotzdem übernehmen (z. B. Abteilung schon belegt)
		if antwort.has("raum"):
			_on_raum_stand(antwort)
	_naechste_aktion()

func _auswerten(result: int, code: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return {"ok": false, "fehler": "LOBBY_ERR_SERVER"}
	var d: Variant = JSON.parse_string(body.get_string_from_utf8())
	return d if d is Dictionary else {"ok": false, "fehler": "LOBBY_ERR_SERVER"}

func _kopf() -> PackedStringArray:
	return PackedStringArray(["Content-Type: application/json"])

## Steam Deck: Steams Bildschirmtastatur ueber dem Namensfeld. Ohne Steam oder
## mit Maus und Tastatur passiert nichts.
func _tastatur() -> void:
	SteamDienst.tastatur_zeigen(%StartName)
