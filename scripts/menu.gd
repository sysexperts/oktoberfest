extends Control
## Hauptmenü. Aussehen und Anordnung liegen als Knoten in menu.tscn und sind im
## Editor änderbar — hier steht nur, was die Knöpfe tun.
## Alle sichtbaren Texte sind Übersetzungsschlüssel (locale/texte.csv).

const EINSTELLUNGEN_SZENE := "res://scenes/ui/einstellungen.tscn"
const SERVER_IP := "185.248.140.225"
const Texte := preload("res://scripts/ui/texte.gd")

@onready var _haupt: Control = %Hauptspalte
@onready var _weiter: Button = %Weiterspielen
@onready var _weiter_info: Label = %WeiterInfo
@onready var _neu: Button = %NeuesSpiel
@onready var _einst: Button = %Einstellungen
@onready var _koop_panel: Control = %KoopPanel
@onready var _credits_panel: Control = %CreditsPanel
@onready var _ip: LineEdit = %IpEingabe
@onready var _status: Label = %Status
@onready var _version: Label = %Version
@onready var _bestaetigen: ConfirmationDialog = %NeuBestaetigen

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	_weiter.pressed.connect(func() -> void: Net.start_solo(false))
	_neu.pressed.connect(_on_neues_spiel)
	%Koop.pressed.connect(_zeige.bind(_koop_panel))
	_einst.pressed.connect(_on_einstellungen)
	%Credits.pressed.connect(_zeige.bind(_credits_panel))
	%Beenden.pressed.connect(func() -> void: get_tree().quit())

	%ServerBeitreten.pressed.connect(_verbinde.bind(SERVER_IP))
	%Hosten.pressed.connect(_on_hosten)
	%IpBeitreten.pressed.connect(_on_ip_beitreten)
	_ip.text_submitted.connect(func(_t: String) -> void: _on_ip_beitreten())
	%KoopZurueck.pressed.connect(_zeige.bind(_haupt))
	%CreditsZurueck.pressed.connect(_zeige.bind(_haupt))
	_bestaetigen.confirmed.connect(func() -> void: Net.start_solo(true))

	# Solange das Einstellungsmenü noch nicht existiert, Knopf nicht anbieten.
	_einst.disabled = not ResourceLoader.exists(EINSTELLUNGEN_SZENE)

	if not Net.connection_failed.is_connected(_on_verbindung_fehlgeschlagen):
		Net.connection_failed.connect(_on_verbindung_fehlgeschlagen)
	Einstellungen.geaendert.connect(_texte_aktualisieren)
	_texte_aktualisieren()
	_zeige(_haupt)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not _haupt.visible:
		_zeige(_haupt)
		get_viewport().set_input_as_handled()

## Texte mit Platzhaltern — die statischen übersetzt Godot von selbst.
func _texte_aktualisieren() -> void:
	_version.text = tr("MENU_VERSION") % Net.version_text()
	var info := Net.speicherstand_info()
	_weiter.visible = not info.is_empty()
	_weiter_info.visible = _weiter.visible
	if _weiter.visible:
		_weiter_info.text = tr("MENU_CONTINUE_INFO") % [info["day"], Texte.geld(info["money"])]

func _zeige(panel: Control) -> void:
	for p: Control in [_haupt, _koop_panel, _credits_panel]:
		p.visible = p == panel
	_status.text = ""
	if panel == _haupt:
		(_weiter if _weiter.visible else _neu).grab_focus()

func _on_neues_spiel() -> void:
	if Net.speicherstand_info().is_empty():
		Net.start_solo(true)
	else:
		_bestaetigen.popup_centered()

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
	_status.text = tr("STATUS_CONNECT_FAILED")
