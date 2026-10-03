extends Control
## Warteraum der Steam-Lobby: bis zu vier Spieler mit Steam-Profilbild, Name und
## gewählter Figur, der Beitrittscode, die Freundesliste zum Einladen und der
## Start. Das Spiel beginnt erst, wenn der Host „Spiel starten" drückt; die Gäste
## folgen automatisch (Lobbydaten "start" = 1).
## Aufbau: scenes/ui/steam_warteraum.tscn.

const KoopDaten := preload("res://scripts/koop_daten.gd")
const Figuren := preload("res://scripts/figuren.gd")
const Texte := preload("res://scripts/ui/texte.gd")
const FreundZeile := preload("res://scenes/ui/steam_freund_zeile.tscn")
const HAUPTMENUE := "res://scenes/ui/hauptmenue.tscn"
const EINSTELLUNGS_DATEI := "user://koop.cfg"
## Pause nach „start", damit der Host seine Seite der Verbindung offen hat
const BEITRITT_VERZOEGERUNG := 1.5

## Woher die Daten kommen: im Spiel der Autoload SteamDienst; die Sichtprobe
## (tools/render_steam_warteraum.tscn) setzt einen Ersatz mit denselben Funktionen.
var quelle: Object = SteamDienst

var _figur := -1
var _start_war_schon_da := false
var _beitritt_laeuft := false
var _freunde_stand := ""
var _eingeladen := {}
## Welt, mit der der Host startet: Platz, neu beginnen?, Schwierigkeit (bei neu)
var _welt := {"platz": 1, "neu": false, "schwierigkeit": 1}

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for i in %Karten.get_child_count():
		var karte := %Karten.get_child(i)
		karte.verzoegerung = 0.25 + i * 0.1
		karte.figur_waehlen.connect(_wahl_oeffnen)
		karte.einladen.connect(_overlay_einladen)
	%Wahl.gewaehlt.connect(_figur_gewaehlt)
	%WeltAendern.pressed.connect(_welt_oeffnen)
	%Welt.gewaehlt.connect(_welt_gewaehlt)
	%Welt.geschlossen.connect(func() -> void: %WeltAendern.grab_focus())
	%Wahl.geschlossen.connect(func() -> void: %Bereit.grab_focus())
	%Kopieren.pressed.connect(_kopieren)
	%Bereit.toggled.connect(_bereit_gesetzt)
	%Los.pressed.connect(_los)
	%Verlassen.pressed.connect(_verlassen)
	%Takt.timeout.connect(_aktualisieren)
	if quelle.has_signal("lobby_aktualisiert"):
		quelle.lobby_aktualisiert.connect(_aktualisieren)
	if not Net.connection_failed.is_connected(_on_verbindung_fehlgeschlagen):
		Net.connection_failed.connect(_on_verbindung_fehlgeschlagen)
	_eingang_animieren()
	_start_pulsieren()
	_start_war_schon_da = quelle.lobby_wert("start") == "1"
	_figur = _gemerkte_figur()
	_welt_vorbelegen()
	_aktualisieren()
	# Controller: ohne angewählten Knopf käme man mit dem Steuerkreuz nirgends hinein
	%Bereit.grab_focus.call_deferred()

# ------------------------------------------------------------ Bewegung
## Das Fenster blendet sich ein.
func _eingang_animieren() -> void:
	var fenster: Control = %Fenster
	# Die Größe regelt Passend (scripts/ui/passend.gd) — hier nur einblenden
	fenster.modulate.a = 0.0
	create_tween().tween_property(fenster, "modulate:a", 1.0, 0.4)

## Der Startknopf atmet leicht, damit er als Hauptknopf auffällt
func _start_pulsieren() -> void:
	var t := create_tween().set_loops()
	t.tween_property(%Los, "self_modulate", Color(1.14, 1.08, 0.92), 1.1).set_trans(Tween.TRANS_SINE)
	t.tween_property(%Los, "self_modulate", Color.WHITE, 1.1).set_trans(Tween.TRANS_SINE)

# ------------------------------------------------------------ Anzeige
func _aktualisieren() -> void:
	if not is_inside_tree():
		return
	var mitglieder: Array = quelle.lobby_mitglieder()
	if mitglieder.is_empty() and quelle.lobby_id == 0:
		# Lobby gibt es nicht mehr (Host weg, Verbindung zu Steam verloren)
		_zum_menue()
		return
	var ich := _eigener_eintrag(mitglieder)
	# Erste Anmeldung: eine Figur nehmen, die noch keiner hat
	if not ich.is_empty() and int(ich.get("figur", -1)) < 0:
		if _figur < 0 or _belegt(mitglieder).has(_figur):
			_figur = _erste_freie_figur(mitglieder)
		quelle.mitglied_setzen("figur", str(_figur))
		ich["figur"] = _figur
	var max_spieler: int = Net.MAX_PLAYERS
	%Untertitel.text = tr("SW_SUB") % [mitglieder.size(), max_spieler]
	var code_text: String = quelle.lobby_wert("code_text")
	%Code.text = code_text if code_text != "" else str(quelle.lobby_code)
	for i in %Karten.get_child_count():
		var karte := %Karten.get_child(i)
		if i < mitglieder.size():
			var d: Dictionary = (mitglieder[i] as Dictionary).duplicate()
			d["textur"] = quelle.avatar_textur(int(d["id"]))
			karte.zeige(d)
		else:
			karte.leer()
	_start_zeigen(mitglieder, ich)
	_welt_zeigen(ich.get("host", false))
	_freunde_zeigen(mitglieder)

func _eigener_eintrag(mitglieder: Array) -> Dictionary:
	for m: Dictionary in mitglieder:
		if m.get("ich", false):
			return m
	return {}

func _host_name(mitglieder: Array) -> String:
	for m: Dictionary in mitglieder:
		if m.get("host", false):
			return str(m["name"])
	return ""

func _start_zeigen(mitglieder: Array, ich: Dictionary) -> void:
	var bin_host: bool = ich.get("host", false)
	var gestartet: bool = quelle.lobby_wert("start") == "1"
	%Bereit.visible = not gestartet
	%Bereit.set_pressed_no_signal(ich.get("bereit", false))
	%Los.visible = false
	if _beitritt_laeuft:
		%Status.text = tr("SW_STARTING")
		%Bereit.visible = false
	elif gestartet and not bin_host:
		if _start_war_schon_da:
			# Das Spiel lief schon, als wir kamen: erst auf Knopfdruck einsteigen
			%Los.visible = true
			%Los.text = tr("SW_JOIN")
			%Status.text = tr("SW_RUNNING")
		else:
			%Status.text = tr("SW_STARTING")
			_beitritt_planen()
	elif bin_host:
		%Los.visible = true
		%Los.text = tr("SW_START")
		%Status.text = ""
	else:
		%Status.text = tr("SW_WAIT_HOST") % _host_name(mitglieder)

func _freunde_zeigen(mitglieder: Array) -> void:
	var drin := {}
	for m: Dictionary in mitglieder:
		drin[int(m["id"])] = true
	var freunde: Array = []
	for f: Dictionary in quelle.freunde():
		if not drin.has(int(f["id"])):
			freunde.append(f)
	# Nur neu aufbauen, wenn sich etwas geändert hat — sonst flackern die Knöpfe
	var stand := ""
	for f: Dictionary in freunde:
		stand += "%d:%s:%s;" % [int(f["id"]), f["status"], quelle.avatar_textur(int(f["id"])) != null]
	if stand == _freunde_stand:
		return
	_freunde_stand = stand
	for k in %FreundeListe.get_children():
		if k != %FreundeLeer:
			k.queue_free()
	%FreundeLeer.visible = freunde.is_empty()
	%FreundeAnzahl.text = str(freunde.size())
	var nr := 0
	for f: Dictionary in freunde:
		var zeile := FreundZeile.instantiate()
		zeile.verzoegerung = nr * 0.07
		nr += 1
		%FreundeListe.add_child(zeile)
		var d := f.duplicate()
		d["textur"] = quelle.avatar_textur(int(f["id"]))
		zeile.zeige(d)
		if _eingeladen.has(int(f["id"])):
			zeile.als_eingeladen()
		zeile.einladen.connect(_freund_einladen)

# ------------------------------------------------------------ Welt (Spielstand)
## Wer hostet, spielt zuerst mit dem zuletzt benutzten Stand weiter — oder beginnt
## neu, wenn es noch keinen gibt. Ändern lässt es sich bis zum Start.
func _welt_vorbelegen() -> void:
	var platz := Net.letzter_slot()
	_welt = {"platz": maxi(platz, 1), "neu": platz == 0, "schwierigkeit": Net.schwierigkeit}

## Kurzfassung für die Lobbydaten, damit die Gäste sehen, was gespielt wird:
## "L|platz|tag|geld|zeit" (weiterspielen) oder "N|platz|schwierigkeit" (neu)
func _welt_code() -> String:
	var platz: int = _welt["platz"]
	if _welt["neu"]:
		return "N|%d|%d" % [platz, _welt["schwierigkeit"]]
	var info := Net.speicherstand_info(platz)
	return "L|%d|%d|%d|%d" % [platz, int(info.get("day", 1)), int(info.get("money", 0)), int(info.get("saved_at", 0))]

func _welt_zeigen(bin_host: bool) -> void:
	if bin_host:
		var code := _welt_code()
		if quelle.lobby_wert("welt") != code:
			quelle.lobby_setzen("welt", code)
	var teile := (_welt_code() if bin_host else str(quelle.lobby_wert("welt"))).split("|")
	%WeltAendern.visible = bin_host and quelle.lobby_wert("start") != "1"
	if teile.size() >= 3 and teile[0] == "N":
		%WeltHaupt.text = tr("SW_WORLD_NEW") % int(teile[1])
		%WeltSub.text = tr("SW_WORLD_DIFF") % tr("DIFF_%d" % clampi(int(teile[2]), 0, 2))
	elif teile.size() >= 5 and teile[0] == "L":
		%WeltHaupt.text = tr("SW_WORLD_LOAD") % [int(teile[1]), int(teile[2])]
		%WeltSub.text = "%s · %s" % [Texte.euro(int(teile[3])), Net.zeit_text(int(teile[4]))]
	else:
		%WeltHaupt.text = "…"
		%WeltSub.text = tr("SW_WORLD_HOST_PICKS")

func _welt_oeffnen() -> void:
	%Welt.zeigen(_welt["platz"], _welt["schwierigkeit"])

func _welt_gewaehlt(platz: int, neu: bool, schwierigkeit: int) -> void:
	_welt = {"platz": platz, "neu": neu, "schwierigkeit": schwierigkeit}
	_aktualisieren()

# ------------------------------------------------------------ Figur
func _belegt(mitglieder: Array) -> Dictionary:
	var belegt := {}
	for m: Dictionary in mitglieder:
		if not m.get("ich", false) and int(m.get("figur", -1)) >= 0:
			belegt[int(m["figur"])] = true
	return belegt

func _erste_freie_figur(mitglieder: Array) -> int:
	var belegt := _belegt(mitglieder)
	for i in Figuren.ALLE.size():
		if not belegt.has(i):
			return i
	return 0

func _wahl_oeffnen() -> void:
	%Wahl.zeigen(maxi(_figur, 0), _belegt(quelle.lobby_mitglieder()))

func _figur_gewaehlt(nr: int) -> void:
	_figur = nr
	quelle.mitglied_setzen("figur", str(nr))
	_figur_merken()
	_aktualisieren()

func _gemerkte_figur() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(EINSTELLUNGS_DATEI) == OK:
		return clampi(int(cfg.get_value("steam", "figur", -1)), -1, Figuren.ALLE.size() - 1)
	return -1

func _figur_merken() -> void:
	var cfg := ConfigFile.new()
	cfg.load(EINSTELLUNGS_DATEI)
	cfg.set_value("steam", "figur", _figur)
	cfg.save(EINSTELLUNGS_DATEI)

# ------------------------------------------------------------ Knöpfe
func _bereit_gesetzt(an: bool) -> void:
	quelle.mitglied_setzen("bereit", "1" if an else "0")
	_aktualisieren()

func _kopieren() -> void:
	DisplayServer.clipboard_set(%Code.text)
	%Kopieren.text = tr("SW_COPIED")
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(self):
			%Kopieren.text = tr("SW_COPY"))

func _overlay_einladen() -> void:
	quelle.freunde_einladen()

func _freund_einladen(steam_id: int) -> void:
	_eingeladen[steam_id] = true
	quelle.freund_einladen(steam_id)

func _wahl_fuer_das_spiel() -> void:
	var name_text := "Spieler"
	for m: Dictionary in quelle.lobby_mitglieder():
		if m.get("ich", false):
			name_text = str(m["name"])
	Net.player_name = name_text
	# Name und Figur stehen damit fest — das Lobby-Fenster im Spiel bleibt zu
	KoopDaten.lobby_wahl = {"name": name_text, "figur": maxi(_figur, 0), "id": ""}

func _los() -> void:
	_wahl_fuer_das_spiel()
	if quelle.bin_lobby_host():
		quelle.lobby_setzen("start", "1")
		if _welt["neu"]:
			Net.schwierigkeit = _welt["schwierigkeit"]
		if Net.host_steam(quelle.lobby_id, _welt["platz"], _welt["neu"]) != OK:
			quelle.lobby_setzen("start", "0")
			KoopDaten.lobby_wahl = {}
			%Status.text = tr("NET_STEAM_LOBBY_FAILED")
	else:
		_beitreten()

func _beitritt_planen() -> void:
	if _beitritt_laeuft:
		return
	_beitritt_laeuft = true
	get_tree().create_timer(BEITRITT_VERZOEGERUNG).timeout.connect(_beitreten)

func _beitreten() -> void:
	if not is_inside_tree():
		return
	_beitritt_laeuft = true
	_wahl_fuer_das_spiel()
	if Net.join_steam(quelle.lobby_id) != OK:
		_on_verbindung_fehlgeschlagen()
	else:
		_start_zeigen(quelle.lobby_mitglieder(), {})

func _on_verbindung_fehlgeschlagen() -> void:
	_beitritt_laeuft = false
	_start_war_schon_da = true
	KoopDaten.lobby_wahl = {}
	%Status.text = tr(Net.meldung if Net.meldung != "" else "NET_STEAM_JOIN_FAILED")
	Net.meldung = ""
	%Los.visible = true
	%Los.text = tr("SW_JOIN")

func _verlassen() -> void:
	quelle.lobby_verlassen()
	_zum_menue()

func _zum_menue() -> void:
	get_tree().change_scene_to_file(HAUPTMENUE)
