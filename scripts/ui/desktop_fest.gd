extends Control
## Fest-App des Desktops (ab Kapitel 6): Motto, Band, Feuerwerk, Deko, Werbung und Aushilfen für das Fest von morgen planen.
## Der Server bucht und merkt sich den Plan (GameManager.net_fest_planen). Aufbau: scenes/ui/desktop_fest.tscn.

const Texte := preload("res://scripts/ui/texte.gd")

var _gm: Node
var _hud: Node
var _motto := 1
var _band := 1
var _feuer := 1

@onready var _motti: Array[Button] = [%Motto0, %Motto1, %Motto2, %Motto3, %Motto4]
@onready var _baende: Array[Button] = [%Band1, %Band2, %Band3]
@onready var _feuer_knoepfe: Array[Button] = [%Feuer0, %Feuer1, %Feuer2, %Feuer3]

func _ready() -> void:
	for i in _motti.size():
		_motti[i].pressed.connect(_motto_waehlen.bind(i))
	for i in _baende.size():
		_baende[i].pressed.connect(_band_waehlen.bind(i + 1))
	for i in _feuer_knoepfe.size():
		_feuer_knoepfe[i].pressed.connect(_feuer_waehlen.bind(i))
	for k: Button in [%Deko, %Werbung, %Hilfe]:
		k.toggled.connect(func(_an: bool) -> void: _anzeigen())
	%Planen.pressed.connect(_planen)

func einrichten(gm: Node, hud: Node) -> void:
	_gm = gm
	_hud = hud

func zeigen() -> void:
	_motto_waehlen(_motto)
	_band_waehlen(_band)
	_feuer_waehlen(_feuer)

func _process(_delta: float) -> void:
	if visible:
		_anzeigen()

func _zustand() -> Dictionary:
	return _hud.get("_zustand") if _hud != null else {}

func _motto_waehlen(i: int) -> void:
	_motto = i
	for k in _motti.size():
		_motti[k].set_pressed_no_signal(k == i)
	_anzeigen()

func _band_waehlen(i: int) -> void:
	_band = i
	for k in _baende.size():
		_baende[k].set_pressed_no_signal(k + 1 == i)
	_anzeigen()

func _feuer_waehlen(i: int) -> void:
	_feuer = i
	for k in _feuer_knoepfe.size():
		_feuer_knoepfe[k].set_pressed_no_signal(k == i)
	_anzeigen()

func _kosten() -> int:
	return int(_gm.fest_kosten(_band, _feuer, %Deko.button_pressed, %Werbung.button_pressed, %Hilfe.button_pressed))

func _anzeigen() -> void:
	if _gm == null:
		return
	var z := _zustand()
	var rang_namen := ["FEST_RANG_0", "FEST_RANG_1", "FEST_RANG_2", "FEST_RANG_3", "FEST_RANG_4"]
	var ruhm := int(z.get("fest_ruhm", 0))
	var rang := 0
	for i in _gm.FEST_RAENGE.size():
		if ruhm >= int(_gm.FEST_RAENGE[i]):
			rang = i
	%Ruhm.text = tr("FEST_RUHM") % [ruhm, tr(rang_namen[rang]), int(z.get("konrad_ruhm", 0))]
	var geplant: Dictionary = z.get("fest", {})
	var moeglich := bool(z.get("fest_moeglich", false))
	if not geplant.is_empty():
		%Status.text = tr("FEST_STATUS_GEPLANT") % [int(geplant.get("tag", 0)), tr("FEST_MOTTO_%d" % int(geplant.get("motto", 0)))]
	elif moeglich:
		%Status.text = tr("FEST_STATUS_MOEGLICH")
	else:
		%Status.text = tr("FEST_STATUS_PAUSE") % (int(z.get("fest_letzter", -100)) + int(_gm.FEST_PAUSE))
	for i in _motti.size():
		_motti[i].text = tr("FEST_MOTTO_%d" % i)
	for i in _baende.size():
		_baende[i].text = tr("FEST_BAND_%d" % (i + 1)) % Texte.euro(int(_gm.FEST_BAND_PREIS[i + 1]))
	for i in _feuer_knoepfe.size():
		var t := tr("FEST_FEUER_%d" % i)
		_feuer_knoepfe[i].text = t % Texte.euro(int(_gm.FEST_FEUER_PREIS[i])) if i > 0 else t
	%Deko.text = tr("FEST_DEKO") % Texte.euro(int(_gm.FEST_DEKO_PREIS))
	%Werbung.text = tr("FEST_WERBUNG") % Texte.euro(int(_gm.FEST_WERBUNG_PREIS))
	%Hilfe.text = tr("FEST_HILFE") % Texte.euro(int(_gm.FEST_HILFE_PREIS))
	%Summe.text = tr("FEST_SUMME") % Texte.euro(_kosten())
	%Planen.disabled = not moeglich

func _planen() -> void:
	_gm.net_fest_planen.rpc_id(1, _motto, _band, _feuer, %Deko.button_pressed, %Werbung.button_pressed, %Hilfe.button_pressed)
