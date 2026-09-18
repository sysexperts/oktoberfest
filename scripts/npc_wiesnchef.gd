extends Node3D
## Der Wiesnchef: steht am Kirmestor. Nach dem Brief von Onkel Sepp
## (scripts/ui/kino.gd) redet er in Sprechblasen über seinem Kopf und läuft zum
## Zelteingang voraus — das ist die erste Mission. Die Spieler können sich dabei
## frei bewegen. Läuft bei jedem Spieler lokal dieselbe Strecke, deshalb braucht
## es kein Netz.
##
## Die Figur steckt als Kind „Model" in der Szene (siehe scripts/figur.gd),
## die Sprechblase als Label3D „Sprechblase".

const Figuren := preload("res://scripts/figuren.gd")
const TEMPO := 1.55
## Wie lange eine Zeile stehen bleibt (Sekunden)
const ZEILE_DAUER := 5.0

## Welche Figur (Index in Figuren.ALLE)
@export var figur_nr := 2
## Strecke vom Tor über die Nordallee zum Zelteingang
@export var weg: Array[Vector3] = [
	Vector3(0.5, 0, 70.0),
	Vector3(0.0, 0, 58.0),
	Vector3(0.0, 0, 40.0),
	Vector3(0.0, 0, 26.0),
	Vector3(2.5, 0, 18.5),
	Vector3(3.6, 0, 15.6),
]
## Was er am Tor sagt (danach geht er los), unterwegs und am Zelt.
## Texte: locale/texte.csv, <Schlüssel>_DU / _IHR.
@export var zeilen_tor: Array[String] = ["CHEF_1", "CHEF_2", "CHEF_3"]
@export var zeilen_weg: Array[String] = ["CHEF_4", "CHEF_5", "CHEF_6"]
@export var zeile_ziel := "CHEF_7"

@onready var _blase: Label3D = get_node_or_null("Sprechblase")

var _figur: Figur
var _punkt := -1
var _mehrere := false
## Warteschlange der noch zu sagenden Zeilen, "" = losgehen
var _rede: Array[String] = []
var _rede_t := 0.0
var _ziel_gesagt := true

func _ready() -> void:
	add_to_group("wiesnchef")
	_figur = Figuren.einsetzen(self, Figuren.ALLE[posmod(figur_nr, Figuren.ALLE.size())])
	_figur.stehen()
	rotation.y = 0.0

## Nach dem Brief: am Tor reden, dann vorauslaufen und unterwegs weiterreden.
func reden(mehrere: bool) -> void:
	_mehrere = mehrere
	_rede.clear()
	_rede.append_array(zeilen_tor)
	_rede.append("")
	_rede.append_array(zeilen_weg)
	_ziel_gesagt = false
	_rede_t = 0.0
	_naechste_zeile()

## Direkt zum Zelt laufen (ohne Gerede)
func losgehen() -> void:
	if _punkt >= 0:
		return
	_punkt = 0
	_figur.gehen()

## true, sobald er am Zelt angekommen ist
func angekommen() -> bool:
	return _punkt >= weg.size()

func _naechste_zeile() -> void:
	while not _rede.is_empty() and _rede[0] == "":
		_rede.pop_front()
		losgehen()
	if _rede.is_empty():
		_sagen("")
		return
	_sagen(_rede.pop_front())
	if _punkt < 0:
		geste()

func _sagen(key: String) -> void:
	_rede_t = 0.0
	if _blase == null:
		return
	_blase.visible = key != ""
	if key != "":
		_blase.text = String(TranslationServer.translate(key + ("_IHR" if _mehrere else "_DU")))

func _process(delta: float) -> void:
	if _blase and _blase.visible:
		_rede_t += delta
		if _rede_t >= ZEILE_DAUER:
			_naechste_zeile()
	if not _ziel_gesagt and angekommen():
		_ziel_gesagt = true
		_rede.clear()
		_sagen(zeile_ziel)
		_rede_t = -4.0   # letzte Zeile länger stehen lassen
	if _punkt < 0 or _punkt >= weg.size():
		return
	var ziel: Vector3 = weg[_punkt]
	var zu := ziel - global_position
	zu.y = 0.0
	if zu.length() < 0.25:
		_punkt += 1
		if _punkt >= weg.size():
			_figur.stehen()
			# am Eingang den nachkommenden Spielern zuwenden (Norden)
			rotation.y = 0.0
		return
	global_position += zu.normalized() * minf(TEMPO * delta, zu.length())
	rotation.y = atan2(zu.x, zu.z)

## Beim Reden gestikulieren: eine Steh-Extraanimation, danach wieder stehen.
func geste() -> void:
	if _punkt >= 0 or _figur == null:
		return
	if not _figur.extra():
		return
	get_tree().create_timer(2.6).timeout.connect(func() -> void:
		if _punkt < 0 and is_instance_valid(_figur):
			_figur.stehen())
