extends Control
## Hauptmenü. Aussehen und Anordnung liegen als Knoten in scenes/ui/hauptmenue.tscn
## und sind im Editor änderbar — hier steht nur, was die Knöpfe tun.
## Alle sichtbaren Texte sind Übersetzungsschlüssel (locale/texte.csv).

const EINSTELLUNGEN_SZENE := "res://scenes/ui/einstellungen.tscn"
const SERVER_IP := "185.248.140.225"
const Texte := preload("res://scripts/ui/texte.gd")

@onready var _haupt: Control = %Hauptspalte
@onready var _weiter: Button = %Weiterspielen
@onready var _weiter_info: Label = %WeiterInfo
@onready var _laden: Button = %Laden
@onready var _neu: Button = %NeuesSpiel
@onready var _einst: Button = %Einstellungen
@onready var _koop_panel: Control = %KoopPanel
@onready var _credits_panel: Control = %CreditsPanel
@onready var _spielstand_panel: Control = %SpielstandPanel
@onready var _ip: LineEdit = %IpEingabe
@onready var _status: Label = %Status
@onready var _version: Label = %Version
@onready var _bestaetigen: ConfirmationDialog = %NeuBestaetigen

## Spielstand-Panel: true = Platz für ein neues Spiel wählen, false = laden
var _modus_neu := false
var _gewaehlter_platz := 0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	_weiter.pressed.connect(func() -> void: Net.start_solo(false, Net.letzter_slot()))
	_laden.pressed.connect(_zeige_spielstaende.bind(false))
	_neu.pressed.connect(_zeige_spielstaende.bind(true))
	%Koop.pressed.connect(_zeige.bind(_koop_panel))
	_einst.pressed.connect(_on_einstellungen)
	%Credits.pressed.connect(_zeige.bind(_credits_panel))
	%Beenden.pressed.connect(func() -> void: get_tree().quit())

	for platz in range(1, Net.SLOTS + 1):
		_platz_knopf(platz).pressed.connect(_on_platz.bind(platz))
	%SpielstandZurueck.pressed.connect(_zeige.bind(_haupt))

	%ServerBeitreten.pressed.connect(_verbinde.bind(SERVER_IP))
	%Hosten.pressed.connect(_on_hosten)
	%IpBeitreten.pressed.connect(_on_ip_beitreten)
	_ip.text_submitted.connect(func(_t: String) -> void: _on_ip_beitreten())
	%KoopZurueck.pressed.connect(_zeige.bind(_haupt))
	%CreditsZurueck.pressed.connect(_zeige.bind(_haupt))
	_bestaetigen.confirmed.connect(func() -> void: Net.start_solo(true, _gewaehlter_platz))

	# Solange das Einstellungsmenü noch nicht existiert, Knopf nicht anbieten.
	_einst.disabled = not ResourceLoader.exists(EINSTELLUNGEN_SZENE)

	if not Net.connection_failed.is_connected(_on_verbindung_fehlgeschlagen):
		Net.connection_failed.connect(_on_verbindung_fehlgeschlagen)
	Einstellungen.geaendert.connect(_texte_aktualisieren)
	_texte_aktualisieren()
	_zeige(_haupt)
	_menue_musik()
	SteamDienst.status_setzen("#Status_Menue")
	# Warum das letzte Spiel endete (Host weg, andere Version …)
	if Net.meldung != "":
		_zeige_meldung()

func _zeige_meldung() -> void:
	var text := tr(Net.meldung)
	_status.text = text % Net.meldung_werte if not Net.meldung_werte.is_empty() else text
	Net.meldung = ""
	Net.meldung_werte = []

## Menümusik aus assets/audio/musik/menue.* — ohne Datei bleibt es still.
func _menue_musik() -> void:
	var spieler: AudioStreamPlayer = %MenueMusik
	for endung in [".ogg", ".wav", ".mp3"]:
		var pfad: String = "res://assets/audio/musik/menue" + endung
		if ResourceLoader.exists(pfad):
			spieler.stream = load(pfad)
			spieler.finished.connect(spieler.play)
			spieler.play()
			return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _haupt.visible:
		_zeige(_haupt)
		get_viewport().set_input_as_handled()

## Texte mit Platzhaltern — die statischen übersetzt Godot von selbst.
func _texte_aktualisieren() -> void:
	_version.text = tr("MENU_VERSION") % Net.version_text()
	var letzter := Net.letzter_slot()
	_weiter.visible = letzter > 0
	_weiter_info.visible = _weiter.visible
	_laden.visible = letzter > 0
	if _weiter.visible:
		var info := Net.speicherstand_info(letzter)
		_weiter_info.text = tr("MENU_CONTINUE_INFO") % [info["day"], Texte.geld(info["money"])]
	if _spielstand_panel.visible:
		_plaetze_aktualisieren()

func _zeige(panel: Control) -> void:
	for p: Control in [_haupt, _koop_panel, _credits_panel, _spielstand_panel]:
		p.visible = p == panel
	_status.text = ""
	if panel == _haupt:
		(_weiter if _weiter.visible else _neu).grab_focus()

# ------------------------------------------------------------ Spielstände
func _zeige_spielstaende(neu: bool) -> void:
	_modus_neu = neu
	_plaetze_aktualisieren()
	_zeige(_spielstand_panel)
	_platz_knopf(1).grab_focus()

func _plaetze_aktualisieren() -> void:
	%SpielstandTitel.text = tr("SLOTS_TITLE_NEW" if _modus_neu else "SLOTS_TITLE_LOAD")
	for platz in range(1, Net.SLOTS + 1):
		var info := Net.speicherstand_info(platz)
		var knopf := _platz_knopf(platz)
		var text: Label = get_node("%%PlatzInfo%d" % platz)
		knopf.text = tr("SLOT_NEW" if _modus_neu else "SLOT_LOAD")
		if info.is_empty():
			text.text = tr("SLOT_EMPTY") % platz
			knopf.disabled = not _modus_neu
		elif info.zu_neu:
			text.text = tr("SLOT_TOO_NEW") % platz
			knopf.disabled = not _modus_neu
		else:
			text.text = tr("SLOT_INFO") % [platz, info.day, Texte.euro(info.money), _datum(info.saved_at)]
			knopf.disabled = false

func _on_platz(platz: int) -> void:
	if not _modus_neu:
		Net.start_solo(false, platz)
		return
	_gewaehlter_platz = platz
	if Net.speicherstand_info(platz).is_empty():
		Net.start_solo(true, platz)
	else:
		_bestaetigen.popup_centered()

func _platz_knopf(platz: int) -> Button:
	return get_node("%%PlatzKnopf%d" % platz)

## Speicherzeit in Ortszeit, z. B. "10.09. 21:30".
func _datum(unix: int) -> String:
	if unix <= 0:
		return "—"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "%02d.%02d. %02d:%02d" % [d.day, d.month, d.hour, d.minute]

# ------------------------------------------------------------ Einstellungen, Koop
func _on_einstellungen() -> void:
	var szene := load(EINSTELLUNGEN_SZENE) as PackedScene
	if szene:
		add_child(szene.instantiate())

func _on_hosten() -> void:
	var err := Net.host_game()
	if err != OK:
		_status.text = tr("STATUS_HOST_FAILED") % err

func _on_ip_beitreten() -> void:
	var ip := _ip.text.strip_edges()
	if ip.is_empty():
		_status.text = tr("STATUS_ENTER_IP")
		return
	_verbinde(ip)

func _verbinde(ip: String) -> void:
	_status.text = tr("STATUS_CONNECTING") % ip
	if Net.join_game(ip) != OK:
		_status.text = tr("STATUS_CONNECT_FAILED")

func _on_verbindung_fehlgeschlagen() -> void:
	if Net.meldung == "":
		Net.meldung = "STATUS_CONNECT_FAILED"
	_zeige_meldung()
